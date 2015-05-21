// light@huohua.tv
#import "HHAlertView.h"

@interface HHAlertView () <UIAlertViewDelegate>
@property (strong, nonatomic) NSMutableArray *blocks;
@end

@implementation HHAlertView
- (NSMutableArray *)blocks
{
    if (!_blocks) {
        _blocks = [[NSMutableArray alloc] init];
    }

    return _blocks;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle
{
    self = [self initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle cancelBlock:^{}];
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(HHBasicBlock)cancelBlock
{
    self = [self initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];

    if (self) {
        [self.blocks addObject:[cancelBlock copy]];
    }

    return self;
}

- (void)addButtonWithTitle:(NSString *)title block:(HHBasicBlock)block
{
    [self addButtonWithTitle:title];
    [self.blocks addObject:[block copy]];
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
    HHBasicBlock block = [self.blocks objectAtIndex:0];

    block();
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    HHBasicBlock block = [self.blocks objectAtIndex:buttonIndex];
    
    block();
}

@end

@interface HHAlertTextView ()
@property (strong, nonatomic) NSMutableArray *blocks;
@end

@implementation HHAlertTextView

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(HHTextBlock)cancelBlock
{
    return [self initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle cancelBlock:cancelBlock keyboardType:UIKeyboardTypeDefault];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(HHTextBlock)cancelBlock keyboardType:(UIKeyboardType)type
{
    self = [self initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    self.alertViewStyle = UIAlertViewStylePlainTextInput;
    if (type != UIKeyboardTypeDefault) {
        UITextField *tf = [self textFieldAtIndex:0];
        tf.keyboardType = type;
    }
    if (self) {
        [self.blocks addObject:[cancelBlock copy]];
    }
    
    return self;
}

- (void)addButtonWithTitle:(NSString *)title block:(HHTextBlock)block
{
    [self addButtonWithTitle:title];
    [self.blocks addObject:[block copy]];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    HHTextBlock block = [self.blocks objectAtIndex:buttonIndex];
    UITextField *tf = [self textFieldAtIndex:0];
    block(tf.text);
}
@end