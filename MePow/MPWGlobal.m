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

+ (NSString *)rootDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    return path;
}
@end
