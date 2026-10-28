#include "ReportShare.h"

#include <QFileInfo>

#if defined(Q_OS_ANDROID)
#include <QJniObject>
#include <QtCore/qcoreapplication_platform.h>
#endif

namespace workorder
{

#if defined(Q_OS_IOS)
bool shareReportOnIos(const QString &path);
#endif

QString ReportShare::publish(const QString &savedPath)
{
    const QFileInfo info(savedPath);
    if(!info.exists() || !info.isFile())
        return {};

#if defined(Q_OS_IOS)
    if(!shareReportOnIos(savedPath))
        return {};
    return QStringLiteral("Документы");
#elif defined(Q_OS_ANDROID)
    const QJniObject context = QNativeInterface::QAndroidApplication::context();
    if(!context.isValid())
        return {};

    const QJniObject place = QJniObject::callStaticObjectMethod(
        "com/workorder/ReportExport",
        "publishAndShare",
        "(Landroid/content/Context;Ljava/lang/String;)Ljava/lang/String;",
        context.object(),
        QJniObject::fromString(savedPath).object<jstring>());
    if(!place.isValid())
        return {};
    return place.toString();
#else
    return {};
#endif
}

} // namespace workorder
