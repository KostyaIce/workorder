#include "applicationBootstrap.h"
#include "appPaths.h"
#include "backendController.h"

#include <QCommandLineParser>
#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlError>
#include <QUrl>

int main(int argc, char *argv[])
{
    workorder::ApplicationBootstrap::setupEnvironment();

    QGuiApplication app(argc, argv);
    app.setApplicationName("WorkOrder");
    app.setOrganizationName("WorkOrderApp");

    QCommandLineParser parser;
    parser.setApplicationDescription("WorkOrder Application");
    parser.addHelpOption();
    QCommandLineOption typeOption(
        QStringList{QStringLiteral("t"), QStringLiteral("type")},
        "Application type: desktop or mobile",
        QStringLiteral("type"),
        workorder::AppPaths::isAndroidRuntime() ? QStringLiteral("mobile") : QStringLiteral("desktop"));
    parser.addOption(typeOption);
    parser.process(app);

    const QString appType = workorder::ApplicationBootstrap::resolveAppType(parser.value(typeOption));
    qInfo("Starting WorkOrder, type=%s", qPrintable(appType));
    workorder::ApplicationBootstrap::setupLightPalette(app);
    const QString uiFontFamily = workorder::ApplicationBootstrap::setupUiFont(app);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::warnings,
        &app,
        [](const QList<QQmlError> &errors)
        {
            for(const QQmlError &error : errors)
                qWarning("%s", qPrintable(error.toString()));
        });
    for(const QString &importPath : workorder::ApplicationBootstrap::qmlImportPaths(appType))
        engine.addImportPath(importPath);

    workorder::ApplicationBootstrap::setQmlThemeContext(engine.rootContext());

    workorder::BackendController backendController(&engine);
    if(!backendController.initialize())
    {
        qCritical("Backend initialization failed");
        return -1;
    }

    backendController.exposeToQml(engine.rootContext());
    engine.rootContext()->setContextProperty("appType", appType);
    engine.rootContext()->setContextProperty("pdfPreviewSupported",
        workorder::ApplicationBootstrap::isPdfPreviewSupported(appType));
    if(!uiFontFamily.isEmpty())
        engine.rootContext()->setContextProperty("defaultFontFamily", uiFontFamily);

    const QUrl qmlUrl = workorder::ApplicationBootstrap::qmlMainUrl(appType);
    qInfo("Loading QML: %s", qPrintable(qmlUrl.toString(QUrl::FullyEncoded)));
    engine.load(qmlUrl);
    if(engine.rootObjects().isEmpty())
    {
        qCritical("Failed to load QML: %s", qPrintable(qmlUrl.toString(QUrl::FullyEncoded)));
        return -1;
    }

    workorder::ApplicationBootstrap::applyWindowIcons(app, engine);
    return app.exec();
}
