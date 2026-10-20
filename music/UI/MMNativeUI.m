#import "MMNativeUI.h"
#import "MeshL10n.h"
#import "OJTheme.h"

@implementation MMNativeUI
+ (UINavigationBar *)navigationBarWithTitle:(NSString *)title width:(CGFloat)width {
    UINavigationBar *bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:title ?: @""];
    bar.items = @[item];
    [OJTheme applyToNavigationBar:bar];
    return bar;
}
+ (UIBarButtonItem *)backItemTarget:(id)target action:(SEL)action {
    return [[UIBarButtonItem alloc] initWithTitle:L(@"Back") style:UIBarButtonItemStyleBordered target:target action:action];
}
+ (UIBarButtonItem *)doneItemTarget:(id)target action:(SEL)action {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:target action:action];
}
+ (UIBarButtonItem *)itemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleBordered target:target action:action];
}
+ (UIBarButtonItem *)itemWithImage:(UIImage *)image target:(id)target action:(SEL)action {
    return [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStyleBordered target:target action:action];
}
@end
