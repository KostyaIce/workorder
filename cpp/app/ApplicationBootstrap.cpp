#include "ApplicationBootstrap.h"

#include "AppLogging.h"
#include "AppPaths.h"

#include <QColor>
#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QFont>
#include <QFontDatabase>
#include <QIcon>
#include <QLibraryInfo>
#include <QOperatingSystemVersion>
#include <QPalette>
#include <QQuickWindow>

namespace workorder
{

namespace
{

QString bundledFontPath()
{
    return QStringLiteral(":/resources/fonts/DejaVuSans.ttf");
}

QIcon loadBundledAppIcon()
{
#if defined(Q_OS_WIN)
    const QString preferred = QStringLiteral(":/resources/icons/appIcons/icon_win32.ico");
#elif defined(Q_OS_MACOS)
    const QString preferred = QStringLiteral(":/resources/icons/appIcons/icon_macos.icns");
#else
    const QString preferred = QStringLiteral(":/resources/icons/appIcons/icon_linux.png");
#endif

    QIcon icon(preferred);
    if(!icon.isNull() && !icon.availableSizes().isEmpty())
        return icon;

    icon = QIcon(QStringLiteral(":/resources/icons/appIcons/icon_linux.png"));
    if(!icon.isNull() && !icon.availableSizes().isEmpty())
        return icon;

    return QIcon();
}

} // namespace

QString ApplicationBootstrap::resolveAppType(const QString &cliType)
{
#if defined(Q_OS_IOS)
    // iOS launches from SpringBoard without the CMake run target's --type.
    // Always use the phone UI, including when environment/CLI says desktop.
    Q_UNUSED(cliType);
    return QStringLiteral("mobile");
#else
    if(AppPaths::isAndroidRuntime())
        return QStringLiteral("mobile");

    const QString envType = qEnvironmentVariable("WORKORDER_APP_TYPE");
    if(envType == QLatin1String("mobile") || envType == QLatin1String("desktop"))
        return envType;

    if(cliType == QLatin1String("mobile") || cliType == QLatin1String("desktop"))
        return cliType;

    return QStringLiteral("desktop");
#endif
}

QString ApplicationBootstrap::qmlMainPath(const QString &appType)
{
    return QStringLiteral("qrc:/resources/qml/%1/main.qml").arg(appType);
}

QUrl ApplicationBootstrap::qmlMainUrl(const QString &appType)
{
    return QUrl(qmlMainPath(appType));
}

QStringList ApplicationBootstrap::qmlImportPaths(const QString &appType)
{
    Q_UNUSED(appType);
    return {QStringLiteral("qrc:/resources/qml")};
}

void ApplicationBootstrap::setupEnvironment()
{
    AppPaths::createPaths();
    AppLogging::setupAppLogging();

    if(AppPaths::isAndroidRuntime())
        qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    else if(QOperatingSystemVersion::currentType() == QOperatingSystemVersion::MacOS)
        qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    else
        qputenv("QT_QUICK_CONTROLS_STYLE", "Fusion");
}

void ApplicationBootstrap::setupLightPalette(QGuiApplication &app)
{
    QPalette palette;
    palette.setColor(QPalette::Window, QColor("#E0ECF9"));
    palette.setColor(QPalette::WindowText, QColor("#1B2430"));
    palette.setColor(QPalette::Base, QColor("#FFFFFF"));
    palette.setColor(QPalette::AlternateBase, QColor("#E0ECF9"));
    palette.setColor(QPalette::Text, QColor("#1B2430"));
    palette.setColor(QPalette::Button, QColor("#FFFFFF"));
    palette.setColor(QPalette::ButtonText, QColor("#1B2430"));
    palette.setColor(QPalette::Highlight, QColor("#2878F5"));
    palette.setColor(QPalette::HighlightedText, QColor("#FFFFFF"));
    palette.setColor(QPalette::Mid, QColor("#E0E0E0"));
    palette.setColor(QPalette::Dark, QColor("#8B95A5"));
    palette.setColor(QPalette::Light, QColor("#FFFFFF"));
    palette.setColor(QPalette::Shadow, QColor("#BDBDBD"));
    app.setPalette(palette);
}

QString ApplicationBootstrap::setupUiFont(QGuiApplication &app)
{
    const QString fontPath = bundledFontPath();
    if(!QFileInfo::exists(fontPath))
    {
        qWarning("UI font not found: %s", qPrintable(fontPath));
        return QString();
    }

    const int fontId = QFontDatabase::addApplicationFont(fontPath);
    if(fontId < 0)
    {
        qWarning("Failed to load UI font: %s", qPrintable(fontPath));
        return QString();
    }

    const QStringList families = QFontDatabase::applicationFontFamilies(fontId);
    if(families.isEmpty())
        return QString();

    QFont font = app.font();
    font.setFamily(families.first());
    app.setFont(font);
    qInfo("UI font: %s", qPrintable(families.first()));
    return families.first();
}

void ApplicationBootstrap::setQmlThemeContext(QQmlContext *context)
{
    if(!context)
        return;

    // Keep in sync with resources/qml/WorkOrder/Common/Theme.qml.
    // Context names stay available in every window, including dialogs outside the main tree.
    context->setContextProperty("primaryColor", "#2878F5");
    context->setContextProperty("secondaryColor", "#1F66D6");
    context->setContextProperty("backgroundColor", "#E0ECF9");
    context->setContextProperty("cardColor", "#FFFFFF");
    context->setContextProperty("textColor", "#1B2430");
    context->setContextProperty("textSecondaryColor", "#8B95A5");
}

void ApplicationBootstrap::applyWindowIcons(QGuiApplication &app, QQmlApplicationEngine &engine)
{
    QIcon icon = app.windowIcon();
    if(icon.isNull() || icon.availableSizes().isEmpty())
        icon = loadBundledAppIcon();

    if(icon.isNull() || icon.availableSizes().isEmpty())
    {
        qWarning("Application icon not found in resources");
        return;
    }

    app.setWindowIcon(icon);

    const QList<QObject *> roots = engine.rootObjects();
    for(QObject *root : roots)
    {
        if(auto *window = qobject_cast<QQuickWindow *>(root))
            window->setIcon(icon);
    }
}

bool ApplicationBootstrap::isPdfPreviewSupported(const QString &appType)
{
    Q_UNUSED(appType);

    if(AppPaths::isAndroidRuntime())
        return false;

    const QString qtQmlPath = QLibraryInfo::path(QLibraryInfo::QmlImportsPath);
    return QFileInfo::exists(QDir(qtQmlPath).filePath("QtQuick/Pdf/qmldir"));
}

} // namespace workorder
