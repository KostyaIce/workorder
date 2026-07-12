#ifndef WORKORDER_UTILS_SERVICES_PDF_BUILDER_H
#define WORKORDER_UTILS_SERVICES_PDF_BUILDER_H

#include "Types.h"

#include <QString>

namespace workorder
{

class ServicesPdfBuilder
{
public:
    explicit ServicesPdfBuilder(const QString &fontPath = QString());

    QByteArray buildPdfBytes(const StringMapList &services, const QString &title = QString()) const;
    QString savePdf(const QString &filePath, const StringMapList &services,
                    const QString &title = QString()) const;

    static QString resolvePdfPath(const QString &fileUrl);

private:
    QString m_fontPath;
};

QString exportServicesPdf(const QString &fileUrl, const StringMapList &services = StringMapList(),
                          const QString &title = QString());

} // namespace workorder

#endif // WORKORDER_UTILS_SERVICES_PDF_BUILDER_H
