// Spotify6Widget.m - Mitteilungszentrum-Widget (iOS 6 / WeeLoader): Cover, Titel, Artist, "Playing from …" und Zurück/Play/Weiter.
// Läuft in SpringBoard. Daten kommen aus SBMediaController (dieselben, die der Sperrbildschirm zeigt); die Tasten schicken
// die normalen Medienbefehle an die spielende App (Spotify6 fängt sie in MMApplication ab).
// Sichtbar nur, wenn Spotify6 die spielende App ist und der Schalter in den Spotify6-Einstellungen an ist.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>

// SpringBoard lädt nur Klassen, die dieses Protokoll erklären (Name zählt; Deklaration wie in BulletinBoard/BBWeeAppController.h)
@protocol BBWeeAppController <NSObject>
- (UIView *)view;
@optional
- (float)viewHeight;
- (void)viewWillAppear;
- (void)viewDidAppear;
- (void)viewWillDisappear;
- (void)viewDidDisappear;
- (void)loadView;
- (void)loadPlaceholderView;
- (void)loadFullView;
@end

#define APP_ID @"io.github.ikiwy.spotify6"
#define W 316.0
#define H 71.0      // Höhe des Wetter-Hintergrunds (weeapp_bg.png, 9x71, inkl. Schatten)
#define SCROLL_PX_PER_S 28.0

#ifdef DEBUG
static void wlog(NSString*fmt,...){   // Test-Log: /var/mobile/Library/Logs/Spotify6Widget.log (angehängt)
    va_list a; va_start(a,fmt); NSString*s=[[NSString alloc] initWithFormat:fmt arguments:a]; va_end(a);
    NSString*p=@"/var/mobile/Library/Logs/Spotify6Widget.log";
    NSFileHandle*h=[NSFileHandle fileHandleForWritingAtPath:p]; if(!h){ [@"" writeToFile:p atomically:NO encoding:NSUTF8StringEncoding error:NULL]; h=[NSFileHandle fileHandleForWritingAtPath:p]; }
    [h seekToEndOfFile]; [h writeData:[[NSString stringWithFormat:@"%@ %@\n",[NSDate date],s] dataUsingEncoding:NSUTF8StringEncoding]]; [h closeFile];
}
#else
#define wlog(...)
#endif

static id MC(void){ Class c=NSClassFromString(@"SBMediaController"); return c?((id(*)(id,SEL))objc_msgSend)(c,@selector(sharedInstance)):nil; }
static id call(id o,NSString*sel){ SEL s=NSSelectorFromString(sel); return (o && [o respondsToSelector:s])?((id(*)(id,SEL))objc_msgSend)(o,s):nil; }

// Knopf-Symbole (weiß, mit leichtem Schatten wie die Wetter-Schrift)
static UIImage* glyph(NSString*kind){
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(26,26),NO,0);
    CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(),CGSizeMake(0,1),0,[UIColor colorWithWhite:0 alpha:0.6].CGColor);
    [[UIColor whiteColor] setFill];
    UIBezierPath*p=[UIBezierPath bezierPath];
    if([kind isEqual:@"play"]){ [p moveToPoint:CGPointMake(8,5)]; [p addLineToPoint:CGPointMake(8,21)]; [p addLineToPoint:CGPointMake(21,13)]; [p closePath]; [p fill]; }
    else if([kind isEqual:@"pause"]){ UIRectFill(CGRectMake(7,6,4,14)); UIRectFill(CGRectMake(15,6,4,14)); }
    else { BOOL n=[kind isEqual:@"next"];
        if(n){ [p moveToPoint:CGPointMake(6,7)]; [p addLineToPoint:CGPointMake(6,19)]; [p addLineToPoint:CGPointMake(16,13)]; [p closePath]; [p fill]; UIRectFill(CGRectMake(17,7,3,12)); }
        else { [p moveToPoint:CGPointMake(20,7)]; [p addLineToPoint:CGPointMake(20,19)]; [p addLineToPoint:CGPointMake(10,13)]; [p closePath]; [p fill]; UIRectFill(CGRectMake(6,7,3,12)); } }
    UIImage*i=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return i;
}

