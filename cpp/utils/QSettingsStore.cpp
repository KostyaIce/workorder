#include "QSettingsStore.h"

#include "WorkOrderPathDefines.h"

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
    if(QCoreApplication::organizationName().isEmpty())
        QCoreApplication::setOrganizationName(QLatin1String(kOrganization));
    if(QCoreApplication::applicationName().isEmpty())
        QCoreApplication::setApplicationName(QLatin1String(kApplication));

    WorkOrderPathDefines::createPaths();
    return QSettings(WorkOrderPathDefines::configFilePath(), QSettings::IniFormat);
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
