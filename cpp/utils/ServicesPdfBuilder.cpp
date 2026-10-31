#include "ServicesPdfBuilder.h"

#include "CoefficientsDatabase.h"
#include "FileIo.h"
#include "PdfReportBuilder.h"
#include "RegionalSettings.h"
#include "ServiceUnits.h"
#include "ServicesDatabase.h"
#include "ServicesExcelBuilder.h"

#include <QBuffer>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QPageLayout>
#include <QPageSize>
#include <QPdfWriter>
#include <QAbstractTextDocumentLayout>
#include <QTextBlockFormat>
#include <QTextCursor>
#include <QTextDocument>
#include <QTextFrame>
#include <QTextTable>
#include <QUrl>
#include <algorithm>
#include <cmath>

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

    return QStringLiteral("%1 %2").arg(QString::number(value / 100.0, 'f', 2),
                                          RegionalSettings::currencySymbol());
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

QString buildServicesHtml(const StringMapList &services, const StringMapList &coefficients,
                          const QString &title, const QString &fontPath)
{
    const QString fontFamily = PdfReportBuilder::registerReportFont(fontPath);
    const QString resolvedFontPath = PdfReportBuilder::resolveReportFontPath(fontPath);

    const QString fontCss = resolvedFontPath.isEmpty()
        ? QString()
        : QStringLiteral("font-family:'%1',sans-serif;").arg(escapeHtml(fontFamily));

    QString html = QStringLiteral("<html><head><meta charset=\"utf-8\"/>");
    if(!resolvedFontPath.isEmpty())
    {
        html += QStringLiteral("<style>@font-face { font-family: '%1'; src: url('%2'); }"
                               "body { font-family: '%1', sans-serif; font-size: 10pt; margin: 0; padding: 0; }</style>")
            .arg(escapeHtml(fontFamily), QUrl::fromLocalFile(resolvedFontPath).toString());
    }
    html += QStringLiteral("</head><body>");
    html += QStringLiteral(
        "<p style=\"%1text-align:center;font-size:16pt;font-weight:bold;margin-top:0;margin-bottom:16pt;\">%2</p>")
        .arg(fontCss, escapeHtml(title));

    // Same hairline on every edge. HTML border="1" is an outset frame plus a second grid.
    const QString cellStyle = QStringLiteral("%1font-size:10pt;border:1px solid #B7C0CC;").arg(fontCss);
    const QString headerRow = QStringLiteral(
        "<tr><td width=\"72%\" style=\"%1\"><b>Услуга</b></td>"
        "<td width=\"18%\" align=\"right\" style=\"%1\"><b>Стоимость</b></td>"
        "<td width=\"10%\" align=\"center\" style=\"%1\"><b>Ед.</b></td></tr>")
        .arg(cellStyle);
    const QVector<ParagraphGroup> groups = groupServicesByParagraph(services);
    StringMapList untitled;
    bool wroteTable = false;

    auto appendRows = [&](const StringMapList &items)
    {
        for(const QVariant &item : items)
        {
            const StringMap service = item.toMap();
            const QString name = service.value("name").toString().trimmed();
            const QString note = service.value("note").toString().trimmed();
            const QString unit = service.value("unit").toString().trimmed();
            const QString priceText = formatPriceForPdf(service.value("price").toInt(), unit);

            QString description = escapeHtml(name);
            if(!note.isEmpty())
                description += QStringLiteral("<br/>%1").arg(escapeHtml(note));

            html += QStringLiteral(
                "<tr><td width=\"72%\" style=\"%1\">%2</td>"
                "<td width=\"18%\" align=\"right\" style=\"%1\">%3</td>"
                "<td width=\"10%\" align=\"center\" style=\"%1\">%4</td></tr>")
                .arg(cellStyle, description, escapeHtml(priceText), escapeHtml(unit));
        }
    };

    auto beginTable = [&]()
    {
        html += QStringLiteral(
            "<table width=\"100%\" cellspacing=\"0\" cellpadding=\"4\" "
            "style=\"border-collapse:collapse;border:1px solid #B7C0CC;\">");
        html += headerRow;
    };

    // The section title is the first table row, so Qt can repeat it with the
    // header on every page and it can never be orphaned above the table.
    auto beginSectionTable = [&](const QString &section)
    {
        html += QStringLiteral(
            "<table width=\"100%\" cellspacing=\"0\" cellpadding=\"4\" "
            "style=\"border-collapse:collapse;border:1px solid #B7C0CC;\">");
        html += QStringLiteral(
            "<tr><td colspan=\"3\" style=\"%1font-size:10pt;font-weight:bold;\">%2</td></tr>")
            .arg(cellStyle, escapeHtml(section));
        html += headerRow;
    };

    // Qt ignores a table's own top margin and drops a block that touches the next table.
    auto gapBeforeNext = [&]()
    {
        if(!wroteTable)
            return;

        html += QStringLiteral(
            "<p style=\"margin:0;font-size:22pt;\">&nbsp;</p>"
            "<p style=\"margin:0;font-size:2pt;\">&nbsp;</p>");
    };

    for(const ParagraphGroup &group : groups)
    {
        if(group.second.isEmpty())
            continue;

        if(group.first.isEmpty())
        {
            untitled += group.second;
            continue;
        }

        gapBeforeNext();
        beginSectionTable(group.first);
        appendRows(group.second);
        html += QStringLiteral("</table>");
        wroteTable = true;
    }

    // Services with no section title stay in one table, with the same gap above it.
    if(!untitled.isEmpty())
    {
        gapBeforeNext();
        beginTable();
        appendRows(untitled);
        html += QStringLiteral("</table>");
        wroteTable = true;
    }

    // Coefficients are listed as a separate section at the end.
    if(!coefficients.isEmpty())
    {
        gapBeforeNext();
        html += QStringLiteral(
            "<table width=\"100%\" cellspacing=\"0\" cellpadding=\"4\" "
            "style=\"border-collapse:collapse;border:1px solid #B7C0CC;\">");
        html += QStringLiteral(
            "<tr><td colspan=\"3\" style=\"%1font-size:10pt;font-weight:bold;\">%2</td></tr>")
            .arg(cellStyle, escapeHtml(QStringLiteral("Коэффициенты")));
        html += QStringLiteral(
            "<tr><td width=\"72%\" style=\"%1\"><b>Коэффициент</b></td>"
            "<td width=\"18%\" align=\"right\" style=\"%1\"><b>Значение</b></td>"
            "<td width=\"10%\" align=\"center\" style=\"%1\"><b>Ед.</b></td></tr>")
            .arg(cellStyle);

        StringMapList sorted = coefficients;
        std::sort(sorted.begin(), sorted.end(), [](const QVariant &left, const QVariant &right)
        {
            return left.toMap().value("name").toString().compare(
                right.toMap().value("name").toString(), Qt::CaseInsensitive) < 0;
        });

        for(const QVariant &item : sorted)
        {
            const StringMap coefficient = item.toMap();
            const QString name = coefficient.value("name").toString().trimmed();
            if(name.isEmpty())
                continue;
            const QString unit = coefficient.value("unit").toString().trimmed();
            const QString priceText = formatPriceForPdf(coefficient.value("price").toInt(), unit);
            html += QStringLiteral(
                "<tr><td width=\"72%\" style=\"%1\">%2</td>"
                "<td width=\"18%\" align=\"right\" style=\"%1\">%3</td>"
                "<td width=\"10%\" align=\"center\" style=\"%1\">%4</td></tr>")
                .arg(cellStyle, escapeHtml(name), escapeHtml(priceText), escapeHtml(unit));
        }
        html += QStringLiteral("</table>");
    }

    html += QStringLiteral("</body></html>");
    return html;
}

