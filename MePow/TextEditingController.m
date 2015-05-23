//
//  TextEditingController.m
//  MePow
//
//  Created by WeeTom on 15/5/23.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "TextEditingController.h"

@interface TextEditingController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@end

@implementation TextEditingController
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.textView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)save:(id)sender {
    [self.textView resignFirstResponder];
    [self.delegate textEditingController:self didFinishEditingTextWithResult:self.textView.text];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancel:(id)sender {
    [self.textView resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Notifications
- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIEdgeInsets insect = UIEdgeInsetsMake(self.navigationController.navigationBar.height + [UIApplication sharedApplication].statusBarFrame.size.height, 0, keyboardRect.size.height, 0);
    self.textView.contentInset = insect;
    self.textView.scrollIndicatorInsets = insect;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets insect = UIEdgeInsetsMake(self.navigationController.navigationBar.height + [UIApplication sharedApplication].statusBarFrame.size.height, 0, 0, 0);
    self.textView.contentInset = insect;
    self.textView.scrollIndicatorInsets = insect;
}
@end
