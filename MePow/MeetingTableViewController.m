//
//  MeetingTableViewController.m
//  MePow
//
//  Created by WeeTom on 15/5/22.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "MeetingTableViewController.h"
#import "EmptyViewController.h"
#import "MDBlockButton.h"
#import "TextEditingController.h"

NSString *MeetingTableViewControllerDidDeleteMeeting = @"MeetingTableViewControllerDidDeleteMeeting";

@interface MeetingTableViewController () <UITextViewDelegate, TextEditingControllerDelegate>
@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UIButton *startPauseBtn;
@property (strong, nonatomic) IBOutlet UILabel *countDownLabel;
@property (strong, nonatomic) IBOutlet UIButton *stopBtn;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UILabel *recordingLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *recordingPV;
@property (strong, nonatomic) IBOutlet UIProgressView *timerPV;
@property (strong, nonatomic) NSMutableArray *notes;
@property (strong, nonatomic) EmptyViewController *emptyVC;
@property (strong, nonatomic) UITextField *editingTextField;
@property (assign, nonatomic) BOOL shouldReload;
@property (strong, nonatomic) NSIndexPath *editingIndexPath;
@end

@implementation MeetingTableViewController
- (void)dealloc
{
    _meeting = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.meeting[@"name"];
    self.tableView.estimatedRowHeight = 100.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.estimatedSectionHeaderHeight = 100;
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.shouldReload = YES;
    self.notes = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbar.translucent = NO;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    if (self.shouldReload) {
        self.shouldReload = NO;
        PFQuery *query = [PFQuery queryWithClassName:@"Note"];
        [query fromLocalDatastore];
        [query whereKey:@"meeting" equalTo:self.meeting];
        [query orderByAscending:@"createTime"];
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDateFormatter *fm = [[NSDateFormatter alloc] init];
    [fm setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    PFObject *note = self.notes[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoteTextCell" forIndexPath:indexPath];
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    label.text = note[@"content"];
    
    UILabel *label2 = (UILabel *)[cell viewWithTag:2];
    label2.text = [fm stringFromDate:note[@"createTime"]];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PFObject *note = self.notes[indexPath.row];
        [note unpin];
        [note deleteEventually];
        [self.notes removeObject:note];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        if (self.notes.count == 0) {
            [self showEmptyVC];
        }
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    CGRect frame = self.tableView.frame;
    frame.size.height -= 120;
    frame.origin.y += 120;
    self.emptyVC.view.frame = frame;
    [self.view addSubview:self.emptyVC.view];
    
    [self.emptyVC setupWithImage:nil text:@"Take a note or never!" actionHandler:^(EmptyViewController *emptyViewController){
        HHActionSheet *ac = [[HHActionSheet alloc] initWithTitle:@"Choose a note"];
        [ac addButtonWithTitle:@"Text" block:^{
            [self performSegueWithIdentifier:@"TextEdit" sender:nil];
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

- (IBAction)voiceBtnPressed:(id)sender {
    self.recordingLabel.hidden = NO;
    self.recordingPV.hidden = NO;
}

- (IBAction)imageBtnPressed:(id)sender {

}

- (IBAction)startPauseBtnPressed:(id)sender {
    self.startPauseBtn.selected = !self.startPauseBtn.selected;
    self.stopBtn.enabled = YES;
}

- (IBAction)stopBtnPressed:(id)sender {
    self.startPauseBtn.selected = NO;
    self.stopBtn.enabled = NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TextEdit"]) {
        UINavigationController *nc = segue.destinationViewController;
        TextEditingController *vc = nc.viewControllers.firstObject;
        vc.delegate = self;
    }
}

#pragma mark - TextEditingController
- (void)textEditingController:(TextEditingController *)controller didFinishEditingTextWithResult:(NSString *)text
{
    if (text.trim.length > 0) {
        PFObject *note = [PFObject objectWithClassName:@"Note"];
        note[@"type"] = @0;
        note[@"content"] = text;
        note[@"creator"] = [PFUser currentUser];
        note[@"meeting"] = self.meeting;
        note[@"createTime"] = [NSDate date];
        [note pin];
        [note saveEventually];
        [self.notes addObject:note];
        NSIndexPath *ip = [NSIndexPath indexPathForRow:self.notes.count - 1 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        [self hideEmptyVC];
    }
}

#pragma mark - Notifications
@end
