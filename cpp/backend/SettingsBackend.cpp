#include "SettingsBackend.h"

#include "AppPaths.h"
#include "DatabaseStorage.h"
#include "MinimalZip.h"
#include "NotificationManager.h"

#include <QDesktopServices>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QIODevice>
#include <QUrl>
#include <QVariantMap>

#if defined(Q_OS_ANDROID)
#include <QJniObject>
#include <QtCore/qcoreapplication_platform.h>
#endif

namespace workorder
{

namespace
{

#if defined(Q_OS_ANDROID)

QString createLogsZip(const QString &logDir)
{
    QDir dir(logDir);
    const QFileInfoList files = dir.entryInfoList(QDir::Files | QDir::Readable, QDir::Name);
    MinimalZipWriter zip;
    int added = 0;
    for(const QFileInfo &info : files)
    {
        if(info.fileName() == QLatin1String("logs.zip"))
            continue;

        QFile file(info.absoluteFilePath());
        if(!file.open(QIODevice::ReadOnly))
            continue;
        zip.addFile(info.fileName(), file.readAll());
        ++added;
    }

    if(added == 0)
        return {};

    const QString zipPath = dir.filePath(QStringLiteral("logs.zip"));
    if(QFile::exists(zipPath))
        QFile::remove(zipPath);
    if(!zip.writeToFile(zipPath))
        return {};
    return zipPath;
}

bool shareZipOnAndroid(const QString &zipPath)
{
    const QJniObject context = QNativeInterface::QAndroidApplication::context();
    if(!context.isValid())
    {
        qWarning("SettingsBackend: Android context is invalid");
        return false;
    }

    const jboolean ok = QJniObject::callStaticMethod<jboolean>(
        "com/workorder/LogShare",
        "shareZip",
        "(Landroid/content/Context;Ljava/lang/String;)Z",
        context.object(),
        QJniObject::fromString(zipPath).object<jstring>());
    return ok == JNI_TRUE;
}

#endif

} // namespace

SettingsBackend::SettingsBackend(QObject *parent)
    : QObject(parent)
    , m_dbPath(QDir(AppPaths::dbDir()).filePath("services.db"))
{
    loadPersistedSettings();
}

SettingsBackend::~SettingsBackend() = default;

QString SettingsBackend::appVersion() const { return m_appVersion; }
QString SettingsBackend::appName() const { return m_appName; }
QString SettingsBackend::buildDate() const { return m_buildDate; }
QString SettingsBackend::developer() const { return m_developer; }
QString SettingsBackend::fullVersion() const { return m_appName + " v" + m_appVersion; }

QString SettingsBackend::theme() const { return m_theme; }

void SettingsBackend::setTheme(const QString &value)
{
    if(m_theme == value)
        return;
    m_theme = value;
    emit themeChanged();
    emit settingsChanged();
}

QString SettingsBackend::language() const { return m_language; }

void SettingsBackend::setLanguage(const QString &value)
{
    if(m_language == value)
        return;
    m_language = value;
    emit languageChanged();
    emit settingsChanged();
}

bool SettingsBackend::autoSave() const { return m_autoSave; }

void SettingsBackend::setAutoSave(bool value)
{
    if(m_autoSave == value)
        return;
    m_autoSave = value;
    emit settingsChanged();
}

QString SettingsBackend::currency() const { return m_currency; }

void SettingsBackend::setCurrency(const QString &value)
{
    if(m_currency == value)
        return;
    m_currency = value;
    emit settingsChanged();
}

int SettingsBackend::vatRate() const { return m_vatRate; }

void SettingsBackend::setVatRate(int value)
{
    if(m_vatRate == value)
        return;
    m_vatRate = value;
    emit settingsChanged();
}

QString SettingsBackend::invoicePrefix() const { return m_invoicePrefix; }

void SettingsBackend::setInvoicePrefix(const QString &value)
{
    if(m_invoicePrefix == value)
        return;
    m_invoicePrefix = value;
    emit settingsChanged();
}

QString SettingsBackend::dbPath() const { return m_dbPath; }

void SettingsBackend::setDbPath(const QString &value)
{
    if(m_dbPath == value)
        return;
    m_dbPath = value;
    emit settingsChanged();
}

QString SettingsBackend::defaultImportPath() const
{
    return QDir(AppPaths::configDir()).filePath("import.json");
}

QString SettingsBackend::personalInfo() const { return m_personalInfo; }

void SettingsBackend::setPersonalInfo(const QString &value)
{
    if(m_personalInfo == value)
        return;
    m_personalInfo = value;
    emit settingsChanged();
}

void SettingsBackend::setThemeSlot(const QString &theme)
{
    setTheme(theme);
}

void SettingsBackend::setLanguageSlot(const QString &language)
{
    setLanguage(language);
}

void SettingsBackend::setPersonalInfoSlot(const QString &value)
{
    setPersonalInfo(value);
}

bool SettingsBackend::saveSettings()
{
    DatabaseStorage::saveAppSettings(collectSettings());
    return true;
}

bool SettingsBackend::resetSettings()
{
    m_theme = QStringLiteral("light");
    m_language = QStringLiteral("ru");
    m_autoSave = true;
    m_currency = QStringLiteral("RUB");
    m_vatRate = 20;
    m_invoicePrefix = QStringLiteral("INV");
    m_dbPath = QDir(AppPaths::dbDir()).filePath("services.db");
    m_personalInfo.clear();
    emit settingsChanged();
    emit themeChanged();
    emit languageChanged();
    DatabaseStorage::saveAppSettings(collectSettings());
    return true;
}

bool SettingsBackend::exportData()
{
    return true;
}

bool SettingsBackend::importData(const QString &filePath)
{
    Q_UNUSED(filePath);
    return true;
}

bool SettingsBackend::resetDatabase()
{
    return true;
}

bool SettingsBackend::openLogDirectory()
{
    const QString path = AppPaths::logDir();
    QDir().mkpath(path);
    if(QDesktopServices::openUrl(QUrl::fromLocalFile(path)))
        return true;

    NotificationManager::notifyError(
        tr("Не удалось открыть каталог: %1").arg(path));
    return false;
}

bool SettingsBackend::openDbDirectory()
{
    const QString path = AppPaths::dbDir();
    QDir().mkpath(path);
    if(QDesktopServices::openUrl(QUrl::fromLocalFile(path)))
        return true;

    NotificationManager::notifyError(
        tr("Не удалось открыть каталог: %1").arg(path));
    return false;
}

bool SettingsBackend::copyLogs()
{
#if defined(Q_OS_ANDROID)
    // Same approach as KelVPN MainActivity.sendLogs: zip private log files and
    // share via FileProvider + ACTION_SEND (directory open is not supported).
    const QString sourceDir = AppPaths::logDir();
    QDir().mkpath(sourceDir);

    const QString zipPath = createLogsZip(sourceDir);
    if(zipPath.isEmpty())
    {
        NotificationManager::notifyError(tr("Нет файлов логов для отправки"));
        return false;
    }

    if(!shareZipOnAndroid(zipPath))
    {
        NotificationManager::notifyError(tr("Не удалось поделиться логами"));
        return false;
    }

    NotificationManager::notifyInfo(tr("Выберите приложение для отправки логов"));
    return true;
#else
    return openLogDirectory();
#endif
}

QVariantList SettingsBackend::getAvailableThemes() const
{
    return {QStringLiteral("light"), QStringLiteral("dark"), QStringLiteral("auto")};
}

QVariantList SettingsBackend::getAvailableLanguages() const
{
    return {
        QVariantMap{{"code", "ru"}, {"name", "Русский"}},
        QVariantMap{{"code", "en"}, {"name", "English"}},
        QVariantMap{{"code", "de"}, {"name", "Deutsch"}},
    };
}

QVariantList SettingsBackend::getAvailableCurrencies() const
{
    return {
        QVariantMap{{"code", "RUB"}, {"symbol", "₽"}, {"name", "Российский рубль"}},
        QVariantMap{{"code", "USD"}, {"symbol", "$"}, {"name", "Доллар США"}},
        QVariantMap{{"code", "EUR"}, {"symbol", "€"}, {"name", "Евро"}},
    };
}

void SettingsBackend::loadPersistedSettings()
{
    const QVariantMap stored = DatabaseStorage::loadAppSettings();
    if(stored.isEmpty())
        return;

    m_theme = stored.value("theme", m_theme).toString();
    m_language = stored.value("language", m_language).toString();
    m_autoSave = stored.value("auto_save", m_autoSave).toBool();
    m_currency = stored.value("currency", m_currency).toString();
    m_vatRate = stored.value("vat_rate", m_vatRate).toInt();
    m_invoicePrefix = stored.value("invoice_prefix", m_invoicePrefix).toString();
    m_dbPath = stored.value("db_path", m_dbPath).toString();
    m_personalInfo = stored.value("personal_info", m_personalInfo).toString();
}

QVariantMap SettingsBackend::collectSettings() const
{
    QVariantMap map;
    map.insert("theme", m_theme);
    map.insert("language", m_language);
    map.insert("auto_save", m_autoSave);
    map.insert("currency", m_currency);
    map.insert("vat_rate", m_vatRate);
    map.insert("invoice_prefix", m_invoicePrefix);
    map.insert("db_path", m_dbPath);
    map.insert("personal_info", m_personalInfo);
    return map;
}

} // namespace workorder
