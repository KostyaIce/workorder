#include "AppPaths.h"

#include "WorkOrderPathDefines.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
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

void AppPaths::createPaths()
{
    WorkOrderPathDefines::createPaths();
}

QString AppPaths::storageDir()
{
    createPaths();
    return WorkOrderPathDefines::storagePath();
}

QString AppPaths::dataDir()
{
    createPaths();
    return WorkOrderPathDefines::dataPath();
}

QString AppPaths::logDir()
{
    createPaths();
    return WorkOrderPathDefines::logPath();
}

QString AppPaths::dbDir()
{
    createPaths();
    return WorkOrderPathDefines::dbPath();
}

QString AppPaths::configDir()
{
    createPaths();
    return WorkOrderPathDefines::configPath();
}

QString AppPaths::projectDataDir()
{
    return dbDir();
}

} // namespace workorder
