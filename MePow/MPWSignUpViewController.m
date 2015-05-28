//
//  MPWSignUpViewController.m
//  MePow
//
//  Created by Wee Tom on 15/5/28.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "MPWSignUpViewController.h"

@implementation MPWSignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    self.signUpView.logo = logoView; // logo can be any UIView
}

@end
