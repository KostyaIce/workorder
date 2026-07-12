#ifndef WORKORDER_UTILS_MINIMAL_ZIP_H
#define WORKORDER_UTILS_MINIMAL_ZIP_H

#include <QByteArray>
#include <QString>
#include <QVector>

namespace workorder
{

class MinimalZipWriter
{
public:
    void addFile(const QString &name, const QByteArray &content);
    bool writeToFile(const QString &path) const;
    QByteArray writeToBytes() const;

private:
    struct Entry
    {
        QString name;
        QByteArray content;
    };

    QVector<Entry> m_entries;
};

class MinimalZipReader
{
public:
    explicit MinimalZipReader(const QByteArray &data);

    bool isValid() const;
    QStringList fileNames() const;
    QByteArray fileContent(const QString &name) const;

private:
    struct Entry
    {
        QString name;
        quint32 localHeaderOffset = 0;
    };

    QByteArray m_data;
    QVector<Entry> m_entries;
    bool m_valid = false;
};

} // namespace workorder

#endif // WORKORDER_UTILS_MINIMAL_ZIP_H
