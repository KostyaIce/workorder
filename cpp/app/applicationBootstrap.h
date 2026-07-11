#ifndef WORKORDER_APP_APPLICATION_BOOTSTRAP_H
#define WORKORDER_APP_APPLICATION_BOOTSTRAP_H

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QString>
#include <QStringList>
#include <QUrl>

namespace workorder
{

class ApplicationBootstrap
{
public:
    static QString resolveAppType(const QString &cliType);
    static QString qmlMainPath(const QString &appType);
    static QUrl qmlMainUrl(const QString &appType);
    static QStringList qmlImportPaths(const QString &appType);
    static void setupEnvironment();
    static void setupLightPalette(QGuiApplication &app);
    static QString setupUiFont(QGuiApplication &app);
    static void setQmlThemeContext(QQmlContext *context);
    static void applyWindowIcons(QGuiApplication &app, QQmlApplicationEngine &engine);
    static bool isPdfPreviewSupported(const QString &appType);
};

} // namespace workorder

#endif // WORKORDER_APP_APPLICATION_BOOTSTRAP_H
