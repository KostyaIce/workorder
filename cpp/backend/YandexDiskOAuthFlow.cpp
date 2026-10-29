#include "YandexDiskOAuthFlow.h"

#include "YandexDiskConfig.h"

#if defined(Q_OS_IOS)
#include "../ios/YandexAuth.h"
#endif

#include <QAbstractSocket>
#include <QCryptographicHash>
#include <QHostAddress>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMap>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRandomGenerator>
#include <QTcpServer>
#include <QTcpSocket>
#include <QTimer>
#include <QUrl>
#include <QUrlQuery>

namespace workorder
{

namespace
{

constexpr int kOAuthTimeoutMs = 5 * 60 * 1000;

const char *kDesktopOAuthHtml = R"HTML(<!DOCTYPE html>
<html lang="ru">
<head><meta charset="utf-8"><title>WorkOrder</title></head>
<body>
<p id="message">Завершаем вход...</p>
<script>
var message = document.getElementById('message');
var payload = window.location.search.indexOf('?') === 0
  ? window.location.search.substring(1)
  : window.location.search;
fetch('/callback/complete', {
  method: 'POST',
  headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  body: payload
}).then(function(response) {
  return response.text();
}).then(function(text) {
  message.textContent = text;
}).catch(function() {
  message.textContent = 'Не удалось завершить вход. Вернитесь в WorkOrder.';
});
</script>
</body>
</html>)HTML";

QString redirectUriForPort()
{
    return QStringLiteral("http://127.0.0.1:%1/callback").arg(YandexDiskConfig::desktopOAuthPort);
}

} // namespace

YandexDiskOAuthFlow::YandexDiskOAuthFlow(QObject *parent)
    : QObject(parent)
    , m_network(new QNetworkAccessManager(this))
    , m_server(new QTcpServer(this))
    , m_timeout(new QTimer(this))
{
    m_timeout->setSingleShot(true);
    connect(m_timeout, &QTimer::timeout, this, [this]()
    {
        if(!m_inProgress)
            return;
        fail(QStringLiteral("Время входа истекло"), QStringLiteral("OAuth timeout"));
    });
    connect(m_server, &QTcpServer::newConnection, this, &YandexDiskOAuthFlow::onNewConnection);
}

YandexDiskOAuthFlow::~YandexDiskOAuthFlow()
{
    cancel();
}

bool YandexDiskOAuthFlow::inProgress() const
{
    return m_inProgress;
}

QString YandexDiskOAuthFlow::redirectUri() const
{
#if defined(Q_OS_IOS)
    return QStringLiteral("yx%1://auth/finish")
        .arg(QString::fromUtf8(YandexDiskConfig::oauthClientId));
#else
    return redirectUriForPort();
#endif
}

bool YandexDiskOAuthFlow::usesNativeSdk() const
{
#if defined(Q_OS_IOS)
    return true;
#else
    return false;
#endif
}

