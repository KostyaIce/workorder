#include "NotificationManager.h"

#include <QDebug>

namespace workorder
{

NotificationManager *NotificationManager::s_instance = nullptr;

NotificationManager::NotificationManager(QObject *parent)
    : QObject(parent)
{
    s_instance = this;
    m_displayTimer.setSingleShot(true);
    QObject::connect(&m_displayTimer, &QTimer::timeout,
                     this, &NotificationManager::onDisplayTimerTimeout);
}

NotificationManager::~NotificationManager()
{
    m_displayTimer.stop();
    if(s_instance == this)
        s_instance = nullptr;
}

NotificationManager *NotificationManager::instance()
{
    return s_instance;
}

bool NotificationManager::isDisplaying() const
{
    return m_isDisplaying;
}

void NotificationManager::notifyInfo(const QString &message, const QString &title)
{
    if(!s_instance)
    {
        qInfo("NotificationManager: no instance, info: %s", qPrintable(message));
        return;
    }
    s_instance->pushInfo(message, title);
}

void NotificationManager::notifyWarning(const QString &message, const QString &title)
{
    if(!s_instance)
    {
        qWarning("NotificationManager: no instance, warning: %s", qPrintable(message));
        return;
    }
    s_instance->pushWarning(message, title);
}

void NotificationManager::notifyError(const QString &message, const QString &title)
{
    if(!s_instance)
    {
        qWarning("NotificationManager: no instance, error: %s", qPrintable(message));
        return;
    }
    s_instance->pushError(message, title);
}

void NotificationManager::dismiss()
{
    if(!m_isDisplaying)
        return;

    m_displayTimer.stop();
    m_isDisplaying = false;
    emit isDisplayingChanged();
    emit hideNotification();

    qInfo("NotificationManager: dismissed severity=%s message=%s",
          qPrintable(m_current.severity),
          qPrintable(m_current.message));

    processQueue();
}

void NotificationManager::pushInfo(const QString &message, const QString &title, int ttlMs)
{
    NotificationRequest req;
    req.title = title.isEmpty() ? tr("Информация") : title;
    req.message = message;
    req.severity = QStringLiteral("info");
    req.ttlMs = ttlMs;
    push(req);
}

void NotificationManager::pushWarning(const QString &message, const QString &title, int ttlMs)
{
    NotificationRequest req;
    req.title = title.isEmpty() ? tr("Внимание") : title;
    req.message = message;
    req.severity = QStringLiteral("warning");
    req.ttlMs = ttlMs;
    push(req);
}

void NotificationManager::pushError(const QString &message, const QString &title, int ttlMs)
{
    NotificationRequest req;
    req.title = title.isEmpty() ? tr("Ошибка") : title;
    req.message = message;
    req.severity = QStringLiteral("error");
    req.ttlMs = ttlMs;
    push(req);
}

void NotificationManager::push(const NotificationRequest &req)
{
    m_queue.enqueue(req);

    if(req.severity == QStringLiteral("error"))
    {
        qWarning("NotificationManager: queued error title=%s message=%s",
                 qPrintable(req.title),
                 qPrintable(req.message));
    }
    else if(req.severity == QStringLiteral("warning"))
    {
        qWarning("NotificationManager: queued warning title=%s message=%s",
                 qPrintable(req.title),
                 qPrintable(req.message));
    }
    else
    {
        qInfo("NotificationManager: queued info title=%s message=%s",
              qPrintable(req.title),
              qPrintable(req.message));
    }

    if(!m_isDisplaying)
        processQueue();
}

void NotificationManager::onDisplayTimerTimeout()
{
    if(!m_isDisplaying)
        return;

    m_isDisplaying = false;
    emit isDisplayingChanged();
    emit hideNotification();

    qInfo("NotificationManager: ttl expired severity=%s message=%s",
          qPrintable(m_current.severity),
          qPrintable(m_current.message));

    processQueue();
}

void NotificationManager::processQueue()
{
    if(m_isDisplaying || m_queue.isEmpty())
        return;

    m_current = m_queue.dequeue();
    m_isDisplaying = true;
    emit isDisplayingChanged();

    const int ttl = m_current.ttlMs > 0 ? m_current.ttlMs : DEFAULT_TTL_MS;
    m_displayTimer.start(ttl);

    qInfo("NotificationManager: showing severity=%s ttl=%d message=%s",
          qPrintable(m_current.severity),
          ttl,
          qPrintable(m_current.message));

    emit showNotification(m_current.title, m_current.message, m_current.severity);
}

} // namespace workorder
