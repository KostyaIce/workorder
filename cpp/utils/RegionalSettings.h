#ifndef WORKORDER_UTILS_REGIONAL_SETTINGS_H
#define WORKORDER_UTILS_REGIONAL_SETTINGS_H

#include <QString>
#include <QVariantList>

namespace workorder
{

// Process-wide regional settings shared by UI, PDF and Excel code.
class RegionalSettings
{
public:
    static QString currencyCode();
    static QString currencySymbol();
    static void setCurrency(const QString &code);
    // Currencies of the CIS countries: code, symbol, name.
    static QVariantList availableCurrencies();
};

} // namespace workorder

#endif // WORKORDER_UTILS_REGIONAL_SETTINGS_H
