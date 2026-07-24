#include "CloudDiskBackend.h"

#include "AppPaths.h"
#include "ClientsDatabase.h"
#include "DatabaseStorage.h"
#include "ObjectsDatabase.h"
#include "QSettingsStore.h"
#include "ServicesDatabase.h"
#include "WorksDatabase.h"

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
#include <QUrl>
#include <QUrlQuery>

namespace workorder
{

namespace
{

const char *KEY_TOKEN = "cloud_disk/token";
const char *KEY_DISK_URL = "cloud_disk/disk_url";
const char *KEY_CLIENT_ID_LEGACY = "cloud_disk/client_id";
const char *DEFAULT_DISK_URL = "https://cloud-api.yandex.net/v1/disk";
const char *AUTH_BASE_URL = "https://oauth.yandex.ru/authorize";
const char *YANDEX_CLIENT_ID = "d3e1a705454a448b841e617117fec451";
const char *WORKORDER_FOLDER_PATH = "app:/workOrder";
const int LIST_LIMIT = 1000;

int httpStatusOf(QNetworkReply *reply)
{
    if(!reply)
        return 0;
    return reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
}

bool isDatabaseFileName(const QString &name)
{
    return name.endsWith(QLatin1String(".db"), Qt::CaseInsensitive);
}

} // namespace

CloudDiskBackend::CloudDiskBackend(QObject *parent)
    : QObject(parent)
    , m_network(new QNetworkAccessManager(this))
    , m_diskUrl(QString::fromUtf8(DEFAULT_DISK_URL))
{
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
    return QString::fromUtf8(YANDEX_CLIENT_ID);
}

QString CloudDiskBackend::authUrl() const
{
    QUrl url(QString::fromUtf8(AUTH_BASE_URL));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("response_type"), QStringLiteral("token"));
    query.addQueryItem(QStringLiteral("client_id"), clientId());
    url.setQuery(query);
    return url.toString();
}

QString CloudDiskBackend::statusMessage() const
{
    return m_statusMessage;
}

QVariantList CloudDiskBackend::entries() const
{
    return m_entries;
}

bool CloudDiskBackend::openAuthInBrowser()
{
    const QString url = authUrl();
    qInfo("CloudDiskBackend: openAuthInBrowser url=%s", qPrintable(url));
    if(!QDesktopServices::openUrl(QUrl(url)))
    {
        qWarning("CloudDiskBackend: failed to open browser");
        setStatusMessage(tr("Не удалось открыть браузер"), QStringLiteral("Failed to open browser"));
        return false;
    }

    setStatusMessage(tr("Откройте ссылку в браузере, войдите и вставьте токен"),
                     QStringLiteral("Open the link in browser, sign in and paste the token"));
    return true;
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
    qInfo("CloudDiskBackend: clearDiskData");
    m_token.clear();
    m_entries.clear();
    m_pendingOp = PendingOp::None;
    m_deletePaths.clear();
    m_transferQueue.clear();
    m_transferIndex = 0;
    QSettingsStore store;
    store.remove(QString::fromUtf8(KEY_TOKEN));
    store.remove(QString::fromUtf8(KEY_DISK_URL));
    store.sync();
    setBusy(false);
    setStatusMessage(tr("Данные диска удалены"), QStringLiteral("Disk credentials cleared"));
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
                     tr("Синхронизация баз..."),
                     QStringLiteral("Syncing databases...")))
        return;
    qInfo("CloudDiskBackend: syncDatabases started");
    clearSyncIncomingDir();
    startEnsureGet();
}

void CloudDiskBackend::forceUploadDatabases()
{
    if(!beginOperation(PendingOp::ForceUpload,
                     tr("Выгрузка баз на диск..."),
                     QStringLiteral("Force uploading databases to disk...")))
        return;
    qInfo("CloudDiskBackend: forceUploadDatabases started");
    startEnsureGet();
}

