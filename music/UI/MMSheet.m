#import "MMSheet.h"
#import "SpotTheme.h"
#import "MMCovers.h"
#import <QuartzCore/QuartzCore.h>

@interface MMSheetView : UIControl
@property (nonatomic, copy) void (^done)(NSInteger idx);
@property (nonatomic, strong) UIView *panel;
@end
@implementation MMSheetView
- (void)close:(NSInteger)idx {
    CGFloat H=self.bounds.size.height; void (^d)(NSInteger)=self.done; self.done=nil;
    [UIView animateWithDuration:0.22 animations:^{
        self.backgroundColor=[UIColor colorWithWhite:0 alpha:0];
        self.panel.frame=CGRectMake(0,H,self.panel.frame.size.width,self.panel.frame.size.height);
    } completion:^(BOOL f){ [self removeFromSuperview]; if(d) d(idx); }];
}
- (void)tapOutside { [self close:-1]; }
// Panel nach unten ziehen: folgt dem Finger; weit genug oder schnell = schließen, sonst zurückfedern
- (void)panelPan:(UIPanGestureRecognizer *)g {
    CGFloat H=self.bounds.size.height, ph=self.panel.bounds.size.height, top=H-ph+20, dy=MAX(0,[g translationInView:self].y);
    if(g.state==UIGestureRecognizerStateBegan || g.state==UIGestureRecognizerStateChanged){
        self.panel.frame=CGRectMake(0,top+dy,self.panel.bounds.size.width,ph);
        self.backgroundColor=[UIColor colorWithWhite:0 alpha:0.55*(1-MIN(1,dy/ph))]; return; }
    if(g.state==UIGestureRecognizerStateEnded && (dy>70 || [g velocityInView:self].y>600)){ [self close:-1]; return; }
    [UIView animateWithDuration:0.2 animations:^{ self.panel.frame=CGRectMake(0,top,self.panel.bounds.size.width,ph);
        self.backgroundColor=[UIColor colorWithWhite:0 alpha:0.55]; }];
}
- (void)tapRow:(UIControl *)row { [self close:row.tag]; }
- (void)rowDown:(UIControl *)row { row.backgroundColor=[UIColor colorWithWhite:1 alpha:0.08]; }
- (void)rowUp:(UIControl *)row { row.backgroundColor=[UIColor clearColor]; }
@end

@implementation MMSheet
+ (void)showIn:(UIView *)view title:(NSString *)title subtitle:(NSString *)sub options:(NSArray *)options done:(void(^)(NSInteger))done {
    [self showIn:view title:title subtitle:sub imageURL:nil options:options done:done];
}
+ (void)showIn:(UIView *)view title:(NSString *)title subtitle:(NSString *)sub imageURL:(NSString *)imageURL options:(NSArray *)options done:(void(^)(NSInteger))done {
    CGFloat W=view.bounds.size.width, H=view.bounds.size.height;
    MMSheetView*ov=[[MMSheetView alloc] initWithFrame:view.bounds]; ov.done=done; ov.tag=MMSheetTag;
    ov.backgroundColor=[UIColor colorWithWhite:0 alpha:0];
    [ov addTarget:ov action:@selector(tapOutside) forControlEvents:UIControlEventTouchUpInside];
    BOOL img=imageURL!=nil; CGFloat tx=img?82:20;   // mit Cover: Text rechts daneben
    CGFloat head=img?84:(sub.length?72:56), rowH=52, ph=head+options.count*rowH+16;
    UIControl*p=[[UIControl alloc] initWithFrame:CGRectMake(0,H,W,ph+20)];   // UIControl: Tippen aufs Panel schließt es nicht
    p.backgroundColor=[UIColor colorWithWhite:0.13 alpha:1]; p.layer.cornerRadius=16; p.clipsToBounds=YES;
    UIView*grip=[[UIView alloc] initWithFrame:CGRectMake(W/2-18,8,36,4)]; grip.backgroundColor=[UIColor colorWithWhite:1 alpha:0.25]; grip.layer.cornerRadius=2; [p addSubview:grip];
    if(img){ UIImageView*cv=[[UIImageView alloc] initWithFrame:CGRectMake(20,22,50,50)]; cv.backgroundColor=[SpotTheme card]; cv.layer.cornerRadius=4; cv.clipsToBounds=YES;
        cv.contentMode=UIViewContentModeScaleAspectFill; [MMCovers load:imageURL into:cv]; [p addSubview:cv]; }
    UILabel*t=[[UILabel alloc] initWithFrame:CGRectMake(tx,img?28:20,W-tx-20,22)]; t.text=title; t.font=[UIFont boldSystemFontOfSize:17]; t.textColor=[UIColor whiteColor]; t.backgroundColor=[UIColor clearColor]; [p addSubview:t];
    if(sub.length){ UILabel*s=[[UILabel alloc] initWithFrame:CGRectMake(tx,img?52:44,W-tx-20,18)]; s.text=sub; s.font=[UIFont systemFontOfSize:13]; s.textColor=[UIColor colorWithWhite:0.58 alpha:1]; s.backgroundColor=[UIColor clearColor]; [p addSubview:s]; }
    UIView*ln=[[UIView alloc] initWithFrame:CGRectMake(0,head,W,0.5)]; ln.backgroundColor=[UIColor colorWithWhite:1 alpha:0.12]; [p addSubview:ln];
    for(NSUInteger i=0;i<options.count;i++){
        UIControl*row=[[UIControl alloc] initWithFrame:CGRectMake(0,head+8+i*rowH,W,rowH)]; row.tag=i;
        UILabel*l=[[UILabel alloc] initWithFrame:CGRectMake(20,0,W-60,rowH)]; l.text=options[i]; l.font=[UIFont systemFontOfSize:16]; l.textColor=[UIColor whiteColor]; l.backgroundColor=[UIColor clearColor];
        l.userInteractionEnabled=NO; [row addSubview:l];
        UILabel*chev=[[UILabel alloc] initWithFrame:CGRectMake(W-34,0,20,rowH)]; chev.text=@"›"; chev.font=[UIFont systemFontOfSize:24]; chev.textColor=[UIColor colorWithWhite:0.45 alpha:1]; chev.backgroundColor=[UIColor clearColor];
        chev.userInteractionEnabled=NO; [row addSubview:chev];
        [row addTarget:ov action:@selector(tapRow:) forControlEvents:UIControlEventTouchUpInside];
        [row addTarget:ov action:@selector(rowDown:) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDragEnter];
        [row addTarget:ov action:@selector(rowUp:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchDragExit|UIControlEventTouchCancel];
        [p addSubview:row];
    }
    ov.panel=p; [ov addSubview:p]; [view addSubview:ov];
    [p addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:ov action:@selector(panelPan:)]];
    [UIView animateWithDuration:0.25 animations:^{
        ov.backgroundColor=[UIColor colorWithWhite:0 alpha:0.55];
        p.frame=CGRectMake(0,H-ph,W,ph+20);
    }];
}
@end
