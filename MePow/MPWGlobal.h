//
//  MPWGlobal.h
//  MePow
//
//  Created by Wee Tom on 15/5/21.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPWRecorder.h"

@interface MPWGlobal : NSObject
+ (MPWGlobal *)sharedInstance;

+ (NSString *)imagePathForMeeting:(PFObject *)meeting;
+ (NSString *)recordPathForMeeting:(PFObject *)meeting;

+ (BOOL)scheduledNotificationExistsForMeeting:(PFObject *)meeting type:(int)startOrEnd;
+ (void)scheduleNotificationForMeeting:(PFObject *)meeting type:(int)startOrEnd;
+ (void)cancelNotificationForMeeting:(PFObject *)meeting type:(int)startOrEnd;

@property (strong, nonatomic) NSMutableArray *uploadingFiles, *downloadingFiles;
@property (strong, nonatomic) MPWRecorder *recorder;

@property (strong, nonatomic) NSMutableArray *meetingTimers;
@end
