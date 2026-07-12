#include "ServicesPdfBuilder.h"

#include "PdfReportBuilder.h"
#include "ServiceUnits.h"
#include "ServicesDatabase.h"
#include "ServicesExcelBuilder.h"

#include <QBuffer>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QPdfWriter>
#include <QTextDocument>
#include <QUrl>
#include <algorithm>

#include <stdexcept>

namespace workorder
{

namespace
{

using ParagraphGroup = QPair<QString, StringMapList>;

QString formatPriceForPdf(int cents, const QString &unit)
{
    const int value = cents;
    if(ServiceUnits::isPercentUnit(unit))
    {
        if(value % 100 == 0)
            return QString::number(value / 100);
        QString text = QString::number(value / 100.0, 'f', 2);
        while(text.endsWith('0'))
            text.chop(1);
        if(text.endsWith('.'))
            text.chop(1);
        return text;
    }

    return QStringLiteral("%1 \u20bd").arg(QString::number(value / 100.0, 'f', 2));
}

QString escapeHtml(const QString &value)
{
    QString text = value;
    text.replace('&', "&amp;");
    text.replace('<', "&lt;");
    text.replace('>', "&gt;");
    return text;
}

QVector<ParagraphGroup> groupServicesByParagraph(const StringMapList &services)
{
    QMap<QString, StringMapList> grouped;
    for(const QVariant &item : services)
    {
        const StringMap service = item.toMap();
        grouped[service.value("paragraph").toString().trimmed()].append(service);
    }

    QStringList paragraphs = grouped.keys();
    std::sort(paragraphs.begin(), paragraphs.end(), [](const QString &a, const QString &b)
    {
        if(a.isEmpty())
            return false;
        if(b.isEmpty())
            return true;
        return a.compare(b, Qt::CaseInsensitive) < 0;
    });

    QVector<ParagraphGroup> result;
    for(const QString &paragraph : paragraphs)
    {
        StringMapList items = grouped.value(paragraph);
        std::sort(items.begin(), items.end(), [](const QVariant &left, const QVariant &right)
        {
            return left.toMap().value("name").toString().compare(
                right.toMap().value("name").toString(), Qt::CaseInsensitive) < 0;
        });
        result.append({paragraph, items});
    }
    return result;
}

QString buildServicesHtml(const StringMapList &services, const QString &title, const QString &fontPath)
{
    const QString fontFamily = PdfReportBuilder::registerReportFont(fontPath);
    const QString resolvedFontPath = PdfReportBuilder::resolveReportFontPath(fontPath);

    QString html = QStringLiteral("<html><head><meta charset=\"utf-8\"/>");
    if(!resolvedFontPath.isEmpty())
    {
        html += QStringLiteral("<style>@font-face { font-family: '%1'; src: url('%2'); }"
                               "body, table { font-family: '%1', sans-serif; font-size: 10pt; }</style>")
            .arg(escapeHtml(fontFamily), QUrl::fromLocalFile(resolvedFontPath).toString());
    }
    html += QStringLiteral("</head><body>");
    html += QStringLiteral("<h2 style=\"text-align:center;\">%1</h2>").arg(escapeHtml(title));

    for(const ParagraphGroup &group : groupServicesByParagraph(services))
    {
        if(!group.first.isEmpty())
            html += QStringLiteral("<h3>%1</h3>").arg(escapeHtml(group.first));

        if(group.second.isEmpty())
            continue;

        html += QStringLiteral("<table border=\"1\" cellspacing=\"0\" cellpadding=\"4\" width=\"100%\">");
        for(const QVariant &item : group.second)
        {
            const StringMap service = item.toMap();
            const QString name = service.value("name").toString().trimmed();
            const QString note = service.value("note").toString().trimmed();
            const QString unit = service.value("unit").toString().trimmed();
            const QString priceText = formatPriceForPdf(service.value("price").toInt(), unit);

            QString description = escapeHtml(name);
            if(!note.isEmpty())
                description += QStringLiteral("<br/>%1").arg(escapeHtml(note));

            html += QStringLiteral("<tr><td>%1</td><td align=\"right\">%2</td><td align=\"center\">%3</td></tr>")
                .arg(description, escapeHtml(priceText), escapeHtml(unit));
        }
        html += QStringLiteral("</table><br/>");
    }

    html += QStringLiteral("</body></html>");
    return html;
}

} // namespace

ServicesPdfBuilder::ServicesPdfBuilder(const QString &fontPath)
    : m_fontPath(fontPath)
{
}

QString ServicesPdfBuilder::resolvePdfPath(const QString &fileUrl)
{
    QString path = ServicesExcelBuilder::resolveExcelPath(fileUrl);
    if(path.isEmpty())
        return QString();

    if(path.endsWith(".xlsx", Qt::CaseInsensitive))
        path.chop(5);

    if(!path.endsWith(".pdf", Qt::CaseInsensitive))
        path += ".pdf";

    return path;
}

QByteArray ServicesPdfBuilder::buildPdfBytes(const StringMapList &services, const QString &title) const
{
    const QString resolvedTitle = title.isEmpty() ? QStringLiteral("Презентация услуг") : title;

    QTextDocument document;
    document.setHtml(buildServicesHtml(services, resolvedTitle, m_fontPath));

    QByteArray bytes;
    QBuffer buffer(&bytes);
    buffer.open(QIODevice::WriteOnly);

    QPdfWriter writer(&buffer);
    writer.setPageSize(QPageSize(QPageSize::A4));
    writer.setPageMargins(QMarginsF(16, 16, 16, 16), QPageLayout::Millimeter);
    document.print(&writer);

    return bytes;
}

QString ServicesPdfBuilder::savePdf(const QString &filePath, const StringMapList &services,
                                      const QString &title) const
{
    QDir().mkpath(QFileInfo(filePath).absolutePath());
    const QByteArray pdfBytes = buildPdfBytes(services, title);

    QFile file(filePath);
    if(!file.open(QIODevice::WriteOnly))
        return QString();

    file.write(pdfBytes);
    return QFileInfo(filePath).absoluteFilePath();
}

QString exportServicesPdf(const QString &fileUrl, const StringMapList &services, const QString &title)
{
    const QString path = ServicesPdfBuilder::resolvePdfPath(fileUrl);
    if(path.isEmpty())
        throw std::runtime_error("Services presentation path is empty");

    StringMapList data = services;
    if(data.isEmpty())
        data = ServicesDatabase::loadServices();

    return ServicesPdfBuilder().savePdf(path, data, title);
}

} // namespace workorder
