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

qint64 workAmountKopecks(const StringMap &work)
{
    const qint64 priceKopecks = work.value("price").toLongLong();
    const qint64 quantityThousandths = qRound64(work.value("quantity", 1).toDouble() * 1000.0);
    const qint64 percentSum = work.value("percent_sum", 100).toLongLong();
    const qint64 numerator = priceKopecks * quantityThousandths * percentSum;
    return (numerator + 50000) / 100000;
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

QString PdfReportBuilder::formatWorkName(const StringMap &work, bool includeCoefficients) const
{
    QString name = work.value("name").toString();
    if(includeCoefficients)
    {
        const QString coefficients = work.value("coefficients").toString().trimmed();
        if(!coefficients.isEmpty())
            name += QStringLiteral(" (%1)").arg(coefficients);
    }

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
    if(info.isEmpty())
        return QStringLiteral("<h3>Исполнитель:</h3><p>—</p>");

    QString htmlBody = escapeHtml(info);
    htmlBody.replace(QLatin1String("\r\n"), QLatin1String("\n"));
    htmlBody.replace(QLatin1Char('\r'), QLatin1Char('\n'));
    htmlBody.replace(QLatin1Char('\n'), QLatin1String("<br/>"));

    return QStringLiteral("<h3>Исполнитель:</h3><p>%1</p>").arg(htmlBody);
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

QPair<QString, qint64> PdfReportBuilder::buildWorksTableHtml(const StringMapList &rows, bool includeTotal,
                                                             const StringMap &options) const
{
    QString html;
    qint64 totalKopecks = 0;
    for(const QVariant &value : rows)
        totalKopecks += workAmountKopecks(value.toMap());
    const bool includeCoefficients = optionEnabled(options, "include_coefficients");
    const QString cellStyle = worksTableStyle();
    const QString headerStyle = worksTableHeaderStyle();
    const QString workColWidth = includeCoefficients ? QStringLiteral("50%") : QStringLiteral("55%");
    const QString qtyColWidth = QStringLiteral("14%");
    const QString priceColWidth = includeCoefficients ? QStringLiteral("14%") : QStringLiteral("16%");
    const QString coeffColWidth = QStringLiteral("7%");
    const QString sumColWidth = includeCoefficients ? QStringLiteral("15%") : QStringLiteral("15%");

    html += QStringLiteral("<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\" width=\"100%\">");
    if(includeCoefficients)
    {
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
    }
    else
    {
        html += QStringLiteral("<tr>"
                               "<td style=\"%1\" width=\"%2\">%3</td>"
                               "<td style=\"%1\" width=\"%4\" align=\"right\">%5</td>"
                               "<td style=\"%1\" width=\"%6\" align=\"right\">%7</td>"
                               "<td style=\"%1\" width=\"%8\" align=\"right\">%9</td>"
                               "</tr>")
            .arg(headerStyle,
                 workColWidth,
                 wrapWorksTableText(QStringLiteral("<b>Работа</b>")),
                 qtyColWidth,
                 wrapWorksTableText(QStringLiteral("<b>Кол-во</b>")),
                 priceColWidth,
                 wrapWorksTableText(QStringLiteral("<b>Цена</b>")),
                 sumColWidth,
                 wrapWorksTableText(QStringLiteral("<b>Сумма</b>")));
    }

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
        const qint64 priceKopecks = work.value("price").toLongLong();
        const double quantity = work.value("quantity", 1).toDouble();
        const int percentSum = work.value("percent_sum", 100).toInt();
        const qint64 displayPriceKopecks = includeCoefficients
            ? priceKopecks
            : (priceKopecks * percentSum + 50) / 100;
        const qint64 lineTotalKopecks = workAmountKopecks(work);

        if(includeCoefficients)
        {
            html += QStringLiteral("<tr>"
                                   "<td style=\"%1\" width=\"%2\">%3</td>"
                                   "<td style=\"%1\" width=\"%4\" align=\"right\">%5</td>"
                                   "<td style=\"%1\" width=\"%6\" align=\"right\">%7</td>"
                                   "<td style=\"%1\" width=\"%8\" align=\"center\">%9</td>"
                                   "<td style=\"%1\" width=\"%10\" align=\"right\">%11</td>"
                                   "</tr>")
                .arg(cellStyle,
                     workColWidth,
                     wrapWorksTableText(formatWorkName(work, true)),
                     qtyColWidth,
                     wrapWorksTableText(formatQuantity(quantity, work.value("unit").toString())),
                     priceColWidth,
                     wrapWorksTableText(escapeHtml(formatMoney(priceKopecks / 100.0))),
                     coeffColWidth,
                     wrapWorksTableText(escapeHtml(formatMultiplier(percentSum))),
                     sumColWidth,
                     wrapWorksTableText(escapeHtml(formatMoney(lineTotalKopecks / 100.0))));
        }
        else
        {
            html += QStringLiteral("<tr>"
                                   "<td style=\"%1\" width=\"%2\">%3</td>"
                                   "<td style=\"%1\" width=\"%4\" align=\"right\">%5</td>"
                                   "<td style=\"%1\" width=\"%6\" align=\"right\">%7</td>"
                                   "<td style=\"%1\" width=\"%8\" align=\"right\">%9</td>"
                                   "</tr>")
                .arg(cellStyle,
                     workColWidth,
                     wrapWorksTableText(formatWorkName(work, false)),
                     qtyColWidth,
                     wrapWorksTableText(formatQuantity(quantity, work.value("unit").toString())),
                     priceColWidth,
                     wrapWorksTableText(escapeHtml(formatMoney(displayPriceKopecks / 100.0))),
                     sumColWidth,
                     wrapWorksTableText(escapeHtml(formatMoney(lineTotalKopecks / 100.0))));
        }
    }

    if(includeTotal)
    {
        const int labelColspan = includeCoefficients ? 4 : 3;
        html += QStringLiteral("<tr>"
                               "<td style=\"%1\" colspan=\"%2\" align=\"right\">%3</td>"
                               "<td style=\"%1\" align=\"right\">%4</td>"
                               "</tr>")
            .arg(headerStyle)
            .arg(labelColspan)
            .arg(wrapWorksTableText(QStringLiteral("<b>Итого:</b>")),
                 wrapWorksTableText(QStringLiteral("<b>%1</b>").arg(
                     escapeHtml(formatMoney(totalKopecks / 100.0)))));
    }

    html += QStringLiteral("</table>");
    return {html, totalKopecks};
}

QString PdfReportBuilder::buildGroupedWorksHtml(const StringMapList &works, const StringMap &options) const
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
    qint64 grandTotalKopecks = 0;
    for(const QString &subobjectName : keys)
    {
        if(!subobjectName.isEmpty())
            html += QStringLiteral("<h4>%1:</h4>").arg(escapeHtml(subobjectName));

        const QPair<QString, qint64> table = buildWorksTableHtml(
            groups.value(subobjectName), false, options);
        html += table.first;
        grandTotalKopecks += table.second;
    }

    html += QStringLiteral("<p align=\"right\"><b>Итого: %1</b></p>")
                .arg(formatMoney(grandTotalKopecks / 100.0));
    return html;
}

