//
//  SettingsTableViewController.m
//  MePow
//
//  Created by Wee Tom on 15/5/28.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "MDAPICategory.h"
#import "MDAuthenticator.h"
#import "MDAuthPanel.h"

@interface SettingsTableViewController () <MDAuthPanelDelegate>
@property (assign, nonatomic) BOOL dataPulled;
@property (strong, nonatomic) NSString *mingdaoKey, *mingdaoSecret, *mingdaoRedirectURL;
@end

@implementation SettingsTableViewController
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MDAPIManagerNewTokenSetNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newTokenSet:) name:MDAPIManagerNewTokenSetNotification object:nil];

    NSDictionary *configuration = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Configuration" ofType:@"plist"]];
    self.mingdaoKey = configuration[@"MingdaoKey"];
    self.mingdaoSecret = configuration[@"MingdaoSecret"];
    self.mingdaoRedirectURL = configuration[@"MingdaoRedirectURL"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    // todo
}

- (void)refreshState
{
    NSString *token = [[PFUser currentUser] objectForKey:@"Mingdao"];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    UISwitch *mingdaoSwitch = [[UISwitch alloc] init];
    if (token.length <= 0) {
        [mingdaoSwitch addTarget:self action:@selector(bindMingdao) forControlEvents:UIControlEventValueChanged];
        mingdaoSwitch.on = NO;
    } else {
        [mingdaoSwitch addTarget:self action:@selector(unbindMingdao) forControlEvents:UIControlEventValueChanged];
        mingdaoSwitch.on = YES;
    }
    cell.accessoryView = mingdaoSwitch;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.dataPulled) {
        NSString *token = [[PFUser currentUser] objectForKey:@"Mingdao"];
        if (token.length <= 0) {
            [self refreshState];
        } else {
            [self loadUserDetail];
        }
    } else {
        [self refreshState];
    }
}

- (IBAction)doneBtnPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)bindMingdao
{
    if (![MDAuthenticator authorizeByMingdaoAppWithAppKey:self.mingdaoKey appSecret:self.mingdaoSecret]) {
        // 未安装明道App
        [self authorizeByMingdaoMobilePage];
    }
}

- (void)authorizeByMingdaoMobilePage
{
    // 通过 @MDAuthPanel 进行web验证
    MDAuthPanel *panel = [[MDAuthPanel alloc] initWithFrame:self.navigationController.view.bounds appKey:self.mingdaoKey appSecret:self.mingdaoSecret redirectURL:self.mingdaoRedirectURL state:nil];
    panel.authDelegate = self;
    [self.view.window addSubview:panel];
    [panel show];
}

- (void)unbindMingdao
{
    [MDAPIManager sharedManager].accessToken = nil;
    [[PFUser currentUser] setObject:@"" forKey:@"Mingdao"];
    [[PFUser currentUser] saveEventually];
    [self refreshState];
}

#pragma mark - Table view data source

#pragma mark -
#pragma mark - MDAuthPanelAuthDelegate
- (void)mingdaoAuthPanel:(MDAuthPanel *)panel didFinishAuthorizeWithResult:(NSDictionary *)result
{
    // @MDAuthPanel 验证结束 返回结果
    [panel hide];
    NSString *errorStirng= result[MDAuthErrorKey];
    if (errorStirng) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failed!" message:errorStirng delegate:nil cancelButtonTitle:@"Done" otherButtonTitles:nil];
        [alertView show];
    } else {
        NSString *accessToken = result[MDAuthAccessTokenKey];
        //    NSString *refeshToken = result[MDAuthRefreshTokenKey];
        //    NSString *expireTime = result[MDAuthExpiresTimeKeyl];
        [MDAPIManager sharedManager].accessToken = accessToken;
        [[PFUser currentUser] setObject:accessToken forKey:@"Mingdao"];
        [[PFUser currentUser] saveEventually];
    }
}

#pragma mark -
#pragma mark - Notification
- (void)newTokenSet:(NSNotification *)notification
{
    NSString *token = notification.object;
    if (token.length <= 0) {
        return;
    }
    [self loadUserDetail];
}

- (void)loadUserDetail
{
    __weak __block typeof(self) weakSelf = self;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UIActivityIndicatorView *iv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [iv startAnimating];
    cell.accessoryView = iv;
    [[[MDAPIManager sharedManager] loadCurrentUserDetailWithHandler:^(id object, NSError *error) {
        if (error) {
            [[PFUser currentUser] setObject:@"" forKey:@"Mingdao"];
            [[PFUser currentUser] saveEventually];
            [MDAPIManager sharedManager].accessToken = nil;
            [weakSelf refreshState];
            return ;
        }
        
        MDUser *user = object;

        [[PFUser currentUser] setObject:user.objectID forKey:@"MingdaoUserID"];
        [[PFUser currentUser] setObject:user.objectName forKey:@"MingdaoUserName"];
        [[PFUser currentUser] setObject:user.avatar forKey:@"MingdaoUserAvatar"];
        [[PFUser currentUser] setObject:user.project.objectID forKey:@"MingdaoUserProjectID"];
        [[PFUser currentUser] saveEventually];
        
        [weakSelf refreshState];
    }] start];
}
@end
