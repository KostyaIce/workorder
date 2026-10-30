#include "ContactPicker.h"

#import <ContactsUI/ContactsUI.h>
#import <UIKit/UIKit.h>

@interface WorkOrderContactPickerDelegate : NSObject <CNContactPickerDelegate>
@property(nonatomic, copy) void (^completion)(BOOL picked, NSString *name, NSString *phone, NSString *error);
@end

@implementation WorkOrderContactPickerDelegate

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact
{
    Q_UNUSED(picker);

    NSString *name = [CNContactFormatter stringFromContact:contact
                                                     style:CNContactFormatterStyleFullName];
    if(name.length == 0)
        name = contact.organizationName ?: @"";

    NSString *phone = @"";
    CNPhoneNumber *number = contact.phoneNumbers.firstObject.value;
    if(number != nil)
        phone = number.stringValue ?: @"";

    if(self.completion)
        self.completion(YES, name, phone, nil);
    self.completion = nil;
}

- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker
{
    Q_UNUSED(picker);
    if(self.completion)
        self.completion(NO, nil, nil, nil);
    self.completion = nil;
}

@end

namespace workorder
{

namespace
{

WorkOrderContactPickerDelegate *gPickerDelegate = nil;

UIViewController *topViewController()
{
    UIApplication *application = UIApplication.sharedApplication;
    for(UIScene *scene in application.connectedScenes)
    {
        if(scene.activationState != UISceneActivationStateForegroundActive)
            continue;
        if(![scene isKindOfClass:UIWindowScene.class])
            continue;
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        UIWindow *window = nil;
        for(UIWindow *candidate in windowScene.windows)
        {
            if(candidate.isKeyWindow)
            {
                window = candidate;
                break;
            }
        }
        if(window == nil)
            window = windowScene.windows.firstObject;
        UIViewController *controller = window.rootViewController;
        while(controller.presentedViewController != nil)
            controller = controller.presentedViewController;
        if(controller != nil)
            return controller;
    }
    return nil;
}

} // namespace

void pickPhoneContact(ContactPickerCallback completion)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *controller = topViewController();
        if(controller == nil)
        {
            completion(false, {}, {}, QStringLiteral("Не удалось открыть контакты"));
            return;
        }

        WorkOrderContactPickerDelegate *delegate = [WorkOrderContactPickerDelegate new];
        delegate.completion = ^(BOOL picked, NSString *name, NSString *phone, NSString *error)
        {
            completion(picked,
                       name != nil ? QString::fromNSString(name) : QString(),
                       phone != nil ? QString::fromNSString(phone) : QString(),
                       error != nil ? QString::fromNSString(error) : QString());
            gPickerDelegate = nil;
        };
        gPickerDelegate = delegate;

        CNContactPickerViewController *picker = [CNContactPickerViewController new];
        picker.delegate = delegate;
        picker.predicateForEnablingContact =
            [NSPredicate predicateWithFormat:@"phoneNumbers.@count > 0"];
        [controller presentViewController:picker animated:YES completion:nil];
    });
}

} // namespace workorder
