#include "ReportShare.h"

#include <QString>

#import <UIKit/UIKit.h>

namespace workorder
{

namespace
{

UIViewController *topViewController()
{
    UIViewController *controller = nil;
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)
    {
        if(![scene isKindOfClass:[UIWindowScene class]])
            continue;
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for(UIWindow *window in windowScene.windows)
        {
            if(window.isKeyWindow && window.rootViewController != nil)
                controller = window.rootViewController;
        }
    }
    while(controller.presentedViewController != nil)
        controller = controller.presentedViewController;
    return controller;
}

void presentShare(NSString *path)
{
    UIViewController *controller = topViewController();
    if(controller == nil)
        return;

    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    UIActivityViewController *activity = [[UIActivityViewController alloc]
        initWithActivityItems:@[fileUrl]
        applicationActivities:nil];
    UIPopoverPresentationController *popover = activity.popoverPresentationController;
    if(popover != nil)
    {
        popover.sourceView = controller.view;
        popover.sourceRect = CGRectMake(CGRectGetMidX(controller.view.bounds),
                                        CGRectGetMaxY(controller.view.bounds) - 1,
                                        1,
                                        1);
    }
    [controller presentViewController:activity animated:YES completion:nil];
}

} // namespace

bool shareReportOnIos(const QString &path)
{
    NSString *nativePath = path.toNSString();
    if(nativePath.length == 0)
        return false;

    dispatch_async(dispatch_get_main_queue(), ^{
        presentShare(nativePath);
    });
    return true;
}

} // namespace workorder
