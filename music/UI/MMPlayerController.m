#import "MMPlayerController.h"
#import "SpotTheme.h"
#import "MMAudio.h"
#import "MMSpotify.h"
#import "MMRootController.h"
#import "MMCovers.h"
#import "MeshL10n.h"
#import "MMTrackListController.h"
#import "MMArtistController.h"
#import "MMQueueController.h"
#import "MMSongMenu.h"

@interface MMPlayerController () <UIGestureRecognizerDelegate>
@end

@implementation MMPlayerController {
    BOOL _playing;
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
    BOOL _appBehind;           // beim Runterziehen liegt die App selbst hinter dem Player (iOS 6 nimmt sie währenddessen aus dem Fenster)
}
- (UIColor *)c:(int)r g:(int)g b:(int)b { return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]; }

- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];   // ohne Statusleiste
    self.view.backgroundColor=[self c:40 g:34 b:52];   // dunkler Verlauf-Ton
    CGFloat W=self.view.bounds.size.width, H=self.view.bounds.size.height;
    _playing=[MMAudio isPlaying];

    // Kopf: Chevron runter + Albumzeile
    UIButton*down=[UIButton buttonWithType:UIButtonTypeCustom]; down.frame=CGRectMake(6,8,40,34);
    UIBezierPath*ch=[UIBezierPath bezierPath]; ch.lineWidth=2; ch.lineCapStyle=kCGLineCapRound;
    [ch moveToPoint:CGPointMake(12,14)];[ch addLineToPoint:CGPointMake(20,22)];[ch addLineToPoint:CGPointMake(28,14)];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40,34),NO,0);[[SpotTheme ink] setStroke];[ch stroke];UIImage*chImg=UIGraphicsGetImageFromCurrentImageContext();UIGraphicsEndImageContext();
    [down setImage:chImg forState:UIControlStateNormal];
    [down addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:down];
    // Runterziehen von überall oberhalb der Fortschrittsleiste: Player folgt dem Finger (darunter: Spulen und Tasten)
    UIPanGestureRecognizer*drag=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragDown:)];
    drag.delegate=self; [self.view addGestureRecognizer:drag];
    // Warteschlange: Symbol oben rechts (drei Linien, wie in der Spotify-App), gegenüber vom Schließen-Pfeil
    UIButton*qb=[UIButton buttonWithType:UIButtonTypeCustom]; qb.frame=CGRectMake(W-46,8,40,34);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(22,18),NO,0); [[SpotTheme ink] setFill];
    for(int i=0;i<3;i++){ UIRectFill(CGRectMake(6,2+i*6,16,2)); UIRectFill(CGRectMake(0,2+i*6,2,2)); }
    [qb setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal]; UIGraphicsEndImageContext();
    [qb addTarget:self action:@selector(openQueue) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:qb];
    UILabel*a1=[[UILabel alloc] initWithFrame:CGRectMake(50,10,W-100,14)]; a1.text=L(@"SONG FROM ALBUM"); a1.font=[UIFont systemFontOfSize:10]; a1.textColor=[SpotTheme muted]; a1.textAlignment=NSTextAlignmentCenter; [self.view addSubview:a1];
    UILabel*a2=[[UILabel alloc] initWithFrame:CGRectMake(50,24,W-100,18)]; a2.font=[UIFont boldSystemFontOfSize:12]; a2.textColor=[SpotTheme ink]; a2.textAlignment=NSTextAlignmentCenter; [self.view addSubview:a2];
    _albumLbl=a2; [self refreshAlbum];

    // ---- Layout von UNTEN verankert, damit alles in 480pt passt ----
    CGFloat devY   = H-28;      // "Verfügbare Geräte"
    CGFloat ctrlCy = H-64;      // Steuerungs-Mitte (Play-Button-Top = ctrlCy-19, unten bleiben ~19 pt)
    CGFloat progY  = H-124;     // Fortschrittsleiste
    CGFloat arY    = progY-40;  // Künstler
    CGFloat tiY    = arY-28;    // Titel
    CGFloat coverTop = 66;
    CGFloat side = (tiY-16) - coverTop; if(side>W-48) side=W-48; if(side<80) side=80;
    CGFloat coverX = (W-side)/2;

    // großes Cover (echtes Bild kommt später rein; dunkler Platzhalter)
    UIView*cover=[[UIView alloc] initWithFrame:CGRectMake(coverX,coverTop,side,side)]; cover.backgroundColor=[SpotTheme card]; cover.layer.cornerRadius=4; cover.clipsToBounds=YES; cover.tag=99;
    UIActivityIndicatorView*cs=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    cs.center=CGPointMake(side/2,side/2); cs.tag=98; [cs startAnimating]; [cover addSubview:cs];
    [self.view addSubview:cover];
    _coverView=cover;
    [cover addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openAlbum)]];   // Cover -> Album

    // Titel + Künstler
    UILabel*t=[[UILabel alloc] initWithFrame:CGRectMake(24,tiY,W-48-44,26)]; t.text=_trackTitle?:@""; t.font=[UIFont boldSystemFontOfSize:19]; t.textColor=[SpotTheme ink]; [self.view addSubview:t]; _titleLbl=t;
    UILabel*ar=[[UILabel alloc] initWithFrame:CGRectMake(24,arY,W-48-44,20)]; ar.text=_trackArtist?:@""; ar.font=[SpotTheme body]; ar.textColor=[SpotTheme muted]; [self.view addSubview:ar]; _artistLbl=ar;
    ar.userInteractionEnabled=YES; [ar addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openArtist)]];   // Artist -> Artist-Seite
    // (+) rechts neben Titel/Artist: laufenden Titel zu den Lieblingssongs oder in eine Playlist
    UIButton*plus=[UIButton buttonWithType:UIButtonTypeCustom]; plus.frame=CGRectMake(W-24-40,tiY+6,44,44);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(28,28),NO,0); [[SpotTheme ink] setStroke];
    UIBezierPath*pc=[UIBezierPath bezierPathWithOvalInRect:CGRectMake(1.5,1.5,25,25)]; pc.lineWidth=1.6; [pc stroke];
    UIBezierPath*pp=[UIBezierPath bezierPath]; pp.lineWidth=1.8; pp.lineCapStyle=kCGLineCapRound;
    [pp moveToPoint:CGPointMake(14,8.5)]; [pp addLineToPoint:CGPointMake(14,19.5)]; [pp moveToPoint:CGPointMake(8.5,14)]; [pp addLineToPoint:CGPointMake(19.5,14)]; [pp stroke];
    [plus setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal]; UIGraphicsEndImageContext();
    [plus addTarget:self action:@selector(saveCurrent) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:plus];
    [self loadCover];

    // Fortschrittsleiste
    _trackX=24; _trackW=W-48; _progY=progY;
    UIView*track=[[UIView alloc] initWithFrame:CGRectMake(24,progY,W-48,3)]; track.backgroundColor=[self c:80 g:80 b:80]; track.layer.cornerRadius=1.5; [self.view addSubview:track];
    _progView=[[UIView alloc] initWithFrame:CGRectMake(24,progY,0,3)]; _progView.backgroundColor=[SpotTheme ink]; _progView.layer.cornerRadius=1.5; [self.view addSubview:_progView];
    _thumbView=[[UIView alloc] initWithFrame:CGRectMake(24-5,progY-3.5,10,10)]; _thumbView.backgroundColor=[SpotTheme ink]; _thumbView.layer.cornerRadius=5; [self.view addSubview:_thumbView];
    _t1=[[UILabel alloc] initWithFrame:CGRectMake(24,progY+10,60,14)]; _t1.text=@"0:00"; _t1.font=[UIFont systemFontOfSize:11]; _t1.textColor=[SpotTheme muted]; [self.view addSubview:_t1];
    _t2=[[UILabel alloc] initWithFrame:CGRectMake(W-84,progY+10,60,14)]; _t2.text=@"-0:00"; _t2.font=[UIFont systemFontOfSize:11]; _t2.textColor=[SpotTheme muted]; _t2.textAlignment=NSTextAlignmentRight; [self.view addSubview:_t2];
    // Spul-Bereich (tippen oder ziehen)
    UIView*seek=[[UIView alloc] initWithFrame:CGRectMake(_trackX-12,progY-20,_trackW+24,44)];
    [seek addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSeek:)]];
    [seek addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSeek:)]];
    [self.view addSubview:seek];

    // Steuerung
    _shufBtn=[UIButton buttonWithType:UIButtonTypeCustom]; _shufBtn.frame=CGRectMake(24-11,ctrlCy-11,44,44);
    [_shufBtn addTarget:self action:@selector(toggleShuffle) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_shufBtn]; [self drawShuffle];
    [self addCtrl:@"prev" x:W*0.28 cy:ctrlCy sz:26 action:nil];
    _playBtn=[[UIView alloc] initWithFrame:CGRectMake(W/2-32,ctrlCy-19,64,64)]; _playBtn.backgroundColor=[SpotTheme ink]; _playBtn.layer.cornerRadius=32; [self.view addSubview:_playBtn];
    UIButton*pb=[UIButton buttonWithType:UIButtonTypeCustom]; pb.frame=_playBtn.bounds; [pb addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside]; [_playBtn addSubview:pb];
    [self drawPlayPause];
    _spinner=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.frame=_playBtn.bounds; _spinner.hidesWhenStopped=YES; _spinner.userInteractionEnabled=NO; [_playBtn addSubview:_spinner];
    [self addCtrl:@"next" x:W*0.72-26 cy:ctrlCy sz:26 action:nil];
    _repBtn=[UIButton buttonWithType:UIButtonTypeCustom]; _repBtn.frame=CGRectMake(W-46-11,ctrlCy-11,44,44);
    [_repBtn addTarget:self action:@selector(cycleRepeat) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_repBtn]; [self drawRepeat];
    // Tap-Flächen für Zurück/Weiter
    UIButton*prevB=[UIButton buttonWithType:UIButtonTypeCustom]; prevB.frame=CGRectMake(W*0.28-9,ctrlCy-9,44,44); [prevB addTarget:self action:@selector(prevTrack) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:prevB];
    UIButton*nextB=[UIButton buttonWithType:UIButtonTypeCustom]; nextB.frame=CGRectMake(W*0.72-26-9,ctrlCy-9,44,44); [nextB addTarget:self action:@selector(nextTrack) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:nextB];

    (void)devY;  // "Verfügbare Geräte" entfernt (keine Connect-Funktion)
}

