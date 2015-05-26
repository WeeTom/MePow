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
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIImageView+WebCache.h"
#import "CountDownPickerViewController.h"

NSString *MeetingTableViewControllerDidDeleteMeeting = @"MeetingTableViewControllerDidDeleteMeeting";

NSString *MeetingTableViewControllerImageUploadPercentChanged = @"MeetingTableViewControllerImageUploadPercentChanged";
NSString *MeetingTableViewControllerRecordUploadPercentChanged = @"MeetingTableViewControllerRecordUploadPercentChanged";
NSString *MeetingTableViewControllerRecordDownloadPercentChanged = @"MeetingTableViewControllerRecordDownloadPercentChanged";


@interface MeetingTableViewController () <UITextViewDelegate, TextEditingControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, CountDownPickerViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (strong, nonatomic) IBOutlet UIButton *startPauseBtn;
@property (strong, nonatomic) IBOutlet UILabel *countDownLabel;
@property (strong, nonatomic) IBOutlet UIButton *stopBtn;
@property (strong, nonatomic) IBOutlet UILabel *recordingLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *recordingPV;
@property (strong, nonatomic) IBOutlet UIProgressView *timerPV;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSMutableArray *notes;
@property (strong, nonatomic) EmptyViewController *emptyVC;
@property (assign, nonatomic) BOOL shouldReload, audioSessionPermitted;
@property (strong, nonatomic) PFObject *playingNote;
@property (strong, nonatomic) AVAudioPlayer *player;
@end

