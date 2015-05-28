//
//  SummaryTableViewController.m
//  MePow
//
//  Created by Wee Tom on 15/5/27.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "SummaryTableViewController.h"
#import "MDBlockButton.h"
#import "UIImageView+WebCache.h"
#import "TextEditingController.h"
#import "MeetingTableViewController.h"
#import <MessageUI/MessageUI.h>
#import "MDAPICategory.h"

NSString *SummaryTableViewControllerRecordDownloadPercentChanged = @"SummaryTableViewControllerRecordDownloadPercentChanged";
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface SummaryTableViewController () <TextEditingControllerDelegate, AVAudioPlayerDelegate>
@property (weak, nonatomic) IBOutlet UITextView *headerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBtnItem;
@property (strong, nonatomic) NSArray *records, *images;
@property (assign, nonatomic) BOOL audioSessionPermitted;
@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) PFFile *playingNote;
@property (nonatomic) UIActivityViewController *activityViewController;
@end

@implementation SummaryTableViewController
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SummaryTableViewControllerRecordDownloadPercentChanged object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordDownloadPercentChanged:) name:SummaryTableViewControllerRecordDownloadPercentChanged object:nil];

    self.tableView.estimatedRowHeight = 60.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.headerView.text = self.summary[@"content"];
    if (self.headerView.text.trim.length == 0) {
        self.headerView.text = @"No summary text here";
        self.headerView.textColor = [UIColor lightGrayColor];
    } else {
        self.headerView.textColor = [UIColor blackColor];
    }
    [self.headerView sizeToFit];
    self.records = self.summary[@"records"];
    self.images = self.summary[@"images"];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self audioPlayerDecodeErrorDidOccur:nil error:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2*((self.records.count + self.images.count) > 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.records.count;
    }
    return self.images.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Records";
    }
    return @"Photos";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak __block typeof(self) weakSelf = self;

    if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoteImageCell" forIndexPath:indexPath];
        UILabel *label2 = (UILabel *)[cell viewWithTag:2];
        label2.text = nil;
        
        UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
        
        UIImageView *iv = (UIImageView *)[cell viewWithTag:1];
        
        PFFile *file = self.images[indexPath.row];
        NSURL *url = [NSURL URLWithString:file.url];
        [iv sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"defaultLoadingImage"] options:SDWebImageProgressiveDownload progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            pv.hidden = NO;
            float f = expectedSize;
            pv.progress = receivedSize/f;
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            pv.hidden = YES;
        }];
        
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoteVoiceCell" forIndexPath:indexPath];
        
        UILabel *label = (UILabel *)[cell viewWithTag:1];
        label.text = @"Voice";
        
        UILabel *label2 = (UILabel *)[cell viewWithTag:2];
        label2.text = nil;
        
        UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
        
        PFFile *file = self.records[indexPath.row];
        MDBlockButton *btn = (MDBlockButton *)[cell viewWithTag:4];
        btn.buttonBlock = ^(MDBlockButton *button){
            [weakSelf playVoiceForFile:file];
        };
        
        pv.hidden = YES;
        return cell;
    }
}


- (void)playVoiceForFile:(PFFile *)file
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&err];
    [audioSession setActive:YES error:&err];
    
    NSIndexPath *ip = [NSIndexPath indexPathForRow:[self.records indexOfObject:file] inSection:0];
    
    if (self.playingNote) {
        NSIndexPath *playingIP = [NSIndexPath indexPathForRow:[self.records indexOfObject:self.playingNote] inSection:0];
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
    
    PFFile *record = file;
    
    [record getDataInBackgroundWithBlock:^(NSData *data, NSError *error){
        if (error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SummaryTableViewControllerRecordDownloadPercentChanged object:file userInfo:@{@"failed":@YES}];
            return ;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SummaryTableViewControllerRecordDownloadPercentChanged object:file userInfo:@{@"completed":@YES, @"data":data}];
        
    } progressBlock:^(int percentDone){
        [[NSNotificationCenter defaultCenter] postNotificationName:SummaryTableViewControllerRecordDownloadPercentChanged object:file userInfo:@{@"percentDone":@(percentDone)}];
    }];
    self.playingNote = file;
}