- (void)drawPlayPause {
    for(UIView*v in _playBtn.subviews){ if(v.tag==7)[v removeFromSuperview]; }
    UIView*icon=[[UIView alloc] initWithFrame:_playBtn.bounds]; icon.tag=7; icon.userInteractionEnabled=NO;
    if(_playing){ // Pause = zwei Balken
        for(int i=0;i<2;i++){ UIView*b=[[UIView alloc] initWithFrame:CGRectMake(23+i*12,20,6,24)]; b.backgroundColor=[SpotTheme bg]; [icon addSubview:b]; }   // 23..41 -> mittig im 64er-Kreis
    } else { // Play = Dreieck
        UIBezierPath*tri=[UIBezierPath bezierPath]; [tri moveToPoint:CGPointMake(25,20)];[tri addLineToPoint:CGPointMake(25,44)];[tri addLineToPoint:CGPointMake(45,32)];[tri closePath];
        CAShapeLayer*sl=[CAShapeLayer layer]; sl.path=tri.CGPath; sl.fillColor=[[SpotTheme bg] CGColor]; [icon.layer addSublayer:sl];
    }
    [_playBtn addSubview:icon];
}
- (void)toggleShuffle { MMRootController*r=[MMRootController shared]; [r setShuffle:!r.shuffle]; [self drawShuffle]; }
// Spotify-Symbol: zwei gekreuzte Pfeile; an = grün + Punkt darunter
- (void)drawShuffle {
    BOOL on=[MMRootController shared].shuffle; CGFloat B=44, sz=22, o=11;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(B,B),NO,0);
    UIColor*col=on?[SpotTheme green]:[SpotTheme muted]; [col setStroke]; [col setFill];
    UIBezierPath*p=[UIBezierPath bezierPath]; p.lineWidth=2; p.lineCapStyle=kCGLineCapRound; p.lineJoinStyle=kCGLineJoinRound;
    #define P(x,y) CGPointMake(o+sz*(x),o+sz*(y))
    [p moveToPoint:P(0.05,0.25)]; [p addCurveToPoint:P(0.9,0.75) controlPoint1:P(0.5,0.25) controlPoint2:P(0.45,0.75)];
    [p moveToPoint:P(0.05,0.75)]; [p addCurveToPoint:P(0.9,0.25) controlPoint1:P(0.5,0.75) controlPoint2:P(0.45,0.25)];
    [p moveToPoint:P(0.74,0.1)];  [p addLineToPoint:P(0.92,0.25)]; [p addLineToPoint:P(0.74,0.4)];
    [p moveToPoint:P(0.74,0.6)];  [p addLineToPoint:P(0.92,0.75)]; [p addLineToPoint:P(0.74,0.9)];
    [p stroke];
    if(on) [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(B/2-2,o+sz+5,4,4)] fill];
    #undef P
    [_shufBtn setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal]; UIGraphicsEndImageContext();
}
- (void)cycleRepeat { MMRootController*r=[MMRootController shared]; r.repeatMode=(r.repeatMode+1)%3; [self drawRepeat]; }
// Spotify-Symbol: Schleife mit Pfeil; an = grün + Punkt, "Titel wiederholen" zusätzlich mit kleiner 1
- (void)drawRepeat {
    NSInteger m=[MMRootController shared].repeatMode; CGFloat B=44, sz=22, o=11;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(B,B),NO,0);
    UIColor*col=m?[SpotTheme green]:[SpotTheme muted]; [col setStroke]; [col setFill];
    UIBezierPath*p=[UIBezierPath bezierPath]; p.lineWidth=2; p.lineCapStyle=kCGLineCapRound; p.lineJoinStyle=kCGLineJoinRound;
    #define P(x,y) CGPointMake(o+sz*(x),o+sz*(y))
    // oben: von links unten hoch, nach rechts, Pfeil nach rechts
    [p moveToPoint:P(0.08,0.56)]; [p addLineToPoint:P(0.08,0.42)]; [p addQuadCurveToPoint:P(0.25,0.25) controlPoint:P(0.08,0.25)];
    [p addLineToPoint:P(0.88,0.25)]; [p moveToPoint:P(0.74,0.12)]; [p addLineToPoint:P(0.88,0.25)]; [p addLineToPoint:P(0.74,0.38)];
    // unten: von rechts oben runter, nach links, Pfeil nach links
    [p moveToPoint:P(0.92,0.44)]; [p addLineToPoint:P(0.92,0.58)]; [p addQuadCurveToPoint:P(0.75,0.75) controlPoint:P(0.92,0.75)];
    [p addLineToPoint:P(0.12,0.75)]; [p moveToPoint:P(0.26,0.62)]; [p addLineToPoint:P(0.12,0.75)]; [p addLineToPoint:P(0.26,0.88)];
    [p stroke];
    #undef P
    if(m==2){   // kleine "1" in der Mitte
        NSString*one=@"1"; UIFont*f=[UIFont boldSystemFontOfSize:9]; CGSize ts=[one sizeWithFont:f];
        [one drawAtPoint:CGPointMake(o+sz/2-ts.width/2,o+sz/2-ts.height/2+1) withFont:f];
    }
    if(m) [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(B/2-2,o+sz+5,4,4)] fill];
    [_repBtn setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal]; UIGraphicsEndImageContext();
}
- (void)togglePlay { [[MMRootController shared] togglePlayPause]; _playing=[MMAudio isPlaying]; [self drawPlayPause]; }   // über die Wiedergabe-Logik (Neustart nach Titelende)

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
    _titleLbl.text=title?:@""; _artistLbl.text=artist?:@""; [self loadCover]; [self refreshAlbum];
}
- (void)refreshAlbum { NSString*al=[MMRootController shared].nowPlaying[@"album"]; _albumLbl.text=al.length?al:(_trackArtist?:@""); }

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
- (void)openQueue { [self presentViewController:[[MMQueueController alloc] init] animated:YES completion:nil]; }
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
    [self.view addSubview:iv];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _timer=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    [self tick];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_timer invalidate]; _timer=nil;
}

