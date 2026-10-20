// MMSheet.h - native action list (UITableView in a navigation controller) with a cover/title header.
#import <UIKit/UIKit.h>
#define MMSheetTag 0x5EE7   // retained for debug/legacy references
@interface MMSheet : NSObject
// options: Titel der Zeilen; done(index) beim Antippen, done(-1) beim Schließen ohne Auswahl
+ (void)showIn:(UIView *)view title:(NSString *)title subtitle:(NSString *)sub options:(NSArray *)options done:(void(^)(NSInteger idx))done;
// dasselbe mit Cover links neben Titel/Untertitel (imageURL nil = ohne)
+ (void)showIn:(UIView *)view title:(NSString *)title subtitle:(NSString *)sub imageURL:(NSString *)imageURL options:(NSArray *)options done:(void(^)(NSInteger idx))done;
@end