#pragma mark - Navigation
- (IBAction)doneBtnPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SumEdit"]) {
        UINavigationController *nav = segue.destinationViewController;
        TextEditingController *vc = nav.viewControllers.firstObject;
        vc.meeting = self.summary[@"meeting"];
        vc.summary = self.summary;
        vc.delegate = self;
    }
}

- (void)textEditingController:(TextEditingController *)controller didFinishEditingTextWithResult:(NSString *)text
{

}

- (void)recordDownloadPercentChanged:(NSNotification *)notification
{
    PFFile *note = notification.object;
    if ([self.records containsObject:note]) {
        NSIndexPath *ip = [NSIndexPath indexPathForRow:[self.records indexOfObject:note] inSection:0];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
        UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
        
        MDBlockButton *btn = (MDBlockButton *)[cell viewWithTag:4];
        
        if ([notification.userInfo[@"completed"] boolValue]) {
            NSData *data = notification.userInfo[@"data"];
            PFFile *file = note;
            NSString *fileName = [[file.name componentsSeparatedByString:@"-"] lastObject];
            NSString *path = [[[MPWGlobal recordPathForMeeting:self.summary[@"meeting"]] stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"pcm"];
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
            int percentDone = [notification.userInfo[@"percentDone"] intValue];
            pv.hidden = NO;
            pv.progress = percentDone/100.0;
            
        }
    }
}

#pragma mark - Audio
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self.player stop];
    NSIndexPath *ip = [NSIndexPath indexPathForRow:[self.records indexOfObject:self.playingNote] inSection:0];
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
    [self.player stop];
    NSIndexPath *ip = [NSIndexPath indexPathForRow:[self.records indexOfObject:self.playingNote] inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
    UIProgressView *pv = (UIProgressView *)[cell viewWithTag:3];
    pv.hidden = YES;
    MDBlockButton *btn = (MDBlockButton *)[cell viewWithTag:4];
    btn.selected = NO;
    self.playingNote = nil;
    self.player = nil;
}

- (IBAction)share:(id)sender {
    HHActionSheet *as = [[HHActionSheet alloc] initWithTitle:@"You may choose a type"];
    [as addButtonWithTitle:@"All in Text" block:^{
        [self exportWithByText:YES];
    }];
    [as addButtonWithTitle:@"Text and Image" block:^{
        [self exportWithByText:NO];
    }];
    if ([MDAPIManager sharedManager].accessToken.length > 0) {
        [as addButtonWithTitle:@"Via Mingdao" block:^{
            [self exportToMingdao];
        }];
    }
    [as addCancelButtonWithTitle:@"Cancel"];
    [as showInView:self.view];
}

- (void)exportWithByText:(BOOL)byText
{
    NSMutableArray *items = [NSMutableArray array];
    NSMutableString *ms = [[NSMutableString alloc] init];
    PFObject *meeting = self.summary[@"meeting"];
    [ms appendFormat:@"Summary For %@\n\n", meeting[@"name"]];
    [ms appendString:self.headerView.text];
    if (self.records.count > 0) {
        [ms appendFormat:@"\nRECORDS\n"];
        for (int i = 0; i < self.records.count; i++) {
            PFFile *file = self.records[i];
            [ms appendFormat:@"%d. %@\n", i+1, file.url];
        }
    }
    
    if (byText) {
        if (self.images.count > 0) {
            [ms appendFormat:@"\nPHOTOS\n"];
            for (int i = 0; i < self.images.count; i++) {
                PFFile *file = self.records[i];
                [ms appendFormat:@"%d. %@\n", i+1, file.url];
            }
        }
        [items addObject:ms];
    } else {
        [items addObject:ms];
        if (self.images.count > 0) {
            for (int i = 0; i < self.images.count; i++) {
                PFFile *file = self.images[i];
                UIImage *image = [UIImage imageWithData:[file getData]];
                if (image) {
                    [items addObject:image];
                }
            }
        }
    }

    self.activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    
    // Show loading spinner after a couple of seconds
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!self.activityViewController) {
        }
    });
    
    self.activityViewController.popoverPresentationController.barButtonItem = self.shareBtnItem;
    [self presentViewController:self.activityViewController animated:YES completion:nil];
}

