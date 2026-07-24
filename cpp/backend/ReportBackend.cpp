#include "ReportBackend.h"

#include "ReportOptionsBackend.h"
#include "SettingsBackend.h"

#include "ClientsModel.h"
#include "ObjectsModel.h"
#include "OrdersModel.h"
#include "SubobjectsFilterModel.h"
#include "SubobjectsModel.h"
#include "WorksModel.h"

#include "ClientsDatabase.h"
#include "DatabaseStorage.h"
#include "FileIo.h"
#include "ObjectsDatabase.h"
#include "PdfReportBuilder.h"
#include "QSettingsStore.h"
#include "WorksDatabase.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTemporaryFile>
#include <QUrl>

namespace workorder
{

namespace
{

const char *kClientIdKey = "report/current_client_id";
const char *kObjectIdKey = "report/current_object_id";

QVariantList mapsToVariantList(const StringMapList &items)
{
    QVariantList result;
    for(const QVariant &item : items)
        result.append(item);
    return result;
}

} // namespace

ReportBackend::ReportBackend(SettingsBackend *settingsBackend,
                             ReportOptionsBackend *reportOptionsBackend,
                             QQmlApplicationEngine *engine,
                             QObject *parent)
    : QObject(parent)
    , m_settingsBackend(settingsBackend)
    , m_reportOptionsBackend(reportOptionsBackend)
    , m_clients(new ClientsModel(this))
    , m_objects(new ObjectsModel(this))
    , m_orders(new OrdersModel(this))
    , m_works(new WorksModel(this))
    , m_workReport(new WorksModel(this))
    , m_subobjects(new SubobjectsModel(this))
    , m_subobjectsFilter(new SubobjectsFilterModel(this))
{
    ClientsDatabase::createClientTable();
    m_subobjectsFilter->setSourceModel(m_subobjects);
    registerModels(engine);
}

ReportBackend::~ReportBackend()
{
    if(!m_previewTempPath.isEmpty())
        QFile::remove(m_previewTempPath);
}

void ReportBackend::registerModels(QQmlApplicationEngine *engine)
{
    if(!engine)
        return;

    QQmlContext *context = engine->rootContext();
    context->setContextProperty("clientsModel", m_clients);
    context->setContextProperty("objectsModel", m_objects);
    context->setContextProperty("ordersModel", m_orders);
    context->setContextProperty("worksModel", m_works);
    context->setContextProperty("workReportModel", m_workReport);
    context->setContextProperty("subobjectsModel", m_subobjects);
    context->setContextProperty("subobjectsFilterModel", m_subobjectsFilter);
}

int ReportBackend::clientCount() const { return m_clients->rowCount(); }
int ReportBackend::workCount() const { return m_works->count(); }

QString ReportBackend::currentUnit() const
{
    const QString unit = m_currentService.unit.trimmed();
    return unit.isEmpty() ? QStringLiteral("ед.") : unit;
}

double ReportBackend::worksTotal() const
{
    double total = 0.0;
    for(const QVariant &item : m_works->items())
    {
        const QVariantMap work = item.toMap();
        total += work.value("price").toDouble()
            * work.value("quantity", 1).toDouble()
            * (work.value("percent_sum", 100).toDouble() / 100.0);
    }
    return total;
}

bool ReportBackend::initializeData()
{
    try
    {
        loadClients();
        restoreSelection();
        return true;
    }
    catch(...)
    {
        emit errorOccurred(QStringLiteral("Ошибка инициализации данных"));
        return false;
    }
}

bool ReportBackend::addClient(const QVariantMap &data)
{
    if(data.isEmpty())
        return false;

    const bool result = ClientsDatabase::addClientEntry(data);
    loadClients();
    return result;
}

void ReportBackend::selectClient(const QString &clientId)
{
    if(!setCurrentClient(clientId))
        return;

    saveSelectedClientId(clientId);
    saveSelectedObjectId(QString());
    emit clientSelected();
    emit objectSelected();
    emit objectUpdated();
}

void ReportBackend::updateLastTimeObject()
{
    if(m_currentObject.name.isEmpty())
        return;

    ObjectsDatabase::updateObjectLastOrderAt(m_currentClient.name, m_currentClient.id, m_currentObject.id);
    m_works->clear();
    loadObjects();
    updateCurrentObjectData();
}

void ReportBackend::selectObject(const QString &objectId)
{
    if(!setCurrentObject(objectId))
        return;

    saveSelectedObjectId(objectId);
    refreshSubobject(m_currentObject.id);
    emit objectSelected();
    emit objectUpdated();
}

void ReportBackend::selectOrder(int startOrderAt)
{
    const int value = startOrderAt;
    if(m_selectedStartOrderAt == value)
        return;

    m_selectedStartOrderAt = value;
    const QVariantMap order = m_orders->itemData(value);
    m_selectedOrderTotalPrice = order.isEmpty() ? 0 : order.value("total_price").toInt();
    emit orderSelected();

    const StringMapList items = WorksDatabase::loadWorksBySelectAt(
        m_currentClient.name, m_currentClient.id, m_currentObject.id, value);
    m_workReport->updateModelFromMaps(mapsToVariantList(items));
}

void ReportBackend::clearWorks()
{
    m_works->clearModel();
    emit worksChanged();
}

void ReportBackend::selectService(const QString &serviceId, const QString &name, const QString &unit, int price)
{
    if(serviceId.isEmpty() || name.isEmpty())
        return;

    m_currentService = {};
    m_currentService.id = serviceId;
    m_currentService.name = name;
    m_currentService.unit = unit;
    m_currentService.price = price;
    m_currentService.percentSum = 100;
    emit serviceSelected();
    emit subObjectChanged(QString());
}

void ReportBackend::setCurrentServicePrice(int price)
{
    m_currentService.price = price;
    emit serviceSelected();
}

void ReportBackend::addCoefficient(const QString &serviceId, const QString &name, const QString &unit, int price)
{
    Q_UNUSED(serviceId);
    Q_UNUSED(unit);

    if(m_currentService.id.isEmpty() || name.trimmed().isEmpty())
        return;

    const QStringList names = parseCoefficientNames(m_currentService.coefficients);
    for(const QString &existing : names)
    {
        if(existing.compare(name.trimmed(), Qt::CaseInsensitive) == 0)
            return;
    }

    QStringList updated = names;
    updated.append(name.trimmed());
    m_currentService.coefficients = updated.join(", ");
    m_currentService.percentSum += coefficientPercentPoints(price);
    emit serviceSelected();
}

void ReportBackend::setCurrentSubObject(const QString &subObject)
{
    const QString value = subObject.trimmed();
    if(m_currentService.subObject == value)
        return;

    m_currentService.subObject = value;
    emit subObjectChanged(value);
}

void ReportBackend::searchSubObjects(const QString &query)
{
    m_subobjectsFilter->setFilterText(query.trimmed());
}

void ReportBackend::clearSubObjectSuggestions()
{
    m_subobjectsFilter->clearFilter();
}

void ReportBackend::clearCurrentService()
{
    m_currentService = {};
    m_subobjectsFilter->clearFilter();
    emit serviceSelected();
    emit subObjectChanged(QString());
}

bool ReportBackend::addWork(double quantity)
{
    if(m_currentService.id.isEmpty())
        return false;
    if(m_currentClient.id.isEmpty())
    {
        emit errorOccurred(QStringLiteral("Выберите заказчика"));
        return false;
    }
    if(m_currentObject.id.isEmpty())
    {
        emit errorOccurred(QStringLiteral("Выберите объект"));
        return false;
    }

    QVariantMap data;
    data.insert("object_id", m_currentObject.id);
    data.insert("service_id", m_currentService.id);
    data.insert("subobject_name", m_currentService.subObject);
    data.insert("name", m_currentService.name);
    data.insert("price", m_currentService.price);
    data.insert("unit", m_currentService.unit);
    data.insert("quantity", quantity);
    data.insert("start_order_at", m_currentObject.lastOrderAt);
    data.insert("coefficients", m_currentService.coefficients);
    data.insert("percent_sum", m_currentService.percentSum);

    const StringMap result = WorksDatabase::addWork(m_currentClient.name, m_currentClient.id, data);
    if(result.isEmpty())
    {
        qDebug() << "Не удалось добавить работу";
        emit errorOccurred(QStringLiteral("Не удалось добавить работу"));
        return false;
    }

    m_works->addItem(result);
    m_subobjects->addItem(m_currentService.subObject);
    emit worksChanged();
    clearCurrentService();
    return true;
}

bool ReportBackend::updateWork(const QVariantMap &data)
{
    if(data.isEmpty() || m_currentClient.id.isEmpty())
        return false;

    if(!WorksDatabase::updateWork(m_currentClient.name, m_currentClient.id, data))
    {
        emit errorOccurred(QStringLiteral("Не удалось обновить работу"));
        return false;
    }

    const QString subobjectName = data.value("subobject_name").toString();
    if(!subobjectName.isEmpty())
        m_subobjects->addItem(subobjectName);

    m_works->updateItem(data);
    emit worksChanged();
    return true;
}

bool ReportBackend::deleteWork(const QString &workId)
{
    if(workId.isEmpty() || m_currentClient.id.isEmpty())
        return false;

    if(!WorksDatabase::deleteWork(m_currentClient.name, m_currentClient.id, workId))
    {
        emit errorOccurred(QStringLiteral("Не удалось удалить работу"));
        return false;
    }

    m_works->removeItem(workId);
    emit worksChanged();
    return true;
}

bool ReportBackend::addObject(const QVariantMap &data)
{
    if(data.isEmpty() || m_currentClient.id.isEmpty())
        return false;

    ObjectsDatabase::createObjectDatabase(m_currentClient.name, m_currentClient.id);
    const bool result = ObjectsDatabase::addObjectEntry(
        m_currentClient.name,
        m_currentClient.id,
        data.value("name").toString(),
        data.value("address").toString());
    loadObjects();
    return result;
}

bool ReportBackend::generateReport()
{
    return generateReportInternal(true);
}

bool ReportBackend::saveReportToFile(const QString &fileUrl)
{
    const QString filePath = resolveLocalFilePath(fileUrl);
    if(filePath.isEmpty())
    {
        emit errorOccurred(QStringLiteral("Не выбран файл для сохранения"));
        return false;
    }
    return generateReportInternal(true, filePath);
}

QString ReportBackend::defaultReportSaveUrl(const QString &clientId) const
{
    const QVariantMap client = m_clients->itemData(clientId);
    if(client.isEmpty())
        return QString();

    const QString reportsDir = DatabaseStorage::defaultReportsDir();
    QDir().mkpath(reportsDir);

    QString safeName;
    for(const QChar ch : client.value("name").toString())
        safeName.append(ch.isLetterOrNumber() ? ch : QChar('_'));

    const QString stamp = QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");
    const QString target = QDir(reportsDir).filePath(QStringLiteral("report_%1_%2.pdf").arg(safeName, stamp));
    return QUrl::fromLocalFile(target).toString();
}

QString ReportBackend::defaultReportSaveFolderUrl() const
{
    const QString reportsDir = DatabaseStorage::defaultReportsDir();
    QDir().mkpath(reportsDir);
    return QUrl::fromLocalFile(reportsDir).toString();
}

bool ReportBackend::previewReport()
{
    return generateReportInternal(false);
}

QVariantList ReportBackend::getOrderStartTimes() const
{
    QVariantList result;
    for(int row = 0; row < m_orders->rowCount(); ++row)
    {
        const QVariantMap item = m_orders->getObject(row);
        if(item.contains("start_order_at"))
            result.append(item.value("start_order_at"));
    }
    return result;
}

QVariantList ReportBackend::getClientWorks() const
{
    return m_works->items();
}

void ReportBackend::refreshOrders()
{
    loadOrders();
}

void ReportBackend::refreshSubobject(const QString &objectId)
{
    loadSubobjects(objectId);
}

void ReportBackend::loadClients()
{
    StringMapList clients = ClientsDatabase::loadClients();
    if(clients.isEmpty())
    {
        ClientsDatabase::createClientTable();
        clients = ClientsDatabase::loadClients();
    }

    m_clients->updateModelFromMaps(mapsToVariantList(clients));
    emit clientsChanged();
}

void ReportBackend::loadObjects()
{
    StringMapList objects = ObjectsDatabase::loadObjects(m_currentClient.name, m_currentClient.id);
    if(objects.isEmpty())
    {
        ObjectsDatabase::createObjectDatabase(m_currentClient.name, m_currentClient.id);
        objects = ObjectsDatabase::loadObjects(m_currentClient.name, m_currentClient.id);
    }

    m_objects->updateModelFromMaps(mapsToVariantList(objects));
}

void ReportBackend::loadOrders()
{
    clearSelectedOrder();

    if(m_currentClient.id.isEmpty() || m_currentObject.id.isEmpty())
    {
        m_orders->updateModelFromMaps({});
        return;
    }

    const StringMapList orders = WorksDatabase::getOrders(
        m_currentClient.name, m_currentClient.id, m_currentObject.id);
    m_orders->updateModelFromMaps(mapsToVariantList(orders));
}

void ReportBackend::loadSubobjects(const QString &objectId)
{
    if(m_currentClient.id.isEmpty() || m_currentObject.id.isEmpty())
    {
        m_subobjects->updateModelFromNames({});
        m_subobjectsFilter->clearFilter();
        return;
    }

    const QStringList names = WorksDatabase::loadSubobjectNames(
        m_currentClient.name, m_currentClient.id, objectId);
    m_subobjects->updateModelFromNames(names);
}

void ReportBackend::reloadWorks()
{
    const StringMapList works = WorksDatabase::loadWorksByStartOrder(
        m_currentClient.name,
        m_currentClient.id,
        m_currentObject.id,
        m_currentObject.lastOrderAt);
    m_works->updateModelFromMaps(mapsToVariantList(works));
    emit worksChanged();
}

bool ReportBackend::setCurrentClient(const QString &clientId)
{
    if(clientId.isEmpty())
        return false;

    const QVariantMap item = m_clients->itemData(clientId);
    if(item.isEmpty())
        return false;

    m_currentClient.id = item.value("id").toString();
    m_currentClient.name = item.value("name").toString();
    m_currentClient.address = item.value("address").toString();

    WorksDatabase::createWorksTable(m_currentClient.name, m_currentClient.id);
    ObjectsDatabase::createObjectDatabase(m_currentClient.name, m_currentClient.id);
    loadObjects();
    m_works->clearModel();
    m_currentObject = {};
    return true;
}

bool ReportBackend::setCurrentObject(const QString &objectId)
{
    if(objectId.isEmpty())
        return false;

    const QVariantMap item = m_objects->itemData(objectId);
    if(item.isEmpty())
        return false;

    m_currentObject.id = item.value("id").toString();
    m_currentObject.name = item.value("name").toString();
    m_currentObject.address = item.value("address").toString();
    m_currentObject.lastOrderAt = item.value("last_order_at").toLongLong();
    reloadWorks();
    return true;
}

void ReportBackend::saveSelectedClientId(const QString &clientId)
{
    QSettingsStore store;
    store.write(kClientIdKey, clientId);
    store.sync();
}

void ReportBackend::saveSelectedObjectId(const QString &objectId)
{
    QSettingsStore store;
    store.write(kObjectIdKey, objectId);
    store.sync();
}

void ReportBackend::clearPersistedSelection()
{
    QSettingsStore store;
    store.write(kClientIdKey, QString());
    store.write(kObjectIdKey, QString());
    store.sync();
}

void ReportBackend::restoreSelection()
{
    QSettingsStore store;
    const QString clientId = store.read(kClientIdKey).toString();
    const QString objectId = store.read(kObjectIdKey).toString();

    if(clientId.isEmpty())
        return;

    if(!setCurrentClient(clientId))
    {
        clearPersistedSelection();
        return;
    }

    emit clientSelected();

    if(objectId.isEmpty())
        return;

    if(!setCurrentObject(objectId))
    {
        saveSelectedObjectId(QString());
        return;
    }

    updateCurrentObjectData();
    reloadWorks();
    refreshSubobject(objectId);
    emit objectSelected();
    emit objectUpdated();
}

void ReportBackend::updateCurrentObjectData()
{
    if(m_currentObject.name.isEmpty())
        return;

    const QVariantMap item = m_objects->itemData(m_currentObject.id);
    if(!item.isEmpty())
    {
        m_currentObject.id = item.value("id").toString();
        m_currentObject.name = item.value("name").toString();
        m_currentObject.address = item.value("address").toString();
        m_currentObject.lastOrderAt = item.value("last_order_at").toLongLong();
    }
    emit objectUpdated();
}

void ReportBackend::clearSelectedOrder()
{
    if(m_selectedStartOrderAt == 0)
        return;

    m_selectedStartOrderAt = 0;
    m_selectedOrderTotalPrice = 0;
    emit orderSelected();
}

bool ReportBackend::generateReportInternal(bool saveToFile, const QString &filePath)
{
    const QVariantMap client = m_clients->itemData(m_currentClient.id);
    if(client.isEmpty())
    {
        emit errorOccurred(QStringLiteral("Выберите заказчика или объект"));
        return false;
    }

    if(m_currentObject.id.isEmpty())
    {
        emit errorOccurred(QStringLiteral("Выберите объект заказчика"));
        return false;
    }

    const QVariantList selectedOrders = m_reportOptionsBackend->selectedOrderTimestamps();
    if(selectedOrders.isEmpty())
    {
        emit errorOccurred(QStringLiteral("Выберите хотя бы один счёт"));
        return false;
    }

    QList<qint64> orderTimestamps;
    for(const QVariant &value : selectedOrders)
        orderTimestamps.append(value.toLongLong());

    const StringMapList works = WorksDatabase::getResultWorks(
        m_currentClient.name,
        m_currentClient.id,
        {m_currentObject.id},
        orderTimestamps);

    if(works.isEmpty())
    {
        emit errorOccurred(QStringLiteral("Нет работ для выбранных счетов"));
        return false;
    }

    QVariantMap objectData;
    objectData.insert("name", m_currentObject.name);
    objectData.insert("address", m_currentObject.address);

    QString targetPath = filePath;
    if(!saveToFile)
    {
        if(!m_previewTempPath.isEmpty())
            QFile::remove(m_previewTempPath);

        QTemporaryFile tempFile;
        tempFile.setAutoRemove(false);
        tempFile.setFileTemplate(QDir::temp().filePath("report_preview_XXXXXX.pdf"));
        if(!tempFile.open())
            return false;

        targetPath = tempFile.fileName();
        tempFile.close();
        m_previewTempPath = targetPath;
    }

    const auto result = saveWorkReportPdf(
        m_settingsBackend->personalInfo(),
        client,
        objectData,
        mapsToVariantList(works),
        m_reportOptionsBackend->asDict(),
        targetPath);

    if(result.first.isEmpty())
    {
        // Android SAF content:// write can fail; fall back to app reports directory.
        if(saveToFile && !targetPath.isEmpty() && FileIo::isContentUri(targetPath))
        {
            qWarning("ReportBackend: content URI save failed, falling back to app reports dir");
            const auto fallback = saveWorkReportPdf(
                m_settingsBackend->personalInfo(),
                client,
                objectData,
                mapsToVariantList(works),
                m_reportOptionsBackend->asDict(),
                QString());
            if(!fallback.first.isEmpty())
            {
                m_lastReportPath = fallback.first;
                m_lastReportUrl = QUrl::fromLocalFile(fallback.first).toString();
                emit reportGenerated(m_lastReportPath, m_lastReportUrl);
                emit errorOccurred(tr("Не удалось записать в выбранный файл. Отчёт сохранён в: %1")
                                       .arg(fallback.first));
                return true;
            }
        }

        emit errorOccurred(QStringLiteral("Не удалось сохранить PDF"));
        return false;
    }

    m_lastReportPath = saveToFile ? result.first : QString();
    if(FileIo::isContentUri(result.first))
        m_lastReportUrl = result.first;
    else
        m_lastReportUrl = QUrl::fromLocalFile(result.first).toString();
    emit reportGenerated(m_lastReportPath, m_lastReportUrl);
    return true;
}

int ReportBackend::coefficientPercentPoints(int price)
{
    return (price / 100) - 100;
}

QStringList ReportBackend::parseCoefficientNames(const QString &value)
{
    QStringList result;
    for(const QString &part : value.split(','))
    {
        const QString trimmed = part.trimmed();
        if(!trimmed.isEmpty())
            result.append(trimmed);
    }
    return result;
}

QString ReportBackend::resolveLocalFilePath(const QString &fileUrl)
{
    QString value = fileUrl.trimmed();
    if(value.isEmpty())
        return QString();

    // Android SAF: keep content:// as-is for QFile.
    if(FileIo::isContentUri(value))
        return value;

    QString path;
    if(value.startsWith("file:", Qt::CaseInsensitive))
        path = QUrl(value).toLocalFile();
    else
        path = value;

    if(!path.endsWith(".pdf", Qt::CaseInsensitive))
        path += ".pdf";

    return path;
}

} // namespace workorder
