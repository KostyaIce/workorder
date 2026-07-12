#ifndef WORKORDER_UTILS_QSETTINGS_STORE_H
#define WORKORDER_UTILS_QSETTINGS_STORE_H

#include <QSettings>
#include <QVariant>

namespace workorder
{

class QSettingsStore
{
public:
    QSettingsStore();
    ~QSettingsStore();

    QVariant read(const QString &key, const QVariant &defaultValue = QVariant()) const;
    void write(const QString &key, const QVariant &value);
    void remove(const QString &key);
    bool contains(const QString &key) const;
    void sync();

private:
    QSettings createSettings();

    static constexpr const char *kOrganization = "WorkOrderApp";
    static constexpr const char *kApplication = "WorkOrder";

    QSettings m_settings;
};

} // namespace workorder

#endif // WORKORDER_UTILS_QSETTINGS_STORE_H
