#include "ReportBackend.h"

#include "ReportOptionsBackend.h"
#include "SettingsBackend.h"

#include "ClientsModel.h"
#include "ExpensesModel.h"
#include "ObjectsModel.h"
#include "OrdersModel.h"
#include "SubobjectsFilterModel.h"
#include "SubobjectsModel.h"
#include "WorksModel.h"

#include "ClientsDatabase.h"
#include "DatabaseStorage.h"
#include "ExpensesDatabase.h"
#include "FileIo.h"
#include "NotificationManager.h"
#include "ObjectsDatabase.h"
#include "PdfReportBuilder.h"
#include "QSettingsStore.h"
#include "WorksDatabase.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QMap>
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

qint64 workAmountKopecks(const QVariantMap &work)
{
    const qint64 priceKopecks = work.value("price").toLongLong();
    const qint64 quantityThousandths = qRound64(work.value("quantity", 1).toDouble() * 1000.0);
    const qint64 percentSum = work.value("percent_sum", 100).toLongLong();
    const qint64 numerator = priceKopecks * quantityThousandths * percentSum;
    return (numerator + 50000) / 100000;
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
    , m_expenses(new ExpensesModel(this))
    , m_subobjects(new SubobjectsModel(this))
    , m_subobjectsFilter(new SubobjectsFilterModel(this))
{
    ClientsDatabase::createClientTable();
    m_subobjectsFilter->setSourceModel(m_subobjects);
    connect(this, &ReportBackend::worksChanged, this, &ReportBackend::totalsChanged);
    connect(this, &ReportBackend::expensesChanged, this, &ReportBackend::totalsChanged);
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
    context->setContextProperty("expensesModel", m_expenses);
    context->setContextProperty("subobjectsModel", m_subobjects);
    context->setContextProperty("subobjectsFilterModel", m_subobjectsFilter);
}

int ReportBackend::clientCount() const { return m_clients->rowCount(); }
int ReportBackend::workCount() const { return m_works->count(); }
int ReportBackend::expenseCount() const { return m_expenses->count(); }

QString ReportBackend::currentUnit() const
{
    const QString unit = m_currentService.unit.trimmed();
    return unit.isEmpty() ? QStringLiteral("ед.") : unit;
}

qint64 ReportBackend::worksTotal() const
{
    qint64 total = 0;
    for(const QVariant &item : m_works->items())
        total += workAmountKopecks(item.toMap());
    return total;
}

qint64 ReportBackend::expensesTotal() const
{
    qint64 total = 0;
    for(const QVariant &item : m_expenses->items())
        total += item.toMap().value("amount").toLongLong();
    return total;
}

qint64 ReportBackend::invoiceTotal() const
{
    return worksTotal() + expensesTotal();
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
        NotificationManager::notifyError(QStringLiteral("Ошибка инициализации данных"));
        return false;
    }
}

bool ReportBackend::addClient(const QVariantMap &data)
{
    if(data.isEmpty())
        return false;
    if(data.value(QStringLiteral("name")).toString().trimmed().isEmpty())
    {
        NotificationManager::notifyError(QStringLiteral("Укажите имя заказчика"));
        return false;
    }

    const bool result = ClientsDatabase::addClientEntry(data);
    loadClients();
    return result;
}

bool ReportBackend::updateClient(const QVariantMap &data)
{
    if(data.isEmpty() || m_currentClient.id.isEmpty())
        return false;

    const QString name = data.value(QStringLiteral("name")).toString().trimmed();
    if(name.isEmpty())
    {
        NotificationManager::notifyError(QStringLiteral("Укажите имя заказчика"));
        return false;
    }

    if(!renameClientStorage(m_currentClient.name, name))
        return false;

    QVariantMap payload = data;
    payload.insert(QStringLiteral("id"), m_currentClient.id);
    payload.insert(QStringLiteral("name"), name);

    if(!ClientsDatabase::updateClientEntry(payload))
    {
        NotificationManager::notifyError(QStringLiteral("Не удалось обновить заказчика"));
        return false;
    }

    const QString objectId = m_currentObject.id;
    loadClients();
    // setCurrentClient() resets the object selection, so it is restored afterwards.
    setCurrentClient(m_currentClient.id);
    if(!objectId.isEmpty())
        setCurrentObject(objectId);

    emit clientSelected();
    emit objectSelected();
    emit objectUpdated();
    return true;
}

