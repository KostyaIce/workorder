#ifndef WORKORDER_UTILS_SERVICES_EXCEL_BUILDER_H
#define WORKORDER_UTILS_SERVICES_EXCEL_BUILDER_H

#include "Types.h"

#include <QString>

namespace workorder
{

// One workbook holds services and coefficients. Coefficients are written as a
// separate section, so importing an old file without that section still works.
struct ExcelCatalog
{
    StringMapList services;
    StringMapList coefficients;
};

class ServicesExcelBuilder
{
public:
    ExcelCatalog readCatalog(const QString &filePath);
    QString writeExport(const QString &filePath, const ExcelCatalog &catalog);

    static QString resolveExcelPath(const QString &fileUrl, bool ensureExtension = false);
    static int parseExcelPrice(const QVariant &value);
    // Section title that separates coefficients from services in the sheet.
    static QString coefficientsSectionTitle();
    static bool isCoefficientsSection(const QString &title);
};

ExcelCatalog importCatalogFromExcel(const QString &fileUrl);
QString exportCatalogExcel(const QString &fileUrl, const ExcelCatalog &catalog = ExcelCatalog());

} // namespace workorder

#endif // WORKORDER_UTILS_SERVICES_EXCEL_BUILDER_H
