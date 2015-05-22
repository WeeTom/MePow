//
//  ViewController.m
//  MePow
//
//  Created by Wee Tom on 15/5/18.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "ViewController.h"
#import "EmptyViewController.h"
#import "MRProgress.h"
#import "HHKit.h"
#import "MeetingTableViewController.h"


@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *meetings;
@property (strong, nonatomic) EmptyViewController *empryVC;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(self.view.frame.size.width/2 - 10, self.view.frame.size.width/2);
    self.collectionView.collectionViewLayout = layout;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    MRProgressOverlayView *progressView = [MRProgressOverlayView showOverlayAddedTo:self.view animated:YES];
    [progressView show:YES];
    PFQuery *query = [PFQuery queryWithClassName:@"Meeting"];
    [query orderByDescending:@"begin"];
    [query fromLocalDatastore];
    [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            NSLog(@"Error: %@", task.error);
            return task;
        }
        
        [HHThreadHelper performBlockInMainThread:^{
            self.meetings = [NSMutableArray array];
            [self.meetings addObjectsFromArray:task.result];
            [self.collectionView reloadData];
            [progressView dismiss:YES];
        }];
        return task;
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Empty
- (void)showEmptyVC
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EmptyViewController * vc = (EmptyViewController *)[sb instantiateViewControllerWithIdentifier:@"Empty"];
    [self addChildViewController:vc];
    [self.view addSubview:vc.view];
    
    [vc setupWithImage:nil text:@"No Meeting yet!\nStart Now!" actionHandler:^(EmptyViewController *emptyViewController){
        
    }];
    self.empryVC = vc;
}

- (void)hideEmptyVC
{
    [self.empryVC.view removeFromSuperview];
    [self.empryVC removeFromParentViewController];
    self.empryVC = nil;
}

#pragma mark - CollectionView
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.meetings.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Meeting Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
//    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    UILabel *label = (UILabel *)[cell viewWithTag:2];
    PFObject *meeting = self.meetings[indexPath.row];
    label.text = meeting[@"name"];
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Meeting"]) {
        MeetingTableViewController *vc = segue.destinationViewController;
        NSIndexPath *ip = [self.collectionView indexPathForCell:sender];
        PFObject *meeting = self.meetings[ip.row];
        vc.meeting = meeting;
    }
}
@end
