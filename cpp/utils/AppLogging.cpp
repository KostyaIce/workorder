#include "AppLogging.h"

#include "AppPaths.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QLoggingCategory>
#include <QMutex>
#include <QTextStream>

#ifndef Q_OS_WIN
#include <sys/stat.h>
#include <unistd.h>
#else
#include <io.h>
#include <windows.h>
#endif

#ifdef Q_OS_ANDROID
#include <android/log.h>
#endif

namespace workorder
{

Q_LOGGING_CATEGORY(logWorkorder, "workorder")

namespace
{

const char *messageLevel(QtMsgType type)
{
    switch(type)
    {
    case QtInfoMsg:
        return "INF";
    case QtWarningMsg:
        return "WAR";
    case QtCriticalMsg:
        return "ERR";
    case QtFatalMsg:
        return "FATAL";
    default:
        return "DEB";
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

bool stderrIsRegularFile()
{
#ifdef Q_OS_WIN
    const int fd = _fileno(stderr);
    if(fd < 0)
        return false;

    const intptr_t osHandle = _get_osfhandle(fd);
    if(osHandle == -1)
        return false;

    return GetFileType(reinterpret_cast<HANDLE>(osHandle)) == FILE_TYPE_DISK;
#else
    struct stat st;
    if(fstat(fileno(stderr), &st) != 0)
        return false;

    return S_ISREG(st.st_mode);
#endif
}

bool consoleColorsEnabled()
{
    if(qEnvironmentVariableIsSet("NO_COLOR"))
        return false;

    if(qEnvironmentVariableIsSet("FORCE_COLOR") || qEnvironmentVariableIsSet("CLICOLOR_FORCE"))
        return true;

    return !stderrIsRegularFile();
}

const char *consoleColorStart(QtMsgType type)
{
    switch(type)
    {
    case QtInfoMsg:
        return "\033[32m";
    case QtCriticalMsg:
    case QtFatalMsg:
        return "\033[31m";
    default:
        return "";
    }
}

const char *consoleColorReset()
{
    return "\033[0m";
}

QString coloredLevelTag(QtMsgType type)
{
    const QString levelTag = QStringLiteral(" [") + QLatin1String(messageLevel(type)) + QStringLiteral("]");
    if(!consoleColorsEnabled())
        return levelTag;

    const char *colorStart = consoleColorStart(type);
    if(colorStart[0] == '\0')
        return levelTag;

    return QString::fromLatin1(colorStart) + levelTag + QString::fromLatin1(consoleColorReset());
}

QString formatLogLine(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    const QString category = context.category ? QString::fromUtf8(context.category) : QStringLiteral("default");
    QString line = QStringLiteral(" [") + QDateTime::currentDateTime().toString(Qt::ISODate) + QStringLiteral("]")
            + coloredLevelTag(type) + QStringLiteral(" ")
            + category + QStringLiteral(": ") + msg;

    if(context.file != nullptr && context.file[0] != '\0')
    {
        const QString filePath = QString::fromUtf8(context.file);
        const int slashIndex = qMax(filePath.lastIndexOf(QLatin1Char('/')),
                                    filePath.lastIndexOf(QLatin1Char('\\')));
        const QString fileName = slashIndex >= 0 ? filePath.mid(slashIndex + 1) : filePath;
        line += QStringLiteral(" (") + fileName + QLatin1Char(':') + QString::number(context.line) + QLatin1Char(')');
    }

    return line;
}

QString formatFileLine(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    const QString category = context.category ? QString::fromUtf8(context.category) : QStringLiteral("default");
    QString line = QStringLiteral(" [") + QDateTime::currentDateTime().toString(Qt::ISODate) + QStringLiteral("]")
            + QStringLiteral(" [") + QLatin1String(messageLevel(type)) + QStringLiteral("] ")
            + category + QStringLiteral(": ") + msg;

    if(context.file != nullptr && context.file[0] != '\0')
    {
        const QString filePath = QString::fromUtf8(context.file);
        const int slashIndex = qMax(filePath.lastIndexOf(QLatin1Char('/')),
                                    filePath.lastIndexOf(QLatin1Char('\\')));
        const QString fileName = slashIndex >= 0 ? filePath.mid(slashIndex + 1) : filePath;
        line += QStringLiteral(" (") + fileName + QLatin1Char(':') + QString::number(context.line) + QLatin1Char(')');
    }

    return line;
}

void writeToConsole(const QString &line)
{
    QTextStream stream(stderr);
    stream << line << '\n';
    stream.flush();
}

#ifdef Q_OS_ANDROID
void writeToAndroidLog(QtMsgType type, const QString &line)
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

    __android_log_print(priority, "WorkOrder", "%s", line.toUtf8().constData());
}
#endif

QString currentLogFileName()
{
    return QStringLiteral("WorkOrder_%1.log")
            .arg(QDateTime::currentDateTime().toString(QStringLiteral("dd-MM-yyyy")));
}

void clearOldLogs(const QString &logDir, int keepDays)
{
    QDir dir(logDir);
    if(!dir.exists())
        return;

    const QDateTime deleteBefore = QDateTime::currentDateTime().addDays(-keepDays);
    const QFileInfoList files = dir.entryInfoList({QStringLiteral("WorkOrder_*.log")}, QDir::Files);
    for(const QFileInfo &fileInfo : files)
    {
        if(fileInfo.lastModified() < deleteBefore)
            dir.remove(fileInfo.fileName());
    }
}

class FileLogWriter
{
public:
    explicit FileLogWriter(const QString &logDir)
        : m_logDir(logDir)
    {
        QDir().mkpath(m_logDir);
        openCurrentLogFile();
    }

    QString currentLogFilePath() const
    {
        QMutexLocker locker(&m_mutex);
        return m_filePath;
    }

    void write(const QString &line)
    {
        QMutexLocker locker(&m_mutex);
        rotateIfNeeded();
        if(!m_stream.device())
            return;

        m_stream << line << '\n';
        m_stream.flush();
    }

private:
    void openCurrentLogFile()
    {
        if(m_file.isOpen())
            m_file.close();

        m_currentDate = QDateTime::currentDateTime().toString(QStringLiteral("dd-MM-yyyy"));
        m_filePath = QDir(m_logDir).filePath(currentLogFileName());
        m_file.setFileName(m_filePath);

        if(m_file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text))
            m_stream.setDevice(&m_file);
        else
            m_stream.setDevice(nullptr);
    }

    void rotateIfNeeded()
    {
        const QString today = QDateTime::currentDateTime().toString(QStringLiteral("dd-MM-yyyy"));
        if(today == m_currentDate)
            return;

        openCurrentLogFile();
    }

    QString m_logDir;
    QString m_filePath;
    QString m_currentDate;
    QFile m_file;
    QTextStream m_stream;
    mutable QMutex m_mutex;
};

FileLogWriter *g_fileWriter = nullptr;

void messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    if(!isProjectLogCategory(context.category))
        return;

    const QString consoleLine = formatLogLine(type, context, msg);
    const QString fileLine = formatFileLine(type, context, msg);

    if(g_fileWriter != nullptr)
        g_fileWriter->write(fileLine);

#ifdef Q_OS_ANDROID
    writeToAndroidLog(type, fileLine);
#else
    writeToConsole(consoleLine);
#endif

    if(type == QtFatalMsg)
        abort();
}

} // namespace

QString AppLogging::setupAppLogging()
{
    static bool installed = false;
    if(installed)
        return g_fileWriter != nullptr ? g_fileWriter->currentLogFilePath() : QString();
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

    const QString logDir = QDir(AppPaths::dataDir()).filePath(QStringLiteral("logs"));
    clearOldLogs(logDir, 2);
    g_fileWriter = new FileLogWriter(logDir);

    qInstallMessageHandler(&messageHandler);
    return g_fileWriter->currentLogFilePath();
}

} // namespace workorder