@implementation MeetingTableViewController
- (void)dealloc
{
    _playingNote = nil;
    [_player stop];
    _player = nil;
    _meeting = nil;
    _headerView = nil;
    _startPauseBtn = nil;
    _countDownLabel = nil;
    _stopBtn = nil;
    _recordingLabel = nil;
    _recordingPV = nil;
    _timerPV = nil;
    _notes = nil;
    _emptyVC = nil;
    [MPWGlobal sharedInstance].recorder.pv = nil;
    [MPWGlobal sharedInstance].recorder.label = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MeetingTableViewControllerImageUploadPercentChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MeetingTableViewControllerRecordUploadPercentChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MeetingTableViewControllerRecordDownloadPercentChanged object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imagePercentChanged:) name:MeetingTableViewControllerImageUploadPercentChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordPercentChanged:) name:MeetingTableViewControllerRecordUploadPercentChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordDownloadPercentChanged:) name:MeetingTableViewControllerRecordDownloadPercentChanged object:nil];

    self.title = self.meeting[@"name"];
    self.tableView.estimatedRowHeight = 200.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.estimatedSectionHeaderHeight = 100;
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.shouldReload = YES;
    self.notes = [NSMutableArray array];
    
    
    NSArray *statuses = self.meeting[@"status"];
    NSDictionary *lastObject = statuses.lastObject;
    if (!lastObject) {
        self.startPauseBtn.selected = NO;
        self.stopBtn.enabled = NO;
    } else {
        NSString *action = lastObject[@"action"];
        NSDate *actionDate = lastObject[@"date"];
        if ([action isEqualToString:@"start"]) {
            self.startPauseBtn.selected = YES;
            self.stopBtn.enabled = YES;
            
            NSDate *cDate = [NSDate date];
            NSTimeInterval time = [cDate timeIntervalSinceDate:actionDate];

            NSLog(@"%.2f", time);
            int hour = 0;
            int minute = 0;
            int second = time;
            while (second >= 60) {
                minute = second/60;
                second = second%60;
            }
            while (minute >= 60) {
                hour = minute/60;
                minute = minute%60;
            }
            
            self.countDownLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
            
            [self startTimer];
        } else if ([action isEqualToString:@"pause"]) {
            self.startPauseBtn.selected = NO;
            self.stopBtn.enabled = YES;

            NSTimeInterval time = [lastObject[@"time"] doubleValue];
            NSLog(@"%.2f", time);
            
            NSTimeInterval absTime = time;
            if (absTime < 0) {
                absTime = -absTime;
                self.countDownLabel.textColor = [UIColor redColor];
            }
            
            int hour = 0;
            int minute = 0;
            int second = absTime;
            while (second >= 60) {
                minute = second/60;
                second = second%60;
            }
            while (minute >= 60) {
                hour = minute/60;
                minute = minute%60;
            }
            
            self.countDownLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
        } else if ([action isEqualToString:@"stop"]) {
            self.startPauseBtn.selected = NO;
            self.stopBtn.enabled = NO;
        }
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbar.translucent = NO;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    if (!self.audioSessionPermitted) {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            if (granted) {
                self.audioSessionPermitted = YES;
            }
            else {
                self.audioSessionPermitted = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[self showAudioSessionDeniedAlert];
                });
            }
        }];
    }
    
    if ([[MPWGlobal sharedInstance].recorder.meeting isEqual:self.meeting]) {
        self.recordingPV.hidden = NO;
        self.recordingLabel.hidden = NO;
        [MPWGlobal sharedInstance].recorder.delegate = self;
        [MPWGlobal sharedInstance].recorder.pv = self.recordingPV;
        [MPWGlobal sharedInstance].recorder.label = self.recordingLabel;
    }
    
    __weak __block typeof(self) weakSelf = self;
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
                BOOL isLocal = object[@"local"];
                PFFile *file = object[@"image"];
                if (isLocal && ![[MPWGlobal sharedInstance].uploadingFiles containsObject:file]) {
                    object[@"percentDone"] = @0;
                    object[@"failed"] = @YES;
                }
                [object pin];
            }
            [weakSelf reloadTableViewWithItems:task.result];
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
    PFObject *note = self.notes[indexPath.row];
    __weak __block typeof(self) weakSelf = self;

    NSDateFormatter *fm = [[NSDateFormatter alloc] init];
    [fm setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    int type = [note[@"type"] intValue];
    if (type == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoteTextCell" forIndexPath:indexPath];
        UILabel *label = (UILabel *)[cell viewWithTag:1];
        label.text = note[@"content"];
        
        UILabel *label2 = (UILabel *)[cell viewWithTag:2];
        label2.text = [fm stringFromDate:note[@"createTime"]];
        
        return cell;
    } else if (type == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoteVoiceCell" forIndexPath:indexPath];
        
        UILabel *label = (UILabel *)[cell viewWithTag:1];
        label.text = @"Voice";
        
        UILabel *label2 = (UILabel *)[cell viewWithTag:2];
        label2.text = [fm stringFromDate:note[@"createTime"]];
        label2.textColor = [UIColor lightGrayColor];
        
        UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
        
        MDBlockButton *btn = (MDBlockButton *)[cell viewWithTag:4];
        btn.buttonBlock = ^(MDBlockButton *button){
            [weakSelf playVoiceForNote:note];
        };
        
        BOOL local = note[@"local"];
        if (local) {
            BOOL failed = [note[@"failed"] boolValue];
            if (failed) {
                pv.hidden = YES;
                label2.textColor = [UIColor redColor];
                label2.text = @"Failed tap to upload again";
            } else {
                int percentDone = [note[@"percentDone"] intValue];
                pv.hidden = NO;
                pv.progress = percentDone/100.0;
            }
        } else {
            pv.hidden = YES;
//            PFFile *file = note[@"image"];
        }
        return cell;
    } else if (type == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoteImageCell" forIndexPath:indexPath];
        
        UILabel *label2 = (UILabel *)[cell viewWithTag:2];
        label2.text = [fm stringFromDate:note[@"createTime"]];
        label2.textColor = [UIColor lightGrayColor];

        UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
        
        UIImageView *iv = (UIImageView *)[cell viewWithTag:1];
        BOOL local = note[@"local"];
        if (local) {
            BOOL failed = [note[@"failed"] boolValue];
            if (failed) {
                pv.hidden = YES;
                label2.textColor = [UIColor redColor];
                label2.text = @"Failed tap to upload again";
            } else {
                int percentDone = [note[@"percentDone"] intValue];
                pv.hidden = NO;
                pv.progress = percentDone/100.0;
            }
            NSURL *url = [NSURL fileURLWithPath:note[@"localURL"]];
            [iv sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"defaultLoadingImage"]];

        } else {
            PFFile *file = note[@"image"];
            NSURL *url = [NSURL URLWithString:file.url];
            [iv sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"defaultLoadingImage"] options:SDWebImageProgressiveDownload progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                pv.hidden = NO;
                float f = expectedSize;
                pv.progress = receivedSize/f;
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                pv.hidden = YES;
                if (cacheType == SDImageCacheTypeNone) {
                    NSString *realName = [[file.name componentsSeparatedByString:@"-"] lastObject];
                    NSString *path = [[[MPWGlobal imagePathForMeeting:weakSelf.meeting] stringByAppendingPathComponent:realName] stringByAppendingPathExtension:@"png"];
                    NSData *imageData = UIImagePNGRepresentation(image);
                    [imageData writeToFile:path atomically:YES];
                }
            }];
        }
        return cell;
    }

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
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
    PFObject *note = self.notes[indexPath.row];
    int type = [note[@"type"] intValue];
    if (type == 0) {
        
    } else if (type == 1) {
    
    } else if (type == 2) {
        if (![note[@"failed"] boolValue]) {
            return;
        }
        NSString *localPath = note[@"localURL"];
        NSURL *fileURL = [NSURL fileURLWithPath:localPath];
        UIImage *image = [UIImage imageWithContentsOfFile:fileURL.path];
        if (!image) {
            image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:fileURL.absoluteString];
        }
        [self saveImageForNote:note image:image];
    }
}

