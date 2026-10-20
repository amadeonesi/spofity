#import "MMPlayerController.h"
#import "SpotTheme.h"
#import "OJTheme.h"
#import "MMLayout.h"
#import "MMAudio.h"
#import "MMSpotify.h"
#import "MMRootController.h"
#import "MMCovers.h"
#import "MeshL10n.h"
#import "MMTrackListController.h"
#import "MMArtistController.h"
#import "MMQueueController.h"
#import "MMSongMenu.h"
#import <MediaPlayer/MediaPlayer.h>

@interface MMPlayerController () <UIGestureRecognizerDelegate>
@end

static NSString* fmtTime(double s);

static UIImage *ControlGlyph(NSString *kind, CGFloat s) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(s,s),NO,0);
    [[UIColor whiteColor] setFill];
    if([kind isEqualToString:@"play"]){
        UIBezierPath *p=[UIBezierPath bezierPath]; [p moveToPoint:CGPointMake(s*0.30,s*0.20)];
        [p addLineToPoint:CGPointMake(s*0.30,s*0.80)]; [p addLineToPoint:CGPointMake(s*0.76,s*0.50)]; [p closePath]; [p fill];
    } else if([kind isEqualToString:@"pause"]){
        [[UIBezierPath bezierPathWithRect:CGRectMake(s*0.30,s*0.20,s*0.13,s*0.60)] fill];
        [[UIBezierPath bezierPathWithRect:CGRectMake(s*0.57,s*0.20,s*0.13,s*0.60)] fill];
    } else if([kind isEqualToString:@"prev"]){
        [[UIBezierPath bezierPathWithRect:CGRectMake(s*0.12,s*0.20,s*0.08,s*0.60)] fill];
        UIBezierPath *p=[UIBezierPath bezierPath]; [p moveToPoint:CGPointMake(s*0.48,s*0.20)];
        [p addLineToPoint:CGPointMake(s*0.48,s*0.80)]; [p addLineToPoint:CGPointMake(s*0.20,s*0.50)]; [p closePath]; [p fill];
        UIBezierPath *q=[UIBezierPath bezierPath]; [q moveToPoint:CGPointMake(s*0.82,s*0.20)];
        [q addLineToPoint:CGPointMake(s*0.82,s*0.80)]; [q addLineToPoint:CGPointMake(s*0.54,s*0.50)]; [q closePath]; [q fill];
    } else { // next
        [[UIBezierPath bezierPathWithRect:CGRectMake(s*0.80,s*0.20,s*0.08,s*0.60)] fill];
        UIBezierPath *p=[UIBezierPath bezierPath]; [p moveToPoint:CGPointMake(s*0.52,s*0.20)];
        [p addLineToPoint:CGPointMake(s*0.52,s*0.80)]; [p addLineToPoint:CGPointMake(s*0.80,s*0.50)]; [p closePath]; [p fill];
        UIBezierPath *q=[UIBezierPath bezierPath]; [q moveToPoint:CGPointMake(s*0.18,s*0.20)];
        [q addLineToPoint:CGPointMake(s*0.18,s*0.80)]; [q addLineToPoint:CGPointMake(s*0.46,s*0.50)]; [q closePath]; [q fill];
    }
    UIImage *img=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext(); return img;
}

