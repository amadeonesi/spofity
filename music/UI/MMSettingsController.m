#import "MMSettingsController.h"
#import "SpotTheme.h"
#import "MMNativeUI.h"
#import "OJTheme.h"
#import "MMLayout.h"
#import "MMSpotify.h"
#import "MMRootController.h"
#import "MMTrackListController.h"
#import "MMKeySetupController.h"
#import "MMKeepAlive.h"
#import "MeshL10n.h"
#import "MMDownloadsController.h"
#import "MMDiagnosticsController.h"

@interface MMSettingsController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
@end

@implementation MMSettingsController {
    UITableView *_table;
    UINavigationBar *_navBar;
    NSArray *_sections;   // @[ @{title, footer, rows:@[ @{kind: switch|link|info|danger, title, key} ]} ]
}

- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:MMPageFrame(YES)];
    self.view.backgroundColor=[SpotTheme pageBackground];
    CGFloat W=self.view.bounds.size.width, H=self.view.bounds.size.height;
    UINavigationBar *navBar=[MMNativeUI navigationBarWithTitle:L(@"Settings") width:W]; _navBar=navBar;
    navBar.topItem.leftBarButtonItem=[MMNativeUI backItemTarget:self action:@selector(close)];
    [self.view addSubview:navBar];

    // flach wie in der Spotify-App: iOS-6-Gruppen zeichnen helle Kanten und Schatten um jede Karte
    _table=[[UITableView alloc] initWithFrame:CGRectMake(0,44,W,H-44) style:UITableViewStyleGrouped];
    _table.backgroundColor=[UIColor clearColor]; _table.separatorStyle=UITableViewCellSeparatorStyleSingleLine;
    [OJTheme applyToGroupedTableView:_table];
    _table.backgroundColor=[OJTheme backgroundColor];
    _table.dataSource=self; _table.delegate=self; _table.rowHeight=54;
    _table.contentInset=_table.scrollIndicatorInsets=UIEdgeInsetsMake(0,0,MMPageBottomInset(90),0); _table.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_table];
    [self build];
    for(NSString*n in @[@"MMDownloadsChanged",@"MMDownloadDone"]) [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:n object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTheme) name:OJThemeDidChangeNotification object:nil];
    MMAutoMask(self.view);   // iPad: Unteransichten folgen der Breite beim Drehen
}
- (void)refresh { [self build]; [_table reloadData]; }   // z. B. nach dem Löschen auf der Downloads-Seite
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; [self build]; [_table reloadData]; }   // z. B. nach dem Suchschlüssel
- (void)build {
    NSArray*dl=[MMSpotify downloadedTracks]; long long dlBytes=0; for(NSDictionary*d in dl) dlBytes+=[d[@"bytes"] longLongValue];
    NSMutableArray *secs=[NSMutableArray arrayWithArray:@[
      @{@"title":L(@"Display"),@"footer":L(@"Big covers: albums and playlists open with their cover at the top and numbered songs."),
        @"rows":MMIsPad()?@[@{@"kind":@"switch",@"title":L(@"Cover Flow in sidebar"),@"key":@"cflow"},   // iPad: Drehen dreht das Layout, Cover Flow kommt aus der Seitenleiste
                            @{@"kind":@"switch",@"title":L(@"Big album covers"),@"key":@"cover"}]
                         :@[@{@"kind":@"switch",@"title":L(@"Cover Flow when rotated"),@"key":@"cflow"},
                            @{@"kind":@"switch",@"title":L(@"Big album covers"),@"key":@"cover"}]},
      @{@"title":L(@"Theme"),@"footer":L(@"Accent and light or dark appearance."),
        @"rows":@[@{@"kind":@"switch",@"title":L(@"Dark Mode"),@"key":@"darkmode"},
                  @{@"kind":@"link",@"title":L(@"Accent"),@"key":@"accent",
                    @"detail":[[OJTheme accentNames] objectAtIndex:[OJTheme accent]]}]},
      @{@"title":L(@"Notification Center"),@"footer":L(@"Shows the current song with play, back and next in Notification Center."),
        @"rows":@[@{@"kind":@"switch",@"title":L(@"Now playing widget"),@"key":@"ncw"}]},
      @{@"title":L(@"Search"),@"footer":L(@"Search uses your own free Spotify developer key."),
        @"rows":@[@{@"kind":@"link",@"title":[MMSpotify hasSearchKey]?L(@"Change search key"):L(@"Unlock search"),@"key":@"key"}]},
      @{@"title":L(@"Downloads"),@"footer":L(@"Background download keeps saving offline songs while Spofity is in the background."),
        @"rows":@[@{@"kind":@"link",@"title":L(@"Downloaded songs"),@"key":@"downloads",
                    @"detail":LF(@"%lu · %@",(unsigned long)dl.count,[MMTrackListController fmtBytes:dlBytes])},
                  @{@"kind":@"switch",@"title":L(@"Background download"),@"key":@"bg"}]},
      @{@"title":L(@"Song cache"),@"footer":L(@"Recently played songs are kept (up to 500 MB) so they play again without downloading."),
        @"rows":@[@{@"kind":@"info",@"title":L(@"In use"),@"detail":[MMTrackListController fmtBytes:[MMSpotify songCacheBytes]]},
                  @{@"kind":@"button",@"title":L(@"Clear song cache"),@"key":@"clearcache"}]},
      @{@"title":L(@"Account"),@"footer":@"",
        @"rows":@[@{@"kind":@"info",@"title":L(@"Logged in to Spotify")},   // der Benutzername ist nur eine Kennung (31xh…), nichts zum Anzeigen
                  @{@"kind":@"button",@"title":L(@"Log out"),@"key":@"logout",@"primary":@1}]},
      @{@"title":L(@"Help"),@"footer":L(@"If songs don't play, open this and send a screenshot to the developer."),
        @"rows":@[@{@"kind":@"link",@"title":L(@"Debug info"),@"key":@"diag"}]},
      @{@"title":L(@"Credits"),@"footer":L(@"Spofity is not affiliated with Spotify or Apple."),
        @"rows":@[@{@"kind":@"credit",@"title":L(@"Developer"),@"detail":@"onionjumoke / amadeonesi"},
                  @{@"kind":@"credit",@"title":L(@"Spotify6"),@"detail":@"iKiWI"},
                  @{@"kind":@"credit",@"title":L(@"riff (base of Spotify6)"),@"detail":@"SecondTrack"},
                  @{@"kind":@"credit",@"title":L(@"Icons"),@"detail":@"lucide.dev"},
                  @{@"kind":@"credit",@"title":L(@"Honorable thanks"),@"detail":@"DeepSeek 4.1 Flash"}]}]];
    [secs insertObject:@{@"title":@"",@"footer":@"",@"rows":@[@{@"kind":@"version",@"title":[NSString stringWithFormat:@"Spofity %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]}]} atIndex:MAX(0,(NSInteger)secs.count-1)];
    _sections=secs;
}
- (BOOL)valueFor:(NSString *)key {
    if([key isEqual:@"darkmode"]) return [OJTheme darkMode];
    if([key isEqual:@"bg"]) return [MMKeepAlive enabled];
    if([key isEqual:@"cflow"]) return [MMRootController coverFlowOnRotate];
    if([key isEqual:@"ncw"]){ id v=[[NSUserDefaults standardUserDefaults] objectForKey:@"ncWidget"]; return v?[v boolValue]:YES; }   // liest das Widget in SpringBoard
    return [MMTrackListController coverStyle];
}
- (void)switched:(UISwitch *)sw {
    NSString*key=@[@"bg",@"cflow",@"cover",@"ncw",@"darkmode"][sw.tag];
    if([key isEqual:@"darkmode"]) [OJTheme setDarkMode:sw.on];
    else if([key isEqual:@"bg"]) [MMKeepAlive setEnabled:sw.on];
    else if([key isEqual:@"ncw"]){ [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:@"ncWidget"]; [[NSUserDefaults standardUserDefaults] synchronize]; }
    else if([key isEqual:@"cflow"]) [MMRootController setCoverFlowOnRotate:sw.on];
    else [MMTrackListController setCoverStyle:sw.on];   // gilt ab dem nächsten Öffnen einer Liste
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return _sections.count; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return [_sections[s][@"rows"] count]; }
static UIFont* footFont(void){ return [UIFont systemFontOfSize:13]; }
- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip {
    NSDictionary*r=_sections[ip.section][@"rows"][ip.row]; NSString*kind=r[@"kind"];
    if([kind isEqual:@"version"]) return 48;
    if([kind isEqual:@"credit"]) return 54;
    return [kind isEqual:@"button"]?64:54;
}
- (CGFloat)tableView:(UITableView *)tv heightForHeaderInSection:(NSInteger)s {
    return [_sections[s][@"title"] length]?30:0;
}
- (CGFloat)tableView:(UITableView *)tv heightForFooterInSection:(NSInteger)s {
    NSString*f=_sections[s][@"footer"]; if(!f.length) return 0;
    return ceilf([f sizeWithFont:footFont() constrainedToSize:CGSizeMake(tv.bounds.size.width-32,200) lineBreakMode:NSLineBreakByWordWrapping].height)+10;
}
- (UIView *)tableView:(UITableView *)tv viewForHeaderInSection:(NSInteger)s {
    NSString*t=_sections[s][@"title"]; if(!t.length) return nil;
    UIView*v=[[UIView alloc] initWithFrame:CGRectMake(0,0,tv.bounds.size.width,30)];
    UILabel*l=[[UILabel alloc] initWithFrame:CGRectMake(16,6,tv.bounds.size.width-32,20)];
    l.text=t; l.font=[UIFont boldSystemFontOfSize:16]; l.textColor=[OJTheme sectionHeaderTextColor];
    l.backgroundColor=[UIColor clearColor]; [v addSubview:l]; return v;
}
- (UIView *)tableView:(UITableView *)tv viewForFooterInSection:(NSInteger)s {
    NSString*f=_sections[s][@"footer"]; if(!f.length) return nil;
    CGFloat h=[self tableView:tv heightForFooterInSection:s];
    UIView*v=[[UIView alloc] initWithFrame:CGRectMake(0,0,tv.bounds.size.width,h)];
    UILabel*l=[[UILabel alloc] initWithFrame:CGRectMake(16,2,tv.bounds.size.width-32,h-4)];
    l.text=f; l.font=footFont(); l.textColor=[OJTheme secondaryTextColor]; l.numberOfLines=0;
    l.backgroundColor=[UIColor clearColor]; [v addSubview:l]; return v;
}
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    NSDictionary*r=_sections[ip.section][@"rows"][ip.row]; NSString*kind=r[@"kind"]; CGFloat W=tv.bounds.size.width;
    UITableViewCell*c=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];   // wenige Zeilen: kein Wiederverwenden nötig
    c.backgroundColor=[SpotTheme card]; c.selectionStyle=UITableViewCellSelectionStyleNone;
    if([kind isEqual:@"version"]){
        UILabel*l=[[UILabel alloc] initWithFrame:CGRectMake(6,8,W-32,32)]; l.text=r[@"title"]; l.textAlignment=NSTextAlignmentCenter;
        l.font=footFont(); l.textColor=[SpotTheme faint]; l.backgroundColor=[UIColor clearColor]; [c.contentView addSubview:l]; return c;
    }
    if([kind isEqual:@"credit"]){
        UILabel*t=[[UILabel alloc] initWithFrame:CGRectMake(6,7,W-32,20)];
        t.text=r[@"title"]; t.font=[UIFont boldSystemFontOfSize:15]; t.textColor=[SpotTheme ink]; t.backgroundColor=[UIColor clearColor]; [c.contentView addSubview:t];
        UILabel*d=[[UILabel alloc] initWithFrame:CGRectMake(6,27,W-32,19)];
        d.text=r[@"detail"]; d.font=[UIFont systemFontOfSize:13]; d.textColor=[SpotTheme muted]; d.backgroundColor=[UIColor clearColor];
        d.adjustsFontSizeToFitWidth=YES; d.minimumFontSize=10; [c.contentView addSubview:d];
        return c;
    }
    UIView*sel=[[UIView alloc] init]; sel.backgroundColor=[SpotTheme card]; c.selectedBackgroundView=sel;
    if([kind isEqual:@"button"]){
        BOOL primary=[r[@"primary"] boolValue];
        UIButton*b=[UIButton buttonWithType:UIButtonTypeRoundedRect];
        b.frame=CGRectMake((W-240)/2,8,220,36);
        [b setTitle:r[@"title"] forState:UIControlStateNormal]; b.titleLabel.font=[UIFont boldSystemFontOfSize:15];
        if(primary) [b setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        b.accessibilityIdentifier=r[@"key"]; [b addTarget:self action:@selector(tapButton:) forControlEvents:UIControlEventTouchUpInside];
        [c.contentView addSubview:b]; return c;
    }
    UILabel*t=[[UILabel alloc] initWithFrame:CGRectMake(6,0,W-140,54)]; t.text=r[@"title"]; t.backgroundColor=[UIColor clearColor];
    t.font=[UIFont systemFontOfSize:16]; t.textColor=[kind isEqual:@"info"]&&!r[@"detail"]?[SpotTheme muted]:[SpotTheme ink]; [c.contentView addSubview:t];
    CGFloat right=W-26;
    if([kind isEqual:@"switch"]){
        UISwitch*sw=[[UISwitch alloc] init]; sw.onTintColor=[SpotTheme green]; sw.on=[self valueFor:r[@"key"]];
        sw.tag=[@[@"bg",@"cflow",@"cover",@"ncw",@"darkmode"] indexOfObject:r[@"key"]];
        sw.frame=CGRectMake(right-sw.frame.size.width,(54-sw.frame.size.height)/2,sw.frame.size.width,sw.frame.size.height);
        [sw addTarget:self action:@selector(switched:) forControlEvents:UIControlEventValueChanged]; [c.contentView addSubview:sw];
    } else if([kind isEqual:@"link"]){
        c.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
        c.selectionStyle=UITableViewCellSelectionStyleGray;
    }
    if(r[@"detail"]){
        UILabel*d=[[UILabel alloc] initWithFrame:CGRectMake(right-130,0,130,54)]; d.text=r[@"detail"]; d.textAlignment=NSTextAlignmentRight;
        d.font=[UIFont systemFontOfSize:15]; d.textColor=[SpotTheme muted]; d.backgroundColor=[UIColor clearColor]; [c.contentView addSubview:d];
    }
    return c;
}
- (void)tapButton:(UIButton *)b { [self run:b.accessibilityIdentifier]; }
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSDictionary*r=_sections[ip.section][@"rows"][ip.row];
    if([r[@"kind"] isEqual:@"link"]) [self run:r[@"key"]];
}
- (void)run:(NSString *)key {
    if([key isEqual:@"key"]){
        MMKeySetupController*k=[[MMKeySetupController alloc] init]; k.skippable=NO;
        k.onDone=^(BOOL saved){ [[MMRootController shared] popContent]; };
        [[MMRootController shared] pushContent:k];
    } else if([key isEqual:@"logout"]) [MMRootController confirmLogout];
    else if([key isEqual:@"diag"]) [[MMRootController shared] pushContent:[[MMDiagnosticsController alloc] init]];
    else if([key isEqual:@"downloads"]) [[MMRootController shared] pushContent:[[MMDownloadsController alloc] init]];
    else if([key isEqual:@"clearcache"]){ [MMSpotify clearSongCache]; [self build]; [_table reloadData]; }
    else if([key isEqual:@"accent"]) [self showAccentSheet];
}
- (void)showAccentSheet {
    NSArray *names=[OJTheme accentNames];
    UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:L(@"Accent") delegate:self cancelButtonTitle:L(@"Cancel")
                                            destructiveButtonTitle:nil otherButtonTitles:names[0],names[1],names[2],nil];
    if(MMIsPad()) [sheet showFromRect:CGRectMake(self.view.bounds.size.width/2,self.view.bounds.size.height-80,1,1) inView:self.view animated:YES];
    else [sheet showInView:self.view];
}
- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex<0 || buttonIndex>=(NSInteger)[[OJTheme accentNames] count]) return;
    [OJTheme setAccent:(OJThemeAccent)buttonIndex];
}
- (void)refreshTheme {
    self.view.backgroundColor=[SpotTheme pageBackground];
    [OJTheme applyToNavigationBar:_navBar];
    [OJTheme applyToGroupedTableView:_table];
    _table.backgroundColor=[OJTheme backgroundColor];
    [self build]; [_table reloadData];
}
- (void)close { [[MMRootController shared] popContent]; }
- (void)relayoutForSize:(CGSize)size { [_table reloadData]; }   // iPad gedreht: Zellen in neuer Breite
@end