bool isGapBlock(const QTextBlock &block)
{
    return block.isValid() && block.text().trimmed().isEmpty();
}

int pageOf(const QTextDocument *document, const QTextBlock &block, qreal pageHeight)
{
    const qreal top = document->documentLayout()->blockBoundingRect(block).top();
    return static_cast<int>(std::floor(std::max(0.0, top) / pageHeight));
}

void breakBeforeBlock(QTextBlock block)
{
    QTextCursor cursor(block);
    QTextBlockFormat format = block.blockFormat();
    format.setPageBreakPolicy(format.pageBreakPolicy() | QTextFormat::PageBreak_AlwaysBefore);
    cursor.setBlockFormat(format);
}

void breakBeforeTable(QTextTable *table)
{
    QTextTableFormat format = table->format();
    format.setPageBreakPolicy(format.pageBreakPolicy() | QTextFormat::PageBreak_AlwaysBefore);
    table->setFormat(format);
}

// Repeat the section title and column header on every page of a table.
void repeatTableHeaders(QTextDocument *document)
{
    for(QTextFrame::iterator it = document->rootFrame()->begin(); !it.atEnd(); ++it)
    {
        QTextTable *table = qobject_cast<QTextTable *>(it.currentFrame());
        if(!table || table->rows() == 0 || table->columns() == 0)
            continue;

        const QTextTableCell firstCell = table->cellAt(0, 0);
        const bool hasSectionTitle = firstCell.columnSpan() == table->columns();
        const int headerRows = hasSectionTitle ? 2 : 1;

        QTextTableFormat format = table->format();
        format.setHeaderRowCount(qMin(headerRows, table->rows()));
        if(hasSectionTitle)
            format.setBorder(0);
        table->setFormat(format);

        // The section title looks like a caption: no top/left/right frame.
        if(hasSectionTitle)
        {
            QTextTableCellFormat cellFormat = firstCell.format().toTableCellFormat();
            cellFormat.setLeftBorder(0);
            cellFormat.setTopBorder(0);
            cellFormat.setRightBorder(0);
            cellFormat.setLeftBorderStyle(QTextFrameFormat::BorderStyle_None);
            cellFormat.setTopBorderStyle(QTextFrameFormat::BorderStyle_None);
            cellFormat.setRightBorderStyle(QTextFrameFormat::BorderStyle_None);
            table->cellAt(0, 0).setFormat(cellFormat);
        }
    }
}

