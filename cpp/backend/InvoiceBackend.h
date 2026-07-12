#ifndef WORKORDER_BACKEND_INVOICE_BACKEND_H
#define WORKORDER_BACKEND_INVOICE_BACKEND_H

#include <QObject>
#include <QQmlApplicationEngine>

namespace workorder
{

class CoefficientsFilterModel;
class ReportBackend;
class ServicesFilterModel;
class ServicesModel;

class InvoiceBackend : public QObject
{
    Q_OBJECT

public:
    explicit InvoiceBackend(QQmlApplicationEngine *engine, QObject *parent = nullptr);

    void bindReportBackend(ReportBackend *reportBackend);

    Q_INVOKABLE bool addService(const QVariantMap &data);
    Q_INVOKABLE bool updateService(const QVariantMap &data);
    Q_INVOKABLE bool deleteService(const QString &serviceId);
    Q_INVOKABLE bool importServicesFromFile(const QString &fileUrl);
    Q_INVOKABLE bool exportServicesToFile(const QString &fileUrl);
    Q_INVOKABLE bool exportServicesPresentationToFile(const QString &fileUrl);
    Q_INVOKABLE void searchServices(const QString &query);
    Q_INVOKABLE void clearSuggestions();
    Q_INVOKABLE void searchCoefficients(const QString &query);
    Q_INVOKABLE void clearCoefficientSuggestions();
    Q_INVOKABLE void addServiceToOrder(double amount, const QString &clientId, const QString &clientName,
                                       const QString &objectId, int price);
    Q_INVOKABLE bool addLineFromSelection();
    Q_INVOKABLE bool createInvoice();
    Q_INVOKABLE void clearForm();
    Q_INVOKABLE QVariantList getAllServices() const;
    Q_INVOKABLE QVariantMap getServiceById(int serviceId) const;
    Q_INVOKABLE QString getCurrentInvoiceNumber() const;

    ServicesModel *servicesModel() const { return m_services; }

signals:
    void countFound(int count);
    void coefficientsCountFound(int count);
    void suggestionsUpdated(const QVariantList &suggestions);
    void suggestionsCleared();
    void invoiceCreated(int invoiceId, const QString &invoiceNumber);

private:
    void loadServices();
    void registerModels(QQmlApplicationEngine *engine);

    ReportBackend *m_reportBackend = nullptr;
    int m_invoiceCounter = 0;
    ServicesModel *m_services = nullptr;
    ServicesFilterModel *m_servicesFilter = nullptr;
    CoefficientsFilterModel *m_coefficientsFilter = nullptr;
};

} // namespace workorder

#endif // WORKORDER_BACKEND_INVOICE_BACKEND_H
