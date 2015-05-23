//
//  MDBlockButton.m
//  MingdaoV2
//
//  Created by Wee Tom on 13-7-11.
//  Copyright (c) 2013年 Mingdao. All rights reserved.
//

#import "MDBlockButton.h"

@implementation MDBlockButton

- (id)init
{
    self = [super init];
    if (self) {
        [self setExclusiveTouch:YES];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setExclusiveTouch:YES];
    }
    return self;
}

- (void)setBlock:(dispatch_block_t)block
{
    _block = block;
    if (block) {
        [self addTarget:self action:@selector(pressed) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setButtonBlock:(MDBlockButtonBlock)buttonBlock
{
    _buttonBlock = buttonBlock;
    if (buttonBlock) {
        [self addTarget:self action:@selector(pressed) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)pressed
{
    if (self.block) {
        self.block();
    }
    if (self.buttonBlock) {
        self.buttonBlock(self);
    }
}
@end
