#ifndef WORKORDER_UTILS_FILE_IO_H
#define WORKORDER_UTILS_FILE_IO_H

#include <QByteArray>
#include <QString>

namespace workorder
{

// Helpers for local file:// paths and Android SAF content:// URIs.
class FileIo
{
public:
    static bool isContentUri(const QString &pathOrUrl);
    // Returns a QFile-compatible name: local filesystem path or content:// URI.
    static QString nativeTarget(const QString &pathOrUrl);
    static bool writeBytes(const QString &pathOrUrl, const QByteArray &data, QString *errorOut = nullptr);
    static QByteArray readBytes(const QString &pathOrUrl, QString *errorOut = nullptr);
};

} // namespace workorder

#endif // WORKORDER_UTILS_FILE_IO_H
