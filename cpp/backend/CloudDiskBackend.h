#ifndef WORKORDER_BACKEND_CLOUD_DISK_BACKEND_H
#define WORKORDER_BACKEND_CLOUD_DISK_BACKEND_H

#include <QObject>
#include <QNetworkRequest>
#include <QString>
#include <QStringList>
#include <QUrl>
#include <QVariantList>

class QNetworkAccessManager;
class QNetworkReply;

namespace workorder
{

class CloudDiskBackend : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool connected READ connected NOTIFY connectionChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString diskUrl READ diskUrl WRITE setDiskUrl NOTIFY connectionChanged)
    Q_PROPERTY(QString clientId READ clientId CONSTANT)
    Q_PROPERTY(QString authUrl READ authUrl CONSTANT)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(QVariantList entries READ entries NOTIFY entriesChanged)

public:
    explicit CloudDiskBackend(QObject *parent = nullptr);
    ~CloudDiskBackend() override;

    bool connected() const;
    bool busy() const;
    QString diskUrl() const;
    void setDiskUrl(const QString &value);
    QString clientId() const;
    QString authUrl() const;
    QString statusMessage() const;
    QVariantList entries() const;

    Q_INVOKABLE bool openAuthInBrowser();
    Q_INVOKABLE bool connectWithToken(const QString &tokenOrUrl);
    Q_INVOKABLE void clearDiskData();
    Q_INVOKABLE void refreshContents();
    Q_INVOKABLE void ensureWorkOrderDirectory();
    // Download cloud DBs to temp, merge missing rows into local, then force-upload.
    Q_INVOKABLE void syncDatabases();
    // Clear app:/workOrder files, then upload all local *.db.
    Q_INVOKABLE void forceUploadDatabases();
    // Clear local *.db, then download all *.db from app:/workOrder.
    Q_INVOKABLE void downloadDatabases();

signals:
    void connectionChanged();
    void busyChanged();
    void statusMessageChanged();
    void entriesChanged();

private:
    enum class PendingOp
    {
        None,
        EnsureOnly,
        Refresh,
        ForceUpload,
        Download,
        Sync
    };

    struct TransferItem
    {
        QString localPath;
        QString remotePath;
        QString name;
    };

    void loadPersisted();
    void persistCredentials();
    void setBusy(bool value);
    void setStatusMessage(const QString &message, const QString &logMessage);
    void setEntries(const QVariantList &entries);
    QString normalizeDiskUrl(const QString &value) const;
    QString extractToken(const QString &tokenOrUrl) const;
    QString resourcesUrl(const QString &path = QStringLiteral("app:/workOrder"),
                         int limit = 100) const;
    QString uploadUrl(const QString &remotePath, bool overwrite = true) const;
    QString downloadUrl(const QString &remotePath) const;
    QNetworkRequest authorizedRequest(const QUrl &url) const;
    bool beginOperation(PendingOp op, const QString &busyMessage, const QString &logMessage);
    void onEnsureReady();
    void startEnsureGet();
    void startEnsurePut();
    void startListRequest();
    void startListForCloudClear();
    void startListForDownload();
    void handleEnsureGetReply(QNetworkReply *reply);
    void handleEnsurePutReply(QNetworkReply *reply);
    void handleListReply(QNetworkReply *reply);
    void handleCloudClearListReply(QNetworkReply *reply);
    void handleCloudDeleteReply(QNetworkReply *reply);
    void handleUploadHrefReply(QNetworkReply *reply);
    void handleUploadPutReply(QNetworkReply *reply);
    void handleDownloadListReply(QNetworkReply *reply);
    void handleDownloadHrefReply(QNetworkReply *reply);
    void handleDownloadContentReply(QNetworkReply *reply);
    void processNextCloudDelete();
    void beginUploadQueue();
    void processNextUpload();
    void processNextDownload();
    void finishDownloadPhase();
    bool mergeIncomingDatabases();
    void clearSyncIncomingDir() const;
    QString syncIncomingDir() const;
    void finishTransferSuccess(const QString &message, const QString &logMessage);
    void finishWithError(const QString &message, const QString &logMessage);
    void closeAllSqlConnections() const;
    QStringList localDatabaseFileNames() const;
    bool clearLocalDatabaseFiles();
    QString remoteDbPath(const QString &fileName) const;

    QNetworkAccessManager *m_network = nullptr;
    QString m_diskUrl;
    QString m_token;
    QString m_statusMessage;
    QVariantList m_entries;
    bool m_busy = false;
    PendingOp m_pendingOp = PendingOp::None;
    QStringList m_deletePaths;
    QList<TransferItem> m_transferQueue;
    int m_transferIndex = 0;
};

} // namespace workorder

#endif // WORKORDER_BACKEND_CLOUD_DISK_BACKEND_H