bool YandexDiskOAuthFlow::begin()
{
    cancel();

#if defined(Q_OS_IOS)
    setInProgress(true);
    m_timeout->start(kOAuthTimeoutMs);
    setProgressMessage(QStringLiteral("Подтвердите вход в Яндекс..."));

    QPointer<YandexDiskOAuthFlow> self(this);
    yandexLogin(QString::fromUtf8(YandexDiskConfig::oauthClientId),
                [self](const QString &token, const QString &error)
    {
        if(!self)
            return;
        QMetaObject::invokeMethod(self, [self, token, error]()
        {
            if(!self->m_inProgress)
                return;
            if(!error.isEmpty())
                self->fail(error, QStringLiteral("Yandex Login SDK failed: %1").arg(error));
            else if(token.isEmpty())
                self->fail(QStringLiteral("Токен не получен"),
                           QStringLiteral("Yandex Login SDK returned an empty token"));
            else
                self->completeWithToken(token);
        }, Qt::QueuedConnection);
    });
    return true;
#else
    m_state = newOAuthState();
    m_codeVerifier = newCodeVerifier();
    if(m_state.isEmpty() || m_codeVerifier.isEmpty())
    {
        fail(QStringLiteral("Не удалось начать вход"),
             QStringLiteral("OAuth state/verifier generation failed"));
        return false;
    }

    if(!m_server->listen(QHostAddress::LocalHost, YandexDiskConfig::desktopOAuthPort))
    {
        qWarning("YandexDiskOAuthFlow: listen failed on port %d: %s",
                 YandexDiskConfig::desktopOAuthPort,
                 qPrintable(m_server->errorString()));
        m_state.clear();
        m_codeVerifier.clear();
        fail(QStringLiteral("Не удалось открыть локальный адрес для возврата из браузера"),
             QStringLiteral("OAuth listen failed"));
        return false;
    }

    setInProgress(true);
    m_timeout->start(kOAuthTimeoutMs);
    setProgressMessage(QStringLiteral("Ожидаем подтверждение в браузере..."));
    qInfo("YandexDiskOAuthFlow: listening on %s", qPrintable(redirectUri()));
    return true;
#endif
}

void YandexDiskOAuthFlow::cancel()
{
#if defined(Q_OS_IOS)
    yandexCancel();
#endif
    if(m_tokenReply)
    {
        disconnect(m_tokenReply, nullptr, this, nullptr);
        m_tokenReply->abort();
        m_tokenReply->deleteLater();
        m_tokenReply = nullptr;
    }
    m_timeout->stop();
    shutdownServer();
    m_state.clear();
    m_codeVerifier.clear();
    if(m_inProgress)
        setInProgress(false);
}

QString YandexDiskOAuthFlow::buildAuthorizeUrl() const
{
    QUrl url(QString::fromUtf8(YandexDiskConfig::oauthAuthorizeUrl));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("response_type"), QStringLiteral("code"));
    query.addQueryItem(QStringLiteral("client_id"),
                       QString::fromUtf8(YandexDiskConfig::oauthClientId));
    query.addQueryItem(QStringLiteral("redirect_uri"), redirectUri());
    query.addQueryItem(QStringLiteral("state"), m_state);
    query.addQueryItem(QStringLiteral("code_challenge"),
                       pkceChallengeFromVerifier(m_codeVerifier));
    query.addQueryItem(QStringLiteral("code_challenge_method"), QStringLiteral("S256"));
    query.addQueryItem(QStringLiteral("scope"),
                       QString::fromUtf8(YandexDiskConfig::oauthScopes));
    url.setQuery(query);
    return url.toString(QUrl::FullyEncoded);
}

void YandexDiskOAuthFlow::setInProgress(bool value)
{
    if(m_inProgress == value)
        return;
    m_inProgress = value;
    emit inProgressChanged(value);
}

void YandexDiskOAuthFlow::setProgressMessage(const QString &message)
{
    if(m_progressMessage == message)
        return;
    m_progressMessage = message;
    emit progressMessageChanged(message);
}

void YandexDiskOAuthFlow::fail(const QString &userMessage, const QString &logMessage)
{
    qWarning("YandexDiskOAuthFlow: %s", qPrintable(logMessage));
    finishHttpOAuthResponse(false);
    cancel();
    setProgressMessage(userMessage);
    emit finished(false, {}, userMessage);
}

void YandexDiskOAuthFlow::completeWithToken(const QString &token)
{
    finishHttpOAuthResponse(true);
    cancel();
    setProgressMessage(QStringLiteral("Подключено"));
    emit finished(true, token, {});
}

void YandexDiskOAuthFlow::finishHttpOAuthResponse(bool success)
{
    if(!m_httpResponseSocket)
        return;

    QTcpSocket *socket = m_httpResponseSocket;
    m_httpResponseSocket = nullptr;
    const QString text = success
        ? QStringLiteral("Доступ получен. Это окно можно закрыть.")
        : QStringLiteral("Не удалось подключить Диск. Это окно можно закрыть.");
    sendPlainResponse(socket, 200, text);
    QObject::disconnect(socket, nullptr, this, nullptr);
    socket->close();
    socket->deleteLater();
}

