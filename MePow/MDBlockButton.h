//
//  MDBlockButton.h
//  MingdaoV2
//
//  Created by Wee Tom on 13-7-11.
//  Copyright (c) 2013年 Mingdao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HHKit.h"

@class MDBlockButton;
typedef void (^MDBlockButtonBlock)(MDBlockButton *button);

@interface MDBlockButton : UIButton
@property (copy, nonatomic) dispatch_block_t block;
@property (copy, nonatomic) MDBlockButtonBlock buttonBlock;
@end
