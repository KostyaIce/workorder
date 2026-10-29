#include "CloudDiskBackend.h"

#include "YandexDiskConfig.h"
#include "YandexDiskOAuthFlow.h"

#include "AppPaths.h"
#include "ClientsDatabase.h"
#include "DatabaseCloudJson.h"
#include "DatabaseStorage.h"
#include "ExpensesDatabase.h"
#include "JsonRecordStore.h"
#include "ObjectsDatabase.h"
#include "QSettingsStore.h"
#include "ServicesDatabase.h"
#include "WorksDatabase.h"

#include <QDate>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QSqlDatabase>
#include <QTimer>
#include <QUrl>
#include <QUrlQuery>
#include <algorithm>
#include <exception>

namespace workorder
{

namespace
{

const char *KEY_TOKEN = "cloud_disk/token";
const char *KEY_LAST_SYNC = "cloud_disk/last_sync_at";
const char *KEY_DISK_URL = "cloud_disk/disk_url";
const char *KEY_CLIENT_ID_LEGACY = "cloud_disk/client_id";
const char *DEFAULT_DISK_URL = "https://cloud-api.yandex.net/v1/disk";
const char *AUTH_BASE_URL = "https://oauth.yandex.ru/authorize";
const char *WORKORDER_FOLDER_PATH = "app:/workOrder";
const int LIST_LIMIT = 1000;

int httpStatusOf(QNetworkReply *reply)
{
    if(!reply)
        return 0;
    return reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
}

QString cloudJsonFileName(const QString &dbFileName)
{
    QString name = dbFileName;
    if(name.endsWith(QLatin1String(".db"), Qt::CaseInsensitive))
        name.chop(3);
    if(!name.endsWith(QLatin1String(".json"), Qt::CaseInsensitive))
        name += QStringLiteral(".json");
    return name;
}

QString logicalDbFileName(const QString &cloudFileName)
{
    QString name = cloudFileName;
    if(name.endsWith(QLatin1String(".json"), Qt::CaseInsensitive))
    {
        name.chop(5);
        name += QStringLiteral(".db");
    }
    return name;
}

bool isCloudDataFileName(const QString &name)
{
    return name.endsWith(QLatin1String(".json"), Qt::CaseInsensitive)
        || name.endsWith(QLatin1String(".db"), Qt::CaseInsensitive);
}

} // namespace

CloudDiskBackend::CloudDiskBackend(QObject *parent)
    : QObject(parent)
    , m_network(new QNetworkAccessManager(this))
    , m_diskUrl(QString::fromUtf8(DEFAULT_DISK_URL))
    , m_oauthFlow(new YandexDiskOAuthFlow(this))
{
    connect(m_oauthFlow,
            &YandexDiskOAuthFlow::finished,
            this,
            &CloudDiskBackend::onOAuthFinished);
    connect(m_oauthFlow,
            &YandexDiskOAuthFlow::progressMessageChanged,
            this,
            &CloudDiskBackend::onOAuthProgressMessage);
    connect(m_oauthFlow,
            &YandexDiskOAuthFlow::inProgressChanged,
            this,
            [this](bool inProgress) { setOauthInProgress(inProgress); });

    loadPersisted();
    if(m_token.isEmpty())
    {
        setStatusMessage(tr("Диск не подключён"), QStringLiteral("Disk not connected"));
        qInfo("CloudDiskBackend: started, disk not connected, url=%s",
              qPrintable(m_diskUrl));
    }
    else
    {
        setStatusMessage(tr("Диск подключён"), QStringLiteral("Disk connected"));
        qInfo("CloudDiskBackend: started, disk connected, url=%s, tokenLen=%d",
              qPrintable(m_diskUrl),
              static_cast<int>(m_token.size()));
    }
}

CloudDiskBackend::~CloudDiskBackend() = default;

bool CloudDiskBackend::connected() const
{
    return !m_token.isEmpty();
}

bool CloudDiskBackend::busy() const
{
    return m_busy;
}

bool CloudDiskBackend::oauthInProgress() const
{
    return m_oauthInProgress;
}

QString CloudDiskBackend::diskUrl() const
{
    return m_diskUrl;
}

void CloudDiskBackend::setDiskUrl(const QString &value)
{
    const QString normalized = normalizeDiskUrl(value);
    if(m_diskUrl == normalized)
        return;
    m_diskUrl = normalized;
    if(connected())
        persistCredentials();
    emit connectionChanged();
}

QString CloudDiskBackend::clientId() const
{
    return QString::fromUtf8(YandexDiskConfig::oauthClientId);
}

QString CloudDiskBackend::authUrl() const
{
    if(m_oauthFlow && m_oauthFlow->inProgress())
        return m_oauthFlow->buildAuthorizeUrl();

    QUrl url(QString::fromUtf8(AUTH_BASE_URL));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("response_type"), QStringLiteral("code"));
    query.addQueryItem(QStringLiteral("client_id"), clientId());
    query.addQueryItem(QStringLiteral("redirect_uri"), m_oauthFlow->redirectUri());
    query.addQueryItem(QStringLiteral("scope"),
                       QString::fromUtf8(YandexDiskConfig::oauthScopes));
    url.setQuery(query);
    return url.toString();
}

QString CloudDiskBackend::statusMessage() const
{
    return m_statusMessage;
}

