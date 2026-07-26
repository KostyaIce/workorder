#include "WorkOrderPathDefines.h"

#include <QCoreApplication>
#include <QDir>
#include <QStandardPaths>

namespace workorder
{

namespace
{

constexpr const char *kOrganization = "WorkOrderApp";
constexpr const char *kApplication = "WorkOrder";

void ensureOrgAppNames()
{
    if(QCoreApplication::organizationName().isEmpty())
        QCoreApplication::setOrganizationName(QLatin1String(kOrganization));
    if(QCoreApplication::applicationName().isEmpty())
        QCoreApplication::setApplicationName(QLatin1String(kApplication));
}

QString appDataLocationOrFallback(const QString &fallback)
{
    QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if(base.isEmpty())
        base = fallback;
    return QDir(base).absolutePath();
}

QString resolveStoragePath()
{
    const QString overridePath = qEnvironmentVariable("WORKORDER_DATA_DIR");
    if(!overridePath.isEmpty())
        return QDir(overridePath).absolutePath();

    ensureOrgAppNames();

#if defined(Q_OS_ANDROID)
    QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if(base.isEmpty())
        base = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    if(base.isEmpty())
        base = qEnvironmentVariable("ANDROID_PRIVATE");
    if(base.isEmpty())
        base = qEnvironmentVariable("ANDROID_APP_PATH");
    if(base.isEmpty())
        base = QDir::homePath() + QLatin1Char('/') + QLatin1String(kApplication);
    return QDir(base).absolutePath();

#elif defined(Q_OS_WIN)
    // %APPDATA%\WorkOrderApp\WorkOrder
    return appDataLocationOrFallback(
        QDir::homePath() + QStringLiteral("/AppData/Roaming/")
            + QLatin1String(kOrganization) + QLatin1Char('/')
            + QLatin1String(kApplication));

#elif defined(Q_OS_MACOS)
    // ~/Library/Application Support/WorkOrderApp/WorkOrder
    return appDataLocationOrFallback(
        QDir::homePath() + QStringLiteral("/Library/Application Support/")
            + QLatin1String(kOrganization) + QLatin1Char('/')
            + QLatin1String(kApplication));

#elif defined(Q_OS_LINUX)
    // ~/.local/share/WorkOrderApp/WorkOrder (sandbox, not /opt)
    return appDataLocationOrFallback(
        QDir::homePath() + QStringLiteral("/.local/share/")
            + QLatin1String(kOrganization) + QLatin1Char('/')
            + QLatin1String(kApplication));

#else
    return appDataLocationOrFallback(
        QDir::homePath() + QLatin1Char('/') + QLatin1String(kApplication));
#endif
}

} // namespace

QString WorkOrderPathDefines::storagePath()
{
    static QString path;
    if(path.isEmpty())
        path = resolveStoragePath();
    return path;
}

QString WorkOrderPathDefines::dataPath()
{
    return QDir(storagePath()).filePath(QStringLiteral("data"));
}

QString WorkOrderPathDefines::logPath()
{
    return QDir(dataPath()).filePath(QStringLiteral("log"));
}

QString WorkOrderPathDefines::dbPath()
{
    return QDir(dataPath()).filePath(QStringLiteral("db"));
}

QString WorkOrderPathDefines::configPath()
{
    return QDir(dataPath()).filePath(QStringLiteral("config"));
}

QString WorkOrderPathDefines::reportsPath()
{
    // Reports live in a user-chosen folder; default is Documents/WorkOrder.
    const QString overridePath = qEnvironmentVariable("WORKORDER_REPORTS_DIR");
    if(!overridePath.isEmpty())
        return QDir(overridePath).absolutePath();

    ensureOrgAppNames();
    QString base = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if(base.isEmpty())
        base = QDir::homePath();
    return QDir(base).filePath(QLatin1String(kApplication));
}

QString WorkOrderPathDefines::configFilePath()
{
    return QDir(configPath()).filePath(QStringLiteral("WorkOrder.conf"));
}

void WorkOrderPathDefines::createPaths()
{
    QDir().mkpath(storagePath());
    QDir().mkpath(dataPath());
    QDir().mkpath(logPath());
    QDir().mkpath(dbPath());
    QDir().mkpath(configPath());
}

} // namespace workorder
