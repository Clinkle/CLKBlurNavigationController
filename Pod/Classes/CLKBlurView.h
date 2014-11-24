#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CLKBlurViewTintStyle)
{
    CLKBlurViewTintExtraLight,
    CLKBlurViewTintLight,
    CLKBlurViewTintDark
};

typedef NS_ENUM(NSInteger, CLKBlurViewBlurBehavior)
{
    CLKBlurViewDefaultBehavior,
    CLKBlurViewForceDynamicBlur
};

@interface CLKBlurView : UIView

- (instancetype)initWithTintStyle:(CLKBlurViewTintStyle)style;
- (instancetype)initWithTintStyle:(CLKBlurViewTintStyle)style
                  andBlurBehavior:(CLKBlurViewBlurBehavior)behavior;
@end
