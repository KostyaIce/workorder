#ifndef WORKORDER_BACKEND_CONTACT_PICKER_H
#define WORKORDER_BACKEND_CONTACT_PICKER_H

#include <QObject>

#if defined(Q_OS_ANDROID)
#include <QtCore/private/qjnihelpers_p.h>
#endif

namespace workorder
{

class ContactPicker : public QObject
#if defined(Q_OS_ANDROID)
    , public QtAndroidPrivate::ActivityResultListener
#endif
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available CONSTANT)

public:
    explicit ContactPicker(QObject *parent = nullptr);
    ~ContactPicker() override;

    bool available() const;
    Q_INVOKABLE void pickContact();

signals:
    void contactPicked(const QString &name, const QString &phone);
    void pickCancelled();
    void pickFailed(const QString &message);

#if defined(Q_OS_ANDROID)
protected:
    bool handleActivityResult(jint requestCode, jint resultCode, jobject data) override;

private:
    void launchAndroidPicker();
#endif
};

} // namespace workorder

#endif // WORKORDER_BACKEND_CONTACT_PICKER_H
