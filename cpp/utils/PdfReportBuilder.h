#ifndef WORKORDER_UTILS_PDF_REPORT_BUILDER_H
#define WORKORDER_UTILS_PDF_REPORT_BUILDER_H

#include "Types.h"

#include <QByteArray>
#include <QPair>
#include <QString>

namespace workorder
{

class PdfReportBuilder
{
public:
    explicit PdfReportBuilder(const QString &fontPath = QString());

    QByteArray buildPdfBytes(const QString &personalInfo, const StringMap &client,
                             const StringMap &objectData, const StringMapList &works,
                             const StringMap &options = StringMap()) const;
    QPair<QString, QByteArray> saveWorkReport(const QString &personalInfo, const StringMap &client,
                                              const StringMap &objectData, const StringMapList &works,
                                              const StringMap &options = StringMap(),
                                              const QString &filePath = QString()) const;

    static QString resolveReportFontPath(const QString &fontPath = QString());
    static QString registerReportFont(const QString &fontPath = QString());

private:
    QString buildHtml(const QString &personalInfo, const StringMap &client,
                      const StringMap &objectData, const StringMapList &works,
                      const StringMap &options) const;
    QString escapeHtml(const QString &value) const;
    QString formatMoney(double value) const;

    QString m_fontPath;
    QString m_fontFamily;
};

QPair<QString, QByteArray> saveWorkReportPdf(const QString &personalInfo, const StringMap &client,
                                             const StringMap &objectData, const StringMapList &works,
                                             const StringMap &options = StringMap(),
                                             const QString &filePath = QString(),
                                             const QString &fontPath = QString());

} // namespace workorder

#endif // WORKORDER_UTILS_PDF_REPORT_BUILDER_H
