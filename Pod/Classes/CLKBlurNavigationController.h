#import <UIKit/UIKit.h>
#import "CLKBlurView.h"

#define kCLKBlurNavigationTransitionDuration 0.4

typedef NS_ENUM(NSUInteger, CLKBlurNavigationDirection)
{
    CLKBlurNavigationDirectionNone, // fades in/out
    CLKBlurNavigationDirectionRight,
    CLKBlurNavigationDirectionLeft,
    CLKBlurNavigationDirectionTop,
    CLKBlurNavigationDirectionBottom,
};

@class CLKBlurNavigationController;
@protocol CLKBlurNavigationControllerDelegate <NSObject>

@optional
- (BOOL)blurNavigationController:(CLKBlurNavigationController *)controller shouldPopViewController:(UIViewController *)viewController;

- (void)blurNavigationControllerWillShow:(CLKBlurNavigationController *)controller;
- (void)blurNavigationControllerDidShow:(CLKBlurNavigationController *)controller;

- (void)blurNavigationControllerWillDismiss:(CLKBlurNavigationController *)controller;
- (void)blurNavigationControllerDidDismiss:(CLKBlurNavigationController *)controller;

@end

@interface CLKBlurNavigationController : UIViewController

@property (nonatomic, readonly) UIViewController *visibleViewController;

@property (nonatomic, weak) id<CLKBlurNavigationControllerDelegate> delegate;

@property (nonatomic, strong) UIView *controllerStackContainer;

@property (nonatomic, readonly) CLKBlurView *blurView;

@property (nonatomic, assign) CLKBlurNavigationDirection showDirection;
@property (nonatomic, assign) CLKBlurNavigationDirection dismissDirection;

@property (nonatomic, readonly) UIViewController *topViewController;

@property (nonatomic, assign) BOOL hidesBackButton;
@property (nonatomic, assign) BOOL showsCloseButton;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
                              andTintStyle:(CLKBlurViewTintStyle)tintStyle;

/**
 * @input view: the view in which to show the controller. pass nil for the application's UIWindow
 * @input animated: true iff controller's view should entere animatedly
 * @input completion: block to be executed upon completion of animation, or immediately after controller's view is added if animated is false
 **/
- (void)show;
- (void)showAnimated:(BOOL)animated;
- (void)showInView:(UIView *)view animated:(BOOL)animated;
- (void)showInView:(UIView *)view animated:(BOOL)animated completion:(void (^)(void))completion;

- (void)dismiss;
- (void)dismissAnimated:(BOOL)animated;
- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion;

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion;

- (UIViewController *)popViewControllerAnimated:(BOOL)animated;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated;

- (void)setViewControllers:(NSArray *)stack
                  animated:(BOOL)animated;

- (CLKBlurNavigationDirection)directionOppositeOfDirection:(CLKBlurNavigationDirection)direction;

- (void)showBackButton;
- (void)dismissBackButton;

@end
