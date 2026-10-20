#import "OJTheme.h"
#import <QuartzCore/QuartzCore.h>

NSString * const OJThemeDidChangeNotification = @"OJThemeDidChangeNotification";

#define kDarkModeKey @"OJThemeDarkMode"
#define kAccentKey   @"OJThemeAccent"
static UIImage *OJStripeImage(CGFloat height) {
    UIImage *stripe = [UIImage imageNamed:@"stripe"];
    if (!stripe) return nil;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, height), NO, 0);
    [stripe drawInRect:CGRectMake(0, 0, 1, height)];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@implementation OJTheme

+ (BOOL)darkMode {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDarkModeKey];
}

+ (void)setDarkMode:(BOOL)dark {
    [[NSUserDefaults standardUserDefaults] setBool:dark forKey:kDarkModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self apply];
    [[NSNotificationCenter defaultCenter] postNotificationName:OJThemeDidChangeNotification object:nil];
}

+ (OJThemeAccent)accent {
    NSInteger v=[[NSUserDefaults standardUserDefaults] integerForKey:kAccentKey];
    if(v<0 || v>=OJThemeAccentCount) v=OJThemeAccentGreen;
    return (OJThemeAccent)v;
}

+ (void)setAccent:(OJThemeAccent)accent {
    [[NSUserDefaults standardUserDefaults] setInteger:accent forKey:kAccentKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self apply];
    [[NSNotificationCenter defaultCenter] postNotificationName:OJThemeDidChangeNotification object:nil];
}

+ (void)resetAccent {
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kAccentKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self apply];
    [[NSNotificationCenter defaultCenter] postNotificationName:OJThemeDidChangeNotification object:nil];
}

+ (NSArray *)accentNames {
    return @[@"Green", @"Blue", @"Black"];
}

#pragma mark - Apply

+ (void)apply {
}

+ (void)applyToNavigationBar:(UINavigationBar *)navBar {
    if (!navBar) return;
    // Use the native bar: blue in light mode, black gloss in dark mode. No stripe texture and no tintColor
    // (on iOS 5 tintColor recolors the whole bar, which is not what we want).
    if ([self darkMode]) {
        navBar.tintColor = nil;
        navBar.barStyle = UIBarStyleBlack;
        UIImage *portrait = OJStripeImage(44.0);
        UIImage *landscape = OJStripeImage(32.0);
        if (portrait) [navBar setBackgroundImage:portrait forBarMetrics:UIBarMetricsDefault];
        if (landscape) [navBar setBackgroundImage:landscape forBarMetrics:UIBarMetricsLandscapePhone];
    } else {
        navBar.tintColor = [self accentColor];
        navBar.barStyle = UIBarStyleDefault;
        [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsLandscapePhone];
    }
    navBar.titleTextAttributes = @{
        UITextAttributeTextColor        : [UIColor whiteColor],
        UITextAttributeTextShadowColor  : [UIColor colorWithWhite:0.0 alpha:0.5],
        UITextAttributeTextShadowOffset : [NSValue valueWithCGSize:CGSizeMake(0, -1)]
    };
    [navBar setNeedsDisplay];
}

+ (void)applyToToolbar:(UIToolbar *)toolbar {
    if (!toolbar) return;
    toolbar.barStyle = [self darkMode] ? UIBarStyleBlack : UIBarStyleDefault;
    toolbar.tintColor = [self accentColor];
}

+ (void)applyToPlainTableView:(UITableView *)tableView {
    tableView.separatorColor = [self darkMode] ?
        [UIColor colorWithWhite:0.3 alpha:1.0] : [UIColor colorWithWhite:0.85 alpha:1.0];
    tableView.backgroundColor = [self darkMode] ?
        [UIColor colorWithWhite:0.15 alpha:1.0] : [UIColor whiteColor];
}

+ (void)applyToGroupedTableView:(UITableView *)tableView {
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.separatorColor = [self darkMode] ? [UIColor colorWithWhite:0.30 alpha:1.0] : [UIColor colorWithWhite:0.85 alpha:1.0];
    tableView.backgroundColor = [self darkMode] ? [UIColor colorWithWhite:0.15 alpha:1.0] : [UIColor groupTableViewBackgroundColor];
}

