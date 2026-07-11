#ifndef WORKORDER_BACKEND_REPORT_BACKEND_H
#define WORKORDER_BACKEND_REPORT_BACKEND_H

#include <QObject>
#include <QQmlApplicationEngine>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

#include "clientsModel.h"
#include "objectsModel.h"
#include "ordersModel.h"
#include "subobjectsFilterModel.h"
#include "subobjectsModel.h"
#include "worksModel.h"

namespace workorder
{

class ReportOptionsBackend;
class SettingsBackend;

class ReportBackend : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int clientCount READ clientCount NOTIFY clientsChanged)
    Q_PROPERTY(int workCount READ workCount NOTIFY worksChanged)
    Q_PROPERTY(double worksTotal READ worksTotal NOTIFY worksChanged)
    Q_PROPERTY(QString selectedClientId READ selectedClientId NOTIFY clientSelected)
    Q_PROPERTY(QString selectedClientName READ selectedClientName NOTIFY clientSelected)
    Q_PROPERTY(QString selectedObjectName READ selectedObjectName NOTIFY objectSelected)
    Q_PROPERTY(int selectedObjectLastOrder READ selectedObjectLastOrder NOTIFY objectUpdated)
    Q_PROPERTY(int selectedStartOrderAt READ selectedStartOrderAt NOTIFY orderSelected)
    Q_PROPERTY(int selectedOrderTotalPrice READ selectedOrderTotalPrice NOTIFY orderSelected)
    Q_PROPERTY(QString currentServiceName READ currentServiceName NOTIFY serviceSelected)
    Q_PROPERTY(int currentPrice READ currentPrice NOTIFY serviceSelected)
    Q_PROPERTY(QString currentCoefficients READ currentCoefficients NOTIFY serviceSelected)
    Q_PROPERTY(int currentPercentSum READ currentPercentSum NOTIFY serviceSelected)
    Q_PROPERTY(QString currentSubObject READ currentSubObject NOTIFY subObjectChanged)
    Q_PROPERTY(QString lastReportPath READ lastReportPath NOTIFY reportGenerated)
    Q_PROPERTY(QString lastReportUrl READ lastReportUrl NOTIFY reportGenerated)

public:
    ReportBackend(SettingsBackend *settingsBackend,
                  ReportOptionsBackend *reportOptionsBackend,
                  QQmlApplicationEngine *engine,
                  QObject *parent = nullptr);

    int clientCount() const;
    int workCount() const;
    double worksTotal() const;
    QString selectedClientId() const;
    QString selectedClientName() const;
    QString selectedObjectName() const;
    int selectedObjectLastOrder() const;
    int selectedStartOrderAt() const;
    int selectedOrderTotalPrice() const;
    QString currentServiceName() const;
    int currentPrice() const;
    QString currentCoefficients() const;
    int currentPercentSum() const;
    QString currentSubObject() const;
    QString lastReportPath() const;
    QString lastReportUrl() const;

    Q_INVOKABLE bool initializeData();
    Q_INVOKABLE bool addClient(const QVariantMap &data);
    Q_INVOKABLE void selectClient(const QString &clientId);
    Q_INVOKABLE void updateLastTimeObject();
    Q_INVOKABLE void selectObject(const QString &objectId);
    Q_INVOKABLE void selectOrder(int startOrderAt);
    Q_INVOKABLE void clearWorks();
    Q_INVOKABLE void selectService(const QString &serviceId, const QString &name, const QString &unit, int price);
    Q_INVOKABLE void setCurrentServicePrice(int price);
    Q_INVOKABLE void addCoefficient(const QString &serviceId, const QString &name, const QString &unit, int price);
    Q_INVOKABLE void setCurrentSubObject(const QString &subObject);
    Q_INVOKABLE void searchSubObjects(const QString &query);
    Q_INVOKABLE void clearSubObjectSuggestions();
    Q_INVOKABLE void clearCurrentService();
    Q_INVOKABLE bool addWork(double quantity);
    Q_INVOKABLE bool updateWork(const QVariantMap &data);
    Q_INVOKABLE bool deleteWork(const QString &workId);
    Q_INVOKABLE bool addObject(const QVariantMap &data);
    Q_INVOKABLE bool generateReport();
    Q_INVOKABLE bool saveReportToFile(const QString &fileUrl);
    Q_INVOKABLE QString defaultReportSaveUrl(const QString &clientId) const;
    Q_INVOKABLE QString defaultReportSaveFolderUrl() const;
    Q_INVOKABLE bool previewReport();
    Q_INVOKABLE QVariantList getOrderStartTimes() const;
    Q_INVOKABLE QVariantList getClientWorks() const;
    Q_INVOKABLE void refreshOrders();
    Q_INVOKABLE void refreshSubobject(const QString &objectId);

    ClientsModel *clientsModel() const;
    ObjectsModel *objectsModel() const;
    OrdersModel *ordersModel() const;
    WorksModel *worksModel() const;
    WorksModel *workReportModel() const;
    SubobjectsModel *subobjectsModel() const;
    SubobjectsFilterModel *subobjectsFilterModel() const;

signals:
    void clientsChanged();
    void worksChanged();
    void clientSelected();
    void objectSelected();
    void objectUpdated();
    void orderSelected();
    void serviceSelected();
    void subObjectChanged(const QString &value);
    void reportGenerated(const QString &path, const QString &url);
    void errorOccurred(const QString &message);

private:
    struct CurrentClient
    {
        QString id;
        QString name;
    };

    struct CurrentObject
    {
        QString id;
        QString name;
        QString address;
        qint64 lastOrderAt = 0;
    };

    struct CurrentService
    {
        QString id;
        QString name;
        QString unit;
        int price = 0;
        QString subObject;
        QString coefficients;
        int percentSum = 100;
    };

    void registerModels(QQmlApplicationEngine *engine);
    void loadClients();
    void loadObjects();
    void loadOrders();
    void loadSubobjects(const QString &objectId);
    void reloadWorks();
    bool setCurrentClient(const QString &clientId);
    bool setCurrentObject(const QString &objectId);
    void saveSelectedClientId(const QString &clientId);
    void saveSelectedObjectId(const QString &objectId);
    void clearPersistedSelection();
    void restoreSelection();
    void updateCurrentObjectData();
    void clearSelectedOrder();
    bool generateReportInternal(bool saveToFile, const QString &filePath = QString());
    static int coefficientPercentPoints(int price);
    static QStringList parseCoefficientNames(const QString &value);
    static QString resolveLocalFilePath(const QString &fileUrl);

    SettingsBackend *m_settingsBackend = nullptr;
    ReportOptionsBackend *m_reportOptionsBackend = nullptr;
    CurrentClient m_currentClient;
    CurrentObject m_currentObject;
    CurrentService m_currentService;
    int m_selectedStartOrderAt = 0;
    int m_selectedOrderTotalPrice = 0;
    QString m_lastReportPath;
    QString m_lastReportUrl;
    QString m_previewTempPath;

    ClientsModel m_clients;
    ObjectsModel m_objects;
    OrdersModel m_orders;
    WorksModel m_works;
    WorksModel m_workReport;
    SubobjectsModel m_subobjects;
    SubobjectsFilterModel m_subobjectsFilter;
};

} // namespace workorder

#endif // WORKORDER_BACKEND_REPORT_BACKEND_H
