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
        }
    }
    return sharedInstance;

}
@end
