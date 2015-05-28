//
//  MPWLogInViewController.m
//  MePow
//
//  Created by Wee Tom on 15/5/28.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "MPWLogInViewController.h"
#import "MPWSignUpViewController.h"

@implementation MPWLogInViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    self.logInView.logo = logoView; // logo can be any UIView
    
    self.signUpController = [[MPWSignUpViewController alloc] init];
}

@end
