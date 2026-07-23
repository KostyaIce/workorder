#ifndef WORKORDER_UTILS_APP_LOGGING_H
#define WORKORDER_UTILS_APP_LOGGING_H

#include <QString>

namespace workorder
{

// Installs qInstallMessageHandler so normal qDebug/qInfo/qWarning/qCritical
// go to console + rotating log file (same idea as DapLogger in dapchainvpn-client).
class AppLogging
{
public:
    // Call once at startup (before other logging). Returns current log file path.
    static QString setupAppLogging();

    static QString pathToLog();
    static QString pathToFile();

private:
    AppLogging() = delete;
};

} // namespace workorder

#endif // WORKORDER_UTILS_APP_LOGGING_H
