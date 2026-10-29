#include "YandexAuth.h"

#import "WorkOrder-Swift.h"

namespace workorder
{

void yandexLogin(const QString &clientId,
                 std::function<void(const QString &token, const QString &error)> completion)
{
    [[WorkOrderYandexAuth shared] authorizeWithClientId:clientId.toNSString()
                                             completion:^(NSString *token, NSString *error)
    {
        if(!completion)
            return;
        completion(token ? QString::fromNSString(token) : QString(),
                   error ? QString::fromNSString(error) : QString());
    }];
}

void yandexCancel()
{
    [[WorkOrderYandexAuth shared] cancel];
}

void yandexLogout()
{
    [[WorkOrderYandexAuth shared] logout];
}

} // namespace workorder