QVariantMap ReportBackend::currentClientData() const
{
    if(m_currentClient.id.isEmpty())
        return {};
    return m_clients->itemData(m_currentClient.id);
}

QVariantMap ReportBackend::currentObjectData() const
{
    if(m_currentObject.id.isEmpty())
        return {};
    return m_objects->itemData(m_currentObject.id);
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
    emit worksChanged();
    emit expensesChanged();
}

void ReportBackend::updateLastTimeObject()
{
    if(m_currentObject.name.isEmpty())
        return;

    ObjectsDatabase::updateObjectLastOrderAt(m_currentClient.name, m_currentClient.id, m_currentObject.id);
    loadObjects();
    updateCurrentObjectData();
    // The new order has no items yet, so both models and totals must be refreshed.
    reloadWorks();
    reloadExpenses();
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
    reloadSelectedOrderWorks();
}

void ReportBackend::activateInvoiceContext()
{
    // Invoice tab always edits the object's latest order (last_order_at).
    // Reports selection (selectedStartOrderAt) is left untouched.
    clearCurrentService();

    if(m_currentClient.id.isEmpty())
        return;

    if(m_currentObject.id.isEmpty())
    {
        m_works->clearModel();
        m_expenses->clearModel();
        emit worksChanged();
        emit expensesChanged();
        return;
    }

    loadObjects();
    updateCurrentObjectData();
    reloadWorks();
    reloadExpenses();
}

void ReportBackend::activateReportsContext()
{
    // Reports tab keeps its own selected order independently from invoice.
    clearCurrentService();

    const int preservedOrder = m_selectedStartOrderAt;

    if(m_currentClient.id.isEmpty() || m_currentObject.id.isEmpty())
    {
        m_orders->updateModelFromMaps({});
        clearSelectedOrder();
        return;
    }

    m_orders->updateModelFromMaps(currentOrderTotals());

    if(preservedOrder > 0 && !m_orders->itemData(preservedOrder).isEmpty())
    {
        m_selectedStartOrderAt = preservedOrder;
        reloadSelectedOrderWorks();
    }
    else
    {
        clearSelectedOrder();
    }
}

