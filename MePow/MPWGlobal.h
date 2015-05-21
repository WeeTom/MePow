//
//  MPWGlobal.h
//  MePow
//
//  Created by Wee Tom on 15/5/21.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPWGlobal : NSObject
+ (MPWGlobal *)sharedInstance;

@property (strong, nonatomic) PFUser *currentUser;
@end
