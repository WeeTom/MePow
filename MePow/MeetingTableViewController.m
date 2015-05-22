//
//  MeetingTableViewController.m
//  MePow
//
//  Created by WeeTom on 15/5/22.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "MeetingTableViewController.h"
#import "EmptyViewController.h"

NSString *MeetingTableViewControllerDidDeleteMeeting = @"MeetingTableViewControllerDidDeleteMeeting";

@interface MeetingTableViewController () <UITextFieldDelegate>
@property (strong, nonatomic) NSMutableArray *notes;
@property (strong, nonatomic) EmptyViewController *emptyVC;
@property (strong, nonatomic) NSArray *originToolbarItems;
@property (assign, nonatomic) CGRect originFrameForToolbar;
@property (strong, nonatomic) UITextField *editingTextField;
@property (assign, nonatomic) BOOL shouldReload;
@end

@implementation MeetingTableViewController
- (void)dealloc
{
    _meeting = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    self.title = self.meeting[@"name"];
    
    self.shouldReload = YES;
    self.notes = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbar.translucent = NO;
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.originToolbarItems) {
        self.originToolbarItems = self.toolbarItems;
        self.originFrameForToolbar = self.navigationController.toolbar.frame;
    }
    
    if (self.shouldReload) {
        self.shouldReload = NO;
        PFQuery *query = [PFQuery queryWithClassName:@"Note"];
        [query fromLocalDatastore];
        [query whereKey:@"meetingID" equalTo:self.meeting.objectId];
        [query orderByDescending:@"createTime"];
        [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task) {
            if (task.error) {
                NSLog(@"Error: %@", task.error);
                return task;
            }
            
            for (PFObject *object in (NSArray *)task.result) {
                [object pin];
            }
            [self reloadTableViewWithItems:task.result];
            return task;
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbar.frame = self.originFrameForToolbar;
    [self.navigationController setToolbarHidden:YES animated:NO];
    [super viewWillDisappear:animated];
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
    return self.notes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoteTextCell" forIndexPath:indexPath];
    if (indexPath.row < self.notes.count) {
        PFObject *note = self.notes[indexPath.row];
        UILabel *label = (UILabel *)[cell viewWithTag:1];
        label.text = note[@"content"];
    }
    return cell;
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

#pragma mark - Empty
- (void)showEmptyVC
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if (!self.emptyVC) {
        EmptyViewController * vc = (EmptyViewController *)[sb instantiateViewControllerWithIdentifier:@"Empty"];
        self.emptyVC = vc;
    }
    [self addChildViewController:self.emptyVC];
    CGRect frame = self.tableView.frame;
    frame.size.height -= 120;
    frame.origin.y += 120;
    self.emptyVC.view.frame = frame;
    [self.view addSubview:self.emptyVC.view];
    
    [self.emptyVC setupWithImage:nil text:@"Take a note or never!" actionHandler:^(EmptyViewController *emptyViewController){
        HHActionSheet *ac = [[HHActionSheet alloc] initWithTitle:@"Choose a note"];
        [ac addButtonWithTitle:@"Text" block:^{
            [self textBtnPressed:nil];
        }];
        [ac addButtonWithTitle:@"Voice" block:^{
            [self voiceBtnPressed:nil];
        }];
        [ac addButtonWithTitle:@"Image" block:^{
            [self imageBtnPressed:nil];
        }];
        [ac addCancelButtonWithTitle:@"Cancel"];
        [ac showInView:self.view];
    }];
}

- (void)hideEmptyVC
{
    [self.emptyVC.view removeFromSuperview];
    [self.emptyVC removeFromParentViewController];
    self.emptyVC = nil;
}

- (void)reloadTableViewWithItems:(NSArray *)items
{
    if (![[NSThread currentThread] isMainThread]) {
        [self performSelectorOnMainThread:@selector(reloadTableViewWithItems:) withObject:items waitUntilDone:NO];
        return;
    }
    self.notes = [NSMutableArray array];
    [self.notes addObjectsFromArray:items];
    if (self.notes.count == 0) {
        [self showEmptyVC];
    } else {
        [self hideEmptyVC];
        [self.tableView reloadData];
    }
}

#pragma mark - Actions
- (IBAction)trashBtnPressed:(id)sender {
    HHActionSheet *actionSheet = [[HHActionSheet alloc] initWithTitle:@"This action can not be undone"];
    [actionSheet addDestructiveButtonWithTitle:@"Yes, delete it" block:^{
        [self.meeting unpin];
        [self.meeting deleteEventually];
        [[NSNotificationCenter defaultCenter] postNotificationName:MeetingTableViewControllerDidDeleteMeeting object:self.meeting];
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [actionSheet addCancelButtonWithTitle:@"No, keep it"];
    [actionSheet showInView:self.view];
}

- (void)backToOriginItems
{
    [self setToolbarItems:self.originToolbarItems animated:YES];
}

- (void)saveText:(UITextField *)textField
{
    PFObject *note = [PFObject objectWithClassName:@"Note"];
    note[@"type"] = @0;
    note[@"content"] = textField.text;
    note[@"creator"] = [[PFUser currentUser] objectId];
    note[@"meetingID"] = self.meeting.objectId;
    note[@"createTime"] = @([[NSDate date] timeIntervalSince1970]);
    [note pin];
    [note saveEventually];
    [self.notes addObject:note];
    NSIndexPath *ip = [NSIndexPath indexPathForRow:self.notes.count - 1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    [self hideEmptyVC];
    textField.text = @"";
}

- (IBAction)textBtnPressed:(id)sender {
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 100, self.navigationController.toolbar.height - 8)];
    tf.returnKeyType = UIReturnKeyDone;
    tf.delegate = self;
    self.editingTextField = tf;
    UIBarButtonItem *textFieldItem = [[UIBarButtonItem alloc] initWithCustomView:tf];
    UIBarButtonItem *flexiItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(backToOriginItems)];
    [self setToolbarItems:@[cancelItem, flexiItem, textFieldItem] animated:YES];
    [tf becomeFirstResponder];
}

- (IBAction)voiceBtnPressed:(id)sender {

}

- (IBAction)imageBtnPressed:(id)sender {

}

#pragma mark - Notifications
- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = 0.25;
    __weak __block typeof(self) bslf = self;
    
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         bslf.navigationController.toolbar.frame = CGRectMake(self.originFrameForToolbar.origin.x, self.originFrameForToolbar.origin.y - keyboardRect.size.height, self.originFrameForToolbar.size.width, self.originFrameForToolbar.size.height);
                         
                         bslf.tableView.frame = CGRectMake(0, 0, bslf.tableView.width, bslf.navigationController.toolbar.frame.origin.y);
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    double duration = 0.25;
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.navigationController.toolbar.frame = self.originFrameForToolbar;
                         
                         self.tableView.frame = CGRectMake(0, 0, self.tableView.width, self.navigationController.toolbar.frame.origin.y);
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

#pragma mark - TextField
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self saveText:textField];
    return NO;
}
@end