@implementation MMPlayerController {
    BOOL _playing, _scrubbing;
    UIView *_playBtn;
    UIView *_coverView;
    UILabel *_titleLbl;
    UILabel *_artistLbl;
    UILabel *_albumLbl;        // Kopfzeile "SONG FROM ALBUM" -> Albumname
    UIView *_progView, *_thumbView;
    UILabel *_t1, *_t2;
    CGFloat _trackX, _trackW, _progY;
    NSTimer *_timer;
    UIActivityIndicatorView *_spinner;
    UIButton *_shufBtn, *_repBtn;
    UIView *_col; CGSize _builtSize;   // Inhalt in einer Spalte (iPhone: ganze Breite, iPad: mittig, max. 528 pt); nach dem Drehen neu gebaut
    MMQueueController *_qDock; BOOL _builtDock;
    UIView *_loadView; double _loadFrac;           // grüner Ladebalken auf der Fortschrittslinie (_loadFrac < 0 = aus)   // iPad quer: Warteschlange als Spalte rechts, der Player rückt nach links
    BOOL _appBehind;           // beim Runterziehen liegt die App selbst hinter dem Player (iOS 6 nimmt sie währenddessen aus dem Fenster)
    UINavigationBar *_navBar;
    UIToolbar *_scrubBar;
    UILabel *_navAlbumLbl, *_navTrackLbl;
    UIToolbar *_controls;
    UISlider *_scrubber;
    UIProgressView *_loadBar;
    UIBarButtonItem *_prevItem, *_nextItem, *_playItem;
    MPVolumeView *_volume;
}
- (UIColor *)c:(int)r g:(int)g b:(int)b { return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]; }

