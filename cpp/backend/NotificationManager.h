#ifndef WORKORDER_BACKEND_NOTIFICATION_MANAGER_H
#define WORKORDER_BACKEND_NOTIFICATION_MANAGER_H

#include <QObject>
#include <QQueue>
#include <QString>
#include <QTimer>

namespace workorder
{

struct NotificationRequest
{
    QString title;
    QString message;
    QString severity; // "info", "warning", "error"
    int ttlMs = 0;
};

// App-scoped toast queue. Owned by BackendController; backends call static notify*.
class NotificationManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isDisplaying READ isDisplaying NOTIFY isDisplayingChanged)

public:
    explicit NotificationManager(QObject *parent = nullptr);
    ~NotificationManager() override;

    static NotificationManager *instance();

    bool isDisplaying() const;

    static void notifyInfo(const QString &message, const QString &title = QString());
    static void notifyWarning(const QString &message, const QString &title = QString());
    static void notifyError(const QString &message, const QString &title = QString());

public slots:
    void dismiss();

    Q_INVOKABLE void pushInfo(const QString &message, const QString &title = QString(), int ttlMs = 0);
    Q_INVOKABLE void pushWarning(const QString &message, const QString &title = QString(), int ttlMs = 0);
    Q_INVOKABLE void pushError(const QString &message, const QString &title = QString(), int ttlMs = 0);

signals:
    void showNotification(const QString &title, const QString &message, const QString &severity);
    void hideNotification();
    void isDisplayingChanged();

private slots:
    void onDisplayTimerTimeout();

private:
    void push(const NotificationRequest &req);
    void processQueue();

    static NotificationManager *s_instance;
    static constexpr int DEFAULT_TTL_MS = 5000;

    QQueue<NotificationRequest> m_queue;
    QTimer m_displayTimer;
    NotificationRequest m_current;
    bool m_isDisplaying = false;
};

} // namespace workorder

#endif // WORKORDER_BACKEND_NOTIFICATION_MANAGER_H
