//
//  RootTableViewController.m
//  MePow
//
//  Created by Wee Tom on 15/5/22.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "RootTableViewController.h"
#import "EmptyViewController.h"
#import "HHKit.h"
#import "MeetingTableViewController.h"
#import "MeetingCreateTableViewController.h"
#import "SummaryTableViewController.h"
#import "MDAPICategory.h"
#import "MPWLogInViewController.h"

@interface RootTableViewController () <PFLogInViewControllerDelegate>
@property (strong, nonatomic) NSMutableArray *meetings;
@property (strong, nonatomic) EmptyViewController *emptyVC;
@property (assign, nonatomic) BOOL shouldReload, loaded;
@end

@implementation RootTableViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MeetingCreateTableViewControllerDidFinishCreatingMeeting object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MeetingTableViewControllerDidDeleteMeeting object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.shouldReload = YES;
    self.navigationController.toolbar.translucent = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(meetingDeleted:) name:MeetingTableViewControllerDidDeleteMeeting object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(meetingCreated:) name:MeetingCreateTableViewControllerDidFinishCreatingMeeting object:nil];
    
    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 30)];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.image = [UIImage imageNamed:@"logo"];
    self.navigationItem.titleView = iv;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    PFUser *user = [PFUser currentUser];
    if (!user) { 
        MPWLogInViewController *logInController = [[MPWLogInViewController alloc] init];
        logInController.fields = (PFLogInFieldsUsernameAndPassword
                                  | PFLogInFieldsLogInButton
                                  | PFLogInFieldsSignUpButton
                                  | PFLogInFieldsPasswordForgotten);
        logInController.delegate = self;
        [self presentViewController:logInController animated:YES completion:nil];
        self.shouldReload = NO;
    } else {
        NSString *token = user[@"Mingdao"];
        if (token.length > 0 && ![MDAPIManager sharedManager].accessToken) {
            [MDAPIManager sharedManager].accessToken = token;
        }
    }
    
    if (self.shouldReload) {
        self.shouldReload = NO;
        if (!self.loaded) {
            self.loaded = YES;
            [self reloadBtnPressed:nil];
        } else {
            PFQuery *query = [PFQuery queryWithClassName:@"Meeting"];
            [query fromLocalDatastore];
            [query whereKey:@"creator" equalTo:user];
            [query orderByDescending:@"begin"];
            [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task) {
                if (task.error) {
                    NSLog(@"Error: %@", task.error);
                    return task;
                }
                
                for (PFObject *object in (NSArray *)task.result) {
                    if (![MPWGlobal scheduledNotificationExistsForMeeting:object type:1]) {
                        [MPWGlobal scheduleNotificationForMeeting:object type:1];
                    }
                    [object pin];
                }
                [self reloadTableViewWithItems:task.result];
                return task;
            }];
        }
    }
    else {
        [self.tableView reloadData];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.meetings.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MeetingCell" forIndexPath:indexPath];
    
    PFObject *meeting = self.meetings[indexPath.row];
    cell.textLabel.text = meeting[@"name"];
    NSDate *date = meeting[@"begin"];
    NSDateFormatter *fm = [[NSDateFormatter alloc] init];
    [fm setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    cell.detailTextLabel.text = [fm stringFromDate:date];
    
    if (meeting[@"summary"]) {
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    PFObject *meeting = self.meetings[indexPath.row];
    PFObject *summary = meeting[@"summary"];
    if (!summary) {
        
    } else {
        if (summary.isDataAvailable) {
            [self showSummary:summary];
        } else {
            [summary fetch];
            [self showSummary:summary];
            // todo
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        HHActionSheet *actionSheet = [[HHActionSheet alloc] initWithTitle:@"This action can not be undone"];
        [actionSheet addDestructiveButtonWithTitle:@"Yes, delete it" block:^{
            PFObject *meeting = self.meetings[indexPath.row];
            [MPWGlobal cancelNotificationForMeeting:meeting type:0];
            [MPWGlobal cancelNotificationForMeeting:meeting type:1];
            [meeting unpin];
            [meeting deleteEventually];
            [self.meetings removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            if (self.meetings.count == 0) {
                [self showEmptyVC];
            }
        }];
        [actionSheet addCancelButtonWithTitle:@"No, keep it"];
        [actionSheet showInView:self.view];
    }
}

#pragma mark - Empty
- (void)showEmptyVC
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if (!self.emptyVC) {
        EmptyViewController * vc = (EmptyViewController *)[sb instantiateViewControllerWithIdentifier:@"Empty"];
        self.emptyVC = vc;
    }
    [self addChildViewController:self.emptyVC];
    [self.view addSubview:self.emptyVC.view];
    
    __weak __block typeof(self) weakSelf = self;
    [self.emptyVC setupWithImage:nil text:@"No Meeting yet!\nStart NOW!" actionHandler:^(EmptyViewController *emptyViewController){
        [weakSelf performSegueWithIdentifier: @"CreateMeeting" sender: self];
    }];
}

- (void)hideEmptyVC
{
    [self.emptyVC.view removeFromSuperview];
    [self.emptyVC removeFromParentViewController];
    self.emptyVC = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Meeting"]) {
        MeetingTableViewController *vc = segue.destinationViewController;
        NSIndexPath *ip = [self.tableView indexPathForCell:sender];
        PFObject *meeting = self.meetings[ip.row];
        vc.meeting = meeting;
    }
}

#pragma mark - Notification
- (void)meetingCreated:(NSNotification *)notification
{
    PFObject *meeting = notification.object;
    if (self.meetings.count == 0) {
        [self.meetings addObject:meeting];
    } else {
        [self.meetings insertObject:meeting atIndex:0];
    }
    
    [self hideEmptyVC];
    [self.tableView reloadData];
}

- (void)meetingDeleted:(NSNotification *)notification
{
    PFObject *meeting = notification.object;
    if ([self.meetings containsObject:meeting]) {
        [self.meetings removeObject:meeting];
        [self.tableView reloadData];
    }
    if (self.meetings.count == 0) {
        [self showEmptyVC];
    }
}

- (void)reloadTableViewWithItems:(NSArray *)items
{
    if (![[NSThread currentThread] isMainThread]) {
        [self performSelectorOnMainThread:@selector(reloadTableViewWithItems:) withObject:items waitUntilDone:NO];
        return;
    }
    self.meetings = [NSMutableArray array];
    [self.meetings addObjectsFromArray:items];
    if (self.meetings.count == 0) {
        [self showEmptyVC];
    } else {
        [self hideEmptyVC];
        [self.tableView reloadData];
    }
}

#pragma mark - Actions
- (IBAction)reloadBtnPressed:(id)sender {
    
    PFUser *user = [PFUser currentUser];
    
    MRProgressOverlayView *progressView = [MRProgressOverlayView showOverlayAddedTo:self.view animated:YES];
    [progressView show:YES];
    PFQuery *query = [PFQuery queryWithClassName:@"Meeting"];
    [query whereKey:@"creator" equalTo:user];
    [query orderByDescending:@"begin"];
    [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task) {
        if ([sender isKindOfClass:[UIRefreshControl class]]) {
            [(UIRefreshControl *)sender endRefreshing];
        }
        
        if (task.error) {
            progressView.mode = MRProgressOverlayViewModeCross;
            progressView.titleLabelText = task.error.userInfo[NSLocalizedDescriptionKey];
            [progressView performSelector:@selector(dismiss:) withObject:@YES afterDelay:2];
            return task;
        }
        
        for (PFObject *object in (NSArray *)task.result) {
            if (![MPWGlobal scheduledNotificationExistsForMeeting:object type:1]) {
                [MPWGlobal scheduleNotificationForMeeting:object type:1];
            }
            [object pin];
        }
        [self reloadTableViewWithItems:task.result];
        [progressView performSelectorOnMainThread:@selector(dismiss:) withObject:@YES waitUntilDone:NO];
        return task;
    }];
}

- (void)showSummary:(PFObject *)summary
{
    if (![[NSThread currentThread] isMainThread]) {
        [self performSelectorOnMainThread:@selector(showSummary:) withObject:summary waitUntilDone:NO];
        return;
    }
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nav = [sb instantiateViewControllerWithIdentifier:@"SumNC"];
    SummaryTableViewController *vc = nav.viewControllers.firstObject;
    vc.summary = summary;
    vc.title = @"Summary";
    [self presentViewController:nav animated:YES completion:^{
    }];
}

#pragma mark - Login
- (void)logInViewController:(PFLogInViewController * __nonnull)logInController didLogInUser:(PFUser * __nonnull)user
{
    [logInController dismissViewControllerAnimated:YES completion:^{
        [self reloadBtnPressed:nil];
    }];
}
@end