void YandexDiskOAuthFlow::shutdownServer()
{
    if(m_httpResponseSocket)
    {
        QObject::disconnect(m_httpResponseSocket, nullptr, this, nullptr);
        m_httpResponseSocket->close();
        m_httpResponseSocket->deleteLater();
        m_httpResponseSocket = nullptr;
    }

    for(auto it = m_pending.begin(); it != m_pending.end(); ++it)
    {
        QTcpSocket *socket = it.key();
        QObject::disconnect(socket, nullptr, this, nullptr);
        socket->close();
        socket->deleteLater();
    }
    m_pending.clear();
    if(m_server->isListening())
        m_server->close();
}

void YandexDiskOAuthFlow::onNewConnection()
{
    while(m_server->hasPendingConnections())
    {
        QTcpSocket *socket = m_server->nextPendingConnection();
        m_pending.insert(socket, PendingHttpRequest{});
        connect(socket, &QTcpSocket::readyRead, this, &YandexDiskOAuthFlow::onSocketReadyRead);
        connect(socket, &QTcpSocket::disconnected, this, &YandexDiskOAuthFlow::onSocketDisconnected);
    }
}

void YandexDiskOAuthFlow::onSocketReadyRead()
{
    auto *socket = qobject_cast<QTcpSocket *>(sender());
    if(!socket || !m_pending.contains(socket))
        return;

    PendingHttpRequest &pending = m_pending[socket];
    pending.buffer.append(socket->readAll());
    tryParseRequest(socket, pending);
}

void YandexDiskOAuthFlow::onSocketDisconnected()
{
    auto *socket = qobject_cast<QTcpSocket *>(sender());
    if(!socket)
        return;
    m_pending.remove(socket);
    if(m_httpResponseSocket == socket)
        m_httpResponseSocket = nullptr;
    socket->deleteLater();
}

void YandexDiskOAuthFlow::tryParseRequest(QTcpSocket *socket, PendingHttpRequest &pending)
{
    if(!pending.headersComplete)
    {
        const int headerEnd = pending.buffer.indexOf("\r\n\r\n");
        if(headerEnd < 0)
            return;

        const QByteArray headerBlock = pending.buffer.left(headerEnd);
        pending.buffer.remove(0, headerEnd + 4);

        const QList<QByteArray> headerLines = headerBlock.split('\n');
        if(headerLines.isEmpty())
            return;

        const QByteArray requestLine = headerLines.first().trimmed();
        const QList<QByteArray> parts = requestLine.split(' ');
        if(parts.size() < 2)
            return;

        pending.method = QString::fromUtf8(parts.at(0).trimmed());
        const QString fullPath = QString::fromUtf8(parts.at(1).trimmed());
        const int queryIndex = fullPath.indexOf(QLatin1Char('?'));
        pending.path = queryIndex >= 0 ? fullPath.left(queryIndex) : fullPath;

        pending.contentLength = 0;
        for(int i = 1; i < headerLines.size(); ++i)
        {
            const QByteArray line = headerLines.at(i).trimmed();
            if(line.toLower().startsWith("content-length:"))
            {
                pending.contentLength = line.mid(15).trimmed().toLongLong();
                break;
            }
        }
        pending.headersComplete = true;
    }

    if(pending.contentLength >= 0
       && pending.buffer.size() < pending.contentLength)
        return;

    pending.body = pending.buffer.left(static_cast<int>(pending.contentLength));
    const bool keepSocket = handleHttpRequest(socket, pending.method, pending.path, pending.body);
    m_pending.remove(socket);
    if(keepSocket)
        return;

    QObject::disconnect(socket, nullptr, this, nullptr);
    socket->close();
    socket->deleteLater();
}

