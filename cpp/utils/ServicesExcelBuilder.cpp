#include "ServicesExcelBuilder.h"

#include "CoefficientsDatabase.h"
#include "FileIo.h"
#include "ServiceUnits.h"
#include "ServicesDatabase.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QUrl>
#include <QXmlStreamReader>
#include <QXmlStreamWriter>

#include <algorithm>
#include <cmath>
#include <stdexcept>

#include "MinimalZip.h"

namespace workorder
{

namespace
{

// Section title separating coefficients from services inside the sheet.
const QString kCoefficientsSectionTitle = QStringLiteral("Коэффициенты");
// Tolerated legacy misspelling of the same section.
const QString kCoefficientsSectionTitleAlt = QStringLiteral("Коэфициенты");

const double kBaseColWidth = 15.0;
const double kExportCol1Width = kBaseColWidth * 4.0;
const double kExportCol2Width = kBaseColWidth * 2.0;

QString cellText(const QVariant &value)
{
    if(!value.isValid() || value.isNull())
        return QString();
    return value.toString().trimmed();
}

QString normalizePriceText(const QVariant &value)
{
    if(!value.isValid() || value.typeId() == QMetaType::Bool)
        return QString();

    if(value.typeId() == QMetaType::Int)
        return QString::number(value.toInt());

    if(value.typeId() == QMetaType::Double)
    {
        const double number = value.toDouble();
        if(qFuzzyCompare(number, std::round(number)))
            return QString::number(static_cast<qint64>(std::round(number)));
        QString text = QString::number(number, 'f', 10);
        while(text.endsWith('0'))
            text.chop(1);
        if(text.endsWith('.'))
            text.chop(1);
        return text.replace(',', '.');
    }

    const QString text = value.toString().trimmed().replace(',', '.');
    return text;
}

QString priceForDb(int cents)
{
    return QString::number(cents / 100.0, 'f', 2);
}

QVariant priceForExcel(int cents)
{
    if(cents % 100 == 0)
        return cents / 100;
    return cents / 100.0;
}

using ParagraphGroup = QPair<QString, StringMapList>;

QVector<ParagraphGroup> groupServicesByParagraph(const StringMapList &services)
{
    QMap<QString, StringMapList> grouped;
    for(const QVariant &item : services)
    {
        const StringMap service = item.toMap();
        const QString paragraph = service.value("paragraph").toString().trimmed();
        grouped[paragraph].append(service);
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

QString xmlEscape(const QString &value)
{
    QString text = value;
    text.replace('&', "&amp;");
    text.replace('<', "&lt;");
    text.replace('>', "&gt;");
    text.replace('"', "&quot;");
    return text;
}

QString columnName(int index)
{
    QString result;
    int value = index;
    while(value > 0)
    {
        const int rem = (value - 1) % 26;
        result.prepend(QChar('A' + rem));
        value = (value - 1) / 26;
    }
    return result;
}

QStringList readSharedStrings(const QByteArray &sharedStringsXml)
{
    QStringList strings;
    QXmlStreamReader reader(sharedStringsXml);
    while(!reader.atEnd())
    {
        reader.readNext();
        if(reader.isStartElement() && reader.name() == QLatin1String("t"))
            strings.append(reader.readElementText());
    }
    return strings;
}

ExcelCatalog readSheetRows(const QByteArray &sheetXml, const QStringList &sharedStrings)
{
    ExcelCatalog catalog;
    QString currentParagraph;
    bool inCoefficientsSection = false;
    QXmlStreamReader reader(sheetXml);

    QStringList rowCells(4);
    while(!reader.atEnd())
    {
        reader.readNext();
        if(reader.isStartElement() && reader.name() == QLatin1String("row"))
        {
            rowCells = QStringList({QString(), QString(), QString(), QString()});
        }
        else if(reader.isStartElement() && reader.name() == QLatin1String("c"))
        {
            const QString ref = reader.attributes().value("r").toString();
            const QChar columnChar = ref.isEmpty() ? QChar() : ref.at(0);
            const int column = columnChar.isNull() ? -1 : columnChar.toLatin1() - 'A';
            const QString cellType = reader.attributes().value("t").toString();

            QString value;
            while(!(reader.isEndElement() && reader.name() == QLatin1String("c")))
            {
                reader.readNext();
                if(reader.isStartElement() && reader.name() == QLatin1String("v"))
                    value = reader.readElementText();
                else if(reader.isStartElement() && reader.name() == QLatin1String("t"))
                    value = reader.readElementText();
            }

            if(column >= 0 && column < rowCells.size())
            {
                if(cellType == QLatin1String("s"))
                {
                    bool ok = false;
                    const int index = value.toInt(&ok);
                    rowCells[column] = ok ? sharedStrings.value(index) : value;
                }
                else
                {
                    rowCells[column] = value;
                }
            }
        }
        else if(reader.isEndElement() && reader.name() == QLatin1String("row"))
        {
            if(rowCells.at(0).isEmpty() && rowCells.at(1).isEmpty()
                && rowCells.at(2).isEmpty() && rowCells.at(3).isEmpty())
            {
                continue;
            }

            const int priceCents = ServicesExcelBuilder::parseExcelPrice(rowCells.at(2));
            if(priceCents < 0)
            {
                const QString paragraphText = !rowCells.at(0).isEmpty() ? rowCells.at(0) : rowCells.at(1);
                if(!paragraphText.isEmpty())
                {
                    inCoefficientsSection = ServicesExcelBuilder::isCoefficientsSection(paragraphText);
                    currentParagraph = inCoefficientsSection ? QString() : paragraphText;
                }
                continue;
            }

            if(rowCells.at(0).isEmpty())
                continue;

            const QString unit = rowCells.at(3).trimmed();
            // Percent rows are coefficients even in workbooks without the section.
            if(inCoefficientsSection || ServiceUnits::isPercentUnit(unit))
            {
                StringMap coefficient;
                coefficient.insert("name", rowCells.at(0));
                coefficient.insert("keywords", rowCells.at(1));
                coefficient.insert("price", priceForDb(priceCents));
                coefficient.insert("unit", unit.isEmpty() ? QStringLiteral("%") : unit);
                catalog.coefficients.append(coefficient);
                continue;
            }

            StringMap service;
            service.insert("name", rowCells.at(0));
            service.insert("note", rowCells.at(1));
            service.insert("paragraph", currentParagraph);
            service.insert("price", priceForDb(priceCents));
            service.insert("unit", unit);
            catalog.services.append(service);
        }
    }

    return catalog;
}

void writeRow(QXmlStreamWriter &writer, int rowNum, const QStringList &values)
{
    writer.writeStartElement("row");
    writer.writeAttribute("r", QString::number(rowNum));

    for(int col = 0; col < values.size(); ++col)
    {
        writer.writeStartElement("c");
        writer.writeAttribute("r", QString("%1%2").arg(columnName(col + 1), QString::number(rowNum)));
        if(col == 2 && !values.at(col).isEmpty())
        {
            writer.writeStartElement("v");
            writer.writeCharacters(values.at(col));
            writer.writeEndElement();
        }
        else if(!values.at(col).isEmpty())
        {
            writer.writeAttribute("t", "inlineStr");
            writer.writeStartElement("is");
            writer.writeTextElement("t", values.at(col));
            writer.writeEndElement();
        }
        writer.writeEndElement();
    }

    writer.writeEndElement();
}

void writeSectionTitle(QXmlStreamWriter &writer, int rowNum, const QString &title)
{
    writer.writeStartElement("row");
    writer.writeAttribute("r", QString::number(rowNum));
    writer.writeStartElement("c");
    writer.writeAttribute("r", QString("%1%2").arg(columnName(1), QString::number(rowNum)));
    writer.writeAttribute("t", "inlineStr");
    writer.writeStartElement("is");
    writer.writeTextElement("t", title);
    writer.writeEndElement();
    writer.writeEndElement();
    writer.writeEndElement();
}

QString buildSheetXml(const ExcelCatalog &catalog)
{
    QString xml;
    QXmlStreamWriter writer(&xml);
    writer.setAutoFormatting(true);
    writer.writeStartDocument();
    writer.writeStartElement("worksheet");
    writer.writeDefaultNamespace("http://schemas.openxmlformats.org/spreadsheetml/2006/main");
    writer.writeStartElement("cols");
    writer.writeEmptyElement("col");
    writer.writeAttribute("min", "1");
    writer.writeAttribute("max", "1");
    writer.writeAttribute("width", QString::number(kExportCol1Width));
    writer.writeAttribute("customWidth", "1");
    writer.writeEmptyElement("col");
    writer.writeAttribute("min", "2");
    writer.writeAttribute("max", "2");
    writer.writeAttribute("width", QString::number(kExportCol2Width));
    writer.writeAttribute("customWidth", "1");
    writer.writeEndElement();

    writer.writeStartElement("sheetData");
    int rowNum = 1;
    for(const ParagraphGroup &group : groupServicesByParagraph(catalog.services))
    {
        if(!group.first.isEmpty())
        {
            writeSectionTitle(writer, rowNum, group.first);
            ++rowNum;
        }

        for(const QVariant &item : group.second)
        {
            const StringMap service = item.toMap();
            const QString name = service.value("name").toString().trimmed();
            if(name.isEmpty())
                continue;

            writeRow(writer, rowNum, {
                name,
                service.value("note").toString().trimmed(),
                priceForExcel(service.value("price").toInt()).toString(),
                service.value("unit").toString().trimmed(),
            });
            ++rowNum;
        }
    }

    // Coefficients always form their own section at the end of the sheet.
    if(!catalog.coefficients.isEmpty())
    {
        writeSectionTitle(writer, rowNum, kCoefficientsSectionTitle);
        ++rowNum;

        for(const QVariant &item : catalog.coefficients)
        {
            const StringMap coefficient = item.toMap();
            const QString name = coefficient.value("name").toString().trimmed();
            if(name.isEmpty())
                continue;

            writeRow(writer, rowNum, {
                name,
                coefficient.value("keywords").toString().trimmed(),
                priceForExcel(coefficient.value("price").toInt()).toString(),
                QStringLiteral("%"),
            });
            ++rowNum;
        }
    }

    writer.writeEndElement();
    writer.writeEndElement();
    writer.writeEndDocument();
    return xml;
}

QByteArray buildWorkbookXml()
{
    return QByteArray(
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        "<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" "
        "xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">"
        "<sheets><sheet name=\"Services\" sheetId=\"1\" r:id=\"rId1\"/></sheets>"
        "</workbook>");
}

} // namespace

QString ServicesExcelBuilder::resolveExcelPath(const QString &fileUrl, bool ensureExtension)
{
    QString value = fileUrl.trimmed();
    if(value.isEmpty())
        return QString();

    if(FileIo::isContentUri(value))
        return value;

    QString path;
    if(value.startsWith("file:", Qt::CaseInsensitive))
        path = QUrl(value).toLocalFile();
    else
        path = value;

    if(ensureExtension && !path.endsWith(".xlsx", Qt::CaseInsensitive))
        path += ".xlsx";

    return path;
}

int ServicesExcelBuilder::parseExcelPrice(const QVariant &value)
{
    const QString text = normalizePriceText(value);
    if(text.isEmpty())
        return -1;

    if(!text.contains('.'))
    {
        bool ok = false;
        const qlonglong whole = text.toLongLong(&ok);
        return ok ? static_cast<int>(whole * 100) : -1;
    }

    const QStringList parts = text.split('.');
    if(parts.size() != 2)
        return -1;

    bool wholeOk = false;
    bool fractionOk = false;
    const qlonglong whole = parts.at(0).isEmpty() ? 0 : parts.at(0).toLongLong(&wholeOk);
    QString fraction = parts.at(1);
    fraction = (fraction + "00").left(2);
    const int fractionValue = fraction.toInt(&fractionOk);
    if(!wholeOk || !fractionOk)
        return -1;

    return static_cast<int>(whole * 100 + fractionValue);
}

QString ServicesExcelBuilder::coefficientsSectionTitle()
{
    return kCoefficientsSectionTitle;
}

bool ServicesExcelBuilder::isCoefficientsSection(const QString &title)
{
    const QString value = title.trimmed();
    return value.compare(kCoefficientsSectionTitle, Qt::CaseInsensitive) == 0
        || value.compare(kCoefficientsSectionTitleAlt, Qt::CaseInsensitive) == 0
        || value.compare(QStringLiteral("Coefficients"), Qt::CaseInsensitive) == 0;
}

ExcelCatalog ServicesExcelBuilder::readCatalog(const QString &filePath)
{
    QString error;
    const QByteArray data = FileIo::readBytes(filePath, &error);
    if(data.isEmpty())
        throw std::runtime_error(QString("Failed to open services import file: %1 (%2)")
                                     .arg(filePath, error)
                                     .toStdString());

    MinimalZipReader zip(data);
    if(!zip.isValid())
        throw std::runtime_error("Invalid XLSX archive");

    const QStringList sharedStrings = readSharedStrings(zip.fileContent("xl/sharedStrings.xml"));
    const QByteArray sheetXml = zip.fileContent("xl/worksheets/sheet1.xml");
    if(sheetXml.isEmpty())
        throw std::runtime_error("Worksheet sheet1.xml not found in XLSX");

    return readSheetRows(sheetXml, sharedStrings);
}

QString ServicesExcelBuilder::writeExport(const QString &filePath, const ExcelCatalog &catalog)
{
    const QByteArray contentTypes =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
        "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>"
        "<Default Extension=\"xml\" ContentType=\"application/xml\"/>"
        "<Override PartName=\"/xl/workbook.xml\" "
        "ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>"
        "<Override PartName=\"/xl/worksheets/sheet1.xml\" "
        "ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
        "</Types>";

    const QByteArray rootRels =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
        "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" "
        "Target=\"xl/workbook.xml\"/>"
        "</Relationships>";

    const QByteArray workbookRels =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
        "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" "
        "Target=\"worksheets/sheet1.xml\"/>"
        "</Relationships>";

    MinimalZipWriter zip;
    zip.addFile("[Content_Types].xml", contentTypes);
    zip.addFile("_rels/.rels", rootRels);
    zip.addFile("xl/workbook.xml", buildWorkbookXml());
    zip.addFile("xl/_rels/workbook.xml.rels", workbookRels);
    zip.addFile("xl/worksheets/sheet1.xml", buildSheetXml(catalog).toUtf8());

    QString error;
    if(!FileIo::writeBytes(filePath, zip.writeToBytes(), &error))
        throw std::runtime_error(QString("Failed to write services export file: %1 (%2)")
                                     .arg(filePath, error)
                                     .toStdString());

    return FileIo::nativeTarget(filePath);
}

ExcelCatalog importCatalogFromExcel(const QString &fileUrl)
{
    const QString path = ServicesExcelBuilder::resolveExcelPath(fileUrl);
    if(path.isEmpty())
        throw std::runtime_error("Services import path is empty");
    return ServicesExcelBuilder().readCatalog(path);
}

QString exportCatalogExcel(const QString &fileUrl, const ExcelCatalog &catalog)
{
    const QString path = ServicesExcelBuilder::resolveExcelPath(fileUrl, true);
    if(path.isEmpty())
        throw std::runtime_error("Services export path is empty");

    ExcelCatalog data = catalog;
    // Only an entirely empty request falls back to the databases, so an explicit
    // catalog is never mixed with unrelated stored rows.
    if(data.services.isEmpty() && data.coefficients.isEmpty())
    {
        data.services = ServicesDatabase::loadServices();
        data.coefficients = CoefficientsDatabase::loadCoefficients();
    }

    return ServicesExcelBuilder().writeExport(path, data);
}

} // namespace workorder
