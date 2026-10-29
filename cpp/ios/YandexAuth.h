#ifndef WORKORDER_IOS_YANDEX_AUTH_H
#define WORKORDER_IOS_YANDEX_AUTH_H

#include <QString>

#include <functional>

namespace workorder
{

void yandexLogin(const QString &clientId,
                 std::function<void(const QString &token, const QString &error)> completion);
void yandexCancel();
void yandexLogout();

} // namespace workorder

#endif // WORKORDER_IOS_YANDEX_AUTH_H