// ---- Lauftext: passt der Text nicht, gleitet er nach kurzer Pause ans Ende, wartet und gleitet zurück (solange sichtbar) ----
@interface S6Marquee : UIView
@property (nonatomic, readonly) UILabel *label;
- (void)setText:(NSString *)t;
- (void)startAfter:(NSTimeInterval)delay;
- (void)stop;
@end
@implementation S6Marquee { BOOL _running; NSUInteger _gen; }
- (id)initWithFrame:(CGRect)f {
    if((self=[super initWithFrame:f])){ self.clipsToBounds=YES; self.backgroundColor=[UIColor clearColor];
        _label=[[UILabel alloc] initWithFrame:self.bounds]; _label.backgroundColor=[UIColor clearColor];
        _label.shadowColor=[UIColor colorWithWhite:0 alpha:0.6]; _label.shadowOffset=CGSizeMake(0,1); [self addSubview:_label]; }
    return self;
}
- (void)setText:(NSString *)t {
    if([t isEqualToString:_label.text]) return;
    [self stop]; _label.text=t; [self fitLabel];
}
- (void)fitLabel { CGFloat w=MAX(self.bounds.size.width,[_label.text sizeWithFont:_label.font].width); _label.frame=CGRectMake(0,0,w,self.bounds.size.height); }
- (void)setFrame:(CGRect)f { [super setFrame:f]; [self fitLabel]; }
- (CGFloat)overflow { return _label.bounds.size.width-self.bounds.size.width; }
- (void)startAfter:(NSTimeInterval)delay {
    [self stop]; if([self overflow]<=1) return;
    _running=YES; NSUInteger g=++_gen; [self loopGen:g delay:delay];
}
- (void)loopGen:(NSUInteger)g delay:(NSTimeInterval)delay {
    if(!_running || g!=_gen) return;
    CGFloat ov=[self overflow]; NSTimeInterval d=ov/SCROLL_PX_PER_S; UILabel*l=_label;
    [UIView animateWithDuration:d delay:delay options:UIViewAnimationOptionCurveLinear|UIViewAnimationOptionAllowUserInteraction
                     animations:^{ l.frame=CGRectMake(-ov,0,l.bounds.size.width,l.bounds.size.height); }
                     completion:^(BOOL f){ if(!f || !_running || g!=_gen) return;
        [UIView animateWithDuration:d delay:1.5 options:UIViewAnimationOptionCurveLinear|UIViewAnimationOptionAllowUserInteraction
                         animations:^{ l.frame=CGRectMake(0,0,l.bounds.size.width,l.bounds.size.height); }
                         completion:^(BOOL f2){ if(f2) [self loopGen:g delay:1.5]; }]; }];
}
- (void)stop {
    _running=NO; _gen++; [_label.layer removeAllAnimations];
    _label.frame=CGRectMake(0,0,_label.bounds.size.width,_label.bounds.size.height);
}
@end

@interface Spotify6WidgetController : NSObject <BBWeeAppController>
@property (nonatomic, strong) UIView *view;
@end

@implementation Spotify6WidgetController {
    UIImageView *_bg, *_cover; S6Marquee *_title, *_artist; UILabel *_from;
    UIButton *_prev, *_play, *_next;
    NSData *_artData; BOOL _shown;
}

