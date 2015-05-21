// light@huohua.tv
#import <UIKit/UIKit.h>
#import "HHBlocks.h"

@interface UINavigationController (HHKit)
- (void)customBackgroundWithImage:(UIImage *)image;

- (void)popWithAnimated;

- (void)replaceVisibleViewController:(UIViewController *)viewController;
@end