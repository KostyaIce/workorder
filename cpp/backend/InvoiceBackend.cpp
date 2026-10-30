#include "InvoiceBackend.h"

#include "CoefficientsFilterModel.h"
#include "CoefficientsModel.h"
#include "ReportBackend.h"
#include "ServicesFilterModel.h"
#include "ServicesModel.h"
#include "CoefficientsDatabase.h"
#include "ServicesDatabase.h"
#include "ServicesExcelBuilder.h"
#include "ServicesPdfBuilder.h"
#include "DatabaseStorage.h"
#include "NotificationManager.h"
#include "QSettingsStore.h"
#include "ReportShare.h"

#include <QDateTime>
#include <QDir>
#include <QDebug>
#include <QQmlContext>
#include <stdexcept>

namespace workorder
{

namespace
{

void announceSavedFile(const QString &savedPath, const QString &title)
{
    if(savedPath.isEmpty())
        return;

    const QString place = ReportShare::publish(savedPath);
    const QString message = place.isEmpty()
        ? QStringLiteral("%1 сохранён: %2").arg(title, savedPath)
        : QStringLiteral("%1 сохранён в %2. Его можно отправить через почту или мессенджер.").arg(title, place);
    if(NotificationManager *notifications = NotificationManager::instance())
        notifications->pushInfo(message, QString(), 12000);
    else
        NotificationManager::notifyInfo(message);
}

QString defaultExportPath(const QString &fileName)
{
    const QString directory = DatabaseStorage::defaultReportsDir();
    QDir().mkpath(directory);
    return QDir(directory).filePath(fileName);
}

const char *kPresentationTitleKey = "services/presentation_title";

QString defaultPresentationTitle()
{
    return QStringLiteral("Презентация услуг");
}

} // namespace

InvoiceBackend::InvoiceBackend(QQmlApplicationEngine *engine, QObject *parent)
    : QObject(parent)
    , m_services(new ServicesModel(this))
    , m_coefficients(new CoefficientsModel(this))
    , m_servicesFilter(new ServicesFilterModel(this))
    , m_coefficientsFilter(new CoefficientsFilterModel(this))
{
    ServicesDatabase::createServicesTable();
    CoefficientsDatabase::createCoefficientsTable();
    m_servicesFilter->setSourceModel(m_services);
    m_coefficientsFilter->setSourceModel(m_coefficients);
    loadServices();
    loadCoefficients();
    loadPresentationTitle();
    registerModels(engine);
}

InvoiceBackend::~InvoiceBackend() = default;

void InvoiceBackend::registerModels(QQmlApplicationEngine *engine)
{
    if(!engine)
        return;

    QQmlContext *context = engine->rootContext();
    context->setContextProperty("servicesModel", m_services);
    context->setContextProperty("servicesFilterModel", m_servicesFilter);
    context->setContextProperty("coefficientsModel", m_coefficients);
    context->setContextProperty("coefficientsFilterModel", m_coefficientsFilter);
}

void InvoiceBackend::bindReportBackend(ReportBackend *reportBackend)
{
    m_reportBackend = reportBackend;
}

void InvoiceBackend::reloadAfterSync()
{
    loadServices();
    loadCoefficients();
}

void InvoiceBackend::loadPresentationTitle()
{
    QSettingsStore store;
    const QString stored = store.read(QLatin1String(kPresentationTitleKey), defaultPresentationTitle()).toString().trimmed();
    m_presentationTitle = stored.isEmpty() ? defaultPresentationTitle() : stored;
}

QString InvoiceBackend::presentationTitle() const
{
    return m_presentationTitle;
}

void InvoiceBackend::rememberPresentationTitle(const QString &title)
{
    const QString stored = title.trimmed().isEmpty() ? defaultPresentationTitle() : title.trimmed();
    if(stored == m_presentationTitle)
        return;

    m_presentationTitle = stored;
    QSettingsStore store;
    store.write(QLatin1String(kPresentationTitleKey), m_presentationTitle);
    emit presentationTitleChanged();
}

void InvoiceBackend::loadServices()
{
    QVariantList items;
    for(const QVariant &item : ServicesDatabase::loadServices())
        items.append(item);
    m_services->updateModelFromMaps(items);
}

void InvoiceBackend::loadCoefficients()
{
    QVariantList items;
    for(const QVariant &item : CoefficientsDatabase::loadCoefficients())
        items.append(item);
    m_coefficients->updateModelFromMaps(items);
}

QString InvoiceBackend::addCoefficient(const QVariantMap &data)
{
    const QString coefficientId = CoefficientsDatabase::addCoefficient(data);
    if(coefficientId.isEmpty())
        return {};

    loadCoefficients();
    return coefficientId;
}

bool InvoiceBackend::updateCoefficient(const QVariantMap &data)
{
    if(data.isEmpty() || !CoefficientsDatabase::updateCoefficient(data))
        return false;

    loadCoefficients();
    return true;
}

bool InvoiceBackend::deleteCoefficient(const QString &coefficientId)
{
    if(coefficientId.isEmpty() || !CoefficientsDatabase::deleteCoefficient(coefficientId))
        return false;

    loadCoefficients();
    return true;
}

bool InvoiceBackend::addService(const QVariantMap &data)
{
    if(data.isEmpty() || !ServicesDatabase::addService(data))
        return false;
    loadServices();
    return true;
}

bool InvoiceBackend::updateService(const QVariantMap &data)
{
    if(data.isEmpty() || !ServicesDatabase::updateService(data))
        return false;
    loadServices();
    return true;
}

bool InvoiceBackend::deleteService(const QString &serviceId)
{
    if(serviceId.isEmpty() || !ServicesDatabase::deleteService(serviceId))
        return false;
    loadServices();
    return true;
}

bool InvoiceBackend::importServicesFromFile(const QString &fileUrl)
{
    try
    {
        const ExcelCatalog catalog = importCatalogFromExcel(fileUrl);
        if(catalog.services.isEmpty() && catalog.coefficients.isEmpty())
        {
            qWarning("InvoiceBackend: import produced no rows from %s",
                     qPrintable(fileUrl));
            emit importFailed(tr("В файле не найдено услуг или коэффициентов"));
            return false;
        }

        int savedServices = 0;
        for(const QVariant &item : catalog.services)
        {
            if(ServicesDatabase::addService(item.toMap()))
                ++savedServices;
        }

        int savedCoefficients = 0;
        for(const QVariant &item : catalog.coefficients)
        {
            if(!CoefficientsDatabase::addCoefficient(item.toMap()).isEmpty())
                ++savedCoefficients;
        }

        loadServices();
        loadCoefficients();
        qInfo("InvoiceBackend: imported %d/%d services and %d/%d coefficients from %s",
              savedServices,
              static_cast<int>(catalog.services.size()),
              savedCoefficients,
              static_cast<int>(catalog.coefficients.size()),
              qPrintable(fileUrl));
        emit importCompleted(savedServices,
                             static_cast<int>(catalog.services.size()),
                             savedCoefficients,
                             static_cast<int>(catalog.coefficients.size()));
        // Parsing succeeded; duplicates are skipped rather than treated as an error.
        return true;
    }
    catch(const std::exception &ex)
    {
        qWarning("InvoiceBackend: import failed from %s: %s",
                 qPrintable(fileUrl),
                 ex.what());
        emit importFailed(tr("Не удалось прочитать Excel-файл"));
        return false;
    }
    catch(...)
    {
        qWarning("InvoiceBackend: import failed from %s: unknown error",
                 qPrintable(fileUrl));
        emit importFailed(tr("Не удалось прочитать Excel-файл"));
        return false;
    }
}

bool InvoiceBackend::exportServicesToFile(const QString &fileUrl)
{
    const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd_HHmmss"));
    const QString target = fileUrl.trimmed().isEmpty()
        ? defaultExportPath(QStringLiteral("services_%1.xlsx").arg(stamp))
        : fileUrl;

    try
    {
        ExcelCatalog catalog;
        catalog.services = ServicesDatabase::loadServices();
        catalog.coefficients = CoefficientsDatabase::loadCoefficients();
        const QString saved = exportCatalogExcel(target, catalog);
        announceSavedFile(saved, QStringLiteral("Шаблон"));
        return !saved.isEmpty();
    }
    catch(const std::exception &ex)
    {
        qWarning("InvoiceBackend: export failed: %s", ex.what());
        NotificationManager::notifyError(QStringLiteral("Не удалось экспортировать услуги"));
        return false;
    }
    catch(...)
    {
        NotificationManager::notifyError(QStringLiteral("Не удалось экспортировать услуги"));
        return false;
    }
}

bool InvoiceBackend::exportServicesPresentationToFile(const QString &fileUrl, const QString &title)
{
    const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd_HHmmss"));
    const QString target = fileUrl.trimmed().isEmpty()
        ? defaultExportPath(QStringLiteral("presentation_%1.pdf").arg(stamp))
        : fileUrl;

    rememberPresentationTitle(title);

    try
    {
        const QString saved = exportServicesPdf(target, ServicesDatabase::loadServices(), title.trimmed());
        announceSavedFile(saved, QStringLiteral("PDF"));
        return !saved.isEmpty();
    }
    catch(const std::exception &ex)
    {
        qWarning("InvoiceBackend: presentation failed: %s", ex.what());
        NotificationManager::notifyError(QStringLiteral("Не удалось сохранить презентацию"));
        return false;
    }
    catch(...)
    {
        NotificationManager::notifyError(QStringLiteral("Не удалось сохранить презентацию"));
        return false;
    }
}

void InvoiceBackend::searchServices(const QString &query)
{
    m_servicesFilter->setFilterText(query);
    emit countFound(m_servicesFilter->rowCount());
}

void InvoiceBackend::clearSuggestions()
{
    m_servicesFilter->clearFilter();
    emit suggestionsCleared();
}

void InvoiceBackend::searchCoefficients(const QString &query)
{
    m_coefficientsFilter->setFilterText(query);
    emit coefficientsCountFound(m_coefficientsFilter->rowCount());
}

void InvoiceBackend::clearCoefficientSuggestions()
{
    m_coefficientsFilter->clearFilter();
}

void InvoiceBackend::addServiceToOrder(double amount, const QString &clientId, const QString &clientName,
                                       const QString &objectId, int price)
{
    Q_UNUSED(amount);
    Q_UNUSED(clientId);
    Q_UNUSED(clientName);
    Q_UNUSED(objectId);
    Q_UNUSED(price);
}

bool InvoiceBackend::addLineFromSelection()
{
    return false;
}

bool InvoiceBackend::createInvoice()
{
    if(!m_reportBackend || m_reportBackend->workCount() == 0)
        return false;

    ++m_invoiceCounter;
    const QString invoiceNumber = QStringLiteral("INV-%1").arg(m_invoiceCounter, 4, 10, QChar('0'));
    emit invoiceCreated(m_invoiceCounter, invoiceNumber);
    clearForm();
    return true;
}

void InvoiceBackend::clearForm()
{
    if(m_reportBackend)
    {
        m_reportBackend->clearCurrentService();
        m_reportBackend->clearWorks();
    }
    clearSuggestions();
    clearCoefficientSuggestions();
    emit suggestionsCleared();
}

QVariantList InvoiceBackend::getAllServices() const
{
    QVariantList result;
    for(int row = 0; row < m_services->rowCount(); ++row)
    {
        const QModelIndex index = m_services->index(row, 0);
        const QString id = m_services->data(index, ServicesModel::IdRole).toString();
        result.append(m_services->itemData(id));
    }
    return result;
}

QVariantList InvoiceBackend::getAllCoefficients() const
{
    QVariantList result;
    for(int row = 0; row < m_coefficients->rowCount(); ++row)
    {
        const QModelIndex index = m_coefficients->index(row, 0);
        const QString id = m_coefficients->data(index, CoefficientsModel::IdRole).toString();
        result.append(m_coefficients->itemData(id));
    }
    return result;
}

QVariantMap InvoiceBackend::getServiceById(int serviceId) const
{
    Q_UNUSED(serviceId);
    return {};
}

QString InvoiceBackend::getCurrentInvoiceNumber() const
{
    return QStringLiteral("INV-%1").arg(m_invoiceCounter + 1, 4, 10, QChar('0'));
}

} // namespace workorder
