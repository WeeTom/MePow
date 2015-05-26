//
//  CountDownPickerViewController.h
//  MePow
//
//  Created by Wee Tom on 15/5/26.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CountDownPickerViewController;
@protocol CountDownPickerViewControllerDelegate
- (void)countDownPickerViewController:(CountDownPickerViewController *)controller didFinishWithResult:(NSTimeInterval)time;
@end

@interface CountDownPickerViewController : UIViewController
@property (weak, nonatomic) id<CountDownPickerViewControllerDelegate> delegate;
@end