bool YandexDiskOAuthFlow::handleHttpRequest(QTcpSocket *socket,
                                            const QString &method,
                                            const QString &path,
                                            const QByteArray &body)
{
    if(method == QStringLiteral("GET") && path == QStringLiteral("/callback"))
    {
        sendHtmlCallbackPage(socket);
        return false;
    }

    if(method == QStringLiteral("POST") && path == QStringLiteral("/callback/complete"))
    {
        if(m_tokenReply || !m_inProgress)
        {
            sendPlainResponse(socket, 400, QStringLiteral("Login already handled"));
            return false;
        }
        const QMap<QString, QString> params = parseFormBody(body);
        if(params.value(QStringLiteral("state")) != m_state)
        {
            sendPlainResponse(
                socket,
                400,
                QStringLiteral("Вход не подтверждён. Вернитесь в WorkOrder и попробуйте снова."));
            return false;
        }

        m_httpResponseSocket = socket;
        completeFromParams(params, redirectUriForPort());
        return true;
    }

    sendPlainResponse(socket, 404, QStringLiteral("Not found"));
    return false;
}

void YandexDiskOAuthFlow::sendHtmlCallbackPage(QTcpSocket *socket)
{
    const QByteArray body(kDesktopOAuthHtml);
    QByteArray response;
    response += "HTTP/1.1 200 OK\r\n";
    response += "Content-Type: text/html; charset=utf-8\r\n";
    response += QByteArray("Content-Length: ") + QByteArray::number(body.size()) + "\r\n";
    response += "Connection: close\r\n\r\n";
    response += body;
    socket->write(response);
    socket->flush();
}

void YandexDiskOAuthFlow::sendPlainResponse(QTcpSocket *socket,
                                            int statusCode,
                                            const QString &text)
{
    const QByteArray body = text.toUtf8();
    const QByteArray reason = statusCode == 200 ? "OK" : "Bad Request";
    QByteArray response;
    response += QByteArray("HTTP/1.1 ") + QByteArray::number(statusCode) + ' ' + reason + "\r\n";
    response += "Content-Type: text/plain; charset=utf-8\r\n";
    response += QByteArray("Content-Length: ") + QByteArray::number(body.size()) + "\r\n";
    response += "Connection: close\r\n\r\n";
    response += body;
    socket->write(response);
    socket->flush();
}

void YandexDiskOAuthFlow::completeFromParams(const QMap<QString, QString> &params,
                                             const QString &redirectUri)
{
    const QString error = oauthErrorText(params.value(QStringLiteral("error")));
    if(!error.isEmpty())
    {
        fail(QStringLiteral("Ошибка: %1").arg(error),
             QStringLiteral("OAuth redirect error: %1").arg(error));
        return;
    }

    const QString code = params.value(QStringLiteral("code")).trimmed();
    if(code.isEmpty())
    {
        fail(QStringLiteral("Код подтверждения не получен"),
             QStringLiteral("OAuth redirect missing code"));
        return;
    }

    if(m_codeVerifier.isEmpty())
    {
        fail(QStringLiteral("Вход устарел, попробуйте снова"),
             QStringLiteral("OAuth missing code verifier"));
        return;
    }

    setProgressMessage(QStringLiteral("Подключение..."));
    exchangeAuthorizationCode(code, redirectUri);
}

void YandexDiskOAuthFlow::exchangeAuthorizationCode(const QString &code,
                                                      const QString &redirectUri)
{
    QUrl url(QString::fromUtf8(YandexDiskConfig::oauthTokenUrl));
    QUrlQuery body;
    body.addQueryItem(QStringLiteral("grant_type"), QStringLiteral("authorization_code"));
    body.addQueryItem(QStringLiteral("code"), code);
    body.addQueryItem(QStringLiteral("client_id"),
                      QString::fromUtf8(YandexDiskConfig::oauthClientId));
    body.addQueryItem(QStringLiteral("code_verifier"), m_codeVerifier);
    body.addQueryItem(QStringLiteral("redirect_uri"), redirectUri);

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader,
                      QStringLiteral("application/x-www-form-urlencoded"));

    const QByteArray payload = body.query(QUrl::FullyEncoded).toUtf8();
    QNetworkReply *reply = m_network->post(request, payload);
    m_tokenReply = reply;
    connect(reply, &QNetworkReply::finished, this, &YandexDiskOAuthFlow::onTokenExchangeFinished);
}

