// light@huohua.tv
#import "UINavigationController+HHKit.h"

@implementation UINavigationController (HHKit)

- (void)customBackgroundWithImage:(UIImage *)image
{
    [self.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];

    self.navigationBar.frame = CGRectMake(0, self.navigationBar.frame.origin.y, self.navigationBar.frame.size.width, 44);
    
    if ([self.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) { // ios5
        [self.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    }
}

- (void)popWithAnimated
{
    if (![self popViewControllerAnimated:YES]) {
        [self.visibleViewController dismissViewControllerAnimated:YES completion:^{}];
    }
}

- (void)replaceVisibleViewController:(UIViewController *)viewController
{
    [self pushViewController:viewController animated:NO];
    
    NSMutableArray *VCs = [self.viewControllers mutableCopy];
    [VCs removeObjectAtIndex:VCs.count - 2];
    [self setViewControllers:VCs animated:NO];
}

@end
