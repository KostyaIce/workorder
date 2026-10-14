#import <AppKit/AppKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <objc/runtime.h>

// Qt 6.8 Cocoa calls [NSImage imageNamed:NSImageNameApplicationIcon] from
// QCocoaIntegration::focusWindowChanged; on macOS 26 this can abort inside AppKit.
@interface NSImage (WorkOrderQtFocusCrashFix)
+ (NSImage *)wo_safeImageNamed:(NSImageName)name;
@end

@implementation NSImage (WorkOrderQtFocusCrashFix)

+ (void)load
{
    Method original = class_getClassMethod(self, @selector(imageNamed:));
    Method swizzled = class_getClassMethod(self, @selector(wo_safeImageNamed:));
    if(original && swizzled)
        method_exchangeImplementations(original, swizzled);
}

+ (NSImage *)wo_safeImageNamed:(NSImageName)name
{
    if(name != nil && [name isEqualToString:NSImageNameApplicationIcon])
    {
        if(@available(macOS 11.0, *))
        {
            NSImage *icon = [NSWorkspace.sharedWorkspace iconForContentType:UTTypeApplicationBundle];
            if(icon != nil)
                return icon;
        }
        return nil;
    }

    return [self wo_safeImageNamed:name];
}

@end
