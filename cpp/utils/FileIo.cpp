#include "FileIo.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QUrl>

namespace workorder
{

bool FileIo::isContentUri(const QString &pathOrUrl)
{
    return pathOrUrl.trimmed().startsWith(QLatin1String("content:"), Qt::CaseInsensitive);
}

QString FileIo::nativeTarget(const QString &pathOrUrl)
{
    const QString value = pathOrUrl.trimmed();
    if(value.isEmpty())
        return {};

    if(isContentUri(value))
        return value;

    if(value.startsWith(QLatin1String("file:"), Qt::CaseInsensitive))
        return QUrl(value).toLocalFile();

    return value;
}

bool FileIo::writeBytes(const QString &pathOrUrl, const QByteArray &data, QString *errorOut)
{
    const QString target = nativeTarget(pathOrUrl);
    if(target.isEmpty())
    {
        if(errorOut)
            *errorOut = QStringLiteral("Empty file path");
        return false;
    }

    // content:// documents are already created by SAF; do not mkpath / absoluteFilePath them.
    if(!isContentUri(target))
        QDir().mkpath(QFileInfo(target).absolutePath());

    QFile file(target);
    if(!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
    {
        const QString error = file.errorString();
        qWarning("FileIo::writeBytes open failed target=%s error=%s",
                 qPrintable(target),
                 qPrintable(error));
        if(errorOut)
            *errorOut = error;
        return false;
    }

    const qint64 written = file.write(data);
    file.close();
    if(written != data.size())
    {
        const QString error = QStringLiteral("Incomplete write (%1 of %2 bytes)")
                                  .arg(written)
                                  .arg(data.size());
        qWarning("FileIo::writeBytes %s target=%s",
                 qPrintable(error),
                 qPrintable(target));
        if(errorOut)
            *errorOut = error;
        return false;
    }

    qInfo("FileIo::writeBytes ok bytes=%d target=%s",
          static_cast<int>(data.size()),
          qPrintable(target));
    return true;
}

QByteArray FileIo::readBytes(const QString &pathOrUrl, QString *errorOut)
{
    const QString target = nativeTarget(pathOrUrl);
    if(target.isEmpty())
    {
        if(errorOut)
            *errorOut = QStringLiteral("Empty file path");
        return {};
    }

    QFile file(target);
    if(!file.open(QIODevice::ReadOnly))
    {
        const QString error = file.errorString();
        qWarning("FileIo::readBytes open failed target=%s error=%s",
                 qPrintable(target),
                 qPrintable(error));
        if(errorOut)
            *errorOut = error;
        return {};
    }

    const QByteArray data = file.readAll();
    file.close();
    return data;
}

} // namespace workorder