#pragma mark - ImagePicker
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (!info[UIImagePickerControllerReferenceURL]) {
        [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:image.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            [self saveImage:image];
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            [self saveImage:image];
        }];
    }
}

- (void)saveImage:(UIImage *)image
{
    PFObject *note = [PFObject objectWithClassName:@"Note"];
    note[@"local"] = @YES;
    note[@"type"] = @2;
    note[@"creator"] = [PFUser currentUser];
    note[@"meeting"] = self.meeting;
    note[@"createTime"] = [NSDate date];
    note[@"percentDone"] = @(0);
    [note pin];
    
    [self saveImageForNote:note image:image];

    [self.notes addObject:note];
    NSIndexPath *ip = [NSIndexPath indexPathForRow:self.notes.count - 1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    [self hideEmptyVC];
}

- (void)saveImageForNote:(PFObject *)note image:(UIImage *)image
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyy_MM_dd_HH_mm_ss_SSS"];
    NSString *timeDesc = [formatter stringFromDate:[NSDate date]];
    NSString *path = [[[MPWGlobal imagePathForMeeting:self.meeting] stringByAppendingPathComponent:timeDesc] stringByAppendingPathExtension:@"png"];
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:path atomically:YES];
    PFFile *originalFile = note[@"image"];
    if (originalFile) {
        [[MPWGlobal sharedInstance].uploadingFiles removeObject:originalFile];
    }
    float rate = 0.5;
    while (imageData.length > 10485760) {
        imageData = [[NSData alloc] initWithData:UIImageJPEGRepresentation((image), rate)];
        rate = rate/2;
    }
    PFFile *imageFile = [PFFile fileWithName:timeDesc data:imageData];
    [[MPWGlobal sharedInstance].uploadingFiles addObject:imageFile];
    note[@"localURL"] = path;
    note[@"image"] = imageFile;
    note[@"failed"] = @NO;
    [note pin];
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error){
        if (error) {
            note[@"failed"] = @YES;
            [note pin];
            [[NSNotificationCenter defaultCenter] postNotificationName:MeetingTableViewControllerImageUploadPercentChanged object:note userInfo:@{@"failed":@YES}];
            return ;
        }
        
        [[SDImageCache sharedImageCache] storeImage:image forKey:imageFile.url toDisk:YES];
        
        PFObject *saveNote = [PFObject objectWithClassName:@"Note"];
        saveNote[@"type"] = @2;
        saveNote[@"image"] = note[@"image"];
        saveNote[@"creator"] = [PFUser currentUser];
        saveNote[@"meeting"] = note[@"meeting"];
        saveNote[@"createTime"] = note[@"createTime"];
        [saveNote pin];
        [saveNote saveEventually];
        [note unpin];
        [[NSNotificationCenter defaultCenter] postNotificationName:MeetingTableViewControllerImageUploadPercentChanged object:note userInfo:@{@"completed":@YES, @"saveNote":saveNote}];
    } progressBlock:^(int percentDone){
        note[@"percentDone"] = @(percentDone);
        [note pin];
        [[NSNotificationCenter defaultCenter] postNotificationName:MeetingTableViewControllerImageUploadPercentChanged object:note];
    }];
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
    if ([MPWGlobal sharedInstance].recorder) {
        if ([[MPWGlobal sharedInstance].recorder.meeting isEqual:self.meeting]) {
            self.recordingLabel.text = @"";
            self.recordingPV.progress = 0;
            self.recordingLabel.hidden = YES;
            self.recordingPV.hidden = YES;
            MPWRecorder *recorder = [MPWGlobal sharedInstance].recorder;
            [recorder stop];
        } else {
            return;
        }
    } else {
        self.recordingLabel.hidden = NO;
        self.recordingPV.hidden = NO;
        MPWRecorder *recorder = [MPWRecorder reocorderForMeeting:self.meeting];
        recorder.pv = self.recordingPV;
        recorder.label = self.recordingLabel;
        recorder.delegate = self;
        [recorder record];
        [MPWGlobal sharedInstance].recorder = recorder;
    }
}