void ReportBackend::clearWorks()
{
    m_works->clearModel();
    m_expenses->clearModel();
    emit worksChanged();
    emit expensesChanged();
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

void ReportBackend::setCurrentServiceName(const QString &name)
{
    const QString value = name.trimmed();
    if(m_currentService.name == value)
        return;
    m_currentService.name = value;
    emit serviceSelected();
}

void ReportBackend::setCurrentCoefficients(const QString &coefficients)
{
    if(m_currentService.coefficients == coefficients)
        return;
    m_currentService.coefficients = coefficients;
    emit serviceSelected();
}

void ReportBackend::setCurrentPercentSum(int percentSum)
{
    const int value = qMax(100, percentSum);
    if(m_currentService.percentSum == value)
        return;
    m_currentService.percentSum = value;
    emit serviceSelected();
}

bool ReportBackend::loadWorkIntoCurrentService(const QString &workId)
{
    if(workId.isEmpty())
        return false;

    QVariantMap item = m_workReport->itemData(workId);
    if(item.isEmpty())
        item = m_works->itemData(workId);
    if(item.isEmpty())
        return false;

    m_currentService = {};
    m_currentService.id = item.value(QStringLiteral("service_id")).toString();
    m_currentService.name = item.value(QStringLiteral("name")).toString();
    m_currentService.unit = item.value(QStringLiteral("unit")).toString();
    m_currentService.price = item.value(QStringLiteral("price")).toInt();
    m_currentService.subObject = item.value(QStringLiteral("subobject_name")).toString();
    m_currentService.coefficients = item.value(QStringLiteral("coefficients")).toString();
    m_currentService.percentSum = item.value(QStringLiteral("percent_sum")).toInt();
    if(m_currentService.percentSum < 100)
        m_currentService.percentSum = 100;

    emit serviceSelected();
    emit subObjectChanged(m_currentService.subObject);
    return true;
}

void ReportBackend::reloadSelectedOrderWorks()
{
    if(m_selectedStartOrderAt <= 0
       || m_currentClient.id.isEmpty()
       || m_currentObject.id.isEmpty())
    {
        m_workReport->clearModel();
        m_selectedOrderTotalPrice = 0;
        emit orderSelected();
        return;
    }

    const StringMapList items = WorksDatabase::loadWorksBySelectAt(
        m_currentClient.name,
        m_currentClient.id,
        m_currentObject.id,
        m_selectedStartOrderAt);
    m_workReport->updateModelFromMaps(mapsToVariantList(items));

    const QVariantMap order = m_orders->itemData(m_selectedStartOrderAt);
    m_selectedOrderTotalPrice = order.isEmpty() ? 0 : order.value(QStringLiteral("total_price")).toInt();

    // Refresh order totals from DB without dropping selection.
    m_orders->updateModelFromMaps(currentOrderTotals());
    const QVariantMap refreshed = m_orders->itemData(m_selectedStartOrderAt);
    if(!refreshed.isEmpty())
        m_selectedOrderTotalPrice = refreshed.value(QStringLiteral("total_price")).toInt();

    emit orderSelected();
}

bool ReportBackend::addWork(double quantity, int startOrderAt)
{
    const qint64 orderAt = startOrderAt > 0
                               ? static_cast<qint64>(startOrderAt)
                               : m_currentObject.lastOrderAt;
    return addWorkAt(quantity, orderAt);
}

bool ReportBackend::addWorkAt(double quantity, qint64 startOrderAt)
{
    if(m_currentService.id.isEmpty() && m_currentService.name.trimmed().isEmpty())
        return false;
    if(m_currentClient.id.isEmpty())
    {
        NotificationManager::notifyError(QStringLiteral("Выберите заказчика"));
        return false;
    }
    if(m_currentObject.id.isEmpty())
    {
        NotificationManager::notifyError(QStringLiteral("Выберите объект"));
        return false;
    }
    if(startOrderAt <= 0)
    {
        NotificationManager::notifyError(QStringLiteral("Выберите счёт или начните новый отчёт"));
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
    data.insert("start_order_at", startOrderAt);
    data.insert("coefficients", m_currentService.coefficients);
    data.insert("percent_sum", m_currentService.percentSum);

    const StringMap result = WorksDatabase::addWork(m_currentClient.name, m_currentClient.id, data);
    if(result.isEmpty())
    {
        qDebug() << "Не удалось добавить работу";
        NotificationManager::notifyError(QStringLiteral("Не удалось добавить работу"));
        return false;
    }

    if(startOrderAt == m_currentObject.lastOrderAt)
        m_works->addItem(result);
    if(startOrderAt == m_selectedStartOrderAt)
        reloadSelectedOrderWorks();

    m_subobjects->addItem(m_currentService.subObject);
    emit worksChanged();
    clearCurrentService();
    return true;
}

bool ReportBackend::updateCurrentWork(const QString &workId, double quantity)
{
    if(workId.isEmpty())
        return false;

    QVariantMap data;
    data.insert(QStringLiteral("id"), workId);
    data.insert(QStringLiteral("name"), m_currentService.name);
    data.insert(QStringLiteral("subobject_name"), m_currentService.subObject);
    data.insert(QStringLiteral("coefficients"), m_currentService.coefficients);
    data.insert(QStringLiteral("unit"), m_currentService.unit);
    data.insert(QStringLiteral("quantity"), quantity);
    data.insert(QStringLiteral("price"), m_currentService.price);
    data.insert(QStringLiteral("percent_sum"), m_currentService.percentSum);
    data.insert(QStringLiteral("service_id"), m_currentService.id);

    if(!updateWork(data))
        return false;

    clearCurrentService();
    return true;
}

bool ReportBackend::updateWork(const QVariantMap &data)
{
    if(data.isEmpty() || m_currentClient.id.isEmpty())
        return false;

    if(!WorksDatabase::updateWork(m_currentClient.name, m_currentClient.id, data))
    {
        NotificationManager::notifyError(QStringLiteral("Не удалось обновить работу"));
        return false;
    }

    const QString subobjectName = data.value("subobject_name").toString();
    if(!subobjectName.isEmpty())
        m_subobjects->addItem(subobjectName);

    m_works->updateItem(data);
    m_workReport->updateItem(data);
    if(m_selectedStartOrderAt > 0)
        reloadSelectedOrderWorks();
    emit worksChanged();
    return true;
}

bool ReportBackend::deleteWork(const QString &workId)
{
    if(workId.isEmpty() || m_currentClient.id.isEmpty())
        return false;

    if(!WorksDatabase::deleteWork(m_currentClient.name, m_currentClient.id, workId))
    {
        NotificationManager::notifyError(QStringLiteral("Не удалось удалить работу"));
        return false;
    }

    m_works->removeItem(workId);
    m_workReport->removeItem(workId);
    if(m_selectedStartOrderAt > 0)
        reloadSelectedOrderWorks();
    emit worksChanged();
    return true;
}

bool ReportBackend::addExpense(const QString &description, int amount)
{
    if(m_currentClient.id.isEmpty() || m_currentObject.id.isEmpty()
       || m_currentObject.lastOrderAt <= 0)
    {
        NotificationManager::notifyError(QStringLiteral("Сначала начните новый отчёт"));
        return false;
    }

    QVariantMap data;
    data.insert("object_id", m_currentObject.id);
    data.insert("start_order_at", m_currentObject.lastOrderAt);
    data.insert("description", description.trimmed());
    data.insert("amount", amount);
    const QVariantMap result = ExpensesDatabase::addExpense(
        m_currentClient.name, m_currentClient.id, data);
    if(result.isEmpty())
    {
        NotificationManager::notifyError(QStringLiteral("Не удалось добавить затраты"));
        return false;
    }

    m_expenses->addItem(result);
    emit expensesChanged();
    return true;
}

bool ReportBackend::updateExpense(const QVariantMap &data)
{
    if(data.isEmpty() || m_currentClient.id.isEmpty())
        return false;

    if(!ExpensesDatabase::updateExpense(m_currentClient.name, m_currentClient.id, data))
    {
        NotificationManager::notifyError(QStringLiteral("Не удалось обновить затраты"));
        return false;
    }

    reloadExpenses();
    return true;
}

bool ReportBackend::deleteExpense(const QString &expenseId)
{
    if(expenseId.isEmpty() || m_currentClient.id.isEmpty())
        return false;

    if(!ExpensesDatabase::deleteExpense(m_currentClient.name, m_currentClient.id, expenseId))
    {
        NotificationManager::notifyError(QStringLiteral("Не удалось удалить затраты"));
        return false;
    }

    m_expenses->removeItem(expenseId);
    emit expensesChanged();
    return true;
}

bool ReportBackend::addObject(const QVariantMap &data)
{
    if(data.isEmpty() || m_currentClient.id.isEmpty())
        return false;
    if(data.value(QStringLiteral("name")).toString().trimmed().isEmpty())
    {
        NotificationManager::notifyError(QStringLiteral("Укажите название объекта"));
        return false;
    }

    ObjectsDatabase::createObjectDatabase(m_currentClient.name, m_currentClient.id);
    const bool result = ObjectsDatabase::addObjectEntry(
        m_currentClient.name,
        m_currentClient.id,
        data.value("name").toString().trimmed(),
        data.value("address").toString());
    loadObjects();
    return result;
}

bool ReportBackend::updateObject(const QVariantMap &data)
{
    if(data.isEmpty() || m_currentClient.id.isEmpty() || m_currentObject.id.isEmpty())
        return false;

    const QString name = data.value(QStringLiteral("name")).toString().trimmed();
    if(name.isEmpty())
    {
        NotificationManager::notifyError(QStringLiteral("Укажите название объекта"));
        return false;
    }

    QVariantMap payload = data;
    payload.insert(QStringLiteral("id"), m_currentObject.id);
    payload.insert(QStringLiteral("name"), name);

    if(!ObjectsDatabase::updateObjectName(m_currentClient.name, m_currentClient.id, payload))
    {
        NotificationManager::notifyError(QStringLiteral("Не удалось обновить объект"));
        return false;
    }

    loadObjects();
    updateCurrentObjectData();
    emit objectSelected();
    return true;
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
        NotificationManager::notifyError(QStringLiteral("Не выбран файл для сохранения"));
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

    m_orders->updateModelFromMaps(currentOrderTotals());
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

void ReportBackend::reloadExpenses()
{
    const StringMapList expenses = ExpensesDatabase::loadExpensesByStartOrder(
        m_currentClient.name,
        m_currentClient.id,
        m_currentObject.id,
        m_currentObject.lastOrderAt);
    m_expenses->updateModelFromMaps(mapsToVariantList(expenses));
    emit expensesChanged();
}

QVariantList ReportBackend::currentOrderTotals() const
{
    const StringMapList works = WorksDatabase::loadWorksByObject(
        m_currentClient.name, m_currentClient.id, m_currentObject.id);
    const StringMapList expenseOrders = ExpensesDatabase::getOrderTotals(
        m_currentClient.name, m_currentClient.id, m_currentObject.id);

    QMap<qint64, qint64> totals;
    for(const QVariant &value : works)
    {
        const QVariantMap work = value.toMap();
        totals[work.value("start_order_at").toLongLong()] += workAmountKopecks(work);
    }
    for(const QVariant &value : expenseOrders)
    {
        const QVariantMap order = value.toMap();
        totals[order.value("start_order_at").toLongLong()]
            += order.value("total_price").toLongLong();
    }

    QVariantList result;
    for(auto it = totals.constBegin(); it != totals.constEnd(); ++it)
    {
        QVariantMap order;
        order.insert("start_order_at", it.key());
        order.insert("total_price", it.value());
        result.append(order);
    }
    return result;
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
    ExpensesDatabase::createExpensesTable(m_currentClient.name, m_currentClient.id);
    ObjectsDatabase::createObjectDatabase(m_currentClient.name, m_currentClient.id);
    loadObjects();
    m_works->clearModel();
    m_expenses->clearModel();
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
    reloadExpenses();
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

bool ReportBackend::renameClientStorage(const QString &previousName, const QString &newName)
{
    if(previousName == newName)
        return true;

    const QString previousPath = DatabaseStorage::objectDbPath(previousName, m_currentClient.id);
    const QString newPath = DatabaseStorage::objectDbPath(newName, m_currentClient.id);
    if(previousPath == newPath || !QFile::exists(previousPath))
        return true;

    if(QFile::exists(newPath))
    {
        NotificationManager::notifyError(QStringLiteral("База данных заказчика уже существует"));
        return false;
    }

    ObjectsDatabase::closeDatabase(previousName, m_currentClient.id);
    WorksDatabase::closeDatabase(previousName, m_currentClient.id);
    ExpensesDatabase::closeDatabase(previousName, m_currentClient.id);

    if(!QFile::rename(previousPath, newPath))
    {
        NotificationManager::notifyError(QStringLiteral("Не удалось переименовать базу данных заказчика"));
        return false;
    }

    qInfo("ReportBackend::renameClientStorage %s -> %s",
          qPrintable(previousPath),
          qPrintable(newPath));
    return true;
}

void ReportBackend::clearSelectedOrder()
{
    if(m_selectedStartOrderAt == 0)
    {
        m_workReport->clearModel();
        return;
    }

    m_selectedStartOrderAt = 0;
    m_selectedOrderTotalPrice = 0;
    m_workReport->clearModel();
    emit orderSelected();
}

bool ReportBackend::generateReportInternal(bool saveToFile, const QString &filePath)
{
    const QVariantMap client = m_clients->itemData(m_currentClient.id);
    if(client.isEmpty())
    {
        NotificationManager::notifyError(QStringLiteral("Выберите заказчика или объект"));
        return false;
    }

    if(m_currentObject.id.isEmpty())
    {
        NotificationManager::notifyError(QStringLiteral("Выберите объект заказчика"));
        return false;
    }

    const QVariantList selectedOrders = m_reportOptionsBackend->selectedOrderTimestamps();
    if(selectedOrders.isEmpty())
    {
        NotificationManager::notifyError(QStringLiteral("Выберите хотя бы один счёт"));
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
    const StringMapList expenses = ExpensesDatabase::getResultExpenses(
        m_currentClient.name,
        m_currentClient.id,
        {m_currentObject.id},
        orderTimestamps);

    if(works.isEmpty() && expenses.isEmpty())
    {
        NotificationManager::notifyError(QStringLiteral("Нет позиций для выбранных счетов"));
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
        mapsToVariantList(expenses),
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
                mapsToVariantList(expenses),
                m_reportOptionsBackend->asDict(),
                QString());
            if(!fallback.first.isEmpty())
            {
                m_lastReportPath = fallback.first;
                m_lastReportUrl = QUrl::fromLocalFile(fallback.first).toString();
                emit reportGenerated(m_lastReportPath, m_lastReportUrl);
                NotificationManager::notifyError(tr("Не удалось записать в выбранный файл. Отчёт сохранён в: %1")
                                       .arg(fallback.first));
                return true;
            }
        }

        NotificationManager::notifyError(QStringLiteral("Не удалось сохранить PDF"));
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
