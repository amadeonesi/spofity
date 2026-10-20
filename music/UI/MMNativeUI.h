#import <UIKit/UIKit.h>

@interface MMNativeUI : NSObject
+ (UINavigationBar *)navigationBarWithTitle:(NSString *)title width:(CGFloat)width;
+ (UIBarButtonItem *)backItemTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)doneItemTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)itemWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (UIBarButtonItem *)itemWithImage:(UIImage *)image target:(id)target action:(SEL)action;
@end
