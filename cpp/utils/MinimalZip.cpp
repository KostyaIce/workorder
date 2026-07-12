#include "MinimalZip.h"

#include <QDataStream>
#include <QFile>
#include <QFileInfo>
#include <QtEndian>

namespace workorder
{

namespace
{

quint32 crc32For(const QByteArray &data)
{
    static quint32 table[256];
    static bool initialized = false;
    if(!initialized)
    {
        for(quint32 i = 0; i < 256; ++i)
        {
            quint32 crc = i;
            for(int j = 0; j < 8; ++j)
                crc = (crc & 1) ? (0xEDB88320u ^ (crc >> 1)) : (crc >> 1);
            table[i] = crc;
        }
        initialized = true;
    }

    quint32 crc = 0xFFFFFFFFu;
    for(unsigned char ch : data)
        crc = table[(crc ^ ch) & 0xFFu] ^ (crc >> 8);
    return crc ^ 0xFFFFFFFFu;
}

QByteArray utf8FileName(const QString &name)
{
    return name.toUtf8();
}

} // namespace

void MinimalZipWriter::addFile(const QString &name, const QByteArray &content)
{
    m_entries.append({name, content});
}

QByteArray MinimalZipWriter::writeToBytes() const
{
    QByteArray output;
    QDataStream stream(&output, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);

    QVector<quint32> localOffsets;
    localOffsets.reserve(m_entries.size());

    for(const Entry &entry : m_entries)
    {
        localOffsets.append(static_cast<quint32>(output.size()));
        const QByteArray nameBytes = utf8FileName(entry.name);
        const quint32 crc = crc32For(entry.content);
        const quint32 size = static_cast<quint32>(entry.content.size());

        stream << quint32(0x04034b50);
        stream << quint16(20);
        stream << quint16(0);
        stream << quint16(0);
        stream << quint16(0);
        stream << quint16(0);
        stream << crc;
        stream << size;
        stream << size;
        stream << quint16(nameBytes.size());
        stream << quint16(0);
        stream.writeRawData(nameBytes.constData(), nameBytes.size());
        stream.writeRawData(entry.content.constData(), entry.content.size());
    }

    const quint32 centralDirOffset = static_cast<quint32>(output.size());
    for(int i = 0; i < m_entries.size(); ++i)
    {
        const Entry &entry = m_entries.at(i);
        const QByteArray nameBytes = utf8FileName(entry.name);
        const quint32 crc = crc32For(entry.content);
        const quint32 size = static_cast<quint32>(entry.content.size());

        stream << quint32(0x02014b50);
        stream << quint16(20);
        stream << quint16(20);
        stream << quint16(0);
        stream << quint16(0);
        stream << quint16(0);
        stream << quint16(0);
        stream << crc;
        stream << size;
        stream << size;
        stream << quint16(nameBytes.size());
        stream << quint16(0);
        stream << quint16(0);
        stream << quint16(0);
        stream << quint16(0);
        stream << quint32(0);
        stream << localOffsets.at(i);
        stream.writeRawData(nameBytes.constData(), nameBytes.size());
    }

    const quint32 centralDirSize = static_cast<quint32>(output.size() - centralDirOffset);
    stream << quint32(0x06054b50);
    stream << quint16(0);
    stream << quint16(0);
    stream << quint16(m_entries.size());
    stream << quint16(m_entries.size());
    stream << centralDirSize;
    stream << centralDirOffset;
    stream << quint16(0);

    return output;
}

bool MinimalZipWriter::writeToFile(const QString &path) const
{
    QFile file(path);
    if(!file.open(QIODevice::WriteOnly))
        return false;
    return file.write(writeToBytes()) >= 0;
}

MinimalZipReader::MinimalZipReader(const QByteArray &data)
    : m_data(data)
{
    if(data.size() < 22)
        return;

    int pos = 0;
    while(pos + 30 <= data.size())
    {
        const quint32 signature = qFromLittleEndian<quint32>(reinterpret_cast<const uchar *>(data.constData() + pos));
        if(signature != 0x04034b50)
            break;

        const quint16 nameLength = qFromLittleEndian<quint16>(reinterpret_cast<const uchar *>(data.constData() + pos + 26));
        const quint16 extraLength = qFromLittleEndian<quint16>(reinterpret_cast<const uchar *>(data.constData() + pos + 28));
        if(pos + 30 + nameLength > data.size())
            break;

        const QString name = QString::fromUtf8(data.constData() + pos + 30, nameLength);
        m_entries.append({name, static_cast<quint32>(pos)});
        pos += 30 + nameLength + extraLength;

        const quint32 compressedSize = qFromLittleEndian<quint32>(reinterpret_cast<const uchar *>(data.constData() + m_entries.last().localHeaderOffset + 18));
        pos += compressedSize;
    }

    m_valid = !m_entries.isEmpty();
}

bool MinimalZipReader::isValid() const
{
    return m_valid;
}

QStringList MinimalZipReader::fileNames() const
{
    QStringList names;
    for(const Entry &entry : m_entries)
        names.append(entry.name);
    return names;
}

QByteArray MinimalZipReader::fileContent(const QString &name) const
{
    for(const Entry &entry : m_entries)
    {
        if(entry.name != name)
            continue;

        const int pos = static_cast<int>(entry.localHeaderOffset);
        const quint16 nameLength = qFromLittleEndian<quint16>(reinterpret_cast<const uchar *>(m_data.constData() + pos + 26));
        const quint16 extraLength = qFromLittleEndian<quint16>(reinterpret_cast<const uchar *>(m_data.constData() + pos + 28));
        const quint32 compressedSize = qFromLittleEndian<quint32>(reinterpret_cast<const uchar *>(m_data.constData() + pos + 18));
        const int dataOffset = pos + 30 + nameLength + extraLength;
        if(dataOffset + static_cast<int>(compressedSize) > m_data.size())
            return {};
        return m_data.mid(dataOffset, static_cast<int>(compressedSize));
    }
    return {};
}

} // namespace workorder
