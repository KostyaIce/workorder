#ifndef WORKORDER_IOS_CONTACT_PICKER_H
#define WORKORDER_IOS_CONTACT_PICKER_H

#include <QString>

#include <functional>

namespace workorder
{

using ContactPickerCallback =
    std::function<void(bool picked, const QString &name, const QString &phone,
                       const QString &error)>;

void pickPhoneContact(ContactPickerCallback completion);

} // namespace workorder

#endif // WORKORDER_IOS_CONTACT_PICKER_H
