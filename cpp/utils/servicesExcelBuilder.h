#ifndef WORKORDER_UTILS_SERVICES_EXCEL_BUILDER_H
#define WORKORDER_UTILS_SERVICES_EXCEL_BUILDER_H

#include "types.h"

#include <QString>

namespace workorder
{

class ServicesExcelBuilder
{
public:
    StringMapList readServices(const QString &filePath);
    QString writeExport(const QString &filePath, const StringMapList &services);

    static QString resolveExcelPath(const QString &fileUrl, bool ensureExtension = false);
    static int parseExcelPrice(const QVariant &value);
};

StringMapList importServicesFromExcel(const QString &fileUrl);
QString exportServicesExcel(const QString &fileUrl, const StringMapList &services = StringMapList());

} // namespace workorder

#endif // WORKORDER_UTILS_SERVICES_EXCEL_BUILDER_H
