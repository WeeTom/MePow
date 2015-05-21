// light@huohua.tv
#import <UIKit/UIKit.h>
#import "HHBlocks.h"

@interface HHAlertView : UIAlertView
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle;
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(HHBasicBlock)cancelBlock;
- (void)addButtonWithTitle:(NSString *)title block:(HHBasicBlock)block;
@end

@interface HHAlertTextView : HHAlertView
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(HHTextBlock)cancelBlock;
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(HHTextBlock)cancelBlock keyboardType:(UIKeyboardType)type;
- (void)addButtonWithTitle:(NSString *)title block:(HHTextBlock)block;
@end