+ (void)applyToTableViewCell:(UITableViewCell *)cell {
    cell.textLabel.textColor = [self textColor];
    cell.detailTextLabel.textColor = [self secondaryTextColor];

    UIColor *bgColor = [self darkMode] ? [UIColor colorWithWhite:0.15 alpha:1.0] : [UIColor whiteColor];
    cell.backgroundView = nil;
    cell.backgroundColor = bgColor;
    cell.contentView.backgroundColor = bgColor;
    cell.opaque = YES;
}

+ (void)applyToTableViewCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    [self applyToTableViewCell:cell];
}

#pragma mark - Colors

+ (UIColor *)backgroundColor {
    return [self darkMode] ? [UIColor colorWithWhite:0.15 alpha:1.0] : [UIColor colorWithWhite:0.91 alpha:1.0];
}

+ (UIColor *)textColor {
    return [self darkMode] ? [UIColor whiteColor] : [UIColor blackColor];
}

+ (UIColor *)secondaryTextColor {
    return [self darkMode] ? [UIColor colorWithWhite:0.75 alpha:1.0] : [UIColor grayColor];
}

+ (UIColor *)accentColor {
    switch ([self accent]) {
        case OJThemeAccentGreen:
            return [UIColor colorWithRed:83.0/255.0 green:122.0/255.0 blue:44.0/255.0 alpha:1.0];
        case OJThemeAccentBlack:
            return [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        default:
            return [UIColor colorWithRed:0.29 green:0.50 blue:0.73 alpha:1.0];
    }
}

+ (UIColor *)sectionHeaderTextColor {
    if ([self darkMode]) return [UIColor whiteColor];
    return [UIColor colorWithWhite:0.3 alpha:1.0];
}

+ (UIColor *)installButtonColor {
    return [self accentColor];
}

#pragma mark - Apply Accent to Controls (iOS 5+)

+ (void)applyGlossToView:(UIView *)view cornerRadius:(CGFloat)radius {
    if (!view) return;
    view.layer.cornerRadius = radius;
    view.clipsToBounds = YES;
    view.layer.borderWidth = 1.0;
    view.layer.borderColor = ([self darkMode] ? [UIColor colorWithWhite:0.0 alpha:0.55] : [UIColor colorWithWhite:0.0 alpha:0.18]).CGColor;
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = view.bounds;
    g.colors = @[(id)[UIColor colorWithWhite:1.0 alpha:0.32].CGColor,
                 (id)[UIColor colorWithWhite:1.0 alpha:0.04].CGColor,
                 (id)[UIColor colorWithWhite:0.0 alpha:0.00].CGColor,
                 (id)[UIColor colorWithWhite:0.0 alpha:0.10].CGColor];
    g.locations = @[@0.0, @0.45, @0.46, @1.0];
    [view.layer insertSublayer:g atIndex:0];
}
+ (void)applyStrongGlossToView:(UIView *)view cornerRadius:(CGFloat)radius {
    if (!view) return;
    view.layer.cornerRadius = radius;
    view.clipsToBounds = YES;
    view.layer.borderWidth = 1.0;
    view.layer.borderColor = ([self darkMode] ? [UIColor colorWithWhite:0.0 alpha:0.60] : [UIColor colorWithWhite:0.0 alpha:0.22]).CGColor;
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = view.bounds;
    g.colors = @[(id)[UIColor colorWithWhite:1.0 alpha:0.50].CGColor,
                 (id)[UIColor colorWithWhite:1.0 alpha:0.14].CGColor,
                 (id)[UIColor colorWithWhite:0.0 alpha:0.00].CGColor,
                 (id)[UIColor colorWithWhite:0.0 alpha:0.14].CGColor];
    g.locations = @[@0.0, @0.48, @0.49, @1.0];
    [view.layer insertSublayer:g atIndex:0];
}
+ (void)applyGlossyButton:(UIButton *)button color:(UIColor *)color {
    if (!button || !color) return;
    [button setBackgroundImage:[self gradientButtonImageWithColor:color height:MAX(1.0,button.bounds.size.height)] forState:UIControlStateNormal];
    button.layer.cornerRadius = 8.0;
    button.clipsToBounds = YES;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:0.30].CGColor;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.45];
    button.titleLabel.shadowOffset = CGSizeMake(0, -1);
}
+ (void)applyAccentToView:(UIView *)view {
    UIColor *accent = [self accentColor];
    
    if ([view isKindOfClass:[UISwitch class]] && [view respondsToSelector:@selector(setOnTintColor:)]) {
        [(UISwitch *)view setOnTintColor:accent];
    }
    if ([view isKindOfClass:[UISlider class]] && [view respondsToSelector:@selector(setMinimumTrackTintColor:)]) {
        [(UISlider *)view setMinimumTrackTintColor:accent];
    }
    if ([view isKindOfClass:[UIProgressView class]] && [view respondsToSelector:@selector(setProgressTintColor:)]) {
        [(UIProgressView *)view setProgressTintColor:accent];
    }
    if ([view isKindOfClass:[UIActivityIndicatorView class]] && [view respondsToSelector:@selector(setColor:)]) {
        [(UIActivityIndicatorView *)view setColor:accent];
    }
}

