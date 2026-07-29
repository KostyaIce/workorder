#ifndef WORKORDER_BACKEND_DATABASE_BACKEND_H
#define WORKORDER_BACKEND_DATABASE_BACKEND_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

namespace workorder
{

class DatabaseBackend : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int serviceCount READ serviceCount NOTIFY servicesChanged)
    Q_PROPERTY(int selectedServiceId READ selectedServiceId NOTIFY serviceSelected)
    Q_PROPERTY(QString servicesDbPath READ servicesDbPath NOTIFY servicesChanged)
    Q_PROPERTY(int workCount READ workCount NOTIFY worksChanged)

public:
    explicit DatabaseBackend(QObject *parent = nullptr);
    ~DatabaseBackend() override;

    int serviceCount() const { return m_services.size(); }
    int selectedServiceId() const { return m_selectedServiceId; }
    QString servicesDbPath() const { return m_servicesDbPath; }
    int workCount() const;

    Q_INVOKABLE bool addService(const QString &name, double price);
    Q_INVOKABLE bool updateService(int serviceId, const QString &name, double price);
    Q_INVOKABLE bool deleteService(int serviceId);
    Q_INVOKABLE void selectService(int serviceId);
    Q_INVOKABLE void clearSelection();
    Q_INVOKABLE QVariantList getAllServices() const;
    Q_INVOKABLE QVariantMap getServiceById(int serviceId) const;
    Q_INVOKABLE QVariantList searchServices(const QString &query) const;
    Q_INVOKABLE QVariantList filterByPriceRange(double minPrice, double maxPrice) const;
    Q_INVOKABLE bool createServicesDatabase(const QString &filePath = QString());
    Q_INVOKABLE bool createWorksDatabase(const QString &filePath = QString());
    Q_INVOKABLE bool repairDatabase(const QString &filePath = QString());
    Q_INVOKABLE bool loadServicesFromDatabase(const QString &filePath = QString());
    Q_INVOKABLE bool loadWorksFromDatabase(const QString &filePath = QString());
    Q_INVOKABLE QVariantList getAllCompletedWorks() const;
    Q_INVOKABLE bool exportToJson(const QString &filePath);
    Q_INVOKABLE bool importFromJson(const QString &filePath);
    Q_INVOKABLE bool resetDatabase();
    Q_INVOKABLE QVariantMap getStatistics() const;

signals:
    void servicesChanged();
    void serviceAdded(int id, const QString &name, double price);
    void serviceUpdated(int id, const QString &name, double price);
    void serviceDeleted(int id);
    void serviceSelected(int id, const QString &name, double price);
    void worksChanged();
    void databaseRepaired(const QString &message);

private:
    void applyServices(const QVariantList &services);
    int priceToCents(double price) const;
    double centsToPrice(int cents) const;

    QString m_servicesDbPath;
    QVariantList m_services;
    int m_nextId = 1;
    int m_selectedServiceId = 0;
};

} // namespace workorder

#endif // WORKORDER_BACKEND_DATABASE_BACKEND_H
