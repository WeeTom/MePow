//
//  EmptyViewController.h
//  MePow
//
//  Created by Wee Tom on 15/5/18.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmptyViewController : UIViewController
- (void)setupWithImage:(UIImage *)image text:(NSString *)text actionHandler:(void (^)(EmptyViewController *emptyViewController))handler;
@end
