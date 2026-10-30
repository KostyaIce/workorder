#include "ContactPicker.h"

#if defined(Q_OS_IOS)
#include "../ios/ContactPicker.h"
#include <QPointer>
#elif defined(Q_OS_ANDROID)
#include <QCoreApplication>
#include <QJniEnvironment>
#include <QJniObject>
#include <QPermissions>
#endif

namespace workorder
{

#if defined(Q_OS_ANDROID)
namespace
{
constexpr jint kContactRequestCode = 0x574f;
}
#endif

ContactPicker::ContactPicker(QObject *parent)
    : QObject(parent)
{
#if defined(Q_OS_ANDROID)
    QtAndroidPrivate::registerActivityResultListener(this);
#endif
}

ContactPicker::~ContactPicker()
{
#if defined(Q_OS_ANDROID)
    QtAndroidPrivate::unregisterActivityResultListener(this);
#endif
}

bool ContactPicker::available() const
{
#if defined(Q_OS_IOS) || defined(Q_OS_ANDROID)
    return true;
#else
    return false;
#endif
}

void ContactPicker::pickContact()
{
#if defined(Q_OS_IOS)
    QPointer<ContactPicker> self(this);
    pickPhoneContact([self](bool picked, const QString &name, const QString &phone,
                            const QString &error)
    {
        if(!self)
            return;
        if(picked)
            emit self->contactPicked(name, phone);
        else if(!error.isEmpty())
            emit self->pickFailed(error);
        else
            emit self->pickCancelled();
    });
#elif defined(Q_OS_ANDROID)
    const QContactsPermission permission;
    if(qApp->checkPermission(permission) == Qt::PermissionStatus::Granted)
    {
        launchAndroidPicker();
        return;
    }

    qApp->requestPermission(permission, this, [this](const QPermission &result)
    {
        if(result.status() == Qt::PermissionStatus::Granted)
            launchAndroidPicker();
        else
            emit pickFailed(tr("Нет доступа к контактам телефона"));
    });
#else
    emit pickFailed(tr("Выбор контактов доступен только на мобильном устройстве"));
#endif
}

#if defined(Q_OS_ANDROID)
void ContactPicker::launchAndroidPicker()
{
    QJniObject activity = QtAndroidPrivate::activity();
    if(!activity.isValid())
    {
        emit pickFailed(tr("Не удалось открыть контакты"));
        return;
    }

    QJniObject::callStaticMethod<void>(
        "com/workorder/ContactPickerHelper",
        "pick",
        "(Landroid/app/Activity;)V",
        activity.object<jobject>());
}

bool ContactPicker::handleActivityResult(jint requestCode, jint resultCode, jobject data)
{
    if(requestCode != kContactRequestCode)
        return false;

    if(resultCode != -1 || data == nullptr)
    {
        emit pickCancelled();
        return true;
    }

    QJniObject activity = QtAndroidPrivate::activity();
    QJniObject result = QJniObject::callStaticObjectMethod(
        "com/workorder/ContactPickerHelper",
        "selectedContact",
        "(Landroid/app/Activity;Landroid/content/Intent;)[Ljava/lang/String;",
        activity.object<jobject>(),
        data);
    if(!result.isValid())
    {
        emit pickFailed(tr("Не удалось прочитать выбранный контакт"));
        return true;
    }

    jobjectArray values = static_cast<jobjectArray>(result.object());
    QJniEnvironment env;
    if(env->GetArrayLength(values) < 2)
    {
        emit pickFailed(tr("В контакте нет номера телефона"));
        return true;
    }

    jstring nameValue = static_cast<jstring>(env->GetObjectArrayElement(values, 0));
    jstring phoneValue = static_cast<jstring>(env->GetObjectArrayElement(values, 1));
    const char *nameChars = nameValue ? env->GetStringUTFChars(nameValue, nullptr) : nullptr;
    const char *phoneChars = phoneValue ? env->GetStringUTFChars(phoneValue, nullptr) : nullptr;
    const QString name = nameChars ? QString::fromUtf8(nameChars) : QString();
    const QString phone = phoneChars ? QString::fromUtf8(phoneChars) : QString();
    if(nameChars)
        env->ReleaseStringUTFChars(nameValue, nameChars);
    if(phoneChars)
        env->ReleaseStringUTFChars(phoneValue, phoneChars);
    if(nameValue)
        env->DeleteLocalRef(nameValue);
    if(phoneValue)
        env->DeleteLocalRef(phoneValue);

    if(phone.trimmed().isEmpty())
    {
        emit pickFailed(tr("В контакте нет номера телефона"));
        return true;
    }

    emit contactPicked(name.trimmed(), phone.trimmed());
    return true;
}
#endif

} // namespace workorder
