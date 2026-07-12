#include "InvoiceBackend.h"

#include "CoefficientsFilterModel.h"
#include "ReportBackend.h"
#include "ServicesFilterModel.h"
#include "ServicesModel.h"
#include "ServicesDatabase.h"
#include "ServicesExcelBuilder.h"
#include "ServicesPdfBuilder.h"

#include <QQmlContext>

namespace workorder
{

InvoiceBackend::InvoiceBackend(QQmlApplicationEngine *engine, QObject *parent)
    : QObject(parent)
    , m_services(new ServicesModel(this))
    , m_servicesFilter(new ServicesFilterModel(this))
    , m_coefficientsFilter(new CoefficientsFilterModel(this))
{
    ServicesDatabase::createServicesTable();
    m_servicesFilter->setSourceModel(m_services);
    m_coefficientsFilter->setSourceModel(m_services);
    loadServices();
    registerModels(engine);
}

void InvoiceBackend::registerModels(QQmlApplicationEngine *engine)
{
    if(!engine)
        return;

    QQmlContext *context = engine->rootContext();
    context->setContextProperty("servicesModel", m_services);
    context->setContextProperty("servicesFilterModel", m_servicesFilter);
    context->setContextProperty("coefficientsFilterModel", m_coefficientsFilter);
}

void InvoiceBackend::bindReportBackend(ReportBackend *reportBackend)
{
    m_reportBackend = reportBackend;
}

void InvoiceBackend::loadServices()
{
    QVariantList items;
    for(const QVariant &item : ServicesDatabase::loadServices())
        items.append(item);
    m_services->updateModelFromMaps(items);
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
    const StringMapList services = importServicesFromExcel(fileUrl);
    if(services.isEmpty())
        return false;

    int savedCount = 0;
    for(const QVariant &item : services)
    {
        if(ServicesDatabase::addService(item.toMap()))
            ++savedCount;
    }

    loadServices();
    return savedCount > 0;
}

bool InvoiceBackend::exportServicesToFile(const QString &fileUrl)
{
    try
    {
        exportServicesExcel(fileUrl, ServicesDatabase::loadServices());
        return true;
    }
    catch(...)
    {
        return false;
    }
}

bool InvoiceBackend::exportServicesPresentationToFile(const QString &fileUrl)
{
    try
    {
        exportServicesPdf(fileUrl, ServicesDatabase::loadServices());
        return true;
    }
    catch(...)
    {
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
    return {};
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
