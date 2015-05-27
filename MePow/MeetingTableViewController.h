//
//  MeetingTableViewController.h
//  MePow
//
//  Created by WeeTom on 15/5/22.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *MeetingTableViewControllerDidDeleteMeeting;

@interface MeetingTableViewController : UITableViewController
@property (strong, nonatomic) PFObject *meeting;
- (void)stopTimer;
@end
