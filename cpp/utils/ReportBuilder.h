#ifndef WORKORDER_UTILS_REPORT_BUILDER_H
#define WORKORDER_UTILS_REPORT_BUILDER_H

#include "Types.h"

#include <QString>
#include <QPair>

namespace workorder
{

class ReportBuilder
{
public:
    static QString buildWorkReport(const QString &personalInfo, const StringMap &client,
                                   const StringMap &objectData, const StringMapList &works,
                                   const StringMap &options = StringMap());
    static QPair<QString, QString> saveWorkReport(const QString &personalInfo, const StringMap &client,
                                                  const StringMap &objectData, const StringMapList &works,
                                                  const StringMap &options = StringMap(),
                                                  const QString &filePath = QString());

private:
    static QString formatMoney(double value);
    static QPair<QString, double> workLine(const StringMap &work, bool includeCoefficients);
    static double appendWorkLines(QStringList &lines, const StringMapList &works, bool includeCoefficients);
};

} // namespace workorder

#endif // WORKORDER_UTILS_REPORT_BUILDER_H