- (IBAction)imageBtnPressed:(id)sender {
    dispatch_block_t showCamera = ^{
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:^{}];
    };
    dispatch_block_t showLibary = ^{
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:^{}];
    };
    
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        HHActionSheet *as = [[HHActionSheet alloc] initWithTitle:@"Choose a source"];
        [as addButtonWithTitle:@"Camera" block:showCamera];
        [as addButtonWithTitle:@"Photo Library" block:showLibary];
        [as showInView:self.view];
    } else {
        showLibary();
    }
}

- (IBAction)startPauseBtnPressed:(id)sender {
    NSArray *statuses = self.meeting[@"status"];
    NSDictionary *lastObject = statuses.lastObject;
    if (!lastObject) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        CountDownPickerViewController *vc = [sb instantiateViewControllerWithIdentifier:@"CountDown"];
        vc.delegate = self;
        [self addChildViewController:vc];
        vc.view.center = self.view.center;
        vc.view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
        [self.view addSubview:vc.view];
        return;
    } else {
        NSString *action = lastObject[@"action"];
        NSDate *actionDate = lastObject[@"date"];
        if ([action isEqualToString:@"start"]) {
            // pause
            [self.timer invalidate];
            self.timer = nil;
            self.startPauseBtn.selected = NO;
            self.stopBtn.enabled = YES;
            NSDate *cDate = [NSDate date];
            NSTimeInterval time = [lastObject[@"time"] doubleValue];
            NSTimeInterval timeleft = time - [cDate timeIntervalSinceDate:actionDate];
            NSMutableArray *newStatuses = [statuses mutableCopy];
            [newStatuses addObject:@{@"action":@"pause", @"date":cDate, @"time":@(timeleft)}];
            self.meeting[@"status"] = newStatuses;
            [self.meeting pin];
            [self.meeting saveEventually];
        } else if ([action isEqualToString:@"pause"]) {
            // start
            NSTimeInterval time = [lastObject[@"time"] doubleValue];
            
            NSMutableArray *newStatuses = [statuses mutableCopy];
            NSDictionary *dic = @{@"action":@"start",@"time":@(time),@"date":[NSDate date]};
            [newStatuses addObject:dic];
            
            self.meeting[@"status"] = newStatuses;
            [self.meeting pin];
            [self.meeting saveEventually];
            
            [self startTimer];
            self.startPauseBtn.selected = YES;
        } else if ([action isEqualToString:@"stop"]) {
            // start
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            CountDownPickerViewController *vc = [sb instantiateViewControllerWithIdentifier:@"CountDown"];
            vc.delegate = self;
            [self addChildViewController:vc];
            vc.view.center = self.view.center;
            vc.view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
            [self.view addSubview:vc.view];
        }
    }
}

