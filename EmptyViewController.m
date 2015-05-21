//
//  EmptyViewController.m
//  MePow
//
//  Created by Wee Tom on 15/5/18.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "EmptyViewController.h"

@interface EmptyViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (copy, nonatomic) void (^handler)(EmptyViewController *emptyViewController);
@end

@implementation EmptyViewController

- (void)setupWithImage:(UIImage *)image text:(NSString *)text actionHandler:(void (^)(EmptyViewController *emptyViewController))handler;
{
    if (image) {
        self.imageView.image = image;
    }
    if (text) {
        self.titleLabel.text = text;
    }
    if (handler) {
        self.handler = handler;
    }
}

- (IBAction)anywhereClicked:(id)sender {
    if (self.handler) {
        self.handler(self);
    }
}
@end
