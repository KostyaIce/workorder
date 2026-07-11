#include "appPaths.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QSysInfo>

namespace workorder
{

namespace
{

bool isRepoRoot(const QDir &dir)
{
    return QFileInfo::exists(dir.filePath("src/main.py"))
        || QFileInfo::exists(dir.filePath("resources/qml/desktop/main.qml"));
}

} // namespace

QString AppPaths::projectRoot()
{
    static QString root;
    if(!root.isEmpty())
        return root;

    QDir dir(QCoreApplication::applicationDirPath());
    for(int i = 0; i < 8; ++i)
    {
        if(isRepoRoot(dir))
        {
            root = dir.absolutePath();
            break;
        }
        if(!dir.cdUp())
            break;
    }

    if(root.isEmpty())
        root = QCoreApplication::applicationDirPath();
    return root;
}

bool AppPaths::isAndroidRuntime()
{
    if(qEnvironmentVariableIsSet("ANDROID_ARGUMENT"))
        return true;
    if(qEnvironmentVariable("WORKORDER_PLATFORM") == QLatin1String("android"))
        return true;
    return QSysInfo::productType().compare(QLatin1String("android"), Qt::CaseInsensitive) == 0;
}

QString AppPaths::resolveDataDir()
{
    if(isAndroidRuntime())
    {
        QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        if(base.isEmpty())
            base = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
        if(base.isEmpty())
            base = qEnvironmentVariable("ANDROID_PRIVATE");
        if(base.isEmpty())
            base = qEnvironmentVariable("ANDROID_APP_PATH");
        if(base.isEmpty())
            return QDir(AppPaths::projectRoot()).filePath("data");

        return QDir(base).filePath("data");
    }

    const QString overridePath = qEnvironmentVariable("WORKORDER_DATA_DIR");
    if(!overridePath.isEmpty())
        return QDir(overridePath).absolutePath();

    return QDir(AppPaths::projectRoot()).filePath("data");
}

QString AppPaths::dataDir()
{
    static QString cached;
    if(cached.isEmpty())
    {
        cached = QDir(resolveDataDir()).absolutePath();
        QDir().mkpath(cached);
    }
    return cached;
}

QString AppPaths::projectDataDir()
{
    return dataDir();
}

} // namespace workorder
