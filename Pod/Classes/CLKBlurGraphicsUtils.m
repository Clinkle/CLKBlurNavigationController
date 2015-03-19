#import "CLKBlurGraphicsUtils.h"
#import <CLKParametricAnimations/CAKeyframeAnimation+CLKParametric.h>

#define kFourInchPixelHeight 1136.0f

@implementation CLKBlurGraphicsUtils

+ (UIWindow *)window
{
    return [[UIApplication sharedApplication].windows firstObject];
}

+ (BOOL)is4InchDisplay
{
    CGFloat scale = [self screenScale];
    CGFloat pixelHeight = [UIScreen mainScreen].bounds.size.height * scale;
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
            scale == 2.0f &&
            pixelHeight == kFourInchPixelHeight);
}

+ (CGFloat)screenScale
{
    UIScreen *mainScreen = [UIScreen mainScreen];
    return ([mainScreen respondsToSelector:@selector(scale)] ? mainScreen.scale : 1.0f);
}

+ (void)  animateView:(UIView *)view
easingBackAndComingIn:(BOOL)comingIn
         withDuration:(CGFloat)duration
{
    CGFloat vanishingScale = 0.0001;
    CATransform3D from = comingIn ? CATransform3DMakeScale(vanishingScale, vanishingScale, 1.0) : CATransform3DIdentity;
    CATransform3D to = comingIn ? CATransform3DIdentity : CATransform3DMakeScale(vanishingScale, vanishingScale, 1.0);
    ParametricTimeBlock timeFxn = comingIn ? kParametricTimeBlockBackOut : kParametricTimeBlockBackIn;
    CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"
                                                                            timeFxn:timeFxn
                                                                      fromTransform:from
                                                                        toTransform:to];
    scaleAnimation.duration = duration;
    [view.layer addAnimation:scaleAnimation
                      forKey:scaleAnimation.keyPath];
    view.layer.transform = to;
}

@end
