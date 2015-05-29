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
    self.signUpController.delegate = self;
}

- (BOOL)signUpViewController:(PFSignUpViewController * __nonnull)signUpController shouldBeginSignUp:(NSDictionary * __nonnull)info
{
    NSString *username = info[@"username"];
    NSString *password = info[@"password"];
    NSString *email = info[@"email"];
    if (email.length == 0
        || username.length == 0
        || password.length == 0) {
        return NO;
    }
    return YES;
}

- (void)signUpViewController:(PFSignUpViewController * __nonnull)signUpController didSignUpUser:(PFUser * __nonnull)user
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate logInViewController:self didLogInUser:[PFUser currentUser]];
    }];
}

- (void)signUpViewController:(PFSignUpViewController * __nonnull)signUpController didFailToSignUpWithError:(nullable NSError *)error
{
}

- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController * __nonnull)signUpController
{

}
@end
