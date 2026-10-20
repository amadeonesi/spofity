#import "MMSheet.h"
#import "MMLayout.h"
#import "OJTheme.h"
#import "SpotTheme.h"
#import "MMCovers.h"
#import "MMRootController.h"
#import "MeshL10n.h"

@interface MMActionListController : UITableViewController
@property (nonatomic, copy) NSArray *options;
@property (nonatomic, copy) NSString *headTitle;
@property (nonatomic, copy) NSString *headSub;
@property (nonatomic, copy) NSString *imageURL;
@property (nonatomic, copy) void (^done)(NSInteger idx);
@end

@implementation MMActionListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = L(@"Options");
    [OJTheme applyToGroupedTableView:self.tableView];
    self.tableView.separatorColor = [OJTheme darkMode] ? [UIColor colorWithWhite:0.30 alpha:1.0] : [UIColor colorWithWhite:0.85 alpha:1.0];

    CGFloat W = self.view.bounds.size.width;
    CGFloat h = self.imageURL.length ? 86 : (self.headSub.length ? 72 : 56);
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W, h)];
    header.backgroundColor = [UIColor clearColor];
    CGFloat tx = 16;
    if (self.imageURL.length) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(16, 16, 52, 52)];
        iv.backgroundColor = [SpotTheme card];
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        [MMCovers load:self.imageURL into:iv];
        [header addSubview:iv];
        tx = 80;
    }
    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(tx, self.imageURL.length ? 18 : 14, W - tx - 16, 22)];
    t.text = self.headTitle; t.font = [UIFont boldSystemFontOfSize:17]; t.textColor = [SpotTheme ink];
    t.backgroundColor = [UIColor clearColor]; t.adjustsFontSizeToFitWidth = YES; [header addSubview:t];
    if (self.headSub.length) {
        UILabel *s = [[UILabel alloc] initWithFrame:CGRectMake(tx, self.imageURL.length ? 42 : 38, W - tx - 16, 18)];
        s.text = self.headSub; s.font = [UIFont systemFontOfSize:13]; s.textColor = [SpotTheme muted];
        s.backgroundColor = [UIColor clearColor]; s.adjustsFontSizeToFitWidth = YES; [header addSubview:s];
    }
    self.tableView.tableHeaderView = header;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self action:@selector(cancel)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [OJTheme applyToNavigationBar:self.navigationController.navigationBar];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 1; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return self.options.count; }

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"row"];
    if (!c) c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"row"];
    c.backgroundColor = [SpotTheme card];
    c.textLabel.text = self.options[ip.row];
    c.textLabel.font = [UIFont systemFontOfSize:16];
    c.textLabel.textColor = [SpotTheme ink];
    c.selectionStyle = UITableViewCellSelectionStyleBlue;
    return c;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    [self finish:ip.row];
}

- (void)cancel { [self finish:-1]; }

- (void)finish:(NSInteger)idx {
    void (^d)(NSInteger) = self.done;
    self.done = nil;
    [self dismissViewControllerAnimated:YES completion:^{ if (d) d(idx); }];
}

@end

@implementation MMSheet

+ (void)showIn:(UIView *)view title:(NSString *)title subtitle:(NSString *)sub options:(NSArray *)options done:(void (^)(NSInteger))done {
    [self showIn:view title:title subtitle:sub imageURL:nil options:options done:done];
}

+ (void)showIn:(UIView *)view title:(NSString *)title subtitle:(NSString *)sub imageURL:(NSString *)imageURL options:(NSArray *)options done:(void (^)(NSInteger))done {
    UIWindow *w = view.window ?: [[UIApplication sharedApplication] keyWindow];
    UIViewController *presenter = w.rootViewController;
    if (!presenter) presenter = [MMRootController shared];
    while (presenter.presentedViewController) presenter = presenter.presentedViewController;

    MMActionListController *list = [[MMActionListController alloc] initWithStyle:UITableViewStyleGrouped];
    list.options = options;
    list.headTitle = title;
    list.headSub = sub;
    list.imageURL = imageURL;
    list.done = done;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    nav.modalPresentationStyle = MMIsPad() ? UIModalPresentationFormSheet : UIModalPresentationFullScreen;
    [presenter presentViewController:nav animated:YES completion:nil];
}

@end
