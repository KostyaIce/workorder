#include "PdfReportBuilder.h"

#include "AppPaths.h"
#include "DatabaseStorage.h"
#include "FileIo.h"
#include "ReportBuilder.h"

#include <QBuffer>
#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMap>
#include <algorithm>
#include <QPageLayout>
#include <QPageSize>
#include <QPdfWriter>
#include <QTextDocument>
#include <QUrl>

namespace workorder
{

namespace
{

bool optionEnabled(const StringMap &options, const char *key, bool defaultValue = true)
{
    if(!options.contains(QLatin1String(key)))
        return defaultValue;
    return options.value(QLatin1String(key)).toBool();
}

QString safeClientName(const StringMap &client)
{
    const QString name = client.value("name").toString();
    QString safe;
    for(const QChar ch : name)
        safe.append(ch.isLetterOrNumber() ? ch : QChar('_'));
    return safe.isEmpty() ? QStringLiteral("client") : safe;
}

} // namespace

QString PdfReportBuilder::resolveReportFontPath(const QString &fontPath)
{
    if(!fontPath.isEmpty())
    {
        const QFileInfo info(fontPath);
        if(info.isFile())
            return info.absoluteFilePath();
    }

    const QString bundled = QStringLiteral(":/resources/fonts/DejaVuSans.ttf");
    if(QFileInfo::exists(bundled))
        return bundled;

    static const QStringList candidates = {
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
        "/Library/Fonts/Arial Unicode.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "C:/Windows/Fonts/arial.ttf",
    };

    for(const QString &candidate : candidates)
    {
        if(QFileInfo::exists(candidate))
            return candidate;
    }

    return QString();
}

QString PdfReportBuilder::registerReportFont(const QString &fontPath)
{
    const QString path = resolveReportFontPath(fontPath);
    if(path.isEmpty())
        return QStringLiteral("DejaVu Sans");

    return QFileInfo(path).completeBaseName();
}

PdfReportBuilder::PdfReportBuilder(const QString &fontPath)
    : m_fontPath(resolveReportFontPath(fontPath))
    , m_fontFamily(registerReportFont(m_fontPath))
{
}

QString PdfReportBuilder::escapeHtml(const QString &value) const
{
    QString text = value;
    text.replace('&', "&amp;");
    text.replace('<', "&lt;");
    text.replace('>', "&gt;");
    return text;
}

QString PdfReportBuilder::formatMoney(double value) const
{
    return QStringLiteral("%1 \u20BD").arg(QString::number(value, 'f', 2));
}

QString PdfReportBuilder::formatMultiplier(int percentSum) const
{
    if(percentSum <= 0)
        percentSum = 100;

    const double value = percentSum / 100.0;
    QString text = QString::number(value, 'f', 2);
    while(text.contains('.') && (text.endsWith('0') || text.endsWith('.')))
    {
        if(text.endsWith('0'))
            text.chop(1);
        else
            text.chop(1);
    }
    return text;
}

QString PdfReportBuilder::formatWorkName(const StringMap &work) const
{
    QString name = work.value("name").toString();
    const QString coefficients = work.value("coefficients").toString().trimmed();
    if(!coefficients.isEmpty())
        name += QStringLiteral(" (%1)").arg(coefficients);

    return escapeHtml(name);
}

QString PdfReportBuilder::formatQuantity(double quantity, const QString &unit) const
{
    QString text = QString::number(quantity, 'g', 12);
    const QString trimmedUnit = unit.trimmed();
    if(!trimmedUnit.isEmpty())
        text += QLatin1Char(' ') + trimmedUnit;

    return escapeHtml(text);
}

QString PdfReportBuilder::worksTableStyle() const
{
    QString style = QStringLiteral("font-size:8pt");
    if(!m_fontPath.isEmpty())
        style += QStringLiteral(";font-family:'%1',sans-serif").arg(escapeHtml(m_fontFamily));
    return style;
}

QString PdfReportBuilder::worksTableHeaderStyle() const
{
    QString style = QStringLiteral("font-size:8pt");
    if(!m_fontPath.isEmpty())
        style += QStringLiteral(";font-family:'%1',sans-serif;font-weight:bold").arg(escapeHtml(m_fontFamily));
    return style;
    // return worksTableStyle() + QStringLiteral(";font-weight:bold");
}

QString PdfReportBuilder::wrapWorksTableText(const QString &text) const
{
    return QStringLiteral("<span style=\"%1\">%2</span>").arg(worksTableStyle(), text);
}

QString PdfReportBuilder::buildHtmlHead() const
{
    QString html = QStringLiteral("<html><head><meta charset=\"utf-8\"/>");
    if(!m_fontPath.isEmpty())
    {
        html += QStringLiteral("<style>@font-face { font-family: '%1'; src: url('%2'); }"
                               "body { font-family: '%1', sans-serif; font-size: 10pt; margin: 0; padding: 0; }</style>")
            .arg(escapeHtml(m_fontFamily), QUrl::fromLocalFile(m_fontPath).toString());
    }
    html += QStringLiteral("</head><body>");
    return html;
}

QString PdfReportBuilder::buildReportHeaderHtml(const StringMap &options) const
{
    if(!optionEnabled(options, "include_report_header"))
        return QString();

    QString headerText = options.value("report_header_text").toString().trimmed();
    if(headerText.isEmpty())
        headerText = QStringLiteral("ОТЧЁТ О ПРОДЕЛАННЫХ РАБОТАХ");

    QString html;
    for(const QString &line : headerText.split('\n'))
        html += QStringLiteral("<h2 style=\"text-align:center;\">%1</h2>").arg(escapeHtml(line));

    return html;
}

QString PdfReportBuilder::buildReportDateHtml(const StringMap &options) const
{
    if(!optionEnabled(options, "include_report_date"))
        return QString();

    return QStringLiteral("<p>Дата: %1</p>")
        .arg(escapeHtml(QDateTime::currentDateTime().toString("dd.MM.yyyy HH:mm")));
}

QString PdfReportBuilder::buildPersonalInfoHtml(const QString &personalInfo, const StringMap &options) const
{
    if(!optionEnabled(options, "include_personal_info"))
        return QString();

    const QString info = personalInfo.trimmed();
    return QStringLiteral("<h3>Исполнитель:</h3><p>%1</p>")
        .arg(escapeHtml(info.isEmpty() ? QStringLiteral("—") : info));
}

QString PdfReportBuilder::buildClientNameHtml(const StringMap &client, const StringMap &options) const
{
    if(!optionEnabled(options, "include_client_name"))
        return QString();

    return QStringLiteral("<p>%1</p>").arg(escapeHtml(client.value("name").toString()));
}

QString PdfReportBuilder::buildClientAddressHtml(const StringMap &client, const StringMap &objectData,
                                                 const StringMap &options) const
{
    if(!optionEnabled(options, "include_client_address"))
        return QString();

    QString html;
    QString address = objectData.value("address").toString();
    if(address.isEmpty())
        address = client.value("address").toString();
    if(!address.isEmpty())
        html += QStringLiteral("<p>Адрес: %1</p>").arg(escapeHtml(address));

    const QString objectName = objectData.value("name").toString();
    if(!objectName.isEmpty())
        html += QStringLiteral("<p>Объект: %1</p>").arg(escapeHtml(objectName));

    return html;
}

QString PdfReportBuilder::buildPartiesHtml(const QString &personalInfo, const StringMap &client,
                                           const StringMap &objectData, const StringMap &options) const
{
    const QString personalHtml = buildPersonalInfoHtml(personalInfo, options);
    const QString clientNameHtml = buildClientNameHtml(client, options);
    const QString clientAddressHtml = buildClientAddressHtml(client, objectData, options);

    if(personalHtml.isEmpty() && clientNameHtml.isEmpty() && clientAddressHtml.isEmpty())
        return QString();

    QString html = QStringLiteral("<table width=\"100%\"><tr><td valign=\"top\" width=\"50%\">");
    html += personalHtml;
    html += QStringLiteral("</td><td valign=\"top\" width=\"50%\">");

    if(!clientNameHtml.isEmpty() || !clientAddressHtml.isEmpty())
    {
        html += QStringLiteral("<h3>Заказчик:</h3>");
        html += clientNameHtml;
        html += clientAddressHtml;
    }

    html += QStringLiteral("</td></tr></table>");
    return html;
}

QPair<QString, double> PdfReportBuilder::buildWorksTableHtml(const StringMapList &rows, bool includeTotal) const
{
    QString html;
    double total = 0.0;
    const QString cellStyle = worksTableStyle();
    const QString headerStyle = worksTableHeaderStyle();
    const QString workColWidth = QStringLiteral("50%");
    const QString qtyColWidth = QStringLiteral("14%");
    const QString priceColWidth = QStringLiteral("14%");
    const QString coeffColWidth = QStringLiteral("7%");
    const QString sumColWidth = QStringLiteral("15%");

    html += QStringLiteral("<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\" width=\"100%\">");
    html += QStringLiteral("<tr>"
                           "<td style=\"%1\" width=\"%2\">%3</td>"
                           "<td style=\"%1\" width=\"%4\" align=\"right\">%5</td>"
                           "<td style=\"%1\" width=\"%6\" align=\"right\">%7</td>"
                           "<td style=\"%1\" width=\"%8\" align=\"center\">%9</td>"
                           "<td style=\"%1\" width=\"%10\" align=\"right\">%11</td>"
                           "</tr>")
        .arg(headerStyle,
             workColWidth,
             wrapWorksTableText(QStringLiteral("<b>Работа</b>")),
             qtyColWidth,
             wrapWorksTableText(QStringLiteral("<b>Кол-во</b>")),
             priceColWidth,
             wrapWorksTableText(QStringLiteral("<b>Цена</b>")),
             coeffColWidth,
             wrapWorksTableText(QStringLiteral("<b>К.</b>")),
             sumColWidth,
             wrapWorksTableText(QStringLiteral("<b>Сумма</b>")));

    QMap<QString, StringMap> merged;
    QStringList order;
    for(const QVariant &item : rows)
    {
        const StringMap work = item.toMap();
        const QString key = work.value("name").toString()
            + '|' + work.value("price").toString()
            + '|' + work.value("unit").toString()
            + '|' + work.value("coefficients").toString()
            + '|' + work.value("percent_sum").toString();
        if(!merged.contains(key))
        {
            merged.insert(key, work);
            order.append(key);
            continue;
        }

        StringMap existing = merged.value(key);
        existing.insert("quantity", existing.value("quantity").toDouble() + work.value("quantity", 1).toDouble());
        merged.insert(key, existing);
    }

    for(const QString &key : order)
    {
        const StringMap work = merged.value(key);
        const double price = work.value("price").toDouble() / 100.0;
        const double quantity = work.value("quantity", 1).toDouble();
        const int percentSum = work.value("percent_sum", 100).toInt();
        const double lineTotal = price * quantity * (percentSum / 100.0);
        total += lineTotal;

        html += QStringLiteral("<tr>"
                               "<td style=\"%1\" width=\"%2\">%3</td>"
                               "<td style=\"%1\" width=\"%4\" align=\"right\">%5</td>"
                               "<td style=\"%1\" width=\"%6\" align=\"right\">%7</td>"
                               "<td style=\"%1\" width=\"%8\" align=\"center\">%9</td>"
                               "<td style=\"%1\" width=\"%10\" align=\"right\">%11</td>"
                               "</tr>")
            .arg(cellStyle,
                 workColWidth,
                 wrapWorksTableText(formatWorkName(work)),
                 qtyColWidth,
                 wrapWorksTableText(formatQuantity(quantity, work.value("unit").toString())),
                 priceColWidth,
                 wrapWorksTableText(escapeHtml(formatMoney(price))),
                 coeffColWidth,
                 wrapWorksTableText(escapeHtml(formatMultiplier(percentSum))),
                 sumColWidth,
                 wrapWorksTableText(escapeHtml(formatMoney(lineTotal))));
    }

    if(includeTotal)
    {
        html += QStringLiteral("<tr>"
                               "<td style=\"%1\" colspan=\"4\" align=\"right\">%2</td>"
                               "<td style=\"%1\" align=\"right\">%3</td>"
                               "</tr>")
            .arg(headerStyle,
                 wrapWorksTableText(QStringLiteral("<b>Итого:</b>")),
                 wrapWorksTableText(QStringLiteral("<b>%1</b>").arg(escapeHtml(formatMoney(total)))));
    }

    html += QStringLiteral("</table>");
    return {html, total};
}

QString PdfReportBuilder::buildGroupedWorksHtml(const StringMapList &works) const
{
    QMap<QString, StringMapList> groups;
    for(const QVariant &item : works)
    {
        const StringMap work = item.toMap();
        const QString key = work.value("subobject_name").toString().trimmed();
        groups[key].append(work);
    }

    QStringList keys = groups.keys();
    std::sort(keys.begin(), keys.end(), [](const QString &a, const QString &b)
    {
        return a.compare(b, Qt::CaseInsensitive) < 0;
    });

    QString html;
    double grandTotal = 0.0;
    for(const QString &subobjectName : keys)
    {
        if(!subobjectName.isEmpty())
            html += QStringLiteral("<h4>%1:</h4>").arg(escapeHtml(subobjectName));

        const QPair<QString, double> table = buildWorksTableHtml(groups.value(subobjectName), false);
        html += table.first;
        grandTotal += table.second;
    }

    html += QStringLiteral("<p align=\"right\"><b>Итого: %1</b></p>").arg(formatMoney(grandTotal));
    return html;
}

QString PdfReportBuilder::buildFlatWorksHtml(const StringMapList &works) const
{
    return buildWorksTableHtml(works, true).first;
}

QString PdfReportBuilder::buildWorksHtml(const StringMapList &works, const StringMap &options) const
{
    QString html = QStringLiteral("<h3>Перечень работ</h3>");

    if(works.isEmpty())
    {
        html += QStringLiteral("<p>Нет записей о выполненных работах.</p>");
        return html;
    }

    if(optionEnabled(options, "group_by_subobjects"))
        html += buildGroupedWorksHtml(works);
    else
        html += buildFlatWorksHtml(works);

    return html;
}

QString PdfReportBuilder::buildHtml(const QString &personalInfo, const StringMap &client,
                                    const StringMap &objectData, const StringMapList &works,
                                    const StringMap &options) const
{
    QString html = buildHtmlHead();
    html += buildReportHeaderHtml(options);
    html += buildWorksHtml(works, options);
    html += buildPartiesHtml(personalInfo, client, objectData, options);
    html += buildReportDateHtml(options);
    html += QStringLiteral("</body></html>");
    return html;
}

QByteArray PdfReportBuilder::buildPdfBytes(const QString &personalInfo, const StringMap &client,
                                           const StringMap &objectData, const StringMapList &works,
                                           const StringMap &options) const
{
    QTextDocument document;
    document.setHtml(buildHtml(personalInfo, client, objectData, works, options));

    QByteArray bytes;
    QBuffer buffer(&bytes);
    buffer.open(QIODevice::WriteOnly);

    QPdfWriter writer(&buffer);
    writer.setPageSize(QPageSize(QPageSize::A4));
    writer.setPageMargins(QMarginsF(18, 18, 18, 18), QPageLayout::Millimeter);

    const QPageLayout layout = writer.pageLayout();
    document.setDocumentMargin(0);
    document.setPageSize(layout.paintRect(QPageLayout::Point).size());

    document.print(&writer);

    return bytes;
}

QPair<QString, QByteArray> PdfReportBuilder::saveWorkReport(const QString &personalInfo, const StringMap &client,
                                                            const StringMap &objectData, const StringMapList &works,
                                                            const StringMap &options, const QString &filePath) const
{
    const QByteArray pdfBytes = buildPdfBytes(personalInfo, client, objectData, works, options);
    const QString reportsDir = DatabaseStorage::defaultReportsDir();
    QDir().mkpath(reportsDir);

    QString target;
    if(!filePath.isEmpty())
    {
        // Keep content:// URIs intact; absoluteFilePath() breaks SAF targets on Android.
        target = FileIo::nativeTarget(filePath);
        if(target.isEmpty())
            target = filePath.trimmed();
    }
    else
    {
        const QString stamp = QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");
        target = QDir(reportsDir).filePath(QStringLiteral("report_%1_%2.pdf").arg(safeClientName(client), stamp));
    }

    QString error;
    if(!FileIo::writeBytes(target, pdfBytes, &error))
    {
        qWarning("PdfReportBuilder: failed to save PDF to %s: %s",
                 qPrintable(target),
                 qPrintable(error));
        return {QString(), pdfBytes};
    }

    return {target, pdfBytes};
}

QPair<QString, QByteArray> saveWorkReportPdf(const QString &personalInfo, const StringMap &client,
                                             const StringMap &objectData, const StringMapList &works,
                                             const StringMap &options, const QString &filePath,
                                             const QString &fontPath)
{
    return PdfReportBuilder(fontPath).saveWorkReport(personalInfo, client, objectData, works, options, filePath);
}

} // namespace workorder