QString CloudDiskBackend::lastSyncWhen() const
{
    if(m_lastSyncAt <= 0)
        return {};

    const QDateTime when = QDateTime::fromSecsSinceEpoch(m_lastSyncAt);
    const QDate today = QDate::currentDate();
    QString day;
    if(when.date() == today)
        day = tr("сегодня");
    else if(when.date() == today.addDays(-1))
        day = tr("вчера");
    else
        day = when.toString(QStringLiteral("dd.MM.yyyy"));
    return QStringLiteral("%1, %2").arg(day, when.toString(QStringLiteral("HH:mm")));
}

QString CloudDiskBackend::lastSyncText() const
{
    const QString when = lastSyncWhen();
    if(when.isEmpty())
        return {};
    return tr("Последняя синхронизация: %1").arg(when);
}

QVariantList CloudDiskBackend::entries() const
{
    return m_entries;
}

bool CloudDiskBackend::openAuthInBrowser()
{
    if(!m_oauthFlow->begin())
    {
        setStatusMessage(tr("Не удалось начать вход в Яндекс"),
                         QStringLiteral("OAuth begin failed"));
        return false;
    }

    if(m_oauthFlow->usesNativeSdk())
    {
        // iOS: YandexLoginSDK already presents its own authorization UI.
        onOAuthProgressMessage(tr("Подтвердите вход в Яндекс..."));
        return true;
    }

    const QString url = m_oauthFlow->buildAuthorizeUrl();
    qInfo("CloudDiskBackend: openAuthInBrowser url=%s", qPrintable(url));
    if(!QDesktopServices::openUrl(QUrl(url)))
    {
        qWarning("CloudDiskBackend: failed to open browser");
        m_oauthFlow->cancel();
        setStatusMessage(tr("Не удалось открыть браузер"), QStringLiteral("Failed to open browser"));
        return false;
    }

    onOAuthProgressMessage(tr("Ожидаем подтверждение в браузере..."));
    return true;
}

void CloudDiskBackend::cancelOAuth()
{
    if(m_oauthFlow)
        m_oauthFlow->cancel();
    setStatusMessage(tr("Вход отменён"), QStringLiteral("OAuth cancelled"));
}

void CloudDiskBackend::onOAuthFinished(bool success,
                                       const QString &accessToken,
                                       const QString &errorMessage)
{
    if(!success)
    {
        if(!errorMessage.isEmpty())
            setStatusMessage(errorMessage, QStringLiteral("OAuth failed"));
        return;
    }

    connectWithToken(accessToken);
}

void CloudDiskBackend::onOAuthProgressMessage(const QString &message)
{
    if(message.isEmpty())
        return;
    setStatusMessage(message, message);
}

void CloudDiskBackend::setOauthInProgress(bool value)
{
    if(m_oauthInProgress == value)
        return;
    m_oauthInProgress = value;
    emit oauthInProgressChanged();
}

bool CloudDiskBackend::connectWithToken(const QString &tokenOrUrl)
{
    const QString token = extractToken(tokenOrUrl);
    if(token.isEmpty())
    {
        qWarning("CloudDiskBackend: connectWithToken failed, token empty or not recognized");
        setStatusMessage(tr("Токен пустой или не распознан"),
                     QStringLiteral("Token is empty or not recognized"));
        return false;
    }

    m_token = token;
    m_diskUrl = normalizeDiskUrl(m_diskUrl);
    persistCredentials();
    setEntries({});
    setStatusMessage(tr("Диск подключён"), QStringLiteral("Disk connected"));
    emit connectionChanged();
    qInfo("CloudDiskBackend: connected, url=%s, tokenLen=%d",
          qPrintable(m_diskUrl),
          static_cast<int>(m_token.size()));
    refreshContents();
    return true;
}

void CloudDiskBackend::clearDiskData()
{
    qInfo("CloudDiskBackend: clearDiskData (disconnect, token only)");
    if(m_oauthFlow)
        m_oauthFlow->cancel();
    m_token.clear();
    m_entries.clear();
    QSettingsStore store;
    store.remove(QString::fromUtf8(KEY_TOKEN));
    store.sync();
    setBusy(false);
    setStatusMessage(tr("Авторизация удалена, диск отключён"), QStringLiteral("Authorization cleared, disk disconnected"));
    emit entriesChanged();
    emit connectionChanged();
}

void CloudDiskBackend::refreshContents()
{
    if(!beginOperation(PendingOp::Refresh,
                     tr("Загрузка содержимого..."),
                     QStringLiteral("Loading contents...")))
        return;
    startEnsureGet();
}

void CloudDiskBackend::ensureWorkOrderDirectory()
{
    if(!beginOperation(PendingOp::EnsureOnly,
                     tr("Проверка каталога workOrder..."),
                     QStringLiteral("Checking workOrder directory...")))
        return;
    startEnsureGet();
}

void CloudDiskBackend::syncDatabases()
{
    if(!beginOperation(PendingOp::Sync,
                     tr("Синхронизация..."),
                     QStringLiteral("Syncing databases...")))
        return;
    m_syncRecordsAdded = 0;
    qInfo("CloudDiskBackend: syncDatabases started");
    clearSyncIncomingDir();
    clearSyncOutgoingDir();
    startEnsureGet();
}

bool CloudDiskBackend::beginOperation(PendingOp op, const QString &busyMessage, const QString &logMessage)
{
    if(m_token.isEmpty())
    {
        setStatusMessage(tr("Сначала подключите диск"),
                         QStringLiteral("Connect the disk first"));
        return false;
    }
    if(m_busy)
    {
        qInfo("CloudDiskBackend: operation skipped, busy");
        return false;
    }

    m_pendingOp = op;
    m_transferQueue.clear();
    m_transferIndex = 0;
    setBusy(true);
    setStatusMessage(busyMessage, logMessage);
    return true;
}

