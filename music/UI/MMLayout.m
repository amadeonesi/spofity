#import "MMLayout.h"
#import "MMRootController.h"
#import "SpotTheme.h"

BOOL MMIsPad(void) {
    static int pad=-1;
    if(pad<0) pad=(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)?1:0;
    return pad==1;
}

CGRect MMPageFrame(BOOL belowStatusBar) {
    if(!MMIsPad()) return belowStatusBar?[UIScreen mainScreen].applicationFrame:[UIScreen mainScreen].bounds;
    CGRect c=[[MMRootController shared] contentBounds];   // auch schon während die Hülle aufgebaut wird
    if(!CGRectIsEmpty(c)) return c;
    return [UIScreen mainScreen].bounds;   // noch keine Hülle (z. B. Anmeldung): ganzer Bildschirm
}

CGFloat MMPageBottomInset(CGFloat phone) { return MMIsPad()?24:phone; }
NSInteger MMGridColumns(CGFloat width) { return MAX(2,(NSInteger)floor((width-16)/170)); }

void MMAutoMask(UIView *page) {
    if(!MMIsPad()) return;
    CGFloat W=page.bounds.size.width, H=page.bounds.size.height;
    for(UIView*v in page.subviews){
        if(v.autoresizingMask!=UIViewAutoresizingNone) continue;
        CGRect f=v.frame; CGFloat l=CGRectGetMinX(f), r=W-CGRectGetMaxX(f), t=CGRectGetMinY(f), b=H-CGRectGetMaxY(f);
        UIViewAutoresizing m=UIViewAutoresizingNone;
        if(f.size.width>=W/2 && r<=100) m|=UIViewAutoresizingFlexibleWidth;                                // breit bis (fast) an den rechten Rand
        else if(fabs(CGRectGetMidX(f)-W/2)<=2 && l>0) m|=UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;   // mittig
        else if(r<l && r<=60) m|=UIViewAutoresizingFlexibleLeftMargin;                                    // rechts bündig
        if(f.size.height>=H/2 && b<=4) m|=UIViewAutoresizingFlexibleHeight;                               // bis ganz unten
        else if(b<t && b<=120 && f.size.height<H/2) m|=UIViewAutoresizingFlexibleTopMargin;                // unten bündig
        v.autoresizingMask=m;
    }
}
NSString *MMCellID(NSString *base, UITableView *tv) { return [NSString stringWithFormat:@"%@%.0f",base,tv.bounds.size.width]; }

BOOL MMShouldAutorotate(UIInterfaceOrientation o) { return MMIsPad() || o==UIInterfaceOrientationPortrait; }
NSUInteger MMSupportedOrientations(void) {
    MM_IOS6_BEGIN
    return MMIsPad()?UIInterfaceOrientationMaskAll:UIInterfaceOrientationMaskPortrait;
    MM_IOS6_END
}

// ---- Tab-Icons (schlichte Linien-Icons wie Spotify) ----
UIImage *MMTintedIcon(NSString *name, UIColor *color) {
    UIImage *img=[UIImage imageNamed:name];
    if(!img) return nil;
    UIGraphicsBeginImageContextWithOptions(img.size,NO,0);
    [img drawAtPoint:CGPointZero];
    [color setFill];
    UIRectFillUsingBlendMode(CGRectMake(0,0,img.size.width,img.size.height),kCGBlendModeSourceIn);
    UIImage *out=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return out;
}
UIImage *MMTabIcon(NSString *name, UIColor *c, CGFloat s) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(s, s), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [c setStroke]; [c setFill];
    UIBezierPath *p = [UIBezierPath bezierPath]; p.lineWidth = s*0.075f; p.lineJoinStyle = kCGLineJoinRound; p.lineCapStyle = kCGLineCapRound;
    if ([name isEqualToString:@"home"]) {
        [p moveToPoint:CGPointMake(s*0.5,s*0.16)]; [p addLineToPoint:CGPointMake(s*0.85,s*0.46)];
        [p moveToPoint:CGPointMake(s*0.5,s*0.16)]; [p addLineToPoint:CGPointMake(s*0.15,s*0.46)];
        UIBezierPath *b=[UIBezierPath bezierPathWithRect:CGRectMake(s*0.26,s*0.44,s*0.48,s*0.4)]; [p appendPath:b]; [p stroke];
    } else if ([name isEqualToString:@"browse"]) {
        CGFloat g=s*0.1, w=s*0.3;
        for(int i=0;i<2;i++)for(int j=0;j<2;j++){ [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(s*0.2+j*(w+g),s*0.2+i*(w+g),w,w) cornerRadius:s*0.03] stroke]; }
    } else if ([name isEqualToString:@"search"]) {
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(s*0.22,s*0.22,s*0.4,s*0.4)] stroke];
        [p moveToPoint:CGPointMake(s*0.6,s*0.6)]; [p addLineToPoint:CGPointMake(s*0.8,s*0.8)]; [p stroke];
    } else if ([name isEqualToString:@"radio"]) {
        // zentriertes Broadcast-Symbol: Punkt in der Mitte + symmetrische Bögen links UND rechts
        // (vorher nur oben-rechts -> Schwerpunkt saß schief/höher als die anderen Icons)
        CGContextAddEllipseInRect(ctx, CGRectMake(s*0.44,s*0.44,s*0.12,s*0.12)); CGContextFillPath(ctx);
        for(int i=1;i<=2;i++){
            CGFloat r=s*0.14*i+s*0.03;
            UIBezierPath*rt=[UIBezierPath bezierPathWithArcCenter:CGPointMake(s*0.5,s*0.5) radius:r startAngle:-M_PI/4 endAngle:M_PI/4 clockwise:YES]; rt.lineWidth=s*0.07; rt.lineCapStyle=kCGLineCapRound; [rt stroke];
            UIBezierPath*lf=[UIBezierPath bezierPathWithArcCenter:CGPointMake(s*0.5,s*0.5) radius:r startAngle:M_PI-M_PI/4 endAngle:M_PI+M_PI/4 clockwise:YES]; lf.lineWidth=s*0.07; lf.lineCapStyle=kCGLineCapRound; [lf stroke];
        }
    } else { // library
        [p moveToPoint:CGPointMake(s*0.3,s*0.2)];[p addLineToPoint:CGPointMake(s*0.3,s*0.8)];
        [p moveToPoint:CGPointMake(s*0.45,s*0.2)];[p addLineToPoint:CGPointMake(s*0.45,s*0.8)];
        [p stroke];
        UIBezierPath*bar=[UIBezierPath bezierPathWithRect:CGRectMake(s*0.58,s*0.22,s*0.14,s*0.58)]; [[UIColor clearColor] setFill];
        CGContextSaveGState(ctx); CGContextTranslateCTM(ctx,s*0.66,s*0.5); CGContextRotateCTM(ctx,0.26); CGContextTranslateCTM(ctx,-s*0.66,-s*0.5);
        [bar stroke]; CGContextRestoreGState(ctx);
    }
    UIImage *img=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return img;
}

