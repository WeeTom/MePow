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

NSString *SummaryTableViewControllerRecordDownloadPercentChanged = @"SummaryTableViewControllerRecordDownloadPercentChanged";

@interface SummaryTableViewController () <TextEditingControllerDelegate, AVAudioPlayerDelegate>
@property (weak, nonatomic) IBOutlet UITextView *headerView;
@property (strong, nonatomic) NSArray *records, *images;
@property (assign, nonatomic) BOOL audioSessionPermitted;
@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) PFFile *playingNote;
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
    return 2;
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
@end
