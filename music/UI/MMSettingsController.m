#import "MMSettingsController.h"
#import "SpotTheme.h"
#import "MMSpotify.h"
#import "MMRootController.h"
#import "MMTrackListController.h"
#import "MMKeySetupController.h"
#import "MMKeepAlive.h"
#import "MeshL10n.h"

@interface MMSettingsController () <UITableViewDataSource, UITableViewDelegate>
@end

@implementation MMSettingsController {
    UITableView *_table;
    NSArray *_sections;   // @[ @{title, footer, rows:@[ @{kind: switch|link|info|danger, title, key} ]} ]
}

- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    self.view.backgroundColor=[SpotTheme bg];
    CGFloat W=self.view.bounds.size.width, H=self.view.bounds.size.height;
    UIButton*back=[UIButton buttonWithType:UIButtonTypeCustom]; back.frame=CGRectMake(8,8,80,34);
    [SpotTheme styleBackButton:back]; back.titleLabel.font=[UIFont systemFontOfSize:14];
    [back addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:back];
    UILabel*nav=[[UILabel alloc] initWithFrame:CGRectMake(90,8,W-180,34)]; nav.text=L(@"Settings"); nav.font=[UIFont boldSystemFontOfSize:16];
    nav.textColor=[SpotTheme ink]; nav.textAlignment=NSTextAlignmentCenter; nav.backgroundColor=[UIColor clearColor]; [self.view addSubview:nav];

    _table=[[UITableView alloc] initWithFrame:CGRectMake(0,46,W,H-46) style:UITableViewStyleGrouped];
    _table.backgroundView=nil; _table.backgroundColor=[SpotTheme bg];   // iOS 6: sonst Nadelstreifen-Hintergrund
    _table.separatorColor=[SpotTheme line]; _table.dataSource=self; _table.delegate=self; _table.rowHeight=50;
    _table.contentInset=UIEdgeInsetsMake(0,0,90,0); _table.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_table];
    [self build];
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; [self build]; [_table reloadData]; }   // z. B. nach dem Suchschlüssel
- (void)build {
    _sections=@[
      @{@"title":L(@"Playback & downloads"),@"footer":L(@"Keeps saving offline songs while Spotify6 is in the background."),
        @"rows":@[@{@"kind":@"switch",@"title":L(@"Background download"),@"key":@"bg"}]},
      @{@"title":L(@"Display"),@"footer":L(@"Big covers: albums and playlists open with their cover at the top and numbered songs."),
        @"rows":@[@{@"kind":@"switch",@"title":L(@"Cover Flow when rotated"),@"key":@"cflow"},
                  @{@"kind":@"switch",@"title":L(@"Big album covers"),@"key":@"cover"}]},
      @{@"title":L(@"Notification Center"),@"footer":L(@"Shows the current song with play, back and next in Notification Center."),
        @"rows":@[@{@"kind":@"switch",@"title":L(@"Now playing widget"),@"key":@"ncw"}]},
      @{@"title":L(@"Search"),@"footer":L(@"Search uses your own free Spotify developer key."),
        @"rows":@[@{@"kind":@"link",@"title":[MMSpotify hasSearchKey]?L(@"Change search key"):L(@"Unlock search"),@"key":@"key"}]},
      @{@"title":L(@"Account"),@"footer":@"",
        @"rows":@[@{@"kind":@"info",@"title":L(@"Logged in to Spotify")},   // der Benutzername ist nur eine Kennung (31xh…), nichts zum Anzeigen
                  @{@"kind":@"danger",@"title":L(@"Log out"),@"key":@"logout"}]}];
}
- (BOOL)valueFor:(NSString *)key {
    if([key isEqual:@"bg"]) return [MMKeepAlive enabled];
    if([key isEqual:@"cflow"]) return [MMRootController coverFlowOnRotate];
    if([key isEqual:@"ncw"]){ id v=[[NSUserDefaults standardUserDefaults] objectForKey:@"ncWidget"]; return v?[v boolValue]:YES; }   // liest das Widget in SpringBoard
    return [MMTrackListController coverStyle];
}
- (void)switched:(UISwitch *)sw {
    NSString*key=@[@"bg",@"cflow",@"cover",@"ncw"][sw.tag];
    if([key isEqual:@"bg"]) [MMKeepAlive setEnabled:sw.on];
    else if([key isEqual:@"ncw"]){ [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:@"ncWidget"]; [[NSUserDefaults standardUserDefaults] synchronize]; }
    else if([key isEqual:@"cflow"]) [MMRootController setCoverFlowOnRotate:sw.on];
    else [MMTrackListController setCoverStyle:sw.on];   // gilt ab dem nächsten Öffnen einer Liste
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return _sections.count; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return [_sections[s][@"rows"] count]; }
- (CGFloat)tableView:(UITableView *)tv heightForHeaderInSection:(NSInteger)s { return 40; }
- (UIView *)tableView:(UITableView *)tv viewForHeaderInSection:(NSInteger)s {
    UIView*v=[[UIView alloc] initWithFrame:CGRectMake(0,0,tv.bounds.size.width,40)];
    UILabel*l=[[UILabel alloc] initWithFrame:CGRectMake(20,16,tv.bounds.size.width-40,20)]; l.text=[_sections[s][@"title"] uppercaseString];
    l.font=[UIFont boldSystemFontOfSize:12]; l.textColor=[SpotTheme muted]; l.backgroundColor=[UIColor clearColor]; [v addSubview:l];
    return v;
}
- (CGFloat)tableView:(UITableView *)tv heightForFooterInSection:(NSInteger)s { return [_sections[s][@"footer"] length]?36:8; }
- (UIView *)tableView:(UITableView *)tv viewForFooterInSection:(NSInteger)s {
    UIView*v=[[UIView alloc] initWithFrame:CGRectMake(0,0,tv.bounds.size.width,36)];
    UILabel*l=[[UILabel alloc] initWithFrame:CGRectMake(20,4,tv.bounds.size.width-40,30)]; l.text=_sections[s][@"footer"]; l.numberOfLines=2;
    l.font=[UIFont systemFontOfSize:11]; l.textColor=[SpotTheme faint]; l.backgroundColor=[UIColor clearColor]; [v addSubview:l];
    return v;
}
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    NSDictionary*r=_sections[ip.section][@"rows"][ip.row]; NSString*kind=r[@"kind"];
    UITableViewCell*c=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];   // wenige Zeilen: kein Wiederverwenden nötig
    c.backgroundColor=[SpotTheme card]; c.textLabel.backgroundColor=[UIColor clearColor];
    c.textLabel.text=r[@"title"]; c.textLabel.font=[UIFont systemFontOfSize:16]; c.textLabel.textColor=[SpotTheme ink];
    c.selectionStyle=UITableViewCellSelectionStyleNone;
    if([kind isEqual:@"switch"]){
        UISwitch*sw=[[UISwitch alloc] init]; sw.onTintColor=[SpotTheme green]; sw.on=[self valueFor:r[@"key"]];
        sw.tag=[@[@"bg",@"cflow",@"cover",@"ncw"] indexOfObject:r[@"key"]];
        [sw addTarget:self action:@selector(switched:) forControlEvents:UIControlEventValueChanged]; c.accessoryView=sw;
    } else if([kind isEqual:@"link"]){
        c.accessoryType=UITableViewCellAccessoryDisclosureIndicator; c.selectionStyle=UITableViewCellSelectionStyleGray;
    } else if([kind isEqual:@"info"]){
        c.textLabel.textColor=[SpotTheme muted]; c.textLabel.font=[UIFont systemFontOfSize:14];
    } else if([kind isEqual:@"danger"]){
        c.textLabel.textColor=[UIColor colorWithRed:0.95 green:0.33 blue:0.33 alpha:1]; c.textLabel.textAlignment=NSTextAlignmentCenter;
        c.textLabel.font=[UIFont boldSystemFontOfSize:16]; c.selectionStyle=UITableViewCellSelectionStyleGray;
    }
    return c;
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSString*key=_sections[ip.section][@"rows"][ip.row][@"key"];
    if([key isEqual:@"key"]){
        MMKeySetupController*k=[[MMKeySetupController alloc] init]; k.skippable=NO;
        k.onDone=^(BOOL saved){ [[MMRootController shared] popContent]; };
        [[MMRootController shared] pushContent:k];
    } else if([key isEqual:@"logout"]) [MMRootController confirmLogout];
}
- (void)close { [[MMRootController shared] popContent]; }
@end
