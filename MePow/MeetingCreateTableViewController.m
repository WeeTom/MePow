//
//  MeetingCreateTableViewController.m
//  MePow
//
//  Created by Wee Tom on 15/5/21.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "MeetingCreateTableViewController.h"
#import "UIImageView+AFNetworking.h"
#import "NSString+HHKit.h"
#import "MRProgress.h"
#import "MeetingTableViewController.h"
#import "MDAPICategory.h"
#import "UserListVC.h"

NSString *MeetingCreateTableViewControllerDidFinishCreatingMeeting = @"MeetingCreateTableViewControllerDidFinishCreatingMeeting";

@interface MeetingCreateTableViewController () <UITextFieldDelegate, UserListVCDelegate>
@property (assign, nonatomic) int viewAppearTime;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *flexibleItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *connectItem;
@property (strong, nonatomic) NSMutableArray *users;
@property (strong, nonatomic) UITextField *name, *location;
@property (strong, nonatomic) UIDatePicker *picker;
@property (strong, nonatomic) UIStepper *stepper;
@end

@implementation MeetingCreateTableViewController
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MDAPIManagerNewTokenSetNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newTokenSet:) name:MDAPIManagerNewTokenSetNotification object:nil];

//    self.duration = 1;
    self.users = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([MDAPIManager sharedManager].accessToken.length <= 0) {
        [self setToolbarItems:@[self.flexibleItem, self.connectItem] animated:YES];
    } else {
        [self setToolbarItems:@[self.flexibleItem] animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.viewAppearTime == 0) {
        self.viewAppearTime ++;
        [self.name becomeFirstResponder];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2 + 1*([MDAPIManager sharedManager].accessToken.length > 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return 3;
            break;
        case 2:
            return self.users.count + 1;
            break;
        default:
            break;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 1:
            switch (indexPath.row) {
                case 2:
                    return 163;
                    break;
            }
            return 44;
            break;
        default:
            return 44;
            break;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"What [Only needed]";
            break;
        case 1:
            return @"Where & When [Optional]";
            break;
        case 2:
            return @"Who [Optional]";
            break;
        default:
            break;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            break;
        case 1:
            break;
        case 2:
            return @"This will create an EVENT on Mingdao";
            break;
        default:
            break;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    switch (indexPath.section) {
        case 0:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldCell" forIndexPath:indexPath];
            self.name = (UITextField *)[cell viewWithTag:1];
            self.name.returnKeyType = UIReturnKeyNext;
        }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldCell" forIndexPath:indexPath];
                    self.location = (UITextField *)[cell viewWithTag:1];
                    self.location.returnKeyType = UIReturnKeyNext;
                }
                    break;
                case 1:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell" forIndexPath:indexPath];
                    cell.textLabel.text = @"Begin";
                    NSDateFormatter *fm = [[NSDateFormatter alloc] init];
                    [fm setDateFormat:@"yyyy-MM-dd HH:mm"];
                    if (!self.picker) {
                        cell.detailTextLabel.text = [fm stringFromDate:[NSDate date]];
                    } else {
                        cell.detailTextLabel.text = [fm stringFromDate:self.picker.date];
                    }
                }
                    break;
                case 2:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"DatePickerCell" forIndexPath:indexPath];
                    UIDatePicker *picker = (UIDatePicker *)[cell viewWithTag:1];
                    self.picker = picker;
                }
                    break;
                default:
                    break;
            }
            break;
        case 2:
            if (indexPath.row >= self.users.count) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"AddLabelCell" forIndexPath:indexPath];
                UILabel *label = (UILabel *)[cell viewWithTag:2];
                label.text = @"Add";
            } else {
                MDUser *user = self.users[indexPath.row];
                cell = [tableView dequeueReusableCellWithIdentifier:@"ImageLabelCell" forIndexPath:indexPath];
                UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
                [imageView setImageWithURL:[NSURL URLWithString:user.avatar] placeholderImage:[UIImage imageNamed:@"defaultLoadingImage"]];
                UILabel *label = (UILabel *)[cell viewWithTag:2];
                label.text = user.objectName;
            }
            
            break;
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case 0: {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            UITextField *tf = (UITextField *)[cell viewWithTag:1];
            [tf becomeFirstResponder];
        }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:{
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    UITextField *tf = (UITextField *)[cell viewWithTag:1];
                    [tf becomeFirstResponder];
                }
                    break;
                default:
                    break;
            }
            break;
        case 2:
        {
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UINavigationController *nav = [sb instantiateViewControllerWithIdentifier:@"PickUser"];
            UserListVC *vc = nav.viewControllers.firstObject;
            vc.delegate = self;
            vc.selectedUsers = self.users;
            [self presentViewController:nav animated:YES completion:^{
                
            }];
        }
            break;
        default:
            break;
    }
}

- (IBAction)dateChanged:(id)sender {
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@"\n"]) {
        if ([textField isEqual:self.name]) {
            [self.location becomeFirstResponder];
        } else {
            [self.location resignFirstResponder];
        }
        return NO;
    }
    return YES;
}