void CloudDiskBackend::downloadDatabases()
{
    if(!beginOperation(PendingOp::Download,
                     tr("Загрузка баз с диска..."),
                     QStringLiteral("Downloading databases from disk...")))
        return;
    qInfo("CloudDiskBackend: downloadDatabases started");
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
    m_deletePaths.clear();
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
    case PendingOp::ForceUpload:
        startListForCloudClear();
        break;
    case PendingOp::Download:
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

void CloudDiskBackend::startListForCloudClear()
{
    setStatusMessage(tr("Очистка облачного каталога..."),
                     QStringLiteral("Clearing cloud directory..."));
    const QString url = resourcesUrl(QString::fromUtf8(WORKORDER_FOLDER_PATH), LIST_LIMIT);
    qInfo("CloudDiskBackend: clear-list GET %s", qPrintable(url));
    QNetworkReply *reply = m_network->get(authorizedRequest(QUrl(url)));
    connect(reply, &QNetworkReply::finished, this, [this, reply]()
    {
        handleCloudClearListReply(reply);
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

void CloudDiskBackend::handleCloudClearListReply(QNetworkReply *reply)
{
    const int status = httpStatusOf(reply);
    const QByteArray body = reply ? reply->readAll() : QByteArray();
    if(status != 200)
    {
        qWarning("CloudDiskBackend: clear-list failed status=%d body=%s",
                 status,
                 qPrintable(QString::fromUtf8(body.left(300))));
        finishWithError(tr("Не удалось прочитать облачный каталог (%1)").arg(status),
                    QStringLiteral("Failed to read cloud directory (%1)").arg(status));
        return;
    }

    const QJsonObject root = QJsonDocument::fromJson(body).object();
    const QJsonArray items = root.value(QStringLiteral("_embedded")).toObject()
                                 .value(QStringLiteral("items")).toArray();
    m_deletePaths.clear();
    for(const QJsonValue &value : items)
    {
        const QJsonObject item = value.toObject();
        const QString path = item.value(QStringLiteral("path")).toString();
        if(!path.isEmpty())
            m_deletePaths.push_back(path);
    }

    qInfo("CloudDiskBackend: cloud clear queued %d items",
          static_cast<int>(m_deletePaths.size()));
    processNextCloudDelete();
}

void CloudDiskBackend::processNextCloudDelete()
{
    if(m_deletePaths.isEmpty())
    {
        beginUploadQueue();
        return;
    }

    const QString path = m_deletePaths.takeFirst();
    setStatusMessage(tr("Удаление на диске: %1 (осталось %2)")
                         .arg(path)
                         .arg(m_deletePaths.size()),
                     QStringLiteral("Deleting on disk: %1 (remaining %2)")
                         .arg(path)
                         .arg(m_deletePaths.size()));

    QUrl url(m_diskUrl + QStringLiteral("/resources"));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("path"), path);
    query.addQueryItem(QStringLiteral("permanently"), QStringLiteral("true"));
    url.setQuery(query);

    qInfo("CloudDiskBackend: DELETE %s", qPrintable(url.toString()));
    QNetworkReply *reply = m_network->deleteResource(authorizedRequest(url));
    connect(reply, &QNetworkReply::finished, this, [this, reply]()
    {
        handleCloudDeleteReply(reply);
        reply->deleteLater();
    });
}

void CloudDiskBackend::handleCloudDeleteReply(QNetworkReply *reply)
{
    const int status = httpStatusOf(reply);
    const QByteArray body = reply ? reply->readAll() : QByteArray();
    // 202 = async folder delete started; 204 = deleted
    if(status != 204 && status != 202 && status != 404)
    {
        qWarning("CloudDiskBackend: DELETE failed status=%d body=%s",
                 status,
                 qPrintable(QString::fromUtf8(body.left(300))));
        finishWithError(tr("Не удалось очистить облако (%1)").arg(status),
                    QStringLiteral("Failed to clear cloud (%1)").arg(status));
        return;
    }

    processNextCloudDelete();
}

void CloudDiskBackend::beginUploadQueue()
{
    closeAllSqlConnections();

    const QString dataDir = AppPaths::dataDir();
    const QStringList names = localDatabaseFileNames();
    m_transferQueue.clear();
    m_transferIndex = 0;
    for(const QString &name : names)
    {
        TransferItem item;
        item.name = name;
        item.localPath = QDir(dataDir).filePath(name);
        item.remotePath = remoteDbPath(name);
        m_transferQueue.push_back(item);
    }

    if(m_transferQueue.isEmpty())
    {
        finishWithError(tr("Локальные файлы баз данных не найдены"),
                    QStringLiteral("Local database files not found"));
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
        if(m_pendingOp == PendingOp::Sync)
        {
            finishTransferSuccess(tr("Синхронизация завершена: выгружено %1 файл(ов)")
                                      .arg(m_transferQueue.size()),
                                  QStringLiteral("Sync finished: uploaded %1 file(s)")
                                      .arg(m_transferQueue.size()));
        }
        else
        {
            finishTransferSuccess(tr("Выгрузка завершена: %1 файл(ов)")
                                      .arg(m_transferQueue.size()),
                                  QStringLiteral("Upload finished: %1 file(s)")
                                      .arg(m_transferQueue.size()));
        }
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
                      QStringLiteral("application/octet-stream"));
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

    const bool syncMode = (m_pendingOp == PendingOp::Sync);
    const QString targetDir = syncMode ? syncIncomingDir() : AppPaths::dataDir();
    if(syncMode)
    {
        clearSyncIncomingDir();
        if(!QDir().mkpath(targetDir))
        {
            finishWithError(tr("Не удалось создать временный каталог синхронизации"),
                    QStringLiteral("Failed to create sync temp directory"));
            return;
        }
    }

    m_transferQueue.clear();
    m_transferIndex = 0;
    for(const QJsonValue &value : items)
    {
        const QJsonObject itemObj = value.toObject();
        if(itemObj.value(QStringLiteral("type")).toString() != QLatin1String("file"))
            continue;

        const QString name = itemObj.value(QStringLiteral("name")).toString();
        if(!isDatabaseFileName(name))
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
        if(syncMode)
        {
            qInfo("CloudDiskBackend: sync cloud has no db files, upload local only");
            setStatusMessage(tr("На диске нет баз, выгружаем локальные..."),
                             QStringLiteral("No databases on disk, uploading local ones..."));
            startListForCloudClear();
            return;
        }
        finishWithError(tr("На диске нет файлов баз данных (*.db)"),
                    QStringLiteral("No database files (*.db) on disk"));
        return;
    }

    if(!syncMode)
    {
        closeAllSqlConnections();
        if(!clearLocalDatabaseFiles())
        {
            finishWithError(tr("Не удалось очистить локальные базы данных"),
                    QStringLiteral("Failed to clear local databases"));
            return;
        }
    }

    qInfo("CloudDiskBackend: download queue size=%d sync=%d",
          static_cast<int>(m_transferQueue.size()),
          syncMode ? 1 : 0);
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
    m_deletePaths.clear();
    m_transferQueue.clear();
    m_transferIndex = 0;
    setStatusMessage(message, logMessage);
    qInfo("CloudDiskBackend: transfer success: %s", qPrintable(logMessage));
    // Keep busy until list refresh finishes.
    startListRequest();
}

void CloudDiskBackend::finishWithError(const QString &message, const QString &logMessage)
{
    clearSyncIncomingDir();
    m_pendingOp = PendingOp::None;
    m_deletePaths.clear();
    m_transferQueue.clear();
    m_transferIndex = 0;
    setBusy(false);
    setStatusMessage(message, logMessage);
}

void CloudDiskBackend::finishDownloadPhase()
{
    if(m_pendingOp == PendingOp::Sync)
    {
        setStatusMessage(tr("Объединение локальных баз..."),
                     QStringLiteral("Merging local databases..."));
        if(!mergeIncomingDatabases())
        {
            finishWithError(tr("Ошибка объединения баз данных"),
                    QStringLiteral("Database merge error"));
            return;
        }
        clearSyncIncomingDir();
        setStatusMessage(tr("Выгрузка объединённых баз на диск..."),
                         QStringLiteral("Uploading merged databases to disk..."));
        startListForCloudClear();
        return;
    }

    finishTransferSuccess(tr("Загрузка завершена: %1 файл(ов)")
                              .arg(m_transferQueue.size()),
                          QStringLiteral("Download finished: %1 file(s)")
                              .arg(m_transferQueue.size()));
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
{
    closeAllSqlConnections();

    QDir incoming(syncIncomingDir());
    if(!incoming.exists())
        return true;

    const QString dataDir = AppPaths::dataDir();
    const QStringList names = incoming.entryList({QStringLiteral("*.db")}, QDir::Files, QDir::Name);
    for(const QString &name : names)
    {
        const QString sourcePath = incoming.filePath(name);
        const QString targetPath = QDir(dataDir).filePath(name);
        if(!QFileInfo::exists(targetPath))
        {
            if(!QFile::copy(sourcePath, targetPath))
            {
                qWarning("CloudDiskBackend: failed to copy new db %s", qPrintable(name));
                return false;
            }
            qInfo("CloudDiskBackend: sync added missing file %s", qPrintable(name));
            continue;
        }

        if(name.compare(QLatin1String("clients.db"), Qt::CaseInsensitive) == 0)
        {
            const int inserted = ClientsDatabase::mergeFromDatabase(sourcePath, targetPath);
            qInfo("CloudDiskBackend: merge %s clients inserted=%d",
                  qPrintable(name),
                  inserted);
            continue;
        }
        if(name.compare(QLatin1String("services.db"), Qt::CaseInsensitive) == 0)
        {
            const int inserted = ServicesDatabase::mergeFromDatabase(sourcePath);
            qInfo("CloudDiskBackend: merge %s services inserted=%d",
                  qPrintable(name),
                  inserted);
            continue;
        }

        QString clientName;
        QString clientId;
        if(!DatabaseStorage::parseObjectDbFileName(name, &clientName, &clientId))
        {
            qWarning("CloudDiskBackend: skip unknown db file %s", qPrintable(name));
            continue;
        }

        const int objectsInserted = ObjectsDatabase::mergeFromDatabase(
            sourcePath, clientName, clientId);
        const int worksInserted = WorksDatabase::mergeFromDatabase(
            sourcePath, clientName, clientId);
        qInfo("CloudDiskBackend: merge %s objects inserted=%d works inserted=%d",
              qPrintable(name),
              objectsInserted,
              worksInserted);
    }

    closeAllSqlConnections();
    return true;
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
    QDir dir(AppPaths::dataDir());
    return dir.entryList({QStringLiteral("*.db")}, QDir::Files, QDir::Name);
}

bool CloudDiskBackend::clearLocalDatabaseFiles()
{
    QDir dir(AppPaths::dataDir());
    const QStringList names = dir.entryList(
        {QStringLiteral("*.db"), QStringLiteral("*.db-wal"), QStringLiteral("*.db-shm")},
        QDir::Files);
    for(const QString &name : names)
    {
        const QString path = dir.filePath(name);
        if(!QFile::remove(path))
        {
            qWarning("CloudDiskBackend: failed to remove local file %s", qPrintable(path));
            return false;
        }
        qInfo("CloudDiskBackend: removed local %s", qPrintable(name));
    }
    return true;
}

QString CloudDiskBackend::remoteDbPath(const QString &fileName) const
{
    return QString::fromUtf8(WORKORDER_FOLDER_PATH) + QLatin1Char('/') + fileName;
}

void CloudDiskBackend::loadPersisted()
{
    QSettingsStore store;
    m_token = store.read(QString::fromUtf8(KEY_TOKEN), QString()).toString().trimmed();
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
