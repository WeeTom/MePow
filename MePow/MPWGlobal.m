//
//  MPWGlobal.m
//  MePow
//
//  Created by Wee Tom on 15/5/21.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "MPWGlobal.h"

@implementation MPWGlobal
static MPWGlobal *sharedInstance = nil;
+ (MPWGlobal *)sharedInstance
{
    @synchronized(self)
    {
        if  (!sharedInstance)
        {
            sharedInstance = [[MPWGlobal alloc] init];
            sharedInstance.uploadingFiles = [NSMutableArray array];
            sharedInstance.downloadingFiles = [NSMutableArray array];
        }
    }
    return sharedInstance;
}

+ (NSString *)imagePathForMeeting:(PFObject *)meeting
{
    NSString *filePathAndDirectory = [[[[self rootDirectory] stringByAppendingPathComponent:[PFUser currentUser].objectId] stringByAppendingPathComponent:meeting.objectId] stringByAppendingPathComponent:@"images"];

    NSError *error1 = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error1])
    {
        //        NSLog(@"Create directory error: %@", error1);
    }
    return filePathAndDirectory;
}

+ (NSString *)recordPathForMeeting:(PFObject *)meeting
{
    NSString *filePathAndDirectory = [[[[self rootDirectory] stringByAppendingPathComponent:[PFUser currentUser].objectId] stringByAppendingPathComponent:meeting.objectId] stringByAppendingPathComponent:@"records"];
    
    NSError *error1 = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error1])
    {
        //        NSLog(@"Create directory error: %@", error1);
    }
    return filePathAndDirectory;
}

+ (BOOL)scheduledNotificationExistsForMeeting:(PFObject *)meeting type:(int)startOrEnd
{
    NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    for (UILocalNotification *noti in notifications) {
        if ([noti.userInfo[@"meetingID"] isEqualToString:meeting.objectId] &&
            [noti.userInfo[@"type"] intValue] == startOrEnd) {
            return YES;
        }
    }
    return NO;
}

+ (void)scheduleNotificationForMeeting:(PFObject *)meeting type:(int)startOrEnd;
{
    if (startOrEnd == 0) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        if (notification != nil) {
            notification.fireDate = [meeting[@"begin"] dateByAddingTimeInterval:-60*15]; //触发通知的时间
            notification.repeatInterval = 0; //循环次数，kCFCalendarUnitWeekday一周一次
            
            notification.timeZone = [NSTimeZone defaultTimeZone];
            notification.soundName = UILocalNotificationDefaultSoundName;
            notification.alertBody = [NSString stringWithFormat:@"%@ will be begun in 15 minutes! please get your self prepared!", meeting[@"name"]];
            
            notification.alertAction = @"Start preparing";  //提示框按钮
            notification.hasAction = YES; //是否显示额外的按钮，为no时alertAction消失
            
            //            notification.applicationIconBadgeNumber = 1; //设置app图标右上角的数字
            
            //下面设置本地通知发送的消息，这个消息可以接受
            if (meeting.objectId) {
                NSDictionary* infoDic = [NSDictionary dictionaryWithObjects:@[meeting.objectId, @"0"] forKeys:@[@"meetingID", @"type"]];
                notification.userInfo = infoDic;
            }
            //发送通知
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        }
    } else {
        NSArray *statuses = meeting[@"status"];
        NSDictionary *lastActionDic = statuses.lastObject;
        if (![lastActionDic[@"action"] isEqualToString:@"start"]) {
            return;
        }
        
        NSDate *startDate = lastActionDic[@"date"];
        NSTimeInterval timeLeft = [lastActionDic[@"time"] doubleValue];
        for (int i = 0; i < 3; i++) {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            if (notification != nil) {
                NSComparisonResult result = [[NSDate date] compare:[startDate dateByAddingTimeInterval:timeLeft + 15*60*i]];
                if (result == NSOrderedDescending) {
                    continue;
                }
                notification.fireDate = [startDate dateByAddingTimeInterval:timeLeft + 15*60*i]; //触发通知的时间
                notification.repeatInterval = 0; //循环次数，kCFCalendarUnitWeekday一周一次
                
                notification.timeZone = [NSTimeZone defaultTimeZone];
                notification.soundName = UILocalNotificationDefaultSoundName;
                if (i == 0) {
                    notification.alertBody = [NSString stringWithFormat:@"%@ should be over!", meeting[@"name"]];
                } else {
                    notification.alertBody = [NSString stringWithFormat:@"%@ has been over time for %d minutes!", meeting[@"name"], 15*i];
                }
                notification.alertAction = @"Got it!";  //提示框按钮
                notification.hasAction = YES; //是否显示额外的按钮，为no时alertAction消失
                
                //            notification.applicationIconBadgeNumber = 1; //设置app图标右上角的数字
                
                //下面设置本地通知发送的消息，这个消息可以接受
                if (meeting.objectId) {
                    NSDictionary* infoDic = [NSDictionary dictionaryWithObjects:@[meeting.objectId, @"1"] forKeys:@[@"meetingID", @"type"]];
                    notification.userInfo = infoDic;
                }
                //发送通知
                [[UIApplication sharedApplication] scheduleLocalNotification:notification];
            }
        }
    }
}

+ (void)cancelNotificationForMeeting:(PFObject *)meeting type:(int)startOrEnd
{
    NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    for (UILocalNotification *noti in notifications) {
        if ([noti.userInfo[@"meetingiD"] isEqualToString:meeting.objectId] &&
            [noti.userInfo[@"type"] intValue] == startOrEnd) {
            [[UIApplication sharedApplication] cancelLocalNotification:noti];
            break;
        }
    }
}

+ (NSString *)rootDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    return path;
}
@end