void CloudDiskBackend::onEnsureReady()
{
    switch(m_pendingOp)
    {
    case PendingOp::Refresh:
        startListRequest();
        break;
    case PendingOp::EnsureOnly:
        setBusy(false);
        m_pendingOp = PendingOp::None;
        setStatusMessage(tr("Каталог workOrder готов"),
                     QStringLiteral("workOrder directory is ready"));
        break;
    case PendingOp::Sync:
        startListForDownload();
        break;
    case PendingOp::None:
    default:
        finishWithError(tr("Внутренняя ошибка операции"),
                    QStringLiteral("Internal operation error"));
        break;
    }
}

void CloudDiskBackend::startEnsureGet()
{
    setStatusMessage(tr("Проверка каталога workOrder..."),
                     QStringLiteral("Checking workOrder directory..."));
    const QUrl metaUrl(resourcesUrl(QString::fromUtf8(WORKORDER_FOLDER_PATH), 0));
    qInfo("CloudDiskBackend: ensure GET %s", qPrintable(metaUrl.toString()));
    QNetworkReply *reply = m_network->get(authorizedRequest(metaUrl));
    connect(reply, &QNetworkReply::finished, this, [this, reply]()
    {
        handleEnsureGetReply(reply);
        reply->deleteLater();
    });
}

void CloudDiskBackend::startEnsurePut()
{
    setStatusMessage(tr("Создание каталога workOrder..."),
                     QStringLiteral("Creating workOrder directory..."));
    const QUrl metaUrl(resourcesUrl(QString::fromUtf8(WORKORDER_FOLDER_PATH), 0));
    qInfo("CloudDiskBackend: ensure PUT %s", qPrintable(metaUrl.toString()));
    QNetworkReply *reply = m_network->sendCustomRequest(authorizedRequest(metaUrl), "PUT");
    connect(reply, &QNetworkReply::finished, this, [this, reply]()
    {
        handleEnsurePutReply(reply);
        reply->deleteLater();
    });
}

void CloudDiskBackend::startListRequest()
{
    setStatusMessage(tr("Загрузка содержимого..."),
                     QStringLiteral("Loading contents..."));
    const QString url = resourcesUrl(QString::fromUtf8(WORKORDER_FOLDER_PATH), LIST_LIMIT);
    qInfo("CloudDiskBackend: list GET %s", qPrintable(url));
    QNetworkReply *reply = m_network->get(authorizedRequest(QUrl(url)));
    connect(reply, &QNetworkReply::finished, this, [this, reply]()
    {
        handleListReply(reply);
        reply->deleteLater();
    });
}

void CloudDiskBackend::startListForDownload()
{
    setStatusMessage(tr("Чтение списка баз на диске..."),
                     QStringLiteral("Reading database list on disk..."));
    const QString url = resourcesUrl(QString::fromUtf8(WORKORDER_FOLDER_PATH), LIST_LIMIT);
    qInfo("CloudDiskBackend: download-list GET %s", qPrintable(url));
    QNetworkReply *reply = m_network->get(authorizedRequest(QUrl(url)));
    connect(reply, &QNetworkReply::finished, this, [this, reply]()
    {
        handleDownloadListReply(reply);
        reply->deleteLater();
    });
}

void CloudDiskBackend::handleEnsureGetReply(QNetworkReply *reply)
{
    const int status = httpStatusOf(reply);
    const QByteArray body = reply ? reply->readAll() : QByteArray();
    qInfo("CloudDiskBackend: ensure GET -> %d", status);

    if(status == 200)
    {
        const QJsonObject root = QJsonDocument::fromJson(body).object();
        const QString type = root.value(QStringLiteral("type")).toString();
        if(type != QLatin1String("dir"))
        {
            finishWithError(tr("Путь workOrder существует, но это не каталог"),
                    QStringLiteral("workOrder path exists but is not a directory"));
            qWarning("CloudDiskBackend: path %s exists but type=%s",
                     WORKORDER_FOLDER_PATH,
                     qPrintable(type));
            return;
        }

        qInfo("CloudDiskBackend: folder %s already exists", WORKORDER_FOLDER_PATH);
        onEnsureReady();
        return;
    }

    if(status == 404)
    {
        startEnsurePut();
        return;
    }

    qWarning("CloudDiskBackend: ensure GET failed status=%d body=%s",
             status,
             qPrintable(QString::fromUtf8(body.left(300))));
    if(status == 403)
        finishWithError(tr("Нет доступа (403). Нужен scope app_folder и путь app:/workOrder"),
                    QStringLiteral("Access denied (403). Need app_folder scope and app:/workOrder path"));
    else
        finishWithError(tr("Не удалось проверить каталог workOrder (%1)").arg(status),
                    QStringLiteral("Failed to check workOrder directory (%1)").arg(status));
}

void CloudDiskBackend::handleEnsurePutReply(QNetworkReply *reply)
{
    const int status = httpStatusOf(reply);
    const QByteArray body = reply ? reply->readAll() : QByteArray();
    qInfo("CloudDiskBackend: ensure PUT -> %d", status);

    if(status == 201 || status == 409)
    {
        qInfo("CloudDiskBackend: folder %s ready, status=%d",
              WORKORDER_FOLDER_PATH,
              status);
        onEnsureReady();
        return;
    }

    qWarning("CloudDiskBackend: ensure PUT failed status=%d body=%s",
             status,
             qPrintable(QString::fromUtf8(body.left(300))));
    finishWithError(tr("Не удалось создать каталог workOrder (%1)").arg(status),
                    QStringLiteral("Failed to create workOrder directory (%1)").arg(status));
}

