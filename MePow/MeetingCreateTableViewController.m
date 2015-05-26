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

NSString *MeetingCreateTableViewControllerDidFinishCreatingMeeting = @"MeetingCreateTableViewControllerDidFinishCreatingMeeting";

@interface MeetingCreateTableViewController () <UITextFieldDelegate>
@property (assign, nonatomic) int viewAppearTime;
//@property (assign, nonatomic) int duration;
@property (strong, nonatomic) NSMutableArray *users;
@property (strong, nonatomic) UITextField *name, *location;
@property (strong, nonatomic) UIDatePicker *picker;
@property (strong, nonatomic) UIStepper *stepper;
@end

@implementation MeetingCreateTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.duration = 1;
    self.users = [@[@"A", @"B"] mutableCopy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
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
                case 3:
                {
//                    cell = [tableView dequeueReusableCellWithIdentifier:@"StepperCell" forIndexPath:indexPath];
//                    UILabel *title = (UILabel *)[cell viewWithTag:1];
//                    title.text = @"Duration";
//                    UILabel *duration = (UILabel *)[cell viewWithTag:2];
//                    UIStepper *stepper = (UIStepper *)[cell viewWithTag:3];
//                    stepper.minimumValue = 1;
//                    stepper.value = self.duration;
//                    self.stepper = stepper;
//                    if (self.duration > 1) {
//                        duration.text = [NSString stringWithFormat:@"%d hours", self.duration];
//                    } else {
//                        duration.text = [NSString stringWithFormat:@"%d hour", self.duration];
//                    }
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
                cell = [tableView dequeueReusableCellWithIdentifier:@"ImageLabelCell" forIndexPath:indexPath];
                UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
                [imageView setImageWithURL:[NSURL URLWithString:@"http://tp3.sinaimg.cn/1657938842/180/5704612869/1"] placeholderImage:nil];
                UILabel *label = (UILabel *)[cell viewWithTag:2];
                label.text = @"Somebody";
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
            break;
        default:
            break;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.name resignFirstResponder];
    [self.location resignFirstResponder];
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
//    meeting[@"duration"] = @(self.duration);
    [meeting pin];
    [meeting saveEventually];
    [[NSNotificationCenter defaultCenter] postNotificationName:MeetingCreateTableViewControllerDidFinishCreatingMeeting object:meeting];
    UINavigationController *nav = self.navigationController;
    [nav popViewControllerAnimated:YES];
    NSComparisonResult result = [[NSDate date] compare:self.picker.date];
    if (result == NSOrderedAscending) {
        result = [[NSDate date] compare:[self.picker.date dateByAddingTimeInterval:-60*15]];
        if (result == NSOrderedAscending) {
            UILocalNotification *notification=[[UILocalNotification alloc] init];
            if (notification!=nil) {
                
                notification.fireDate = [self.picker.date dateByAddingTimeInterval:-60*15]; //触发通知的时间
                notification.repeatInterval = 0; //循环次数，kCFCalendarUnitWeekday一周一次
                
                notification.timeZone = [NSTimeZone defaultTimeZone];
                notification.soundName = UILocalNotificationDefaultSoundName;
                notification.alertBody = [NSString stringWithFormat:@"%@ will be begun in 15 minutes! please get your self prepared!", self.name.text];
                
                notification.alertAction = @"Start preparing";  //提示框按钮
                notification.hasAction = YES; //是否显示额外的按钮，为no时alertAction消失
                
                //            notification.applicationIconBadgeNumber = 1; //设置app图标右上角的数字
                
                //下面设置本地通知发送的消息，这个消息可以接受
                if (meeting.objectId) {
                    NSDictionary* infoDic = [NSDictionary dictionaryWithObject:@"meetingID" forKey:meeting.objectId];
                    notification.userInfo = infoDic;
                }
                //发送通知
                [[UIApplication sharedApplication] scheduleLocalNotification:notification];
            }
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
}

- (IBAction)stepperValueChanged:(id)sender {
    //self.duration = self.stepper.value;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