QString PdfReportBuilder::buildFlatWorksHtml(const StringMapList &works, const StringMap &options) const
{
    return buildWorksTableHtml(works, true, options).first;
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
        html += buildGroupedWorksHtml(works, options);
    else
        html += buildFlatWorksHtml(works, options);

    return html;
}

QString PdfReportBuilder::buildExpensesHtml(const StringMapList &expenses) const
{
    if(expenses.isEmpty())
        return QString();

    const QString cellStyle = worksTableStyle();
    const QString headerStyle = worksTableHeaderStyle();
    QString html = QStringLiteral(
        "<h3>Затраты</h3>"
        "<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\" width=\"100%\">"
        "<tr><td style=\"%1\" width=\"75%\"><b>Описание</b></td>"
        "<td style=\"%1\" width=\"25%\" align=\"right\"><b>Сумма</b></td></tr>")
                       .arg(headerStyle);

    qint64 totalKopecks = 0;
    for(const QVariant &value : expenses)
    {
        const StringMap expense = value.toMap();
        const qint64 amount = expense.value("amount").toLongLong();
        totalKopecks += amount;
        html += QStringLiteral(
            "<tr><td style=\"%1\">%2</td>"
            "<td style=\"%1\" align=\"right\">%3</td></tr>")
                    .arg(cellStyle,
                         wrapWorksTableText(escapeHtml(expense.value("description").toString())),
                         wrapWorksTableText(escapeHtml(formatMoney(amount / 100.0))));
    }

    html += QStringLiteral(
        "<tr><td style=\"%1\" align=\"right\"><b>Итого по затратам:</b></td>"
        "<td style=\"%1\" align=\"right\"><b>%2</b></td></tr></table>")
                .arg(headerStyle, escapeHtml(formatMoney(totalKopecks / 100.0)));
    return html;
}

QString PdfReportBuilder::buildTotalsHtml(const StringMapList &works,
                                          const StringMapList &expenses) const
{
    if(expenses.isEmpty())
        return QString();

    qint64 worksTotalKopecks = 0;
    for(const QVariant &value : works)
        worksTotalKopecks += workAmountKopecks(value.toMap());

    qint64 expensesTotalKopecks = 0;
    for(const QVariant &value : expenses)
        expensesTotalKopecks += value.toMap().value("amount").toLongLong();

    return QStringLiteral(
        "<p align=\"right\"><b>Итого по работам: %1</b><br/>"
        "<b>Итого по затратам: %2</b><br/>"
        "<b>Общая сумма: %3</b></p>")
        .arg(escapeHtml(formatMoney(worksTotalKopecks / 100.0)),
             escapeHtml(formatMoney(expensesTotalKopecks / 100.0)),
             escapeHtml(formatMoney(
                 (worksTotalKopecks + expensesTotalKopecks) / 100.0)));
}

QString PdfReportBuilder::buildHtml(const QString &personalInfo, const StringMap &client,
                                    const StringMap &objectData, const StringMapList &works,
                                    const StringMapList &expenses,
                                    const StringMap &options) const
{
    QString html = buildHtmlHead();
    html += buildReportHeaderHtml(options);
    html += buildWorksHtml(works, options);
    html += buildExpensesHtml(expenses);
    html += buildTotalsHtml(works, expenses);
    html += buildPartiesHtml(personalInfo, client, objectData, options);
    html += buildReportDateHtml(options);
    html += QStringLiteral("</body></html>");
    return html;
}

QByteArray PdfReportBuilder::buildPdfBytes(const QString &personalInfo, const StringMap &client,
                                           const StringMap &objectData, const StringMapList &works,
                                           const StringMapList &expenses,
                                           const StringMap &options) const
{
    QTextDocument document;
    document.setHtml(buildHtml(personalInfo, client, objectData, works, expenses, options));

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
                                                            const StringMapList &expenses,
                                                            const StringMap &options, const QString &filePath) const
{
    const QByteArray pdfBytes = buildPdfBytes(personalInfo, client, objectData, works, expenses, options);
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
                                             const StringMapList &expenses,
                                             const StringMap &options, const QString &filePath,
                                             const QString &fontPath)
{
    return PdfReportBuilder(fontPath).saveWorkReport(
        personalInfo, client, objectData, works, expenses, options, filePath);
}

} // namespace workorder