// A section label or a column header must not be the last thing on a page.
void keepHeadsWithFirstRow(QTextDocument *document)
{
    const qreal pageHeight = document->pageSize().height();
    if(pageHeight <= 0)
        return;

    // The very first block is the document title; everything else that is a
    // non-empty paragraph directly before a table is a section heading.
    QTextBlock titleBlock;
    {
        const QTextFrame::iterator first = document->rootFrame()->begin();
        if(!first.atEnd())
            titleBlock = first.currentBlock();
    }

    for(int pass = 0; pass < 64; ++pass)
    {
        bool changed = false;
        QTextBlock pendingHeading;
        for(QTextFrame::iterator it = document->rootFrame()->begin(); !it.atEnd(); ++it)
        {
            QTextTable *table = qobject_cast<QTextTable *>(it.currentFrame());
            if(!table)
            {
                const QTextBlock block = it.currentBlock();
                if(!block.isValid())
                    continue;
                if(block == titleBlock)
                {
                    pendingHeading = QTextBlock();
                    continue;
                }
                if(isGapBlock(block))
                    continue;
                pendingHeading = block;
                continue;
            }

            if(table->rows() < 2)
            {
                pendingHeading = QTextBlock();
                continue;
            }

            const QTextTableCell dataCell = table->cellAt(1, 0);
            if(!dataCell.isValid())
            {
                pendingHeading = QTextBlock();
                continue;
            }

            const QTextBlock dataBlock = dataCell.firstCursorPosition().block();
            if(!dataBlock.isValid())
            {
                pendingHeading = QTextBlock();
                continue;
            }

            const int dataPage = pageOf(document, dataBlock, pageHeight);
            if(pendingHeading.isValid())
            {
                const int headPage = pageOf(document, pendingHeading, pageHeight);
                if(headPage < dataPage
                    && !(pendingHeading.blockFormat().pageBreakPolicy() & QTextFormat::PageBreak_AlwaysBefore))
                {
                    breakBeforeBlock(pendingHeading);
                    changed = true;
                    break;
                }
            }
            else
            {
                const QTextBlock headerBlock = table->cellAt(0, 0).firstCursorPosition().block();
                if(headerBlock.isValid()
                    && pageOf(document, headerBlock, pageHeight) < dataPage
                    && !(table->format().pageBreakPolicy() & QTextFormat::PageBreak_AlwaysBefore))
                {
                    breakBeforeTable(table);
                    changed = true;
                    break;
                }
            }
            pendingHeading = QTextBlock();
        }

        if(!changed)
            break;
    }
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

    // Do not mutate Android SAF content:// document URIs.
    if(FileIo::isContentUri(path))
        return path;

    if(path.endsWith(".xlsx", Qt::CaseInsensitive))
        path.chop(5);

    if(!path.endsWith(".pdf", Qt::CaseInsensitive))
        path += ".pdf";

    return path;
}