void YandexDiskOAuthFlow::onTokenExchangeFinished()
{
    auto *reply = qobject_cast<QNetworkReply *>(sender());
    if(!reply || reply != m_tokenReply || !m_inProgress)
        return;

    m_tokenReply = nullptr;
    reply->deleteLater();
    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    const QByteArray body = reply->readAll();

    if(reply->error() != QNetworkReply::NoError || status != 200)
    {
        QString detail;
        const QJsonDocument doc = QJsonDocument::fromJson(body);
        if(doc.isObject())
        {
            const QJsonObject obj = doc.object();
            detail = obj.value(QStringLiteral("error_description")).toString();
            if(detail.isEmpty())
                detail = obj.value(QStringLiteral("error")).toString();
        }
        if(detail.isEmpty())
            detail = QStringLiteral("ошибка обмена кода (%1)").arg(status);
        qWarning("YandexDiskOAuthFlow: token exchange failed status=%d body=%s",
                 status,
                 body.constData());
        fail(QStringLiteral("Ошибка: %1").arg(detail),
             QStringLiteral("Token exchange failed"));
        return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(body);
    if(!doc.isObject())
    {
        fail(QStringLiteral("Токен не получен"), QStringLiteral("Token response not JSON"));
        return;
    }

    const QString token = doc.object().value(QStringLiteral("access_token")).toString().trimmed();
    if(token.isEmpty())
    {
        fail(QStringLiteral("Токен не получен"), QStringLiteral("Token response missing access_token"));
        return;
    }

    completeWithToken(token);
}

QString YandexDiskOAuthFlow::newCodeVerifier()
{
    static const char chars[] =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~";
    QString result;
    result.reserve(64);
    for(int i = 0; i < 64; ++i)
    {
        const int index =
            QRandomGenerator::global()->bounded(static_cast<int>(sizeof(chars) - 1));
        result.append(QLatin1Char(chars[index]));
    }
    return result;
}

QString YandexDiskOAuthFlow::newOAuthState()
{
    QByteArray bytes(16, 0);
    QRandomGenerator::global()->fillRange(reinterpret_cast<quint32 *>(bytes.data()), 4);
    return QString::fromLatin1(
        bytes.toBase64(QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals));
}

QString YandexDiskOAuthFlow::pkceChallengeFromVerifier(const QString &verifier)
{
    const QByteArray hash =
        QCryptographicHash::hash(verifier.toUtf8(), QCryptographicHash::Sha256);
    return QString::fromLatin1(
        hash.toBase64(QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals));
}

QMap<QString, QString> YandexDiskOAuthFlow::parseFormBody(const QByteArray &body)
{
    QMap<QString, QString> result;
    const QString text = QString::fromUtf8(body).trimmed();
    if(text.isEmpty())
        return result;

    const QUrlQuery query(text);
    const auto items = query.queryItems(QUrl::FullyDecoded);
    for(const auto &pair : items)
        result.insert(pair.first, pair.second);
    return result;
}

QMap<QString, QString> YandexDiskOAuthFlow::parseQueryString(const QString &query)
{
    QMap<QString, QString> result;
    const QUrlQuery urlQuery(query);
    const auto items = urlQuery.queryItems(QUrl::FullyDecoded);
    for(const auto &pair : items)
        result.insert(pair.first, pair.second);
    return result;
}

QString YandexDiskOAuthFlow::oauthErrorText(const QString &error)
{
    if(error.isEmpty())
        return {};
    if(error == QStringLiteral("access_denied"))
        return QStringLiteral("доступ не выдан");
    return error;
}

} // namespace workorder