- (IBAction)stopBtnPressed:(id)sender {
    NSArray *statuses = self.meeting[@"status"];
    NSDictionary *lastObject = statuses.lastObject;
    
    NSString *action = lastObject[@"action"];
    NSDate *actionDate = lastObject[@"date"];
    [self.timer invalidate];
    self.timer = nil;
    
    if ([action isEqualToString:@"start"]) {
        NSDate *cDate = [NSDate date];
        NSTimeInterval timeleft = [cDate timeIntervalSinceDate:actionDate];
        NSMutableArray *newStatuses = [statuses mutableCopy];
        [newStatuses addObject:@{@"action":@"stop", @"date":cDate, @"time":@(timeleft)}];
        self.meeting[@"status"] = newStatuses;
        [self.meeting pin];
        [self.meeting saveEventually];
    }
    else if ([action isEqualToString:@"pause"]) {
        NSTimeInterval time = [lastObject[@"time"] doubleValue];
        NSLog(@"%.2f", time);

        NSMutableArray *newStatuses = [statuses mutableCopy];
        NSDictionary *dic = @{@"action":@"stop",@"time":@(time),@"date":[NSDate date]};
        [newStatuses addObject:dic];
        
        self.meeting[@"status"] = newStatuses;
        [self.meeting pin];
        [self.meeting saveEventually];
        
        self.startPauseBtn.selected = YES;
    }
    

    self.startPauseBtn.selected = NO;
    self.stopBtn.enabled = NO;
}

- (void)playVoiceForNote:(PFObject *)note
{
    NSIndexPath *ip = [NSIndexPath indexPathForRow:[self.notes indexOfObject:note] inSection:0];

    if (self.playingNote) {
        NSIndexPath *playingIP = [NSIndexPath indexPathForRow:[self.notes indexOfObject:self.playingNote] inSection:0];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:playingIP];

        UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
        pv.progress = 0;
        pv.hidden = YES;
        MDBlockButton *btn = (MDBlockButton *)[cell viewWithTag:4];
        btn.selected = NO;
        [self.player stop];
        
        if ([playingIP isEqual:ip]) {
            self.playingNote = nil;
            self.player = nil;
            return;
        }
        self.playingNote = nil;
        self.player = nil;
    }
    
    PFFile *record = note[@"record"];
    
    [record getDataInBackgroundWithBlock:^(NSData *data, NSError *error){
        if (error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:MeetingTableViewControllerRecordDownloadPercentChanged object:note userInfo:@{@"failed":@YES}];
            return ;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MeetingTableViewControllerRecordDownloadPercentChanged object:note userInfo:@{@"completed":@YES, @"data":data}];

    } progressBlock:^(int percentDone){
        [[NSNotificationCenter defaultCenter] postNotificationName:MeetingTableViewControllerRecordDownloadPercentChanged object:note userInfo:@{@"percentDone":@(percentDone)}];
    }];
    self.playingNote = note;
}

- (void)startTimer
{
    [self stopTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateLabel) userInfo:nil repeats:YES];
    [self.timer fire];
}

- (void)updateLabel
{
    NSDictionary *lastObject = [self.meeting[@"status"] lastObject];
    // it must be action start
    
    NSTimeInterval time = [lastObject[@"time"] doubleValue];
    NSDate *startDate = lastObject[@"date"];
    NSDate *cDate = [NSDate date];
    NSTimeInterval timeleft = time - [cDate timeIntervalSinceDate:startDate];
    NSLog(@"%.2f", timeleft);
    
    NSTimeInterval absTimeLeft = timeleft;
    if (absTimeLeft < 0) {
        absTimeLeft = - absTimeLeft;
    }
    int hour = 0;
    int minute = 0;
    int second = absTimeLeft;
    while (second >= 60) {
        minute = second/60;
        second = second%60;
    }
    while (minute >= 60) {
        hour = minute/60;
        minute = minute%60;
    }
    if (timeleft > 0) {
        self.countDownLabel.textColor = [UIColor blackColor];
    } else {
        self.countDownLabel.textColor = [UIColor redColor];
    }
    self.countDownLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TextEdit"]) {
        UINavigationController *nc = segue.destinationViewController;
        TextEditingController *vc = nc.viewControllers.firstObject;
        vc.delegate = self;
    }
}

