//
//  UserListVC.m
//  MePow
//
//  Created by Wee Tom on 15/5/28.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "UserListVC.h"
#import "UIImageView+WebCache.h"
#import "MDAPICategory.h"
#import "pinyin.h"

@interface UserListVC ()
@property (assign, nonatomic) BOOL loaded;
@property (strong, nonatomic) NSArray *users;
@property (strong, nonatomic) NSArray *sectionTitles;
@property (strong, nonatomic) NSDictionary *userDic;
@property (strong, nonatomic) NSMutableArray *result;
@end

@implementation UserListVC

- (IBAction)refreshControlValueChanged:(UIRefreshControl *)sender {
    [self loadData:^{
        [self sort];
        [self.tableView reloadData];
        [sender endRefreshing];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.selectedUsers) {
        self.result = [self.selectedUsers mutableCopy];
    }
    if (!self.result) {
        self.result = [NSMutableArray array];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.users.count == 0 && !self.loaded) {
        MRProgressOverlayView *progressView = [MRProgressOverlayView showOverlayAddedTo:self.view animated:YES];
        [progressView show:YES];
        [self loadData:^{
            [progressView hide:YES];
        }];
    }
}

- (void)loadData:(dispatch_block_t)comletion
{
    [[[MDAPIManager sharedManager] loadAllUsersWithHandler:^(NSArray *objects, NSError *error) {
        if (error) {
            return ;
        }
        self.users = objects;
        [self sort];
        [self.tableView reloadData];
        comletion();
    }] start];
}

- (void)sort
{
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableDictionary *userDic = [NSMutableDictionary dictionary];
    
    MDUser *cu = [[MDUser alloc] init];
    cu.objectID = [[PFUser currentUser] objectForKey:@"MingdaoUserID"];
    NSArray *users = [self.users sortedArrayUsingComparator:^NSComparisonResult(MDUser *u1, MDUser *u2){
        return [[u1.objectName uppercaseString] localizedCompare:[u2.objectName uppercaseString]];
    }];
    for (MDUser *user in users) {
        @autoreleasepool {
            if ([user isEqual:cu]) {
                continue;
            }
            NSString *trimmedName = user.objectName.trim;
            if (trimmedName.length == 0) {
                user.objectName = NSLocalizedString(@"未命名用户", @"未命名用户");
                trimmedName = user.objectName.trim;
            }
            char firstLetter = pinyinFirstLetter([trimmedName characterAtIndex:0]);
            NSString *title = [[NSString stringWithFormat:@"%c", firstLetter] uppercaseString];
            NSArray *alphabetList = @[@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z"];
            if (![alphabetList containsObject:title]) {
                title = @"#";
            }
            if (![titles containsObject:title]) {
                [titles addObject:title];
            }
            NSMutableArray *users = [userDic objectForKey:title];
            if (!users) {
                users = [NSMutableArray array];
                [userDic setObject:users forKey:title];
            }
            [users addObject:user];
        }
    }
    
    [titles sortUsingComparator:^NSComparisonResult(NSString *s1, NSString *s2){
        if ([s1 isEqualToString:@"#"]) {
            return NSOrderedDescending;
        }
        if ([s2 isEqualToString:@"#"]) {
            return NSOrderedAscending;
        }
        return [s1 localizedCompare:s2];
    }];
    
    self.sectionTitles = titles;
    self.userDic = userDic;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *sectionTitle = self.sectionTitles[section];
    NSArray *users = self.userDic[sectionTitle];
    return users.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = self.sectionTitles[section];
    return sectionTitle;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.sectionTitles;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"User" forIndexPath:indexPath];
    
    NSString *sectionTitle = self.sectionTitles[indexPath.section];
    NSArray *users = self.userDic[sectionTitle];
    MDUser *user =  users[indexPath.row];
    UIImageView *iv = (UIImageView *)[cell viewWithTag:1];
    [iv sd_setImageWithURL:[NSURL URLWithString:user.avatar] placeholderImage:[UIImage imageNamed:@"defaultLoadingImage"]];
    UILabel *label = (UILabel *)[cell viewWithTag:2];
    label.text = user.objectName;
    
    if ([self.result containsObject:user]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *sectionTitle = self.sectionTitles[indexPath.section];
    NSArray *users = self.userDic[sectionTitle];
    MDUser *user =  users[indexPath.row];
    if ([self.result containsObject:user]) {
        [self.result removeObject:user];
    } else {
        [self.result addObject:user];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)doneBtnPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate userListVC:self didFinishWithResult:self.result];
    }];
}

@end