- (void)loadView {
    _loadFrac=-1;
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];   // ohne Statusleiste
    self.view.backgroundColor=[SpotTheme pageBackground];
    _playing=[MMAudio isPlaying];
    // Runterziehen von überall oberhalb der Fortschrittsleiste: Player folgt dem Finger (darunter: Spulen und Tasten)
    UIPanGestureRecognizer*drag=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragDown:)];
    drag.delegate=self; [self.view addGestureRecognizer:drag];
    [self buildUI];
}
// Drehen wie die App (iPad alle Richtungen); nach dem Drehen baut sich die Spalte in der neuen Größe neu auf
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)o { return MMShouldAutorotate(o); }
- (BOOL)shouldAutorotate { return MMIsPad(); }
MM_IOS6_BEGIN
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return (UIInterfaceOrientationMask)MMSupportedOrientations(); }
MM_IOS6_END
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if(_qDock && self.view.bounds.size.width<self.view.bounds.size.height) [self closeQueueDock];   // hochkant: keine zwei Spalten
    if(MMIsPad() && (!CGSizeEqualToSize(self.view.bounds.size,_builtSize) || _builtDock!=(_qDock!=nil))){ [self buildUI]; [self tick]; }
    if(_qDock){ CGSize b=self.view.bounds.size; _qDock.view.frame=CGRectMake(b.width-320,0,320,b.height); }
}
- (void)buildUI {
    [_col removeFromSuperview];
    CGFloat FW=self.view.bounds.size.width-(_qDock?320:0), H=self.view.bounds.size.height, W=MMIsPad()?MIN(FW,528):FW;
    _builtDock=(_qDock!=nil);
    _col=[[UIView alloc] initWithFrame:CGRectMake(floor((FW-W)/2),0,W,H)]; [self.view insertSubview:_col atIndex:0]; _builtSize=self.view.bounds.size;
    self.view.backgroundColor=[UIColor blackColor]; _col.backgroundColor=[UIColor blackColor];

    // Native black navigation bar (Music app style). No tintColor: on iOS 5 that would color the bar itself.
    _navBar=[[UINavigationBar alloc] initWithFrame:CGRectMake(0,0,W,44)];
    _navBar.barStyle=UIBarStyleBlack; _navBar.translucent=NO;
    UINavigationItem *item=[[UINavigationItem alloc] initWithTitle:L(@"Now Playing")];
    CGFloat tvW=MIN(220,W-150);
    UIView *tv=[[UIView alloc] initWithFrame:CGRectMake(0,0,tvW,40)];
    _navAlbumLbl=[[UILabel alloc] initWithFrame:CGRectMake(0,1,tvW,16)];
    _navAlbumLbl.font=[UIFont systemFontOfSize:10]; _navAlbumLbl.textColor=[UIColor colorWithWhite:0.65 alpha:1];
    _navAlbumLbl.textAlignment=NSTextAlignmentCenter; _navAlbumLbl.backgroundColor=[UIColor clearColor]; _navAlbumLbl.adjustsFontSizeToFitWidth=YES; _navAlbumLbl.minimumFontSize=8;
    _navTrackLbl=[[UILabel alloc] initWithFrame:CGRectMake(0,17,tvW,20)];
    _navTrackLbl.font=[UIFont boldSystemFontOfSize:13]; _navTrackLbl.textColor=[UIColor whiteColor];
    _navTrackLbl.textAlignment=NSTextAlignmentCenter; _navTrackLbl.backgroundColor=[UIColor clearColor]; _navTrackLbl.adjustsFontSizeToFitWidth=YES; _navTrackLbl.minimumFontSize=9;
    [tv addSubview:_navAlbumLbl]; [tv addSubview:_navTrackLbl];
    tv.userInteractionEnabled=YES; [tv addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openArtist)]];
    item.titleView=tv;
    item.leftBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:L(@"Back") style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    UIBarButtonItem *add=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(saveCurrent)];
    UIBarButtonItem *queue=[[UIBarButtonItem alloc] initWithImage:MMTintedIcon(@"lucide-list",[UIColor whiteColor]) style:UIBarButtonItemStylePlain target:self action:@selector(openQueue)];
    item.rightBarButtonItems=@[queue,add];
    _navBar.items=@[item];
    [_col addSubview:_navBar];

    _scrubBar=[[UIToolbar alloc] initWithFrame:CGRectMake(0,44,W,54)];
    _scrubBar.barStyle=UIBarStyleBlackTranslucent; _scrubBar.translucent=YES;
    [_col addSubview:_scrubBar];

    CGFloat barH=50, volH=30, gap=8, bottomMargin=4;
    CGFloat volY=H-bottomMargin-volH, ctrlY=volY-gap-barH;

    // Scrubber at the top, then repeat/shuffle, then the big square artwork, then the native bottom bar.
    CGFloat scrubY=50;
    _trackX=44; _trackW=W-88; _progY=ctrlY;   // drag threshold above controls + volume
    _t1=[[UILabel alloc] initWithFrame:CGRectMake(8,scrubY,36,16)]; _t1.text=@"0:00"; _t1.font=[UIFont systemFontOfSize:11]; _t1.textColor=[UIColor colorWithWhite:0.75 alpha:1]; _t1.backgroundColor=[UIColor clearColor]; [_col addSubview:_t1];
    _t2=[[UILabel alloc] initWithFrame:CGRectMake(W-44,scrubY,36,16)]; _t2.text=@"-0:00"; _t2.font=[UIFont systemFontOfSize:11]; _t2.textColor=[UIColor colorWithWhite:0.75 alpha:1]; _t2.textAlignment=NSTextAlignmentRight; _t2.backgroundColor=[UIColor clearColor]; [_col addSubview:_t2];
    _scrubber=[[UISlider alloc] initWithFrame:CGRectMake(_trackX,scrubY,_trackW,30)];
    _scrubber.minimumValue=0; _scrubber.maximumValue=1; _scrubber.value=0;
    [_scrubber addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [_scrubber addTarget:self action:@selector(sliderEnded:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    [OJTheme applyAccentToView:_scrubber];
    [_col addSubview:_scrubber];
    _loadBar=[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    _loadBar.frame=CGRectMake(_trackX,scrubY+30,_trackW,2); _loadBar.hidden=YES; _loadBar.progress=0;
    [OJTheme applyAccentToView:_loadBar];
    [_col addSubview:_loadBar];

    _repBtn=[UIButton buttonWithType:UIButtonTypeCustom]; _repBtn.frame=CGRectMake(0,scrubY+16,32,32);
    [_repBtn addTarget:self action:@selector(cycleRepeat) forControlEvents:UIControlEventTouchUpInside]; [_col addSubview:_repBtn]; [self drawRepeat];
    _shufBtn=[UIButton buttonWithType:UIButtonTypeCustom]; _shufBtn.frame=CGRectMake(W-32,scrubY+16,32,32);
    [_shufBtn addTarget:self action:@selector(toggleShuffle) forControlEvents:UIControlEventTouchUpInside]; [_col addSubview:_shufBtn]; [self drawShuffle];

    // Bottom control bar.
    _controls=[[UIToolbar alloc] initWithFrame:CGRectMake(0,ctrlY,W,barH)];
    _controls.barStyle=UIBarStyleBlack; _controls.translucent=NO;
    _prevItem=[[UIBarButtonItem alloc] initWithImage:ControlGlyph(@"prev",34) style:UIBarButtonItemStylePlain target:self action:@selector(prevTrack)];
    _nextItem=[[UIBarButtonItem alloc] initWithImage:ControlGlyph(@"next",34) style:UIBarButtonItemStylePlain target:self action:@selector(nextTrack)];
    [self buildControlItems];
    [_col addSubview:_controls];
    _volume=[[MPVolumeView alloc] initWithFrame:CGRectMake(20,volY,W-40,volH)];
    _volume.showsRouteButton=NO;
    [_col addSubview:_volume];
    [self applyVolumeAccent];

    // Artwork fills the width and stays square; no rounded corners.
    CGFloat coverTop=98, availableBottom=ctrlY;
    CGFloat side=MIN(W-16, availableBottom-coverTop);
    if(side<80) side=80;
    coverTop += floor((availableBottom-coverTop-side)/2);
    CGFloat coverX=floor((W-side)/2);
    UIView*cover=[[UIView alloc] initWithFrame:CGRectMake(coverX,coverTop,side,side)];
    cover.backgroundColor=[UIColor colorWithWhite:0.14 alpha:1];
    cover.clipsToBounds=YES; cover.tag=99;
    _spinner=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _spinner.center=CGPointMake(side/2,side/2); _spinner.hidesWhenStopped=YES; [cover addSubview:_spinner];
    [_col addSubview:cover]; _coverView=cover;
    [cover addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openAlbum)]];
    [self loadCover];

    [self setLoadProgress:_loadFrac];
    [self refreshAlbum];
    [self tick];
}
- (void)buildControlItems {
    UIBarButtonItem *flex=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    _playItem=[[UIBarButtonItem alloc] initWithImage:ControlGlyph(_playing?@"pause":@"play",34) style:UIBarButtonItemStylePlain target:self action:@selector(togglePlay)];
    _controls.items=@[flex,_prevItem,flex,_playItem,flex,_nextItem,flex];
}
- (void)drawPlayPause {
    [self buildControlItems];
}
- (void)toggleShuffle { MMRootController*r=[MMRootController shared]; [r setShuffle:!r.shuffle]; [self drawShuffle]; }
// Spotify-Symbol: zwei gekreuzte Pfeile; an = grün + Punkt darunter
- (void)drawShuffle { [_shufBtn setImage:[SpotTheme shuffleIcon:[MMRootController shared].shuffle] forState:UIControlStateNormal]; }
- (void)cycleRepeat { MMRootController*r=[MMRootController shared]; r.repeatMode=(r.repeatMode+1)%3; [self drawRepeat]; }
// Spotify-Symbol: Schleife mit Pfeil; an = grün + Punkt, "Titel wiederholen" zusätzlich mit kleiner 1
- (void)drawRepeat { [_repBtn setImage:[SpotTheme repeatIcon:[MMRootController shared].repeatMode] forState:UIControlStateNormal]; }
- (void)togglePlay { [[MMRootController shared] togglePlayPause]; _playing=[MMAudio isPlaying]; [self drawPlayPause]; }   // über die Wiedergabe-Logik (Neustart nach Titelende)
- (void)prevTrack { [[MMRootController shared] playPrev]; }
- (void)nextTrack { [[MMRootController shared] playNext]; }

- (void)loadCover {
    if(!_coverURL.length) return;
    NSString*u=_coverURL;
    UIImageView*cur=[_coverView.subviews lastObject];
    if([cur isKindOfClass:[UIImageView class]] && [MMCovers cached:u]){ cur.image=[MMCovers cached:u]; return; }   // schon im Speicher -> sofort
    [MMCovers load:u completion:^(UIImage*img){
        if(!img || ![u isEqualToString:_coverURL]) return;   // veraltet (inzwischen weitergeskippt)
        for(UIView*v in _coverView.subviews)[v removeFromSuperview];
        UIImageView*iv=[[UIImageView alloc] initWithFrame:_coverView.bounds];
        iv.image=img; iv.contentMode=UIViewContentModeScaleAspectFill; iv.clipsToBounds=YES;
        [_coverView addSubview:iv];
    }];
}

// Von außen aufrufbar, wenn echte Metadaten/Cover nach dem Öffnen eintreffen.
- (void)updateTitle:(NSString *)title artist:(NSString *)artist cover:(NSString *)cover {
    self.trackTitle=title; self.trackArtist=artist; self.coverURL=cover;
    [self loadCover]; [self refreshAlbum];
    [_qDock reload];   // eingeblendete Warteschlange zeigt den neuen Titel
}
- (void)setLoadProgress:(double)frac {
    _loadFrac=frac; _loadBar.hidden=(frac<0);
    if(frac>=0) _loadBar.progress=MIN(1.0,frac);
}
- (void)refreshAlbum {
    NSString*al=[MMRootController shared].nowPlaying[@"album"];
    if(!al.length) al=_trackArtist?:@"";
    _navAlbumLbl.text=al;
    NSString*t=_trackTitle?:@"", *a=_trackArtist?:@"";
    _navTrackLbl.text=(a.length&&t.length)?[NSString stringWithFormat:@"%@ - %@",a,t]:t;
}
- (void)sliderChanged:(UISlider *)slider {
    _scrubbing=YES;
    double dur=[MMAudio duration]; if(dur<=0) return;
    double t=slider.value*dur; _t1.text=fmtTime(t); _t2.text=[NSString stringWithFormat:@"-%@",fmtTime(dur-t)];
}
- (void)sliderEnded:(UISlider *)slider {
    _scrubbing=NO;
    double dur=[MMAudio duration]; if(dur>0) [MMAudio seekTo:slider.value*dur];
}

// ---- Album / Artist des laufenden Titels öffnen: Player schließen, Seite im Inhaltsbereich zeigen ----
// IDs kommen aus den Titel-Metadaten; sind sie noch nicht da (gerade gewechselt), erst nachladen.
- (void)openPage:(BOOL)album {
    NSDictionary*np=[MMRootController shared].nowPlaying; if(!np) return;
    NSString*key=album?@"albumId":@"artistId";
    void (^go)(NSString*,NSString*)=^(NSString*pid,NSString*name){
        UIViewController*vc=album?[[MMTrackListController alloc] initWithTitle:name.length?name:L(@"Album") path:[@"albums/" stringByAppendingString:pid]]
                                 :[[MMArtistController alloc] initWithArtistId:pid name:name];
        [self dismissViewControllerAnimated:YES completion:^{ [[MMRootController shared] pushContent:vc]; }];
    };
    if([np[key] length]){ go(np[key], album?np[@"album"]:np[@"artist"]); return; }
    [MMSpotify fetchTrack:np[@"id"] completion:^(NSDictionary*info,NSString*e){
        if([info[key] length]) go(info[key], album?info[@"album"]:info[@"artist"]);
    }];
}
- (void)openAlbum { [self openPage:YES]; }
- (void)saveCurrent { NSDictionary*np=[MMRootController shared].nowPlaying; if(np) [MMSongMenu showSaveForTrack:np]; }
- (void)openQueue {
    if(MMIsPad() && UIInterfaceOrientationIsLandscape(self.interfaceOrientation)){ [self toggleQueueDock]; return; }   // quer: von rechts herein
    [self presentViewController:[[MMQueueController alloc] init] animated:YES completion:nil];
}
// ---- iPad quer: Warteschlange schiebt sich von rechts herein, die Player-Spalte rückt in die linke Fläche ----
- (void)toggleQueueDock {
    if(_qDock){ [self closeQueueDock]; return; }
    MMQueueController*q=[[MMQueueController alloc] init]; __weak MMPlayerController*ws=self; q.onClose=^{ [ws closeQueueDock]; };
    [self addChildViewController:q];
    CGSize b=self.view.bounds.size; q.view.frame=CGRectMake(b.width,0,320,b.height);
    UIView*edge=[[UIView alloc] initWithFrame:CGRectMake(0,0,1,b.height)]; edge.backgroundColor=[SpotTheme line]; edge.autoresizingMask=UIViewAutoresizingFlexibleHeight; [q.view addSubview:edge];
    [q viewWillAppear:YES]; [self.view addSubview:q.view]; [q didMoveToParentViewController:self];
    _qDock=q; [self slideColumn];
    [UIView animateWithDuration:0.3 animations:^{ q.view.frame=CGRectMake(b.width-320,0,320,b.height); }];
}
- (void)closeQueueDock {
    MMQueueController*q=_qDock; if(!q) return; _qDock=nil;
    [q willMoveToParentViewController:nil]; [self slideColumn];
    [UIView animateWithDuration:0.3 animations:^{ q.view.frame=CGRectOffset(q.view.frame,320,0); } completion:^(BOOL f){ [q.view removeFromSuperview]; [q removeFromParentViewController]; }];
}
// Spalte neu bauen und vom alten Platz an den neuen gleiten lassen
- (void)slideColumn {
    CGFloat oldX=_col.frame.origin.x; [self buildUI]; [self tick];
    _col.transform=CGAffineTransformMakeTranslation(oldX-_col.frame.origin.x,0);
    [UIView animateWithDuration:0.3 animations:^{ _col.transform=CGAffineTransformIdentity; }];
}
- (void)openArtist { [self openPage:NO]; }

- (void)addCtrl:(NSString *)kind x:(CGFloat)x cy:(CGFloat)cy sz:(CGFloat)sz action:(SEL)sel {
    UIImageView*iv=[[UIImageView alloc] initWithFrame:CGRectMake(x,cy,sz,sz)];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(sz,sz),NO,0);
    UIColor*col=([kind isEqualToString:@"shuffle"]||[kind isEqualToString:@"repeat"])?[SpotTheme muted]:[SpotTheme ink];
    [col setStroke]; [col setFill];
    UIBezierPath*p=[UIBezierPath bezierPath]; p.lineWidth=2; p.lineCapStyle=kCGLineCapRound; p.lineJoinStyle=kCGLineJoinRound;
    if([kind isEqualToString:@"prev"]||[kind isEqualToString:@"next"]){
        BOOL n=[kind isEqualToString:@"next"]; CGFloat a=n?0:sz, d=n?1:-1;
        UIBezierPath*t1=[UIBezierPath bezierPath]; [t1 moveToPoint:CGPointMake(a+d*sz*0.15,sz*0.2)];[t1 addLineToPoint:CGPointMake(a+d*sz*0.15,sz*0.8)];[t1 addLineToPoint:CGPointMake(a+d*sz*0.55,sz*0.5)];[t1 closePath];[t1 fill];
        UIBezierPath*bar=[UIBezierPath bezierPathWithRect:CGRectMake(n?sz*0.78:sz*0.1,sz*0.2,sz*0.12,sz*0.6)];[bar fill];
    } else if([kind isEqualToString:@"shuffle"]){
        [p moveToPoint:CGPointMake(sz*0.1,sz*0.3)];[p addLineToPoint:CGPointMake(sz*0.35,sz*0.3)];[p addLineToPoint:CGPointMake(sz*0.7,sz*0.7)];[p addLineToPoint:CGPointMake(sz*0.9,sz*0.7)];
        [p moveToPoint:CGPointMake(sz*0.1,sz*0.7)];[p addLineToPoint:CGPointMake(sz*0.35,sz*0.7)];[p addLineToPoint:CGPointMake(sz*0.7,sz*0.3)];[p addLineToPoint:CGPointMake(sz*0.9,sz*0.3)];[p stroke];
    } else { // repeat
        [p moveToPoint:CGPointMake(sz*0.25,sz*0.3)];[p addLineToPoint:CGPointMake(sz*0.75,sz*0.3)];[p addLineToPoint:CGPointMake(sz*0.75,sz*0.6)];
        [p moveToPoint:CGPointMake(sz*0.75,sz*0.7)];[p addLineToPoint:CGPointMake(sz*0.25,sz*0.7)];[p addLineToPoint:CGPointMake(sz*0.25,sz*0.4)];[p stroke];
    }
    iv.image=UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext();
    [_col addSubview:iv];
}
- (UISlider *)volumeSliderIn:(UIView *)v {
    if([v isKindOfClass:[UISlider class]]) return (UISlider *)v;
    for(UIView *s in v.subviews){ UISlider *r=[self volumeSliderIn:s]; if(r) return r; }
    return nil;
}
- (void)applyVolumeAccent {
    UISlider *sl=[self volumeSliderIn:_volume];
    if([sl respondsToSelector:@selector(setMinimumTrackTintColor:)]) sl.minimumTrackTintColor=[OJTheme accentColor];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self applyVolumeAccent];
    _timer=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    [self tick];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_timer invalidate]; _timer=nil;
    [[UIApplication sharedApplication] setStatusBarStyle:([OJTheme darkMode]?UIStatusBarStyleBlackOpaque:UIStatusBarStyleDefault) animated:NO];
}