#pragma mark - Audio
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    PFObject *note = [PFObject objectWithClassName:@"Note"];
    note[@"local"] = @YES;
    note[@"type"] = @1;
    note[@"creator"] = [PFUser currentUser];
    note[@"meeting"] = self.meeting;
    note[@"createTime"] = [NSDate date];
    note[@"percentDone"] = @(0);
    [note pin];
    
    [self saveRecordForNote:note recordPath:recorder.url.path];
    
    [self.notes addObject:note];
    NSIndexPath *ip = [NSIndexPath indexPathForRow:self.notes.count - 1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    [self hideEmptyVC];
    
    [MPWGlobal sharedInstance].recorder = nil;
}

- (void)saveRecordForNote:(PFObject *)note recordPath:(NSString *)path
{
    PFFile *originalFile = note[@"record"];
    if (originalFile) {
        [[MPWGlobal sharedInstance].uploadingFiles removeObject:originalFile];
    }
 
    NSData *data = [NSData dataWithContentsOfFile:path];
    PFFile *imageFile = [PFFile fileWithName:[path.lastPathComponent stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", path.pathExtension] withString:@""] data:data];
    [[MPWGlobal sharedInstance].uploadingFiles addObject:imageFile];
    note[@"localURL"] = path;
    note[@"record"] = imageFile;
    note[@"failed"] = @NO;
    [note pin];
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error){
        if (error) {
            note[@"failed"] = @YES;
            [note pin];
            [[NSNotificationCenter defaultCenter] postNotificationName:MeetingTableViewControllerRecordUploadPercentChanged object:note userInfo:@{@"failed":@YES}];
            return ;
        }
        
        PFObject *saveNote = [PFObject objectWithClassName:@"Note"];
        saveNote[@"type"] = @1;
        saveNote[@"record"] = note[@"record"];
        saveNote[@"creator"] = [PFUser currentUser];
        saveNote[@"meeting"] = note[@"meeting"];
        saveNote[@"createTime"] = note[@"createTime"];
        [saveNote pin];
        [saveNote saveEventually];
        [note unpin];
        [[NSNotificationCenter defaultCenter] postNotificationName:MeetingTableViewControllerRecordUploadPercentChanged object:note userInfo:@{@"completed":@YES, @"saveNote":saveNote}];
    } progressBlock:^(int percentDone){
        note[@"percentDone"] = @(percentDone);
        [note pin];
        [[NSNotificationCenter defaultCenter] postNotificationName:MeetingTableViewControllerRecordUploadPercentChanged object:note];
    }];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSIndexPath *ip = [NSIndexPath indexPathForRow:[self.notes indexOfObject:self.playingNote] inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
    UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
    pv.hidden = YES;
    MDBlockButton *btn = (MDBlockButton *)[cell viewWithTag:4];
    btn.selected = NO;
    self.playingNote = nil;
    self.player = nil;
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSIndexPath *ip = [NSIndexPath indexPathForRow:[self.notes indexOfObject:self.playingNote] inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
    UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
    pv.hidden = YES;
    MDBlockButton *btn = (MDBlockButton *)[cell viewWithTag:4];
    btn.selected = NO;
    self.playingNote = nil;
    self.player = nil;
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

#pragma mark - CountDownPickerViewController
- (void)countDownPickerViewController:(CountDownPickerViewController *)controller didFinishWithResult:(NSTimeInterval)time
{
    NSLog(@"%.2f", time);
    int hour = 0;
    int minute = 0;
    int second = time;
    while (second >= 60) {
        minute = second/60;
        second = second%60;
    }
    while (minute >= 60) {
        hour = minute/60;
        minute = minute%60;
    }
    
    self.countDownLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
    NSMutableArray *newStatuses = [self.meeting[@"status"] mutableCopy];
    if (!newStatuses) {
        newStatuses = [NSMutableArray array];
    }
    NSDictionary *dic = @{@"action":@"start",@"time":@(time),@"date":[NSDate date]};
    [newStatuses addObject:dic];
    
    self.meeting[@"status"] = newStatuses;
    [self.meeting pin];
    [self.meeting saveEventually];
    
    self.startPauseBtn.selected = YES;
    self.stopBtn.enabled = YES;
    [self startTimer];
    
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
}

#pragma mark - Notifications
- (void)imagePercentChanged:(NSNotification *)notification
{
    PFObject *note = notification.object;
    if ([self.notes containsObject:note]) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.notes indexOfObject:note] inSection:0]];

        if ([notification.userInfo[@"completed"] boolValue]) {
            UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
            pv.hidden = YES;
            
            PFObject *saveNote = notification.userInfo[@"saveNote"];
            [self.notes replaceObjectAtIndex:[self.notes indexOfObject:note] withObject:saveNote];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.notes indexOfObject:note] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
            UILabel *label2 = (UILabel *)[cell viewWithTag:2];
            if ([note[@"failed"] boolValue]) {
                pv.hidden = YES;
                label2.textColor = [UIColor redColor];
                label2.text = @"Failed tap to upload again";
            } else {
                NSDateFormatter *fm = [[NSDateFormatter alloc] init];
                [fm setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                label2.text = [fm stringFromDate:note[@"createTime"]];
                label2.textColor = [UIColor lightGrayColor];
                int percentDone = [note[@"percentDone"] intValue];
                pv.hidden = NO;
                pv.progress = percentDone/100.0;
            }
        }
    }
}

