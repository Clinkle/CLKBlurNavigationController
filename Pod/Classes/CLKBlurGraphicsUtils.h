#import <UIKit/UIKit.h>

@interface CLKBlurGraphicsUtils : NSObject

+ (UIWindow *)window;
+ (BOOL)is4InchDisplay;

+ (void)  animateView:(UIView *)view
easingBackAndComingIn:(BOOL)comingIn
         withDuration:(CGFloat)duration;

@end
