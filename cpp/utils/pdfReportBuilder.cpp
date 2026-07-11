#include "pdfReportBuilder.h"

#include "appPaths.h"
#include "databaseStorage.h"
#include "reportBuilder.h"

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
    return QString::number(value, 'f', 2);
}

QString PdfReportBuilder::buildHtml(const QString &personalInfo, const StringMap &client,
                                    const StringMap &objectData, const StringMapList &works,
                                    const StringMap &options) const
{
    QString html = QStringLiteral("<html><head><meta charset=\"utf-8\"/>");
    if(!m_fontPath.isEmpty())
    {
        html += QStringLiteral("<style>@font-face { font-family: '%1'; src: url('%2'); }"
                               "body, table { font-family: '%1', sans-serif; font-size: 10pt; }</style>")
            .arg(escapeHtml(m_fontFamily), QUrl::fromLocalFile(m_fontPath).toString());
    }
    html += QStringLiteral("</head><body>");

    if(optionEnabled(options, "include_report_header"))
    {
        QString headerText = options.value("report_header_text").toString().trimmed();
        if(headerText.isEmpty())
            headerText = QStringLiteral("ОТЧЁТ О ПРОДЕЛАННЫХ РАБОТАХ");

        for(const QString &line : headerText.split('\n'))
            html += QStringLiteral("<h2 style=\"text-align:center;\">%1</h2>").arg(escapeHtml(line));

        html += QStringLiteral("<hr/>");
    }

    if(optionEnabled(options, "include_report_date"))
    {
        html += QStringLiteral("<p>Дата формирования: %1</p>")
            .arg(escapeHtml(QDateTime::currentDateTime().toString("dd.MM.yyyy HH:mm")));
    }

    if(optionEnabled(options, "include_personal_info")
        || optionEnabled(options, "include_client_name")
        || optionEnabled(options, "include_client_address"))
    {
        html += QStringLiteral("<table width=\"100%\"><tr><td valign=\"top\" width=\"50%\">");
        if(optionEnabled(options, "include_personal_info"))
        {
            html += QStringLiteral("<h3>Исполнитель:</h3><p>%1</p>")
                .arg(escapeHtml(personalInfo.trimmed().isEmpty() ? QStringLiteral("—") : personalInfo.trimmed()));
        }
        html += QStringLiteral("</td><td valign=\"top\" width=\"50%\">");
        if(optionEnabled(options, "include_client_name") || optionEnabled(options, "include_client_address"))
        {
            html += QStringLiteral("<h3>Заказчик:</h3>");
            if(optionEnabled(options, "include_client_name"))
                html += QStringLiteral("<p>%1</p>").arg(escapeHtml(client.value("name").toString()));
            if(optionEnabled(options, "include_client_address"))
            {
                QString address = objectData.value("address").toString();
                if(address.isEmpty())
                    address = client.value("address").toString();
                if(!address.isEmpty())
                    html += QStringLiteral("<p>Адрес: %1</p>").arg(escapeHtml(address));
                const QString objectName = objectData.value("name").toString();
                if(!objectName.isEmpty())
                    html += QStringLiteral("<p>Объект: %1</p>").arg(escapeHtml(objectName));
            }
        }
        html += QStringLiteral("</td></tr></table>");
    }

    html += QStringLiteral("<h3>Перечень работ</h3>");

    if(works.isEmpty())
    {
        html += QStringLiteral("<p>Нет записей о выполненных работах.</p>");
    }
    else
    {
        auto appendTable = [&](const StringMapList &rows, bool includeTotal)
        {
            double total = 0.0;
            html += QStringLiteral("<table border=\"1\" cellspacing=\"0\" cellpadding=\"4\" width=\"100%\">");
            html += QStringLiteral("<tr><th>Работа</th><th>Кол-во</th><th>Ед.</th><th>Цена</th><th>Сумма</th></tr>");

            QMap<QString, StringMap> merged;
            QStringList order;
            for(const QVariant &item : rows)
            {
                const StringMap work = item.toMap();
                const QString key = work.value("name").toString() + '|' + work.value("price").toString();
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
                const double lineTotal = price * quantity;
                total += lineTotal;

                html += QStringLiteral("<tr><td>%1</td><td align=\"right\">%2</td><td align=\"center\">%3</td>"
                                       "<td align=\"right\">%4</td><td align=\"right\">%5</td></tr>")
                    .arg(escapeHtml(work.value("name").toString()))
                    .arg(quantity, 0, 'g', 12)
                    .arg(escapeHtml(work.value("unit").toString()))
                    .arg(formatMoney(price))
                    .arg(formatMoney(lineTotal));
            }

            if(includeTotal)
            {
                html += QStringLiteral("<tr><td colspan=\"4\" align=\"right\"><b>Итого:</b></td>"
                                       "<td align=\"right\"><b>%1</b></td></tr>").arg(formatMoney(total));
            }

            html += QStringLiteral("</table>");
            return total;
        };

        double grandTotal = 0.0;
        if(optionEnabled(options, "group_by_subobjects"))
        {
            QMap<QString, StringMapList> groups;
            for(const QVariant &item : works)
            {
                const StringMap work = item.toMap();
                QString key = work.value("subobject_name").toString().trimmed();
                groups[key].append(work);
            }

            QStringList keys = groups.keys();
            std::sort(keys.begin(), keys.end(), [](const QString &a, const QString &b)
            {
                return a.compare(b, Qt::CaseInsensitive) < 0;
            });

            for(const QString &subobjectName : keys)
            {
                if(!subobjectName.isEmpty())
                    html += QStringLiteral("<h4>%1:</h4>").arg(escapeHtml(subobjectName));
                grandTotal += appendTable(groups.value(subobjectName), false);
            }

            html += QStringLiteral("<p align=\"right\"><b>Итого: %1</b></p>").arg(formatMoney(grandTotal));
        }
        else
        {
            appendTable(works, true);
        }
    }

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
        target = QFileInfo(filePath).absoluteFilePath();
    }
    else
    {
        const QString stamp = QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");
        target = QDir(reportsDir).filePath(QStringLiteral("report_%1_%2.pdf").arg(safeClientName(client), stamp));
    }

    QDir().mkpath(QFileInfo(target).absolutePath());
    QFile file(target);
    if(file.open(QIODevice::WriteOnly))
        file.write(pdfBytes);

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
