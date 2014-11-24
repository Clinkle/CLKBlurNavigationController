#import "UIViewController+CLKBlurNavigationController.h"
#import "CLKBlurNavigationController.h"

@implementation UIViewController (CLKBlurNavigationController)

- (CLKBlurNavigationController *)blurNavigationController
{
    if ([self.parentViewController isKindOfClass:[CLKBlurNavigationController class]]) {
        return (CLKBlurNavigationController *)self.parentViewController;
    }

    return nil;
}

@end