- (IBAction)saveBtnPressed:(id)sender {
    if (self.name.text.trim.length == 0) {
        MRProgressOverlayView *progressView = [MRProgressOverlayView showOverlayAddedTo:self.view animated:YES];
        progressView.mode = MRProgressOverlayViewModeCross;
        progressView.titleLabelText = @"Name is REQUIRED";
        [progressView performSelector:@selector(dismiss:) withObject:@YES afterDelay:1];
        [self.name becomeFirstResponder];
        return;
    }
    
    PFObject *meeting = [PFObject objectWithClassName:@"Meeting"];
    [meeting setObject:[PFUser currentUser] forKey:@"creator"];
    meeting[@"name"] = self.name.text;
    if (self.location.text.trim.length > 0) {
        meeting[@"location"] = self.location.text;
    }
    meeting[@"createTime"] = [NSDate date];
    meeting[@"begin"] = self.picker.date;
    
    
    dispatch_block_t startMeeting = ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MeetingCreateTableViewControllerDidFinishCreatingMeeting object:meeting];
        UINavigationController *nav = self.navigationController;
        [nav popViewControllerAnimated:YES];
        NSComparisonResult result = [[NSDate date] compare:self.picker.date];
        if (result == NSOrderedAscending) {
            result = [[NSDate date] compare:[self.picker.date dateByAddingTimeInterval:-60*15]];
            if (result == NSOrderedAscending) {
                [MPWGlobal scheduleNotificationForMeeting:meeting type:0];
            }
            else {
                HHAlertView *alert = [[HHAlertView alloc] initWithTitle:@"Hey!" message:[NSString stringWithFormat:@"%@ will begun soon! please get your self prepared!", self.name.text] cancelButtonTitle:@"Sure" cancelBlock:^{
                    MeetingTableViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MeetingDetail"];
                    vc.meeting = meeting;
                    [nav pushViewController:vc animated:YES];
                }];
                [alert show];
            }
        }
        else {
            HHAlertView *alert = [[HHAlertView alloc] initWithTitle:@"Hey!" message:[NSString stringWithFormat:@"%@ has begun! please get your self prepared!", self.name.text] cancelButtonTitle:@"Sure" cancelBlock:^{
                MeetingTableViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MeetingDetail"];
                vc.meeting = meeting;
                [nav pushViewController:vc animated:YES];
            }];
            [alert show];
        }
    };
    NSMutableArray *userIDs = [NSMutableArray array];
    if (self.users.count > 0) {
        NSMutableArray *users = [NSMutableArray array];
        
        NSMutableDictionary *mDic = [NSMutableDictionary dictionary];
        [mDic setObject:[[PFUser currentUser] objectForKey:@"MingdaoUserID"] forKey:@"MingdaoUserID"];
        [mDic setObject:[[PFUser currentUser] objectForKey:@"MingdaoUserName"] forKey:@"MingdaoUserName"];
        [mDic setObject:[[PFUser currentUser] objectForKey:@"MingdaoUserAvatar"] forKey:@"MingdaoUserAvatar"];
        NSString *projectID = [[PFUser currentUser] objectForKey:@"MingdaoUserProjectID"];
        [users addObject:mDic];
        [userIDs addObject:[[PFUser currentUser] objectForKey:@"MingdaoUserID"]];
        
        for (MDUser *user in self.users) {
            NSMutableDictionary *mDic = [NSMutableDictionary dictionary];
            [mDic setObject:user.objectID forKey:@"MingdaoUserID"];
            [mDic setObject:user.objectName forKey:@"MingdaoUserName"];
            [mDic setObject:user.avatar forKey:@"MingdaoUserAvatar"];
            [mDic setObject:projectID forKey:@"MingdaoUserProjectID"];
            [users addObject:mDic];
            [userIDs addObject:user.objectID];
        }
        meeting[@"users"] = users;
        NSDateFormatter *fm = [[NSDateFormatter alloc] init];
        [fm setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        MRProgressOverlayView *progressView = [MRProgressOverlayView showOverlayAddedTo:self.view animated:YES];
        [progressView show:YES];
        [[[MDAPIManager sharedManager] createEventWithEventName:self.name.text startDateString:[fm stringFromDate:self.picker.date] endDateString:[fm stringFromDate:[self.picker.date dateByAddingTimeInterval:60*60]] remindType:0 remindTime:0 categoryID:0 isAllDay:NO address:self.location.text description:@"Created via MePow" isPrivate:NO userIDs:userIDs emails:nil isRecur:NO frequency:0 interval:0 weekDays:nil recurCount:0 untilDate:nil handler:^(NSString *string, NSError *error) {
            if (error) {
                progressView.mode = MRProgressOverlayViewModeCross;
                progressView.titleLabelText = error.userInfo[NSLocalizedDescriptionKey];
                [progressView performSelector:@selector(dismiss:) withObject:@YES afterDelay:2];

                return ;
            }
            [progressView hide:YES];
            [meeting pin];
            [meeting saveEventually];
            startMeeting();
        }] start];
    } else {
        startMeeting();
        [meeting pin];
        [meeting saveEventually];
    }
}

- (IBAction)stepperValueChanged:(id)sender {
    //self.duration = self.stepper.value;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark -
#pragma mark - Notification
- (void)newTokenSet:(NSNotification *)notification
{
    NSString *token = notification.object;
    if (token.length <= 0) {
        return;
    }
    [self.tableView reloadData];
}

- (void)userListVC:(UserListVC *)viewController didFinishWithResult:(NSArray *)users
{
    self.users = [users mutableCopy];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
}
@end