- (void)recordPercentChanged:(NSNotification *)notification
{
    PFObject *note = notification.object;
    if ([self.notes containsObject:note]) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.notes indexOfObject:note] inSection:0]];
        
        if ([notification.userInfo[@"completed"] boolValue]) {
            UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
            pv.hidden = YES;
            
            PFObject *saveNote = notification.userInfo[@"saveNote"];
            [self.notes replaceObjectAtIndex:[self.notes indexOfObject:note] withObject:saveNote];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.notes indexOfObject:note] inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
            UILabel *label2 = (UILabel *)[cell viewWithTag:2];
            if ([note[@"failed"] boolValue]) {
                pv.hidden = YES;
                label2.textColor = [UIColor redColor];
                label2.text = @"Failed tap to upload again";
            } else {
                NSDateFormatter *fm = [[NSDateFormatter alloc] init];
                [fm setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                label2.text = [fm stringFromDate:note[@"createTime"]];
                label2.textColor = [UIColor lightGrayColor];
                int percentDone = [note[@"percentDone"] intValue];
                pv.hidden = NO;
                pv.progress = percentDone/100.0;
            }
        }
    }
}

- (void)recordDownloadPercentChanged:(NSNotification *)notification
{
    PFObject *note = notification.object;
    if ([self.notes containsObject:note]) {
        NSIndexPath *ip = [NSIndexPath indexPathForRow:[self.notes indexOfObject:note] inSection:0];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
        UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
        
        MDBlockButton *btn = (MDBlockButton *)[cell viewWithTag:4];
        
        if ([notification.userInfo[@"completed"] boolValue]) {
            NSData *data = notification.userInfo[@"data"];
            PFFile *file = note[@"record"];
            NSString *fileName = [[file.name componentsSeparatedByString:@"-"] lastObject];
            NSString *path = [[[MPWGlobal recordPathForMeeting:self.meeting] stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"pcm"];
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
            if (!exists) {
                [data writeToFile:path atomically:YES];
            }
            pv.hidden = YES;
            NSError *error = nil;
            AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:data error:&error];
            player.delegate = self;
            self.player = player;
            [player play];
            btn.selected = YES;
        } else {
            UILabel *label2 = (UILabel *)[cell viewWithTag:2];
            if ([note[@"failed"] boolValue]) {
                pv.hidden = YES;
                label2.textColor = [UIColor redColor];
                label2.text = @"Failed tap to download again";
            } else {
                NSDateFormatter *fm = [[NSDateFormatter alloc] init];
                [fm setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                label2.text = [fm stringFromDate:note[@"createTime"]];
                label2.textColor = [UIColor lightGrayColor];
                int percentDone = [note[@"percentDone"] intValue];
                pv.hidden = NO;
                pv.progress = percentDone/100.0;
            }
        }
    }
}
@end