- (void)exportToMingdao
{
    NSMutableString *ms = [[NSMutableString alloc] init];
    PFObject *meeting = self.summary[@"meeting"];
    [ms appendFormat:@"Summary For #%@#\n\n", meeting[@"name"]];
    [ms appendString:self.headerView.text];
    if (self.records.count > 0) {
        [ms appendFormat:@"\nRECORDS\n"];
        for (int i = 0; i < self.records.count; i++) {
            PFFile *file = self.records[i];
            [ms appendFormat:@"%d. %@\n", i+1, file.url];
        }
    }

    NSMutableArray *images = [NSMutableArray array];
    if (self.images.count > 0) {
        if (self.images.count > 6) {
            [ms appendFormat:@"\nMORE PHOTOS\n"];
        }
        for (int i = 0; i < self.images.count; i++) {
            PFFile *file = self.images[i];
            if (images.count < 6) {
                UIImage *image = [UIImage imageWithData:[file getData]];
                if (image) {
                    [images addObject:image];
                }
            } else {
                [ms appendFormat:@"%d. %@\n", i+1, file.url];
            }
        }
    }
    
    NSArray *users = [meeting[@"users"] sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        NSString *name1 = obj1[@"MingdaoUserName"];
        NSString *name2 = obj2[@"MingdaoUserName"];
        if (name1.length > name2.length) {
            return NSOrderedAscending;
        } else if (name1.length == name2.length) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }];
    
    if (users.count > 0) {
        [ms appendString:@"\nATTENDANCES:\n"];
        for (NSDictionary *user in users) {
            NSString *name = user[@"MingdaoUserName"];
            NSString *userID = user[@"MingdaoUserID"];
            [ms replaceOccurrencesOfString:[NSString stringWithFormat:@"@%@", name] withString:[NSString stringWithFormat:@"###%@###", userID] options:NSLiteralSearch range:NSMakeRange(0, ms.length)];
            [ms appendString:[NSString stringWithFormat:@"###%@### ", userID]];
        }
    }
    
    MRProgressOverlayView *progressView = [MRProgressOverlayView showOverlayAddedTo:self.view animated:YES];
    [progressView show:YES];
    MDAPINSStringHandler handler = ^(NSString *string, NSError *error) {
        if (error) {
            progressView.mode = MRProgressOverlayViewModeCross;
            progressView.titleLabelText = error.userInfo[NSLocalizedDescriptionKey];
            [progressView performSelector:@selector(dismiss:) withObject:@YES afterDelay:2];
            return ;
        }
        
        NSString *urlString = [NSString stringWithFormat:@"mingdao://post/%@", string];
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]) {
            [progressView hide:YES];
            HHAlertView *alert = [[HHAlertView alloc] initWithTitle:@"YES!" message:@"You have posted the SUMMARY to Mingdao successfully!" cancelButtonTitle:@"Later"];
            [alert addButtonWithTitle:@"Checkout!" block:^{
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
            }];
            [alert show];
        } else {
            progressView.mode = MRProgressOverlayViewModeCheckmark;
            progressView.titleLabelText = @"Done!";
            [progressView performSelector:@selector(dismiss:) withObject:@YES afterDelay:1];
        }
    };
    if (self.images.count == 0) {
        [[[MDAPIManager sharedManager] createTextPostWithText:ms groupIDs:nil shareType:3 handler:handler] start];
    } else {
        [[[MDAPIManager sharedManager] createImagePostWithText:ms images:images groupIDs:nil shareType:3 toCenter:NO handler:handler] start];
    }
}

- (IBAction)trash:(id)sender {
    HHActionSheet *actionSheet = [[HHActionSheet alloc] initWithTitle:@"This action can not be undone"];
    [actionSheet addDestructiveButtonWithTitle:@"Yes, delete it" block:^{
        PFObject *meeting = self.summary[@"meeting"];
        [meeting removeObjectForKey:@"summary"];
        [self.summary unpin];
        [self.summary deleteEventually];
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }];
    [actionSheet addCancelButtonWithTitle:@"No, keep it"];
    [actionSheet showInView:self.view];
}
@end
