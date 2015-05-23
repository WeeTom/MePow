//
//  TextEditingController.h
//  MePow
//
//  Created by WeeTom on 15/5/23.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TextEditingController;
@protocol TextEditingControllerDelegate
- (void)textEditingController:(TextEditingController *)controller didFinishEditingTextWithResult:(NSString *)text;
@end

@interface TextEditingController : UIViewController
@property (weak, nonatomic) id<TextEditingControllerDelegate> delegate;
@end