QByteArray ServicesPdfBuilder::buildPdfBytes(const StringMapList &services,
                                             const StringMapList &coefficients,
                                             const QString &title) const
{
    const QString resolvedTitle = title.isEmpty() ? QStringLiteral("Презентация услуг") : title;

    QTextDocument document;
    document.setHtml(buildServicesHtml(services, coefficients, resolvedTitle, m_fontPath));

    QByteArray bytes;
    QBuffer buffer(&bytes);
    buffer.open(QIODevice::WriteOnly);

    QPdfWriter writer(&buffer);
    writer.setPageSize(QPageSize(QPageSize::A4));
    writer.setPageMargins(QMarginsF(18, 18, 18, 18), QPageLayout::Millimeter);

    // Same printable width as the work report. The document's own page size
    // otherwise stays narrower and the table is centered on the sheet.
    const QPageLayout layout = writer.pageLayout();
    document.setDocumentMargin(0);
    document.setPageSize(layout.paintRect(QPageLayout::Point).size());
    repeatTableHeaders(&document);
    keepHeadsWithFirstRow(&document);
    document.print(&writer);

    return bytes;
}

QString ServicesPdfBuilder::savePdf(const QString &filePath, const StringMapList &services,
                                      const StringMapList &coefficients,
                                      const QString &title) const
{
    const QByteArray pdfBytes = buildPdfBytes(services, coefficients, title);
    QString error;
    if(!FileIo::writeBytes(filePath, pdfBytes, &error))
    {
        qWarning("ServicesPdfBuilder::savePdf failed: %s", qPrintable(error));
        return QString();
    }

    return FileIo::nativeTarget(filePath);
}

QString exportServicesPdf(const QString &fileUrl, const StringMapList &services,
                          const StringMapList &coefficients, const QString &title)
{
    const QString path = ServicesPdfBuilder::resolvePdfPath(fileUrl);
    if(path.isEmpty())
        throw std::runtime_error("Services presentation path is empty");

    StringMapList data = services;
    StringMapList coefficientData = coefficients;
    // An entirely empty request falls back to the databases.
    if(data.isEmpty() && coefficientData.isEmpty())
    {
        data = ServicesDatabase::loadServices();
        coefficientData = CoefficientsDatabase::loadCoefficients();
    }

    return ServicesPdfBuilder().savePdf(path, data, coefficientData, title);
}

} // namespace workorder