void CloudDiskBackend::handleListReply(QNetworkReply *reply)
{
    m_pendingOp = PendingOp::None;
    setBusy(false);

    if(!reply)
    {
        qWarning("CloudDiskBackend: handleListReply null reply");
        setStatusMessage(tr("Ошибка сети"), QStringLiteral("Network error"));
        return;
    }

    const int httpStatus = httpStatusOf(reply);
    if(reply->error() != QNetworkReply::NoError)
    {
        const QByteArray body = reply->readAll();
        qWarning("CloudDiskBackend: list failed status=%d error=%s body=%s",
                 httpStatus,
                 qPrintable(reply->errorString()),
                 qPrintable(QString::fromUtf8(body.left(300))));
        if(httpStatus == 403)
            setStatusMessage(tr("Нет доступа (403). Нужен scope app_folder и путь app:/workOrder"),
                         QStringLiteral("Access denied (403). Need app_folder scope and app:/workOrder path"));
        else if(httpStatus == 404)
            setStatusMessage(tr("Каталог app:/workOrder не найден"),
                         QStringLiteral("Directory app:/workOrder not found"));
        else
            setStatusMessage(tr("Ошибка запроса (%1): %2")
                                 .arg(httpStatus)
                                 .arg(reply->errorString()),
                         QStringLiteral("Request error (%1): %2")
                             .arg(httpStatus)
                             .arg(reply->errorString()));
        return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    if(!doc.isObject())
    {
        qWarning("CloudDiskBackend: list response is not a JSON object");
        setStatusMessage(tr("Некорректный ответ API"), QStringLiteral("Invalid API response"));
        return;
    }

    const QJsonObject root = doc.object();
    const QJsonObject embedded = root.value(QStringLiteral("_embedded")).toObject();
    const QJsonArray items = embedded.value(QStringLiteral("items")).toArray();

    QVariantList entries;
    entries.reserve(items.size());
    for(const QJsonValue &value : items)
    {
        const QJsonObject item = value.toObject();
        QVariantMap entry;
        entry.insert(QStringLiteral("name"), item.value(QStringLiteral("name")).toString());
        entry.insert(QStringLiteral("type"), item.value(QStringLiteral("type")).toString());
        entry.insert(QStringLiteral("path"), item.value(QStringLiteral("path")).toString());
        entries.push_back(entry);
    }

    setEntries(entries);
    setStatusMessage(tr("Найдено элементов: %1").arg(entries.size()),
                     QStringLiteral("Found entries: %1").arg(entries.size()));
    qInfo("CloudDiskBackend: listed %d entries", static_cast<int>(entries.size()));
}

void CloudDiskBackend::beginUploadQueue()
{
    closeAllSqlConnections();

    if(!exportLocalDatabasesToOutgoingJson())
    {
        finishWithError(tr("Не удалось подготовить JSON для выгрузки"),
                        QStringLiteral("Failed to prepare JSON for upload"));
        return;
    }

    const QStringList names = localDatabaseFileNames();
    m_transferQueue.clear();
    m_transferIndex = 0;
    for(const QString &name : names)
    {
        const QString jsonName = cloudJsonFileName(name);
        TransferItem item;
        item.name = jsonName;
        item.localPath = QDir(syncOutgoingDir()).filePath(jsonName);
        item.remotePath = remoteDbPath(jsonName);
        if(!QFileInfo::exists(item.localPath))
            continue;
        // Compare against the file that was downloaded, including legacy *.db
        // names. Only files changed by the merge or by local edits are uploaded.
        QString incomingPath = QDir(syncIncomingDir()).filePath(jsonName);
        if(!QFileInfo::exists(incomingPath))
            incomingPath = QDir(syncIncomingDir()).filePath(name);
        if(QFileInfo::exists(incomingPath)
           && JsonRecordStore::documentsEqual(JsonRecordStore::loadDocument(item.localPath),
                                               JsonRecordStore::loadDocument(incomingPath)))
            continue;
        m_transferQueue.push_back(item);
    }

    if(m_transferQueue.isEmpty())
    {
        clearSyncIncomingDir();
        clearSyncOutgoingDir();
        finishTransferSuccess(tr("Синхронизация завершена: выгрузка не требуется"),
                              QStringLiteral("Cloud data unchanged; upload skipped"));
        return;
    }

    qInfo("CloudDiskBackend: upload queue size=%d",
          static_cast<int>(m_transferQueue.size()));
    processNextUpload();
}

void CloudDiskBackend::processNextUpload()
{
    if(m_transferIndex >= m_transferQueue.size())
    {
        clearSyncIncomingDir();
        clearSyncOutgoingDir();
        finishTransferSuccess(tr("Синхронизация завершена: подгружено %1 новых записей")
                                  .arg(m_syncRecordsAdded),
                              QStringLiteral("Sync finished: pulled %1 new records")
                                  .arg(m_syncRecordsAdded));
        return;
    }

    const TransferItem &item = m_transferQueue.at(m_transferIndex);
    setStatusMessage(tr("Выгрузка %1/%2: %3")
                         .arg(m_transferIndex + 1)
                         .arg(m_transferQueue.size())
                         .arg(item.name),
                     QStringLiteral("Uploading %1/%2: %3")
                         .arg(m_transferIndex + 1)
                         .arg(m_transferQueue.size())
                         .arg(item.name));

    const QUrl url(uploadUrl(item.remotePath, true));
    qInfo("CloudDiskBackend: upload href GET %s", qPrintable(url.toString()));
    QNetworkReply *reply = m_network->get(authorizedRequest(url));
    connect(reply, &QNetworkReply::finished, this, [this, reply]()
    {
        handleUploadHrefReply(reply);
        reply->deleteLater();
    });
}

void CloudDiskBackend::handleUploadHrefReply(QNetworkReply *reply)
{
    const int status = httpStatusOf(reply);
    const QByteArray body = reply ? reply->readAll() : QByteArray();
    if(status != 200)
    {
        qWarning("CloudDiskBackend: upload href failed status=%d body=%s",
                 status,
                 qPrintable(QString::fromUtf8(body.left(300))));
        finishWithError(tr("Не удалось получить URL загрузки (%1)").arg(status),
                    QStringLiteral("Failed to get upload URL (%1)").arg(status));
        return;
    }

    const QJsonObject root = QJsonDocument::fromJson(body).object();
    const QString href = root.value(QStringLiteral("href")).toString();
    if(href.isEmpty())
    {
        finishWithError(tr("Пустой URL загрузки"), QStringLiteral("Empty upload URL"));
        return;
    }

    if(m_transferIndex < 0 || m_transferIndex >= m_transferQueue.size())
    {
        finishWithError(tr("Внутренняя ошибка очереди выгрузки"),
                    QStringLiteral("Internal upload queue error"));
        return;
    }

    const TransferItem item = m_transferQueue.at(m_transferIndex);
    auto *file = new QFile(item.localPath);
    if(!file->open(QIODevice::ReadOnly))
    {
        const QString error = file->errorString();
        delete file;
        finishWithError(tr("Не удалось открыть %1: %2").arg(item.name, error),
                    QStringLiteral("Failed to open %1: %2").arg(item.name, error));
        return;
    }

    QNetworkRequest request{QUrl(href)};
    request.setHeader(QNetworkRequest::ContentTypeHeader,
                      QStringLiteral("application/json"));
    qInfo("CloudDiskBackend: upload PUT %s size=%lld",
          qPrintable(item.name),
          static_cast<long long>(file->size()));
    QNetworkReply *putReply = m_network->put(request, file);
    file->setParent(putReply);
    connect(putReply, &QNetworkReply::finished, this, [this, putReply]()
    {
        handleUploadPutReply(putReply);
        putReply->deleteLater();
    });
}

void CloudDiskBackend::handleUploadPutReply(QNetworkReply *reply)
{
    const int status = httpStatusOf(reply);
    const QByteArray body = reply ? reply->readAll() : QByteArray();
    if(status != 201 && status != 202)
    {
        qWarning("CloudDiskBackend: upload PUT failed status=%d body=%s",
                 status,
                 qPrintable(QString::fromUtf8(body.left(300))));
        finishWithError(tr("Ошибка выгрузки файла (%1)").arg(status),
                    QStringLiteral("File upload error (%1)").arg(status));
        return;
    }

    ++m_transferIndex;
    processNextUpload();
}

void CloudDiskBackend::handleDownloadListReply(QNetworkReply *reply)
{
    const int status = httpStatusOf(reply);
    const QByteArray body = reply ? reply->readAll() : QByteArray();
    if(status != 200)
    {
        qWarning("CloudDiskBackend: download-list failed status=%d body=%s",
                 status,
                 qPrintable(QString::fromUtf8(body.left(300))));
        finishWithError(tr("Не удалось прочитать облачный каталог (%1)").arg(status),
                    QStringLiteral("Failed to read cloud directory (%1)").arg(status));
        return;
    }

    const QJsonObject root = QJsonDocument::fromJson(body).object();
    const QJsonArray items = root.value(QStringLiteral("_embedded")).toObject()
                                 .value(QStringLiteral("items")).toArray();

    const QString targetDir = syncIncomingDir();
    clearSyncIncomingDir();
    if(!QDir().mkpath(targetDir))
    {
        finishWithError(tr("Не удалось создать временный каталог синхронизации"),
                        QStringLiteral("Failed to create sync temp directory"));
        return;
    }

    m_transferQueue.clear();
    m_transferIndex = 0;
    for(const QJsonValue &value : items)
    {
        const QJsonObject itemObj = value.toObject();
        if(itemObj.value(QStringLiteral("type")).toString() != QLatin1String("file"))
            continue;

        const QString name = itemObj.value(QStringLiteral("name")).toString();
        if(!isCloudDataFileName(name))
            continue;

        TransferItem item;
        item.name = name;
        item.remotePath = itemObj.value(QStringLiteral("path")).toString();
        if(item.remotePath.isEmpty())
            item.remotePath = remoteDbPath(name);
        item.localPath = QDir(targetDir).filePath(name);
        m_transferQueue.push_back(item);
    }

    if(m_transferQueue.isEmpty())
    {
        qInfo("CloudDiskBackend: sync cloud has no json files, upload local JSON only");
        setStatusMessage(tr("На диске нет данных, выгружаем локальные..."),
                         QStringLiteral("No cloud data files, uploading local JSON..."));
        beginUploadQueue();
        return;
    }

    qInfo("CloudDiskBackend: download queue size=%d",
          static_cast<int>(m_transferQueue.size()));
    processNextDownload();
}

void CloudDiskBackend::processNextDownload()
{
    if(m_transferIndex >= m_transferQueue.size())
    {
        finishDownloadPhase();
        return;
    }

    const TransferItem &item = m_transferQueue.at(m_transferIndex);
    setStatusMessage(tr("Загрузка %1/%2: %3")
                         .arg(m_transferIndex + 1)
                         .arg(m_transferQueue.size())
                         .arg(item.name),
                     QStringLiteral("Downloading %1/%2: %3")
                         .arg(m_transferIndex + 1)
                         .arg(m_transferQueue.size())
                         .arg(item.name));

    const QUrl url(downloadUrl(item.remotePath));
    qInfo("CloudDiskBackend: download href GET %s", qPrintable(url.toString()));
    QNetworkReply *reply = m_network->get(authorizedRequest(url));
    connect(reply, &QNetworkReply::finished, this, [this, reply]()
    {
        handleDownloadHrefReply(reply);
        reply->deleteLater();
    });
}

void CloudDiskBackend::handleDownloadHrefReply(QNetworkReply *reply)
{
    const int status = httpStatusOf(reply);
    const QByteArray body = reply ? reply->readAll() : QByteArray();
    if(status != 200)
    {
        qWarning("CloudDiskBackend: download href failed status=%d body=%s",
                 status,
                 qPrintable(QString::fromUtf8(body.left(300))));
        finishWithError(tr("Не удалось получить URL скачивания (%1)").arg(status),
                    QStringLiteral("Failed to get download URL (%1)").arg(status));
        return;
    }

    const QJsonObject root = QJsonDocument::fromJson(body).object();
    const QString href = root.value(QStringLiteral("href")).toString();
    if(href.isEmpty())
    {
        finishWithError(tr("Пустой URL скачивания"), QStringLiteral("Empty download URL"));
        return;
    }

    QNetworkRequest request{QUrl(href)};
    request.setRawHeader("Authorization", QByteArray("OAuth ") + m_token.toUtf8());
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    qInfo("CloudDiskBackend: download content GET %s", qPrintable(href));
    QNetworkReply *contentReply = m_network->get(request);
    connect(contentReply, &QNetworkReply::finished, this, [this, contentReply]()
    {
        handleDownloadContentReply(contentReply);
        contentReply->deleteLater();
    });
}

void CloudDiskBackend::handleDownloadContentReply(QNetworkReply *reply)
{
    if(m_transferIndex < 0 || m_transferIndex >= m_transferQueue.size())
    {
        finishWithError(tr("Внутренняя ошибка очереди загрузки"),
                    QStringLiteral("Internal download queue error"));
        return;
    }

    const TransferItem item = m_transferQueue.at(m_transferIndex);
    const int status = httpStatusOf(reply);
    if(!reply || reply->error() != QNetworkReply::NoError || (status != 0 && status != 200))
    {
        qWarning("CloudDiskBackend: download content failed status=%d error=%s",
                 status,
                 reply ? qPrintable(reply->errorString()) : "null");
        finishWithError(tr("Ошибка скачивания %1 (%2)")
                            .arg(item.name)
                            .arg(status ? status : -1),
                    QStringLiteral("Download error %1 (%2)")
                        .arg(item.name)
                        .arg(status ? status : -1));
        return;
    }

    const QByteArray data = reply->readAll();
    QDir().mkpath(QFileInfo(item.localPath).absolutePath());
    QFile file(item.localPath);
    if(!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        finishWithError(tr("Не удалось записать %1: %2")
                            .arg(item.name, file.errorString()),
                    QStringLiteral("Failed to write %1: %2")
                        .arg(item.name, file.errorString()));
        return;
    }
    if(file.write(data) != data.size())
    {
        finishWithError(tr("Неполная запись файла %1").arg(item.name),
                    QStringLiteral("Incomplete write of file %1").arg(item.name));
        return;
    }
    file.close();

    qInfo("CloudDiskBackend: downloaded %s bytes=%d",
          qPrintable(item.name),
          static_cast<int>(data.size()));
    ++m_transferIndex;
    processNextDownload();
}

void CloudDiskBackend::finishTransferSuccess(const QString &message, const QString &logMessage)
{
    m_pendingOp = PendingOp::None;
    m_transferQueue.clear();
    m_transferIndex = 0;
    rememberLastSync();
    setStatusMessage(message, logMessage);
    qInfo("CloudDiskBackend: transfer success: %s", qPrintable(logMessage));
    // Local SQLite changed, so in-memory models must reload before the next view.
    emit databasesSynchronized();
    // Keep busy until list refresh finishes.
    startListRequest();
}

void CloudDiskBackend::finishWithError(const QString &message, const QString &logMessage)
{
    qWarning("CloudDiskBackend: %s", qPrintable(logMessage));
    // Defer UI reset: calling from QNetworkReply while a modal dialog is open can
    // trigger a macOS/Qt Cocoa focusWindowChanged crash (NSImage imageNamed assert).
    QTimer::singleShot(0, this, [this, message, logMessage]()
    {
        clearSyncIncomingDir();
        clearSyncOutgoingDir();
        m_pendingOp = PendingOp::None;
        m_transferQueue.clear();
        m_transferIndex = 0;
        setBusy(false);
        setStatusMessage(message, logMessage);
    });
}

void CloudDiskBackend::finishDownloadPhase()
{
    setStatusMessage(tr("Объединение с локальными базами..."),
                     QStringLiteral("Merging cloud JSON into local SQLite..."));
    if(!mergeIncomingDatabases())
    {
        finishWithError(tr("Ошибка объединения данных"),
                        QStringLiteral("Data merge error"));
        return;
    }
    setStatusMessage(tr("Выгрузка на диск..."),
                     QStringLiteral("Uploading merged JSON to disk..."));
    beginUploadQueue();
}

QString CloudDiskBackend::syncIncomingDir() const
{
    return QDir(AppPaths::dataDir()).filePath(QStringLiteral("_cloud_sync_incoming"));
}

void CloudDiskBackend::clearSyncIncomingDir() const
{
    QDir dir(syncIncomingDir());
    if(!dir.exists())
        return;
    const QStringList names = dir.entryList(QDir::Files | QDir::NoDotAndDotDot);
    for(const QString &name : names)
        QFile::remove(dir.filePath(name));
    dir.rmdir(dir.absolutePath());
}

bool CloudDiskBackend::mergeIncomingDatabases()
try
{
    closeAllSqlConnections();

    QDir incoming(syncIncomingDir());
    if(!incoming.exists())
        return true;

    const QString dataDir = AppPaths::dbDir();
    QStringList names = incoming.entryList(
        {QStringLiteral("*.json"), QStringLiteral("*.db")}, QDir::Files, QDir::Name);
    std::sort(names.begin(), names.end(), [](const QString &left, const QString &right)
    {
        const bool leftJson = left.endsWith(QLatin1String(".json"), Qt::CaseInsensitive);
        const bool rightJson = right.endsWith(QLatin1String(".json"), Qt::CaseInsensitive);
        if(leftJson != rightJson)
            return leftJson;
        return left.compare(right, Qt::CaseInsensitive) < 0;
    });
    QStringList mergedLogicalNames;
    for(const QString &name : names)
    {
        const QString logicalName = logicalDbFileName(name);
        if(mergedLogicalNames.contains(logicalName, Qt::CaseInsensitive))
            continue;
        mergedLogicalNames.append(logicalName);

        const QString sourcePath = incoming.filePath(name);
        QFile sourceFile(sourcePath);
        if(!sourceFile.open(QIODevice::ReadOnly))
        {
            qWarning("CloudDiskBackend: failed to read incoming %s", qPrintable(name));
            return false;
        }
        const QByteArray payload = sourceFile.readAll();
        sourceFile.close();
        if(!JsonRecordStore::isJsonPayload(payload))
        {
            qWarning("CloudDiskBackend: unsupported cloud format in %s; sync stopped", qPrintable(name));
            return false;
        }
        const QJsonDocument document = QJsonDocument::fromJson(payload);
        if(!document.isObject() || document.object().isEmpty())
            return false;

        const QString targetPath = QDir(dataDir).filePath(logicalName);
        if(logicalName.compare(QLatin1String("clients.db"), Qt::CaseInsensitive) == 0)
        {
            if(!QFileInfo::exists(targetPath))
                ClientsDatabase::createClientTable(targetPath);
            const int added = DatabaseCloudJson::mergeClientsFromJsonFile(sourcePath, targetPath);
            if(added < 0)
                return false;
            m_syncRecordsAdded += added;
            continue;
        }
        if(logicalName.compare(QLatin1String("services.db"), Qt::CaseInsensitive) == 0)
        {
            const int added = DatabaseCloudJson::mergeServicesFromJsonFile(sourcePath);
            if(added < 0)
                return false;
            m_syncRecordsAdded += added;
            continue;
        }

        QString clientName;
        QString clientId;
        if(!DatabaseStorage::parseObjectDbFileName(logicalName, &clientName, &clientId))
        {
            qWarning("CloudDiskBackend: skip unknown db file %s", qPrintable(name));
            continue;
        }

        if(!QFileInfo::exists(targetPath))
        {
            ObjectsDatabase::createObjectDatabase(clientName, clientId);
            WorksDatabase::createWorksTable(clientName, clientId);
            ExpensesDatabase::createExpensesTable(clientName, clientId);
        }

        const int added = DatabaseCloudJson::mergeClientDbFromJsonFile(
            sourcePath, clientName, clientId);
        if(added < 0)
            return false;
        m_syncRecordsAdded += added;
    }

    closeAllSqlConnections();
    return true;
}
catch(const std::exception &error)
{
    qWarning("Cloud sync read failed: %s", error.what());
    return false;
}

void CloudDiskBackend::closeAllSqlConnections() const
{
    const QStringList names = QSqlDatabase::connectionNames();
    for(const QString &name : names)
    {
        {
            QSqlDatabase db = QSqlDatabase::database(name, false);
            if(db.isValid())
                db.close();
        }
        QSqlDatabase::removeDatabase(name);
    }
    qInfo("CloudDiskBackend: closed %d sql connections", static_cast<int>(names.size()));
}

QStringList CloudDiskBackend::localDatabaseFileNames() const
{
    QDir dir(AppPaths::dbDir());
    return dir.entryList({QStringLiteral("*.db")}, QDir::Files, QDir::Name);
}

QString CloudDiskBackend::syncOutgoingDir() const
{
    return QDir(AppPaths::dataDir()).filePath(QStringLiteral("_cloud_sync_outgoing"));
}

void CloudDiskBackend::clearSyncOutgoingDir() const
{
    QDir dir(syncOutgoingDir());
    if(!dir.exists())
        return;
    const QStringList names = dir.entryList(QDir::Files | QDir::NoDotAndDotDot);
    for(const QString &name : names)
        QFile::remove(dir.filePath(name));
    dir.rmdir(dir.absolutePath());
}

bool CloudDiskBackend::exportLocalDatabasesToOutgoingJson() const
try
{
    clearSyncOutgoingDir();
    const QString outDir = syncOutgoingDir();
    if(!QDir().mkpath(outDir))
        return false;

    const QString dataDir = AppPaths::dbDir();
    const QStringList names = localDatabaseFileNames();
    for(const QString &name : names)
    {
        const QString sqlitePath = QDir(dataDir).filePath(name);
        const QString jsonPath = QDir(outDir).filePath(cloudJsonFileName(name));
        if(name.compare(QLatin1String("clients.db"), Qt::CaseInsensitive) == 0)
        {
            if(!DatabaseCloudJson::exportClientsToJsonFile(sqlitePath, jsonPath))
                return false;
            continue;
        }
        if(name.compare(QLatin1String("services.db"), Qt::CaseInsensitive) == 0)
        {
            if(!DatabaseCloudJson::exportServicesToJsonFile(jsonPath))
                return false;
            continue;
        }

        QString clientName;
        QString clientId;
        if(!DatabaseStorage::parseObjectDbFileName(name, &clientName, &clientId))
            continue;
        if(!DatabaseCloudJson::exportClientDbToJsonFile(clientName, clientId, jsonPath))
            return false;
    }

    return true;
}
catch(const std::exception &error)
{
    qWarning("Cloud export read failed: %s", error.what());
    return false;
}

QString CloudDiskBackend::remoteDbPath(const QString &fileName) const
{
    return QString::fromUtf8(WORKORDER_FOLDER_PATH) + QLatin1Char('/') + fileName;
}

void CloudDiskBackend::loadPersisted()
{
    QSettingsStore store;
    m_token = store.read(QString::fromUtf8(KEY_TOKEN), QString()).toString().trimmed();
    m_lastSyncAt = store.read(QString::fromUtf8(KEY_LAST_SYNC), 0).toLongLong();
    const QString savedUrl = store.read(QString::fromUtf8(KEY_DISK_URL), QString()).toString();
    m_diskUrl = normalizeDiskUrl(savedUrl.isEmpty()
                                     ? QString::fromUtf8(DEFAULT_DISK_URL)
                                     : savedUrl);
    store.remove(QString::fromUtf8(KEY_CLIENT_ID_LEGACY));
    store.sync();
}

void CloudDiskBackend::persistCredentials()
{
    QSettingsStore store;
    if(m_token.isEmpty())
        store.remove(QString::fromUtf8(KEY_TOKEN));
    else
        store.write(QString::fromUtf8(KEY_TOKEN), m_token);
    store.write(QString::fromUtf8(KEY_DISK_URL), m_diskUrl);
    store.remove(QString::fromUtf8(KEY_CLIENT_ID_LEGACY));
    store.sync();
}

void CloudDiskBackend::setBusy(bool value)
{
    if(m_busy == value)
        return;
    m_busy = value;
    emit busyChanged();
}

void CloudDiskBackend::rememberLastSync()
{
    m_lastSyncAt = QDateTime::currentSecsSinceEpoch();
    QSettingsStore store;
    store.write(QString::fromUtf8(KEY_LAST_SYNC), m_lastSyncAt);
    store.sync();
    emit lastSyncChanged();
}

void CloudDiskBackend::setStatusMessage(const QString &message, const QString &logMessage)
{
    qDebug() << "[CloudDiskBackend][setStatusMessage]" << logMessage;
    if(m_statusMessage == message)
        return;
    m_statusMessage = message;
    emit statusMessageChanged();
}

void CloudDiskBackend::setEntries(const QVariantList &entries)
{
    m_entries = entries;
    emit entriesChanged();
}

QString CloudDiskBackend::normalizeDiskUrl(const QString &value) const
{
    QString url = value.trimmed();
    if(url.isEmpty())
        url = QString::fromUtf8(DEFAULT_DISK_URL);
    while(url.endsWith(QLatin1Char('/')))
        url.chop(1);
    return url;
}

QString CloudDiskBackend::extractToken(const QString &tokenOrUrl) const
{
    const QString raw = tokenOrUrl.trimmed();
    if(raw.isEmpty())
        return {};

    static const QRegularExpression tokenInUrl(
        QStringLiteral("access_token=([^&\\s#]+)"));
    const QRegularExpressionMatch match = tokenInUrl.match(raw);
    if(match.hasMatch())
        return QUrl::fromPercentEncoding(match.captured(1).toUtf8()).trimmed();

    if(raw.contains(QLatin1Char(' ')) || raw.contains(QLatin1Char('\n')))
        return {};

    return raw;
}

QString CloudDiskBackend::resourcesUrl(const QString &path, int limit) const
{
    QUrl url(m_diskUrl + QStringLiteral("/resources"));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("path"), path);
    if(limit > 0)
        query.addQueryItem(QStringLiteral("limit"), QString::number(limit));
    url.setQuery(query);
    return url.toString();
}

QString CloudDiskBackend::uploadUrl(const QString &remotePath, bool overwrite) const
{
    QUrl url(m_diskUrl + QStringLiteral("/resources/upload"));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("path"), remotePath);
    query.addQueryItem(QStringLiteral("overwrite"),
                       overwrite ? QStringLiteral("true") : QStringLiteral("false"));
    url.setQuery(query);
    return url.toString();
}

QString CloudDiskBackend::downloadUrl(const QString &remotePath) const
{
    QUrl url(m_diskUrl + QStringLiteral("/resources/download"));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("path"), remotePath);
    url.setQuery(query);
    return url.toString();
}

QNetworkRequest CloudDiskBackend::authorizedRequest(const QUrl &url) const
{
    QNetworkRequest request{url};
    request.setRawHeader("Authorization", QByteArray("OAuth ") + m_token.toUtf8());
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    return request;
}

} // namespace workorder