static NSString* fmtTime(double s){ if(s<0)s=0; int m=(int)s/60, sec=(int)s%60; return [NSString stringWithFormat:@"%d:%02d",m,sec]; }

- (void)tick {
    double cur=[MMAudio currentTime], dur=[MMAudio duration];
    double frac=(dur>0)?(cur/dur):0; if(frac<0)frac=0; if(frac>1)frac=1;
    CGFloat w=_trackW*frac;
    _progView.frame=CGRectMake(_trackX,_progY,w,3);
    _thumbView.frame=CGRectMake(_trackX+w-5,_progY-3.5,10,10);
    _t1.text=fmtTime(cur);
    _t2.text=[NSString stringWithFormat:@"-%@",fmtTime(dur>cur?dur-cur:0)];
    // Laden -> Spinner statt Play/Pause; sonst Icon mit echtem Zustand synchronisieren
    UIView*icon=[_playBtn viewWithTag:7];
    if([MMSpotify isLoading]){
        if(!_spinner.isAnimating)[_spinner startAnimating];
        icon.hidden=YES;
        // Anzeige des alten Tracks zurücksetzen
        _progView.frame=CGRectMake(_trackX,_progY,0,3); _thumbView.frame=CGRectMake(_trackX-5,_progY-3.5,10,10);
        _t1.text=@"0:00"; _t2.text=@"-0:00";
    } else {
        [_spinner stopAnimating]; icon.hidden=NO;
        BOOL p=[MMAudio isPlaying];
        if(p!=_playing){ _playing=p; [self drawPlayPause]; }
    }
}

- (void)prevTrack { [[MMRootController shared] playPrev]; }
- (void)nextTrack { [[MMRootController shared] playNext]; }

- (void)handleSeek:(UIGestureRecognizer *)g {
    double dur=[MMAudio duration]; if(dur<=0) return;
    CGPoint p=[g locationInView:self.view];
    double frac=(p.x-_trackX)/_trackW; if(frac<0)frac=0; if(frac>1)frac=1;
    CGFloat w=_trackW*frac;
    _progView.frame=CGRectMake(_trackX,_progY,w,3); _thumbView.frame=CGRectMake(_trackX+w-5,_progY-3.5,10,10);
    _t1.text=fmtTime(frac*dur); _t2.text=[NSString stringWithFormat:@"-%@",fmtTime(dur-frac*dur)];
    BOOL tap=[g isKindOfClass:[UITapGestureRecognizer class]];
    if(tap || g.state==UIGestureRecognizerStateEnded) [MMAudio seekTo:frac*dur];
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }

// ---- Runterziehen am Schließen-Pfeil: Player folgt dem Finger; weit genug oder schnell = schließen, sonst zurückfedern ----
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g {
    if(![g isKindOfClass:[UIPanGestureRecognizer class]] || g.view!=self.view) return YES;
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
