#ifndef WORKORDER_BACKEND_YANDEX_DISK_OAUTH_FLOW_H
#define WORKORDER_BACKEND_YANDEX_DISK_OAUTH_FLOW_H

#include <QByteArray>
#include <QHash>
#include <QMap>
#include <QObject>
#include <QPointer>
#include <QString>
#include <QtGlobal>

class QNetworkAccessManager;
class QNetworkReply;
class QTcpServer;
class QTcpSocket;
class QTimer;

namespace workorder
{

// Desktop OAuth 2.0 + PKCE (same pattern as Skedula/planer): loopback callback page exchanges code for token.
class YandexDiskOAuthFlow : public QObject
{
    Q_OBJECT

public:
    explicit YandexDiskOAuthFlow(QObject *parent = nullptr);
    ~YandexDiskOAuthFlow() override;

    bool inProgress() const;
    QString redirectUri() const;

    bool begin();
    void cancel();
    QString buildAuthorizeUrl() const;

signals:
    void progressMessageChanged(const QString &message);
    void inProgressChanged(bool value);
    void finished(bool success, const QString &accessToken, const QString &errorMessage);

private:
    struct PendingHttpRequest
    {
        QByteArray buffer;
        bool headersComplete = false;
        qint64 contentLength = -1;
        QString method;
        QString path;
        QByteArray body;
    };

    void setInProgress(bool value);
    void setProgressMessage(const QString &message);
    void fail(const QString &userMessage, const QString &logMessage);
    void completeWithToken(const QString &token);
    void shutdownServer();
    void onNewConnection();
    void onSocketReadyRead();
    void onSocketDisconnected();
    void tryParseRequest(QTcpSocket *socket, PendingHttpRequest &pending);
    bool handleHttpRequest(QTcpSocket *socket,
                           const QString &method,
                           const QString &path,
                           const QByteArray &body);
    void sendHtmlCallbackPage(QTcpSocket *socket);
    void sendPlainResponse(QTcpSocket *socket, int statusCode, const QString &text);
    void completeFromParams(const QMap<QString, QString> &params, const QString &redirectUri);
    void exchangeAuthorizationCode(const QString &code, const QString &redirectUri);
    void onTokenExchangeFinished();
    void finishHttpOAuthResponse(bool success);

    static QString newCodeVerifier();
    static QString newOAuthState();
    static QString pkceChallengeFromVerifier(const QString &verifier);
    static QMap<QString, QString> parseFormBody(const QByteArray &body);
    static QMap<QString, QString> parseQueryString(const QString &query);
    static QString oauthErrorText(const QString &error);

    QNetworkAccessManager *m_network = nullptr;
    QTcpServer *m_server = nullptr;
    QTimer *m_timeout = nullptr;
    QString m_state;
    QString m_codeVerifier;
    QString m_progressMessage;
    bool m_inProgress = false;
    QHash<QTcpSocket *, PendingHttpRequest> m_pending;
    QPointer<QTcpSocket> m_httpResponseSocket;
    QPointer<QNetworkReply> m_tokenReply;
};

} // namespace workorder

#endif // WORKORDER_BACKEND_YANDEX_DISK_OAUTH_FLOW_H