#pragma mark - Helpers

+ (UIImage *)navBarBackgroundImage {
    UIColor *accent = [self accentColor];
    CGColorRef cgColor = [accent CGColor];
    size_t numComponents = CGColorGetNumberOfComponents(cgColor);
    const CGFloat *components = CGColorGetComponents(cgColor);
    CGFloat r, g, b;
    if (numComponents >= 4) {
        r = components[0]; g = components[1]; b = components[2];
    } else {
        r = components[0]; g = components[0]; b = components[0];
    }

    CGFloat h = 44;
    UIGraphicsBeginImageContext(CGSizeMake(1, h));
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();

    CGFloat baseColors[] = {
        MIN(r + 0.30, 1.0), MIN(g + 0.30, 1.0), MIN(b + 0.30, 1.0), 1.0,
        MIN(r + 0.18, 1.0), MIN(g + 0.18, 1.0), MIN(b + 0.18, 1.0), 1.0,
        r, g, b, 1.0,
        MAX(r - 0.18, 0), MAX(g - 0.18, 0), MAX(b - 0.18, 0), 1.0
    };
    CGFloat baseLocs[] = { 0.0, 0.35, 0.75, 1.0 };
    CGGradientRef baseGrad = CGGradientCreateWithColorComponents(rgb, baseColors, baseLocs, 4);
    CGContextDrawLinearGradient(ctx, baseGrad, CGPointMake(0, 0), CGPointMake(0, h), 0);
    CGGradientRelease(baseGrad);

    CGFloat glossColors[] = {
        0, 0, 0, 0,
        0, 0, 0, 0,
        1, 1, 1, 0.1,
        1, 1, 1, 0.1
    };
    CGFloat glossLocs[] = { 0.0, 0.49, 0.50, 1.0 };
    CGGradientRef glossGrad = CGGradientCreateWithColorComponents(rgb, glossColors, glossLocs, 4);
    CGContextDrawLinearGradient(ctx, glossGrad, CGPointMake(0, h), CGPointMake(0, 0), 0);
    CGGradientRelease(glossGrad);

    CGColorSpaceRelease(rgb);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

+ (UIImage *)gradientButtonImageWithColor:(UIColor *)color height:(CGFloat)height {
    CGColorRef cgColor = [color CGColor];
    size_t numComponents = CGColorGetNumberOfComponents(cgColor);
    const CGFloat *components = CGColorGetComponents(cgColor);
    CGFloat r, g, b;
    if (numComponents >= 4) {
        r = components[0]; g = components[1]; b = components[2];
    } else {
        r = components[0]; g = components[0]; b = components[0];
    }

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, height), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();

    CGFloat baseColors[] = {
        MIN(r + 0.15, 1.0), MIN(g + 0.15, 1.0), MIN(b + 0.15, 1.0), 1.0,
        r, g, b, 1.0,
        MAX(r - 0.10, 0), MAX(g - 0.10, 0), MAX(b - 0.10, 0), 1.0
    };
    CGGradientRef baseGrad = CGGradientCreateWithColorComponents(rgb, baseColors, NULL, 3);
    CGContextDrawLinearGradient(ctx, baseGrad, CGPointMake(0, 0), CGPointMake(0, height), 0);
    CGGradientRelease(baseGrad);

    CGFloat glossColors[] = {
        0, 0, 0, 0,
        0, 0, 0, 0,
        1, 1, 1, 0.12,
        1, 1, 1, 0.12
    };
    CGFloat glossLocs[] = { 0.0, 0.49, 0.50, 1.0 };
    CGGradientRef glossGrad = CGGradientCreateWithColorComponents(rgb, glossColors, glossLocs, 4);
    CGContextDrawLinearGradient(ctx, glossGrad, CGPointMake(0, height), CGPointMake(0, 0), 0);
    CGGradientRelease(glossGrad);

    CGColorSpaceRelease(rgb);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end
