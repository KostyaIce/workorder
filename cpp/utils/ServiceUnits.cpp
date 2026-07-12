#include "ServiceUnits.h"

#include <QStringList>

namespace workorder
{

bool ServiceUnits::isPercentUnit(const QString &unit)
{
    QString value = unit.trimmed().toCaseFolded();
    value.replace(' ', QString());
    if(value.isEmpty())
        return false;

    static const QStringList percentTokens = {
        QStringLiteral("%"),
        QStringLiteral("проц"),
        QStringLiteral("проц."),
        QStringLiteral("процент"),
        QStringLiteral("percent"),
    };

    if(percentTokens.contains(value))
        return true;

    return value.contains('%');
}

} // namespace workorder
