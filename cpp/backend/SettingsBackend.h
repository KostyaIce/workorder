#ifndef WORKORDER_BACKEND_SETTINGS_BACKEND_H
#define WORKORDER_BACKEND_SETTINGS_BACKEND_H

#include <QObject>
#include <QString>
#include <QVariantList>

#ifndef WORKORDER_VERSION
#define WORKORDER_VERSION "1.0.0"
#endif

namespace workorder
{

class SettingsBackend : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString appVersion READ appVersion NOTIFY settingsChanged)
    Q_PROPERTY(QString appName READ appName NOTIFY settingsChanged)
    Q_PROPERTY(QString buildDate READ buildDate NOTIFY settingsChanged)
    Q_PROPERTY(QString developer READ developer NOTIFY settingsChanged)
    Q_PROPERTY(QString fullVersion READ fullVersion NOTIFY settingsChanged)
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(bool autoSave READ autoSave WRITE setAutoSave NOTIFY settingsChanged)
    Q_PROPERTY(QString currency READ currency WRITE setCurrency NOTIFY settingsChanged)
    Q_PROPERTY(int vatRate READ vatRate WRITE setVatRate NOTIFY settingsChanged)
    Q_PROPERTY(QString invoicePrefix READ invoicePrefix WRITE setInvoicePrefix NOTIFY settingsChanged)
    Q_PROPERTY(QString dbPath READ dbPath WRITE setDbPath NOTIFY settingsChanged)
    Q_PROPERTY(QString defaultImportPath READ defaultImportPath CONSTANT)
    Q_PROPERTY(QString personalInfo READ personalInfo WRITE setPersonalInfo NOTIFY settingsChanged)

public:
    explicit SettingsBackend(QObject *parent = nullptr);
    ~SettingsBackend() override;

    QString appVersion() const;
    QString appName() const;
    QString buildDate() const;
    QString developer() const;
    QString fullVersion() const;

    QString theme() const;
    void setTheme(const QString &value);

    QString language() const;
    void setLanguage(const QString &value);

    bool autoSave() const;
    void setAutoSave(bool value);

    QString currency() const;
    void setCurrency(const QString &value);

    int vatRate() const;
    void setVatRate(int value);

    QString invoicePrefix() const;
    void setInvoicePrefix(const QString &value);

    QString dbPath() const;
    void setDbPath(const QString &value);

    QString defaultImportPath() const;

    QString personalInfo() const;
    void setPersonalInfo(const QString &value);

    Q_INVOKABLE void setThemeSlot(const QString &theme);
    Q_INVOKABLE void setLanguageSlot(const QString &language);
    Q_INVOKABLE void setPersonalInfoSlot(const QString &value);
    Q_INVOKABLE bool saveSettings();
    Q_INVOKABLE bool resetSettings();
    Q_INVOKABLE bool exportData();
    Q_INVOKABLE bool importData(const QString &filePath);
    Q_INVOKABLE bool resetDatabase();
    Q_INVOKABLE QVariantList getAvailableThemes() const;
    Q_INVOKABLE QVariantList getAvailableLanguages() const;
    Q_INVOKABLE QVariantList getAvailableCurrencies() const;

signals:
    void settingsChanged();
    void themeChanged();
    void languageChanged();

private:
    void loadPersistedSettings();
    QVariantMap collectSettings() const;

    QString m_appVersion = QLatin1String(WORKORDER_VERSION);
    QString m_appName = QStringLiteral("WorkOrder");
    QString m_buildDate = QStringLiteral("2024-01-15");
    QString m_developer = QStringLiteral("WorkOrder Team");
    QString m_theme = QStringLiteral("light");
    QString m_language = QStringLiteral("ru");
    bool m_autoSave = true;
    QString m_currency = QStringLiteral("RUB");
    int m_vatRate = 20;
    QString m_invoicePrefix = QStringLiteral("INV");
    QString m_dbPath;
    QString m_personalInfo;
};

} // namespace workorder

#endif // WORKORDER_BACKEND_SETTINGS_BACKEND_H
