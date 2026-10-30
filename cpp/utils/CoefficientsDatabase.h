#ifndef WORKORDER_UTILS_COEFFICIENTS_DB_H
#define WORKORDER_UTILS_COEFFICIENTS_DB_H

#include "Types.h"

#include <QString>

namespace workorder
{

// Coefficients live in their own table (inside services.db), separate from the
// services catalog. A coefficient price is stored the same way as a service
// price: percent * 100, so 150% is 15000.
class CoefficientsDatabase
{
public:
    static QString defaultCoefficientsDbPath();
    static void createCoefficientsTable();
    // Returns the new coefficient id, or an empty string when the insert fails.
    static QString addCoefficient(const StringMap &data);
    static bool updateCoefficient(const StringMap &data);
    static bool deleteCoefficient(const QString &coefficientId);
    static StringMapList loadCoefficients();
    static StringMap getCoefficientById(const QString &coefficientId);
    static StringMapList searchCoefficients(const QString &query);
    // Moves legacy percent-unit rows out of the services table.
    static int migratePercentServices();

private:
    static int parsePriceCents(const QVariant &value);
    static QString keywordsFromName(const QString &name);
};

} // namespace workorder

#endif // WORKORDER_UTILS_COEFFICIENTS_DB_H
