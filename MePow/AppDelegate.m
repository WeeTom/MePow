//
//  AppDelegate.m
//  MePow
//
//  Created by Wee Tom on 15/5/18.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "AppDelegate.h"
#import "MeetingTableViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Parse enableLocalDatastore];
    NSDictionary *configuration = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Configuration" ofType:@"plist"]];

    [Parse setApplicationId:configuration[@"ParseAppID"]
                  clientKey:configuration[@"ParseClientKey"]];
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];

    [self registerPushService];
    
    [MPWGlobal sharedInstance];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Notification
- (void)registerPushService
{
    UIApplication *application = [UIApplication sharedApplication];
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    switch ([[UIApplication sharedApplication] applicationState]) {
        case UIApplicationStateActive: {
            HHAlertView *alertView = [[HHAlertView alloc] initWithTitle:@"Alert!" message:notification.alertBody cancelButtonTitle:@"Check Out!" cancelBlock:^{
                PFQuery *query = [PFQuery queryWithClassName:@"Meeting"];
                [query fromLocalDatastore];
                [query whereKey:@"objectId" equalTo:notification.userInfo[@"meetingID"]];
                [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task) {
                    if (task.error) {
                        return task;
                    }
                    
                    PFObject *meeting = [task.result lastObject];
                    if ([meeting isKindOfClass:[PFObject class]]) {
                        [self showMeeting:meeting];
                    }
                    return task;
                }];

            }];
            [alertView show];
        }
            break;
        default: {
            PFQuery *query = [PFQuery queryWithClassName:@"Meeting"];
            [query fromLocalDatastore];
            [query whereKey:@"objectId" equalTo:notification.userInfo[@"meetingID"]];
            [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task) {
                if (task.error) {
                    return task;
                }
                
                PFObject *meeting = [task.result lastObject];
                if ([meeting isKindOfClass:[PFObject class]]) {
                    [self showMeeting:meeting];
                }
                return task;
            }];
        }
            break;
    }
}

- (void)showMeeting:(PFObject *)meeting
{
    if (![[NSThread currentThread] isMainThread]) {
        [self performSelectorOnMainThread:@selector(showMeeting:) withObject:meeting waitUntilDone:NO];
        return;
    }
    UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
    UIViewController *lastVC = nav.viewControllers.lastObject;
    MeetingTableViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MeetingDetail"];
    vc.meeting = meeting;
    if ([lastVC isKindOfClass:[MeetingTableViewController class]]) {
        MeetingTableViewController *lastMTVC = (MeetingTableViewController *)lastVC;
        [lastMTVC stopTimer];
        [nav replaceVisibleViewController:vc];
    } else {
        [nav pushViewController:vc animated:YES];
    }
}
@end