- (id)init {
    if((self=[super init])){ wlog(@"init");
        id mc=MC(); NSNotificationCenter*nc=[NSNotificationCenter defaultCenter];
        for(NSString*n in @[@"SBMediaNowPlayingChangedNotification",@"SBMediaNowPlayingAppChangedNotification"])
            [nc addObserver:self selector:@selector(refresh) name:n object:mc];
    }
    return self;
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (void)loadView {
    _view=[[UIView alloc] initWithFrame:CGRectMake(2,0,W,H)];
    // Hintergrund wie das Wetter-Widget: Apples eigenes Bild aus dem System (nicht kopiert), seitlich gestreckt
    UIImage*bg=[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/WeatherNotifications.bundle/weeapp_bg.png"]
            ?:[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/StocksWeeApp.bundle/WeeAppBackground.png"];
    _bg=[[UIImageView alloc] initWithFrame:_view.bounds]; _bg.image=[bg stretchableImageWithLeftCapWidth:4 topCapHeight:0]; [_view addSubview:_bg];
    if(!bg){ _bg.backgroundColor=[UIColor colorWithWhite:0 alpha:0.4]; _bg.layer.cornerRadius=6; }   // Notfall, falls das Systembild fehlt
    CGFloat cs=52, cy=(H-4-cs)/2;   // unten liegen ~4 pt Schatten im Bild
    _cover=[[UIImageView alloc] initWithFrame:CGRectMake(8,cy,cs,cs)]; _cover.backgroundColor=[UIColor colorWithWhite:0.2 alpha:1];
    _cover.layer.cornerRadius=3; _cover.clipsToBounds=YES; _cover.contentMode=UIViewContentModeScaleAspectFill; [_view addSubview:_cover];
    CGFloat tx=8+cs+9, tw=W-tx-110;
    _title=[[S6Marquee alloc] initWithFrame:CGRectMake(tx,0,tw,18)]; _title.label.font=[UIFont boldSystemFontOfSize:14]; _title.label.textColor=[UIColor whiteColor];
    _artist=[[S6Marquee alloc] initWithFrame:CGRectMake(tx,0,tw,16)]; _artist.label.font=[UIFont systemFontOfSize:12]; _artist.label.textColor=[UIColor colorWithWhite:0.88 alpha:1];
    _from=[[UILabel alloc] initWithFrame:CGRectMake(tx,0,tw,15)]; _from.font=[UIFont systemFontOfSize:11]; _from.textColor=[UIColor colorWithWhite:0.7 alpha:1];
    _from.backgroundColor=[UIColor clearColor]; _from.shadowColor=[UIColor colorWithWhite:0 alpha:0.6]; _from.shadowOffset=CGSizeMake(0,1);
    [_view addSubview:_title]; [_view addSubview:_artist]; [_view addSubview:_from];
    CGFloat bx=W-108;
    _prev=[self button:@"prev" x:bx action:@selector(prevTap)]; _play=[self button:@"play" x:bx+34 action:@selector(playTap)]; _next=[self button:@"next" x:bx+68 action:@selector(nextTap)];
    [self refresh];
}
- (UIButton *)button:(NSString *)kind x:(CGFloat)x action:(SEL)a {
    UIButton*b=[UIButton buttonWithType:UIButtonTypeCustom]; b.frame=CGRectMake(x,(H-4-40)/2,34,40); b.showsTouchWhenHighlighted=YES;
    [b setImage:glyph(kind) forState:UIControlStateNormal]; [b addTarget:self action:a forControlEvents:UIControlEventTouchUpInside]; [_view addSubview:b];
    return b;
}
// Titel + Artist (+ "Playing from …") als Block senkrecht mittig neben dem Cover
- (void)layoutText {
    CGFloat x=_title.frame.origin.x, w=_title.bounds.size.width, gap=1;
    BOOL from=_from.text.length>0; _from.hidden=!from;
    CGFloat total=18+gap+16+(from?gap+15:0), y=(H-4-total)/2;
    _title.frame=CGRectMake(x,y,w,18); y+=18+gap;
    _artist.frame=CGRectMake(x,y,w,16); y+=16+gap;
    if(from) _from.frame=CGRectMake(x,y,w,15);
}

// ---- Sichtbarkeit: Spotify6 spielt + Schalter in den Spotify6-Einstellungen an (Einstellungen liegen im App-Container) ----
- (NSDictionary *)appPrefs {
    Class ac=NSClassFromString(@"SBApplicationController");
    id ctl=ac?((id(*)(id,SEL))objc_msgSend)(ac,@selector(sharedInstance)):nil;
    id app=ctl?((id(*)(id,SEL,id))objc_msgSend)(ctl,NSSelectorFromString(@"applicationWithDisplayIdentifier:"),APP_ID):nil;
    NSString*path=call(app,@"path"); if(!path.length) return nil;
    return [NSDictionary dictionaryWithContentsOfFile:[[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Library/Preferences/" APP_ID ".plist"]];
}
- (BOOL)spotifyPlaying {
    id app=call(MC(),@"nowPlayingApplication");
    NSString*bid=call(app,@"displayIdentifier")?:call(app,@"bundleIdentifier");
    return [bid isEqualToString:APP_ID];
}
- (BOOL)visible {
    if(![self spotifyPlaying]) return NO;
    id v=[self appPrefs][@"ncWidget"]; return v?[v boolValue]:YES;
}

- (void)refresh {
    if(!_bg) return;
    BOOL vis=[self visible]; _view.hidden=!vis; wlog(@"refresh visible=%d",vis); if(!vis) return;
    id mc=MC();
    [_title setText:call(mc,@"nowPlayingTitle")?:@""]; [_artist setText:call(mc,@"nowPlayingArtist")?:@""];
    NSString*ctx=[self appPrefs][@"spContext"];   // von Spotify6 gespeichert (Playlist, Album, Artist, Lieblingssongs)
    _from.text=([ctx isKindOfClass:[NSString class]] && [ctx length])?[@"Playing from " stringByAppendingString:ctx]:@"";
    [self layoutText];
    id art=call(mc,@"artworkData");
    if(![art isKindOfClass:[NSData class]]){ NSDictionary*info=nil; @try{ info=[mc valueForKey:@"_nowPlayingInfo"]; }@catch(NSException*e){} art=info[@"artworkData"]; }
    if([art isKindOfClass:[NSData class]] && ![art isEqualToData:_artData]){ _artData=art; _cover.image=[UIImage imageWithData:art]; }
    BOOL playing=[mc respondsToSelector:@selector(isPlaying)] && ((BOOL(*)(id,SEL))objc_msgSend)(mc,@selector(isPlaying));
    [_play setImage:glyph(playing?@"pause":@"play") forState:UIControlStateNormal];
    if(_shown){ [_title startAfter:1.5]; [_artist startAfter:1.5]; }   // neuer Titel während sichtbar: wieder laufen lassen
}

// ---- Tasten: dieselben Befehle wie auf dem Sperrbildschirm ----
- (void)playTap { ((BOOL(*)(id,SEL))objc_msgSend)(MC(),@selector(togglePlayPause)); [self performSelector:@selector(refresh) withObject:nil afterDelay:0.3]; }
- (void)nextTap { ((BOOL(*)(id,SEL,int))objc_msgSend)(MC(),@selector(changeTrack:),1); }
- (void)prevTap { ((BOOL(*)(id,SEL,int))objc_msgSend)(MC(),@selector(changeTrack:),-1); }

// ---- BBWeeAppController ----
- (UIView *)view { if(!_view) [self loadView]; return _view; }
- (void)loadPlaceholderView { if(!_view) [self loadView]; }   // iOS 6: erst Platzhalter, dann volle Ansicht
- (void)loadFullView { if(!_view) [self loadView]; [self refresh]; }
- (float)viewHeight { return [self visible]?H:0; }
- (void)viewWillAppear { [self refresh]; }
- (void)viewDidAppear { _shown=YES; [_title startAfter:1.5]; [_artist startAfter:1.5]; }   // Lauftext 1,5 s nach dem Aufziehen
- (void)viewWillDisappear { _shown=NO; [_title stop]; [_artist stop]; }
- (void)viewDidDisappear { _shown=NO; [_title stop]; [_artist stop]; }
@end
