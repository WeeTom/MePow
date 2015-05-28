//
//  TextEditingController.m
//  MePow
//
//  Created by WeeTom on 15/5/23.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "TextEditingController.h"

@interface TextEditingController () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) UIView *multiDataView, *imagesView, *fileView;
@property (strong, nonatomic) NSMutableArray *images, *records;
@property (assign, nonatomic) CGSize kbSize;
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

    self.images = [NSMutableArray array];
    self.records = [NSMutableArray array];
    
    NSArray *users = self.meeting[@"users"];
    if (users.count > 0) {
        UIMenuController *menu = [UIMenuController sharedMenuController];
        menu.menuItems = @[[[UIMenuItem alloc] initWithTitle:@"@User" action:@selector(addUser:)]];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.multiDataView) {
        if (self.summary) {
            self.textView.text = self.summary[@"content"];
            self.records = self.summary[@"records"];
            self.images = self.summary[@"images"];
        }
        
        if (self.records.count > 0) {
            [self resetFileView];
        }
        if (self.images.count > 0) {
            [self resetImagesView];
        }
        
        [self.textView becomeFirstResponder];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)resetFileView
{
    if (!self.fileView) {
        self.fileView = [[UIView alloc] initWithFrame:CGRectMake(0, self.textView.bottom, self.textView.width - 20, 0)];
        self.fileView.autoresizesSubviews = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        self.fileView.layer.cornerRadius = 4;
        self.fileView.layer.borderWidth = 1;
        self.fileView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.fileView.width - 20, self.fileView.height)];
        label.numberOfLines = 0;
        label.tag = 1;
        [self.fileView addSubview:label];
    }
    
    UILabel *iv = (UILabel *)[self.fileView viewWithTag:1];
    iv.text = [NSString stringWithFormat:@"%d records", (int)self.records.count];
    [iv sizeToFit];
    self.fileView.height = iv.height + 20;
    [self resetMultiDataView];
}

- (void)resetImagesView
{
    if (!self.imagesView) {
        self.imagesView = [[UIView alloc] initWithFrame:CGRectMake(0, self.textView.bottom, self.textView.width - 20, (self.textView.width - 20)/4.0*3.0)];
        self.imagesView.autoresizesSubviews = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        self.imagesView.layer.cornerRadius = 4;
        self.imagesView.layer.borderWidth = 1;
        self.imagesView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.imagesView.clipsToBounds = YES;
        
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.imagesView.width, self.imagesView.height)];
        iv.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.tag = 1;
        iv.clipsToBounds = YES;
        [self.imagesView addSubview:iv];
        
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.imagesView.height/3, self.imagesView.height/3)];
        textLabel.tag = 2;
        textLabel.layer.cornerRadius = self.imagesView.height/6;
        textLabel.clipsToBounds = YES;
        textLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        textLabel.textColor = [UIColor whiteColor];
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.center = iv.center;
        [self.imagesView addSubview:textLabel];
    }
    
    self.imagesView.frame = CGRectMake(0, self.textView.bottom, self.textView.width - 20, (self.textView.width - 20)/4.0*3.0);
    PFFile *imageFile = self.images.firstObject;
    NSData *imageData = [imageFile getData];
    UIImage *image = [UIImage imageWithData:imageData];
    UIImageView *iv = (UIImageView *)[self.imagesView viewWithTag:1];
    iv.frame = CGRectMake(0, 0, self.imagesView.width, self.imagesView.height);
    iv.image = image;
    
    UILabel *label = (UILabel *)[self.imagesView viewWithTag:2];
    label.text = [NSString stringWithFormat:@"%d", (int)self.images.count];
    [self resetMultiDataView];
}

- (void)resetMultiDataView
{
    if (!self.multiDataView) {
        self.multiDataView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, self.textView.width - 20, 0)];
    }
    CGFloat padding = 10;
    CGFloat height = 0;
    self.fileView.offsetY = height;
    [self.multiDataView addSubview:self.fileView];
    height += self.fileView.height + padding*(self.fileView.height > 0);
    self.imagesView.offsetY = height;
    [self.multiDataView addSubview:self.imagesView];
    height += self.imagesView.height + padding*(self.imagesView.height > 0);
    
    CGRect textFrame = [[self.textView layoutManager]usedRectForTextContainer:[self.textView textContainer]];
//    height = textFrame.size.height + 16;
    
    if (height < 52) {
        self.multiDataView.frame = CGRectMake(10, 52, self.view.width - 20, height);
    } else {
        self.multiDataView.frame = CGRectMake(10, textFrame.size.height + 16, self.view.width - 20, height);
    }
    
    CGFloat bottom = 0;
    if (self.kbSize.height > 0) {
        bottom = MIN(height, self.textView.height - 52);
    } else {
        bottom = height;
    }
    
    if (self.textView.contentInset.bottom != bottom) {
        UIEdgeInsets originalInsets = self.textView.contentInset;
        self.textView.contentInset = UIEdgeInsetsMake(originalInsets.top, originalInsets.left, bottom, originalInsets.right);
    }
    
    [self.textView addSubview:self.multiDataView];
}

- (IBAction)save:(id)sender {
    [self.textView resignFirstResponder];
    if (self.summary) {
        PFObject *summary = self.summary;
        summary[@"content"] = self.textView.text;
        [summary pin];
        
        MRProgressOverlayView *progressView = [MRProgressOverlayView showOverlayAddedTo:self.view animated:YES];
        [progressView show:YES];
        [summary saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            if (error) {
                NSLog(@"Error: %@", error);
                [progressView performSelectorOnMainThread:@selector(dismiss:) withObject:@YES waitUntilDone:NO];
                return ;
            }
            [progressView performSelectorOnMainThread:@selector(dismiss:) withObject:@YES waitUntilDone:NO];
            if (self.delegate) {
                [self.delegate textEditingController:self didFinishEditingTextWithResult:self.textView.text];
                [self dismissViewControllerAnimated:YES completion:^{
                    
                }];
            }
        }];
    } else if (self.delegate) {
        [self.delegate textEditingController:self didFinishEditingTextWithResult:self.textView.text];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)cancel:(id)sender {
    [self.textView resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TextView
- (void)textViewDidChange:(UITextView *)textView
{
    [self resetMultiDataView];
}

- (void)addUser:(UIMenuController *)sender
{
    NSArray *users = self.meeting[@"users"];
    HHActionSheet *as = [[HHActionSheet alloc] initWithTitle:@"Choose"];
    for (NSDictionary *user in users) {
        NSString *name = user[@"MingdaoUserName"];
        [as addButtonWithTitle:name block:^{
            [self.textView insertText:[NSString stringWithFormat:@"@%@ ", name]];
        }];
    }
    [as addCancelButtonWithTitle:@"Cancel"];
    [as showInView:self.view];
}

#pragma mark - Notifications
- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.kbSize = keyboardRect.size;
    [self resetMultiDataView];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [self resetMultiDataView];
}
@end
