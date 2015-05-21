// light@huohua.tv
#import "HHThreadHelper.h"

@implementation HHThreadHelper

+ (void)performBlockInBackground:(HHBasicBlock)block completion:(HHBasicBlock)completionBlock waitUntilDone:(BOOL)waitUntilDone
{
    dispatch_queue_t    concurrentQueue = dispatch_queue_create("hhkit.core.threadhelper", NULL);
    dispatch_queue_t    mainQueue = dispatch_get_main_queue();

    HHBasicBlock    operation = [block copy];
    HHBasicBlock    completion = [completionBlock copy];

    if (completion == nil) completion =^{};

    if (operation == nil) operation =^{};

    if (waitUntilDone) {
        dispatch_sync(concurrentQueue, operation);
        dispatch_sync(mainQueue, ^{
            completion();
        });
    } else {
        dispatch_async(concurrentQueue, ^{
            operation();
            dispatch_async(mainQueue, ^{
                completion();
            });
        });
    }
}

+ (void)performBlockInBackground:(HHBasicBlock)block completion:(HHBasicBlock)completionBlock
{
    [self performBlockInBackground:block completion:completionBlock waitUntilDone:NO];
}

+ (void)performBlockInBackground:(HHBasicBlock)block
{
    [self performBlockInBackground:block completion:nil];
}

+ (void)performBlockInMainThread:(HHBasicBlock)block waitUntilDone:(BOOL)waitUntilDone
{
    [self performBlockInBackground:nil completion:block waitUntilDone:waitUntilDone];
}

+ (void)performBlockInMainThread:(HHBasicBlock)block afterDelay:(NSTimeInterval)delay
{
    [self performBlockInBackground:^{
        sleep(delay);
    } completion:block];
}

+ (void)performBlockInMainThread:(HHBasicBlock)block
{
    [self performBlockInMainThread:block waitUntilDone:NO];
}

@end