static NSString* fmtTime(double s){ if(s<0)s=0; int m=(int)s/60, sec=(int)s%60; return [NSString stringWithFormat:@"%d:%02d",m,sec]; }

- (void)tick {
    double cur=[MMAudio currentTime], dur=[MMAudio duration];
    double frac=(dur>0)?(cur/dur):0; if(frac<0)frac=0; if(frac>1)frac=1;
    if(!_scrubbing) _scrubber.value=frac;
    _t1.text=fmtTime(cur);
    _t2.text=[NSString stringWithFormat:@"-%@",fmtTime(dur>cur?dur-cur:0)];
    if([MMSpotify isLoading]) [_spinner startAnimating]; else [_spinner stopAnimating];
    BOOL p=[MMAudio isPlaying];
    if(p!=_playing){ _playing=p; [self drawPlayPause]; }
    if(!_scrubbing && [MMSpotify isLoading]){
        _t1.text=@"0:00"; _t2.text=@"-0:00"; _scrubber.value=0;
    }
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }

// ---- Runterziehen am Schließen-Pfeil: Player folgt dem Finger; weit genug oder schnell = schließen, sonst zurückfedern ----
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g {
    if(![g isKindOfClass:[UIPanGestureRecognizer class]] || g.view!=self.view) return YES;
    if(MMIsPad() && self.interfaceOrientation!=UIInterfaceOrientationPortrait) return NO;   // iPad gedreht: Schließen über den Pfeil oben
    CGPoint p=[g locationInView:self.view], v=[(UIPanGestureRecognizer*)g velocityInView:self.view];
    return p.y<_progY-16 && v.y>0 && v.y>fabs(v.x);   // nur oberhalb der Leiste und nach unten
}
- (void)dragDown:(UIPanGestureRecognizer *)g {
    UIWindow*win=self.view.window; if(!win) return;
    CGFloat H=win.bounds.size.height, dy=MAX(0,[g translationInView:win].y);
    UIView*app=[MMRootController shared].view;
    if(g.state==UIGestureRecognizerStateBegan){
        // Die App selbst darunterlegen (kostet nichts); ein Bild davon zu zeichnen dauerte auf dem 3GS ~0,2 s und ließ den Finger hängen
        if(!app.window){ [win insertSubview:app belowSubview:self.view]; _appBehind=YES; }
    } else if(g.state==UIGestureRecognizerStateChanged){
        self.view.transform=CGAffineTransformMakeTranslation(0,dy);
    } else {
        BOOL dismiss=(g.state==UIGestureRecognizerStateEnded) && (dy>H*0.25 || [g velocityInView:win].y>700);
        BOOL put=_appBehind; _appBehind=NO;
        [UIView animateWithDuration:0.22 animations:^{ self.view.transform=dismiss?CGAffineTransformMakeTranslation(0,H):CGAffineTransformIdentity; }
                         completion:^(BOOL f){
            if(dismiss) [self dismissViewControllerAnimated:NO completion:nil];   // die App liegt schon richtig im Fenster
            else if(put) [app removeFromSuperview];                              // zurückgefedert: wieder wie vor dem Ziehen
        }];
    }
}
@end
