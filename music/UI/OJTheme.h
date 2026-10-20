#import <UIKit/UIKit.h>

typedef enum {
    OJThemeAccentGreen,
    OJThemeAccentDefaultBlue,
    OJThemeAccentBlack,
    OJThemeAccentCount
} OJThemeAccent;

extern NSString * const OJThemeDidChangeNotification;

@interface OJTheme : NSObject

+ (BOOL)darkMode;
+ (void)setDarkMode:(BOOL)dark;
+ (OJThemeAccent)accent;
+ (void)setAccent:(OJThemeAccent)accent;
+ (void)resetAccent;
+ (NSArray *)accentNames;

+ (void)apply;
+ (void)applyToNavigationBar:(UINavigationBar *)navBar;
+ (void)applyToToolbar:(UIToolbar *)toolbar;
+ (void)applyToPlainTableView:(UITableView *)tableView;
+ (void)applyToGroupedTableView:(UITableView *)tableView;
+ (void)applyToTableViewCell:(UITableViewCell *)cell;
+ (void)applyToTableViewCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;

+ (UIColor *)backgroundColor;
+ (UIColor *)textColor;
+ (UIColor *)secondaryTextColor;
+ (UIColor *)accentColor;
+ (UIColor *)sectionHeaderTextColor;
+ (UIColor *)installButtonColor;

+ (void)applyAccentToView:(UIView *)view;
+ (void)applyGlossToView:(UIView *)view cornerRadius:(CGFloat)radius;
+ (void)applyStrongGlossToView:(UIView *)view cornerRadius:(CGFloat)radius;
+ (void)applyGlossyButton:(UIButton *)button color:(UIColor *)color;
+ (UIImage *)gradientButtonImageWithColor:(UIColor *)color height:(CGFloat)height;

@end
