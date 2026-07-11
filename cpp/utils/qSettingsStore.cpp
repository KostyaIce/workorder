#include "qSettingsStore.h"

#include <QCoreApplication>

namespace workorder
{

QSettingsStore::QSettingsStore()
    : m_settings(createSettings())
{
}

QSettingsStore::~QSettingsStore()
{
    sync();
}

QSettings QSettingsStore::createSettings()
{
    QCoreApplication *app = QCoreApplication::instance();
    if(app != nullptr)
    {
        if(app->organizationName().isEmpty())
            app->setOrganizationName(QLatin1String(kOrganization));
        if(app->applicationName().isEmpty())
            app->setApplicationName(QLatin1String(kApplication));
        return QSettings();
    }

    return QSettings(QLatin1String(kOrganization), QLatin1String(kApplication));
}

QVariant QSettingsStore::read(const QString &key, const QVariant &defaultValue) const
{
    return m_settings.value(key, defaultValue);
}

void QSettingsStore::write(const QString &key, const QVariant &value)
{
    m_settings.setValue(key, value);
}

void QSettingsStore::remove(const QString &key)
{
    m_settings.remove(key);
}

bool QSettingsStore::contains(const QString &key) const
{
    return m_settings.contains(key);
}

void QSettingsStore::sync()
{
    m_settings.sync();
}

} // namespace workorder
