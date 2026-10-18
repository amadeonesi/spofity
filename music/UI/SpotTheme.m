#import "SpotTheme.h"
static UIColor* rgb(int r,int g,int b){ return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]; }
@implementation SpotTheme
+ (UIColor *)bg    { return rgb(18,18,18); }
+ (UIColor *)bar   { return rgb(24,24,24); }
+ (UIColor *)card  { return rgb(40,40,40); }
+ (UIColor *)green { return rgb(29,185,84); }
+ (UIColor *)ink   { return [UIColor whiteColor]; }
+ (UIColor *)muted { return rgb(179,179,179); }
+ (UIColor *)faint { return rgb(114,114,114); }
+ (UIColor *)line  { return rgb(42,42,42); }
+ (UIFont *)h1  { return [UIFont boldSystemFontOfSize:22]; }
+ (UIFont *)h2  { return [UIFont boldSystemFontOfSize:17]; }
+ (UIFont *)body{ return [UIFont systemFontOfSize:15]; }
+ (UIFont *)sub { return [UIFont systemFontOfSize:13]; }
+ (UIFont *)tab { return [UIFont systemFontOfSize:10]; }

// Echtes Spotify-Logo: grüner Kreis + drei schwarze Schallwellen (nach oben gewölbt).
// Eigenes Zeichen der App: grüner Kreis mit Puls-Linie (kein Spotify-Logo – Markenrecht).
+ (UIImage *)logo:(CGFloat)s {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(s,s),NO,0);
    [[self green] setFill]; [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0,0,s,s)] fill];
    UIBezierPath*p=[UIBezierPath bezierPath]; p.lineWidth=s*0.075; p.lineCapStyle=kCGLineCapRound; p.lineJoinStyle=kCGLineJoinRound;
    CGFloat y=s/2, pts[7][2]={{0.06,0},{0.33,0},{0.41,-0.18},{0.52,0.21},{0.6,-0.08},{0.65,0},{0.94,0}};
    [p moveToPoint:CGPointMake(s*pts[0][0],y)];
    for(int i=1;i<7;i++) [p addLineToPoint:CGPointMake(s*pts[i][0],y+s*pts[i][1])];
    [[UIColor colorWithRed:0.055 green:0.055 blue:0.063 alpha:1] setStroke]; [p stroke];
    UIImage*img=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return img;
}
+ (void)spaced:(UILabel *)label text:(NSString *)text font:(UIFont *)font color:(UIColor *)color kern:(CGFloat)kern {
    if ([label respondsToSelector:@selector(setAttributedText:)]) {
        label.attributedText = [[NSAttributedString alloc] initWithString:text ?: @"" attributes:@{NSKernAttributeName:@(kern), NSFontAttributeName:font, NSForegroundColorAttributeName:color}];
    } else { label.text = text; label.font = font; label.textColor = color; }
}
+ (void)styleBackButton:(UIButton *)b {
    static UIImage*img;
    if(!img){ UIGraphicsBeginImageContextWithOptions(CGSizeMake(12,20),NO,0); [[self ink] setStroke];
        UIBezierPath*p=[UIBezierPath bezierPath]; p.lineWidth=2.4; p.lineCapStyle=kCGLineCapRound; p.lineJoinStyle=kCGLineJoinRound;
        [p moveToPoint:CGPointMake(9.5,2.5)]; [p addLineToPoint:CGPointMake(2.5,10)]; [p addLineToPoint:CGPointMake(9.5,17.5)]; [p stroke];
        img=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); }
    [b setImage:img forState:UIControlStateNormal];
    [b setTitle:NSLocalizedString(@"Back",nil) forState:UIControlStateNormal]; [b setTitleColor:[self ink] forState:UIControlStateNormal];
    b.titleLabel.font=[UIFont systemFontOfSize:15]; b.titleEdgeInsets=UIEdgeInsetsMake(0,6,0,0);
    b.contentHorizontalAlignment=UIControlContentHorizontalAlignmentLeft;
}
+ (UIImage *)downloadedIcon:(CGFloat)d {
    static NSMutableDictionary*memo; if(!memo) memo=[NSMutableDictionary dictionary];
    UIImage*m=memo[@(d)]; if(m) return m;
    CGFloat k=d/26.0;   // gezeichnet im 26er-Raster wie der Knopf oben rechts
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(d,d),NO,0);
    [[self green] setFill]; [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(1*k,1*k,24*k,24*k)] fill];
    UIBezierPath*p=[UIBezierPath bezierPath]; p.lineWidth=MAX(1.5,2*k); p.lineCapStyle=kCGLineCapRound; p.lineJoinStyle=kCGLineJoinRound;
    [[UIColor blackColor] setStroke];
    [p moveToPoint:CGPointMake(7.5*k,13.5*k)]; [p addLineToPoint:CGPointMake(11.5*k,17.5*k)]; [p addLineToPoint:CGPointMake(18.5*k,9*k)]; [p stroke];
    m=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); memo[@(d)]=m; return m;
}
+ (UIImage *)downloadsCover:(CGFloat)S {
    static NSMutableDictionary*memo; if(!memo) memo=[NSMutableDictionary dictionary];
    UIImage*m=memo[@(S)]; if(m) return m;
    CGFloat k=S/48.0; UIGraphicsBeginImageContextWithOptions(CGSizeMake(S,S),YES,0); CGContextRef cx=UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs=CGColorSpaceCreateDeviceRGB(); CGFloat comps[]={0.16,0.80,0.42,1, 0.04,0.36,0.20,1};
    CGGradientRef g=CGGradientCreateWithColorComponents(cs,comps,NULL,2); CGContextDrawLinearGradient(cx,g,CGPointMake(0,0),CGPointMake(S,S),0);
    CGGradientRelease(g); CGColorSpaceRelease(cs);
    [[UIColor whiteColor] setStroke]; UIBezierPath*p=[UIBezierPath bezierPath]; p.lineWidth=3*k; p.lineCapStyle=kCGLineCapRound; p.lineJoinStyle=kCGLineJoinRound;
    [p moveToPoint:CGPointMake(24*k,13*k)]; [p addLineToPoint:CGPointMake(24*k,32*k)]; [p moveToPoint:CGPointMake(16*k,25*k)]; [p addLineToPoint:CGPointMake(24*k,33*k)]; [p addLineToPoint:CGPointMake(32*k,25*k)];
    [p moveToPoint:CGPointMake(15*k,37*k)]; [p addLineToPoint:CGPointMake(33*k,37*k)]; [p stroke];
    m=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); memo[@(S)]=m; return m;
}
@end
