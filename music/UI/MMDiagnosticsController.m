#import "MMDiagnosticsController.h"
#import "SpotTheme.h"
#import "MMNativeUI.h"
#import "MMLayout.h"
#import "MMSpotify.h"
#import "MMRootController.h"
#import "MMTrackListController.h"
#import "MeshL10n.h"

@implementation MMDiagnosticsController {
    UITextView *_text;
    UIButton *_testBtn;
    NSMutableArray *_test;   // Zeilen des Verbindungstests (nil = noch nicht gelaufen)
}

- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:MMPageFrame(YES)];
    self.view.backgroundColor=[SpotTheme pageBackground];
    CGFloat W=self.view.bounds.size.width, H=self.view.bounds.size.height;
    UINavigationBar *navBar=[MMNativeUI navigationBarWithTitle:L(@"Debug info") width:W];
    navBar.topItem.leftBarButtonItem=[MMNativeUI backItemTarget:self action:@selector(close)];
    navBar.topItem.rightBarButtonItem=[MMNativeUI itemWithTitle:L(@"Copy") target:self action:@selector(copyText)];
    [self.view addSubview:navBar];

    // Verbindungstest: prüft Netz, Spotify-Server/Ports, Song-Schlüssel und Download, jeweils mit Zeitlimit
    _testBtn=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    _testBtn.frame=CGRectMake(16,50,W-32,36);
    _testBtn.titleLabel.font=[UIFont boldSystemFontOfSize:14];
    [_testBtn setTitle:L(@"Run connection test") forState:UIControlStateNormal];
    [_testBtn addTarget:self action:@selector(runTest) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:_testBtn];

    _text=[[UITextView alloc] initWithFrame:CGRectMake(0,94,W,H-94)];
    _text.editable=NO; _text.backgroundColor=[SpotTheme card]; _text.textColor=[SpotTheme ink];
    _text.font=[UIFont fontWithName:@"Courier" size:10]; _text.contentInset=UIEdgeInsetsMake(0,0,MMPageBottomInset(90),0);
    _text.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; [self.view addSubview:_text];
    _text.text=[self report];
    MMAutoMask(self.view);   // iPad: Unteransichten folgen der Breite beim Drehen
}
- (NSString *)report {
    NSDictionary*info=[[NSBundle mainBundle] infoDictionary];
    NSDateFormatter*df=[[NSDateFormatter alloc] init]; df.dateFormat=@"yyyy-MM-dd HH:mm";
    NSMutableString*r=[NSMutableString string];
    [r appendFormat:@"Spofity %@ · %@ · iOS %@\n",info[@"CFBundleShortVersionString"]?:@"?",[MMSpotify deviceModel],[UIDevice currentDevice].systemVersion];
    [r appendFormat:@"Account: %@ · Country: %@\n",[MMSpotify productType]?:@"unknown",[MMSpotify country]?:@"?"];
    [r appendFormat:@"Song keys: %@\n",[MMSpotify keyStatus]];
    [r appendFormat:@"Network: %@ · Free: %@\n",[MMSpotify networkReachable]?@"online":@"offline",[MMTrackListController fmtBytes:[MMSpotify freeDiskBytes]]];
    [r appendFormat:@"Time: %@\n\n",[df stringFromDate:[NSDate date]]];
    if(_test){ [r appendString:@"--- Connection test ---\n"]; [r appendString:[_test componentsJoinedByString:@"\n"]]; [r appendString:@"\n\n--- Log ---\n"]; }
    NSString*log=[MMSpotify diagnosticLog];
    [r appendString:log.length?log:L(@"(no log lines yet: play a song, then open this page again)")];
    return r;
}
- (void)runTest {
    _test=[NSMutableArray arrayWithObject:L(@"running … (up to about a minute)")];
    _testBtn.enabled=NO; _testBtn.alpha=0.5; _text.text=[self report]; [_text setContentOffset:CGPointZero animated:NO];
    [MMSpotify runConnectionTest:^(NSString*l){
        if(_test.count==1 && [_test[0] hasPrefix:@"running"]) [_test removeAllObjects];
        [_test addObject:l]; _text.text=[self report];
    } done:^{ _testBtn.enabled=YES; _testBtn.alpha=1; _text.text=[self report]; }];
}
- (void)copyText {
    [UIPasteboard generalPasteboard].string=_text.text;
    [[MMRootController shared] showDownloadMessage:L(@"Copied")];
}
- (void)close { [[MMRootController shared] popContent]; }
@end
