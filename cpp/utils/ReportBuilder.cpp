#include "ReportBuilder.h"

#include "DatabaseStorage.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QMap>
#include <algorithm>

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
    safe.reserve(name.size());
    for(const QChar ch : name)
    {
        if(ch.isLetterOrNumber())
            safe.append(ch);
        else
            safe.append('_');
    }
    if(safe.isEmpty())
        safe = QStringLiteral("client");
    return safe;
}

} // namespace

QString ReportBuilder::formatMoney(double value)
{
    return QString::number(value, 'f', 2);
}

QPair<QString, double> ReportBuilder::workLine(const StringMap &work, bool includeCoefficients)
{
    const double price = work.value("price").toDouble() / 100.0;
    const double quantity = work.value("quantity", 1).toDouble();
    const int percentSum = work.value("percent_sum", 100).toInt();
    const double multiplier = percentSum / 100.0;
    const double displayPrice = includeCoefficients ? price : price * multiplier;
    const double total = price * quantity * multiplier;
    const QString unit = work.value("unit").toString();
    const QString unitSuffix = unit.isEmpty() ? QString() : QStringLiteral(" %1").arg(unit);

    QString name = work.value("name").toString();
    if(includeCoefficients)
    {
        const QString coefficients = work.value("coefficients").toString().trimmed();
        if(!coefficients.isEmpty())
            name += QStringLiteral(" (%1)").arg(coefficients);
    }

    QString line;
    if(includeCoefficients)
    {
        line = QStringLiteral("- %1: %2%3 x %4 x %5 = %6")
            .arg(name)
            .arg(quantity, 0, 'g', 12)
            .arg(unitSuffix)
            .arg(formatMoney(price))
            .arg(QString::number(multiplier, 'g', 12))
            .arg(formatMoney(total));
    }
    else
    {
        line = QStringLiteral("- %1: %2%3 x %4 = %5")
            .arg(name)
            .arg(quantity, 0, 'g', 12)
            .arg(unitSuffix)
            .arg(formatMoney(displayPrice))
            .arg(formatMoney(total));
    }
    return {line, total};
}

double ReportBuilder::appendWorkLines(QStringList &lines, const StringMapList &works, bool includeCoefficients)
{
    double total = 0.0;
    for(const QVariant &item : works)
    {
        const StringMap work = item.toMap();
        const QPair<QString, double> line = workLine(work, includeCoefficients);
        lines.append(line.first);
        total += line.second;
    }
    return total;
}

QString ReportBuilder::buildWorkReport(const QString &personalInfo, const StringMap &client,
                                       const StringMap &objectData, const StringMapList &works,
                                       const StringMap &options)
{
    QStringList lines;

    if(optionEnabled(options, "include_report_header"))
    {
        QString headerText = options.value("report_header_text").toString().trimmed();
        if(headerText.isEmpty())
            headerText = QStringLiteral("ОТЧЁТ О ПРОДЕЛАННЫХ РАБОТАХ");

        const QStringList headerLines = headerText.split('\n');
        if(headerLines.isEmpty())
            lines.append(headerText);
        else
            lines.append(headerLines);

        int separatorLen = 0;
        for(const QString &line : lines)
            separatorLen = qMax(separatorLen, line.size());
        lines.append(QString(separatorLen > 40 ? 40 : separatorLen, '='));
        lines.append(QString());
    }

    if(optionEnabled(options, "include_report_date"))
    {
        lines.append(QStringLiteral("Дата формирования: %1")
            .arg(QDateTime::currentDateTime().toString("dd.MM.yyyy HH:mm")));
        lines.append(QString());
    }

    if(optionEnabled(options, "include_personal_info"))
    {
        lines.append(QStringLiteral("Исполнитель:"));
        const QString info = personalInfo.trimmed();
        if(info.isEmpty())
        {
            lines.append(QStringLiteral("—"));
        }
        else
        {
            const QString normalized = QString(info).replace(QLatin1String("\r\n"), QLatin1String("\n"))
                                                    .replace(QLatin1Char('\r'), QLatin1Char('\n'));
            const QStringList infoLines = normalized.split(QLatin1Char('\n'));
            for(const QString &line : infoLines)
                lines.append(line);
        }
        lines.append(QString());
    }

    if(optionEnabled(options, "include_client_name"))
        lines.append(QStringLiteral("Заказчик: %1").arg(client.value("name").toString()));

    if(optionEnabled(options, "include_client_address"))
    {
        QString address = objectData.value("address").toString();
        if(address.isEmpty())
            address = client.value("address").toString();
        if(!address.isEmpty())
            lines.append(QStringLiteral("Адрес: %1").arg(address));

        const QString objectName = objectData.value("name").toString();
        if(!objectName.isEmpty())
            lines.append(QStringLiteral("Объект: %1").arg(objectName));
    }

    if(optionEnabled(options, "include_client_name") || optionEnabled(options, "include_client_address"))
        lines.append(QString());

    lines.append(QStringLiteral("Перечень работ:"));
    lines.append(QString(40, '-'));

    if(works.isEmpty())
    {
        lines.append(QStringLiteral("Нет записей о выполненных работах."));
    }
    else
    {
        double total = 0.0;
        const bool includeCoefficients = optionEnabled(options, "include_coefficients");
        if(optionEnabled(options, "group_by_subobjects"))
        {
            QMap<QString, StringMapList> groups;
            for(const QVariant &item : works)
            {
                const StringMap work = item.toMap();
                QString key = work.value("subobject_name").toString().trimmed();
                if(key.isEmpty())
                    key = QStringLiteral("Без субобъекта");
                groups[key].append(work);
            }

            QStringList keys = groups.keys();
            std::sort(keys.begin(), keys.end(), [](const QString &a, const QString &b)
            {
                return a.compare(b, Qt::CaseInsensitive) < 0;
            });

            for(const QString &subobjectName : keys)
            {
                lines.append(QString());
                lines.append(subobjectName + ':');
                total += appendWorkLines(lines, groups.value(subobjectName), includeCoefficients);
            }
        }
        else
        {
            lines.append(QString());
            int index = 1;
            for(const QVariant &item : works)
            {
                const StringMap work = item.toMap();
                const QPair<QString, double> line = workLine(work, includeCoefficients);
                lines.append(QStringLiteral("%1. %2").arg(index++).arg(line.first.mid(2)));
                total += line.second;
            }
        }

        lines.append(QString());
        lines.append(QStringLiteral("Итого: %1").arg(formatMoney(total)));
    }

    lines.append(QString());
    lines.append(QString(40, '='));
    return lines.join('\n');
}

QPair<QString, QString> ReportBuilder::saveWorkReport(const QString &personalInfo, const StringMap &client,
                                                        const StringMap &objectData, const StringMapList &works,
                                                        const StringMap &options, const QString &filePath)
{
    const QString content = buildWorkReport(personalInfo, client, objectData, works, options);
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
        target = QDir(reportsDir).filePath(QStringLiteral("report_%1_%2.txt").arg(safeClientName(client), stamp));
    }

    QDir().mkpath(QFileInfo(target).absolutePath());
    QFile file(target);
    if(file.open(QIODevice::WriteOnly | QIODevice::Text))
        file.write(content.toUtf8());

    return {target, content};
}

} // namespace workorder
