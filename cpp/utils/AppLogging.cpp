#include "AppLogging.h"

#include "AppPaths.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QLoggingCategory>
#include <QMutex>
#include <QTextStream>

#ifdef Q_OS_ANDROID
#include <android/log.h>
#endif

namespace workorder
{

Q_LOGGING_CATEGORY(logWorkorder, "workorder")

namespace
{

QtMessageHandler g_previousHandler = nullptr;

const char *messageLevel(QtMsgType type)
{
    switch(type)
    {
    case QtInfoMsg:
        return "INFO";
    case QtWarningMsg:
        return "WARN";
    case QtCriticalMsg:
        return "ERROR";
    case QtFatalMsg:
        return "FATAL";
    default:
        return "DEBUG";
    }
}

bool isProjectLogCategory(const char *category)
{
    if(category == nullptr || category[0] == '\0')
        return true;

    if(qstrncmp(category, "default", 7) == 0 && (category[7] == '\0' || category[7] == '.'))
        return true;
    if(qstrncmp(category, "workorder", 9) == 0 && (category[9] == '\0' || category[9] == '.'))
        return true;
    if(qstrncmp(category, "qml", 3) == 0 && (category[3] == '\0' || category[3] == '.'))
        return true;
    if(qstrncmp(category, "js", 2) == 0 && (category[2] == '\0' || category[2] == '.'))
        return true;

    return false;
}

void writeToConsole(QtMsgType type, const QString &msg)
{
    QTextStream stream(stderr);
    stream << '[' << messageLevel(type) << "] " << msg << '\n';
    stream.flush();
}

#ifdef Q_OS_ANDROID
void writeToAndroidLog(QtMsgType type, const QString &msg)
{
    android_LogPriority priority = ANDROID_LOG_DEBUG;
    switch(type)
    {
    case QtInfoMsg:
        priority = ANDROID_LOG_INFO;
        break;
    case QtWarningMsg:
        priority = ANDROID_LOG_WARN;
        break;
    case QtCriticalMsg:
        priority = ANDROID_LOG_ERROR;
        break;
    case QtFatalMsg:
        priority = ANDROID_LOG_FATAL;
        break;
    default:
        break;
    }

    __android_log_print(priority, "WorkOrder", "%s", msg.toUtf8().constData());
}
#endif

class FileLogWriter
{
public:
    explicit FileLogWriter(const QString &path)
        : m_file(path)
    {
        if(m_file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text))
            m_stream.setDevice(&m_file);
    }

    void write(QtMsgType type, const QMessageLogContext &context, const QString &msg)
    {
        QMutexLocker locker(&m_mutex);
        if(!m_stream.device())
            return;

        const QString category = context.category ? QString::fromUtf8(context.category) : QStringLiteral("default");
        m_stream << QDateTime::currentDateTime().toString(Qt::ISODate)
                 << " [" << messageLevel(type) << "] " << category << ": " << msg << '\n';
        m_stream.flush();
    }

private:
    QFile m_file;
    QTextStream m_stream;
    QMutex m_mutex;
};

FileLogWriter *g_fileWriter = nullptr;

void messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    if(!isProjectLogCategory(context.category))
        return;

    if(g_fileWriter != nullptr)
        g_fileWriter->write(type, context, msg);

#ifdef Q_OS_ANDROID
    writeToAndroidLog(type, msg);
#else
    if(g_previousHandler != nullptr)
        g_previousHandler(type, context, msg);
    else
        writeToConsole(type, msg);
#endif

    if(type == QtFatalMsg)
        abort();
}

} // namespace

QString AppLogging::setupAppLogging()
{
    static bool installed = false;
    if(installed)
        return QString();
    installed = true;

    QLoggingCategory::setFilterRules(QStringLiteral(
        "qt.*.debug=false\n"
        "qt.*.info=false\n"
        "qt.*.warning=false\n"
        "qt.*.critical=false\n"
        "default.debug=true\n"
        "default.info=true\n"
        "default.warning=true\n"
        "default.critical=true\n"
        "workorder.debug=true\n"
        "workorder.info=true\n"
        "workorder.warning=true\n"
        "workorder.critical=true\n"
        "qml.debug=true\n"
        "qml.info=true\n"
        "qml.warning=true\n"
        "qml.critical=true\n"
        "js.debug=true\n"
        "js.info=true\n"
        "js.warning=true\n"
        "js.critical=true"));

    QString logFilePath;
    if(AppPaths::isAndroidRuntime())
    {
        logFilePath = QDir(AppPaths::dataDir()).filePath("debug.log");
        QDir().mkpath(QFileInfo(logFilePath).absolutePath());
        g_fileWriter = new FileLogWriter(logFilePath);
    }

    g_previousHandler = qInstallMessageHandler(&messageHandler);
    return logFilePath;
}

} // namespace workorder
