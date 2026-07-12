#ifndef WORKORDER_UTILS_SERVICE_UNITS_H
#define WORKORDER_UTILS_SERVICE_UNITS_H

#include <QString>

namespace workorder
{

class ServiceUnits
{
public:
    static bool isPercentUnit(const QString &unit);
};

} // namespace workorder

#endif // WORKORDER_UTILS_SERVICE_UNITS_H
