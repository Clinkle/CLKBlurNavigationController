#import "CLKBlurNavigationController.h"
#import "CLKGfx.h"

#define kHorizontalOffset 300
#define kVerticalOffset 568
#define kButtonDownScale 0.85

typedef void(^TransitionAfterCompletionBlockType)(void);

@interface CLKBlurNavigationController ()

@property (nonatomic,readonly) UIViewController *rootViewController;
@property (nonatomic, strong) UIViewController *visibleViewController;

@property (nonatomic, strong) CLKBlurView *blurView;

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, assign) BOOL backButtonShowing;
@property (nonatomic, assign) BOOL didDismiss;

@property (nonatomic, assign) BOOL presenting; // State for presenting a new View Controller

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, copy) TransitionAfterCompletionBlockType transitionAfterCompletionBlock;

@end

@implementation CLKBlurNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super init];
    if (self) {
        [self pushViewController:rootViewController
                        animated:NO];
        self.hidesBackButton = NO;
        self.showDirection = CLKBlurNavigationDirectionRight;
        self.dismissDirection = CLKBlurNavigationDirectionRight;
    }

    return self;
}

- (UIViewController *)topViewController
{
    return [self.childViewControllers lastObject];
}

- (UIViewController *)rootViewController
{
    return [self.childViewControllers firstObject];
}

# pragma mark - Show / Dismiss / Close
- (void)showInView:(UIView *)view
          animated:(BOOL)animated
        completion:(void (^)(void))completion
{
    if ([self.delegate respondsToSelector:@selector(blurNavigationControllerWillShow:)]) {
        [self.delegate blurNavigationControllerWillShow:self];
    }

    if (view == nil) {
        view = [CLKGfx window];
    }

    view.userInteractionEnabled = NO;

    self.view.frame = view.bounds;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    self.view.alpha = 0;
    [view addSubview:self.view];

    void (^animations)(void) = ^{
        self.view.alpha = 1.0;
    };

    void (^afterAnimation)(BOOL) = ^(BOOL finished) {
        view.userInteractionEnabled = YES;

        if (completion) {
            completion();
        }
        if ([self.delegate respondsToSelector:@selector(blurNavigationControllerDidShow:)]) {
            [self.delegate blurNavigationControllerDidShow:self];
        }
    };

    if (animated) {
        [UIView animateWithDuration:kCLKBlurNavigationTransitionDuration
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:animations
                         completion:afterAnimation];

    } else {
        animations();
        afterAnimation(YES);
    }
}

- (void)showInView:(UIView *)view
          animated:(BOOL)animated
{
    [self showInView:view
            animated:animated
          completion:nil];
}

- (void)showAnimated:(BOOL)animated
{
    [self showInView:nil animated:YES];
}

- (void)show
{
    [self showAnimated:YES];
}

- (void)closeAnimated:(BOOL)animated
           completion:(void (^)(void))completion
{
    void (^animations)(void) = ^{
        self.view.alpha = 0.0;
    };

    void (^afterAnimation)(BOOL) = ^(BOOL finished) {
        if (completion) {
            completion();
        }
        if ([self.delegate respondsToSelector:@selector(blurNavigationControllerDidDismiss:)]) {
            [self.delegate blurNavigationControllerDidDismiss:self];
        }
    };

    if (animated) {
        [UIView animateWithDuration:kCLKBlurNavigationTransitionDuration
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:animations
                         completion:afterAnimation];

    } else {
        animations();
        afterAnimation(YES);
    }
}

- (void)dismiss
{
    [self dismissBackButton];
    [self dismissCloseButton];
    [self dismissAnimated:YES];
}

- (void)dismissAnimated:(BOOL)animated
{
    [self dismissAnimated:animated
               completion:NULL];
}

- (void)dismissAnimated:(BOOL)animated
             completion:(void (^)(void))completion
{
    if (self.didDismiss) {
        if (completion) {
            completion();
        }
        return;
    }
    if ([self.delegate respondsToSelector:@selector(blurNavigationControllerWillDismiss:)]) {
        [self.delegate blurNavigationControllerWillDismiss:self];
    }

    [self.view endEditing:YES];

    __block UIViewController *visibleViewController = self.visibleViewController;
    [visibleViewController willMoveToParentViewController:nil];

    // First let's throw the visible view controller off the screen
    [self transitionToViewController:nil
                            animated:animated
                           direction:[self directionOppositeOfDirection:self.dismissDirection]
                          completion:^{
                              self.didDismiss = YES;
                              [visibleViewController removeFromParentViewController];
                              // Then we can close the navigation controller
                              [self closeAnimated:animated
                                       completion:completion];
                          }];
}

# pragma mark - Transitions
- (void)transitionToViewController:(UIViewController *)viewController
                          animated:(BOOL)animated
                         direction:(CLKBlurNavigationDirection)direction
                        completion:(void (^)(void))completion
{
    __weak typeof(self) weakSelf = self;
    
    if (self.presenting && viewController) {
        // it's already presenting, so we wait until it's finished to execute this again
        // TODO: if this already exists, don't clobber here, add to an array
        self.transitionAfterCompletionBlock = ^(void) {
            [weakSelf transitionToViewController:viewController
                                        animated:animated
                                       direction:direction
                                      completion:completion];
        };
        return;
    }
    [self view]; // forces view to load

    self.presenting = YES;

    [self.controllerStackContainer insertSubview:viewController.view
                                    belowSubview:self.backButton];

    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    // New VC Initial Frame
    viewController.view.frame = [self offsetFrameForDirection:direction];
    viewController.view.alpha = 0;

    void (^animations)(void) = ^{
        // Old VC Final Frame
        if (weakSelf.visibleViewController != nil) {
            CLKBlurNavigationDirection oppositeDirection = [weakSelf directionOppositeOfDirection:direction];
            weakSelf.visibleViewController.view.frame = [weakSelf offsetFrameForDirection:oppositeDirection];
            weakSelf.visibleViewController.view.alpha = 0;
        }

        // New VC Final Frame
        viewController.view.frame = weakSelf.view.bounds;
        viewController.view.alpha = 1;
    };

    void (^afterAnimation)(BOOL) = ^(BOOL finished) {
        [weakSelf.visibleViewController.view removeFromSuperview];
        weakSelf.visibleViewController = viewController;
        weakSelf.presenting = NO;
        if (completion) {
            completion();
        }
        if (weakSelf.transitionAfterCompletionBlock) {
            weakSelf.presenting = NO;
            TransitionAfterCompletionBlockType completionBlock = weakSelf.transitionAfterCompletionBlock;
            weakSelf.transitionAfterCompletionBlock = NULL;
            completionBlock();
        }
    };

    if (animated) {
        [UIView animateWithDuration:kCLKBlurNavigationTransitionDuration
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:animations
                         completion:afterAnimation];
    } else {
        animations();
        afterAnimation(YES);
    }

    // Do it this way so that all you need to do is update viewController's title to use IT'S child's title (if needed), and this can work recursively :)
    self.title = viewController.title;
    // TODO: listen for title changes?
    [self showTitleLabelWithTitle:self.title direction:direction];
}

#pragma mark - pushing
- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
{
    [self pushViewController:viewController
                    animated:animated
                  completion:NULL];
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
                completion:(void (^)(void))completion
{
    if (viewController == nil || [self.childViewControllers containsObject:viewController]) {
        return;
    }
    self.didDismiss = NO;
    [self.visibleViewController willMoveToParentViewController:nil];
    [self addChildViewController:viewController];
    [self transitionToViewController:viewController
                            animated:animated
                           direction:self.showDirection
                          completion:^{
                              [viewController didMoveToParentViewController:self];
                              if (completion) {
                                  completion();
                              }
                          }];
}

- (void)setViewControllers:(NSArray *)newViewControllers
                  animated:(BOOL)animated
{
    if ([newViewControllers count] == 0) {
        return;
    }

    // clear the old stack
    NSArray *oldViewControllers = self.childViewControllers;
    UIViewController *oldTopController = [oldViewControllers lastObject];
    [self popToRootViewControllerAnimated:NO];
    [self popViewControllerAnimated:NO];

    // build up the new stack
    for (NSInteger index = 0; index < [newViewControllers count]; index++) {
        BOOL isLast = (index == ([newViewControllers count] - 1));
        UIViewController *newViewController = newViewControllers[index];
        BOOL shouldAnimate = animated && (isLast && oldTopController == nil);
        [self pushViewController:newViewController
                        animated:shouldAnimate];
    }

    if (oldTopController) {
        // transition from the old top controller to the new top controller
        // we reverse the direction so that a pop looks like a push
        CLKBlurNavigationDirection showDirection = self.showDirection;
        self.showDirection = [self directionOppositeOfDirection:showDirection];

        [self pushViewController:oldTopController
                        animated:NO];
        [self popViewControllerAnimated:animated];

        self.showDirection = showDirection;
    }
}

#pragma mark - popping
- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    return [self popViewControllerAnimated:animated
                                completion:NULL];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
                                     completion:(void (^)(void))completion
{
    NSUInteger numberOfChildren = [self.childViewControllers count];

    // The newest view Controller is the last childViewController, and that should also be self.visibileViewController (Unless we
    // support left/right navigation at some point.)  So, popping should get rid of that last View Controller completely and update
    // self.visibleViewController
    UIViewController *currentViewController = [self.childViewControllers lastObject];
    UIViewController *nextViewController = numberOfChildren >= 2 ? self.childViewControllers[numberOfChildren - 2] : nil;
    [currentViewController willMoveToParentViewController:nil];
    [self transitionToViewController:nextViewController
                            animated:animated
                           direction:[self directionOppositeOfDirection:self.showDirection]
                          completion:^{
                              [currentViewController removeFromParentViewController];
                              if (completion) {
                                  completion();
                              }
                          }];
    return currentViewController;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
    UIViewController *rootViewController = self.rootViewController;
    NSMutableArray *childViewControllers = [self.childViewControllers mutableCopy];
    if ([childViewControllers count] > 1) {
        for (UIViewController *viewController in childViewControllers) {
            [viewController removeFromParentViewController];
        }

        [self transitionToViewController:rootViewController
                                animated:animated
                               direction:[self directionOppositeOfDirection:self.showDirection]
                              completion:^{
                                  [rootViewController didMoveToParentViewController:self];
                              }];

        [childViewControllers removeObject:rootViewController];
    }
    return childViewControllers;
}

#pragma mark - Back Button
- (void)backButtonTouched:(UIButton *)button
{
    BOOL shouldPop = YES;
    if ([self.delegate respondsToSelector:@selector(blurNavigationController:shouldPopViewController:)]) {
        shouldPop = [self.delegate blurNavigationController:self shouldPopViewController:self.visibleViewController];
        if (!shouldPop) {
            return;
        }
    }

    if ([self.childViewControllers count] > 1) {
        [self popViewControllerAnimated:YES];
    } else {
        [self dismiss];
    }
}

- (void)closeButtonTouched:(UIButton *)button
{
    [self dismiss];
}

- (void)buttonDown:(UIButton *)button
{
    button.transform = CGAffineTransformMakeScale(kButtonDownScale, kButtonDownScale);
}

- (void)buttonUp:(UIButton *)button
{
    button.transform = CGAffineTransformIdentity;
}

- (void)updateBackButton
{
    self.backButton.hidden = self.hidesBackButton;
}

- (void)setHidesBackButton:(BOOL)hidesBackButton
{
    _hidesBackButton = hidesBackButton;
    [self updateBackButton];
}

- (void)setShowsCloseButton:(BOOL)showsCloseButton
{
    if (showsCloseButton == _showsCloseButton) {
        return;
    }

    _showsCloseButton = showsCloseButton;
    self.closeButton.hidden = !self.showsCloseButton;

    if (showsCloseButton) {
        [self showCloseButton];
    } else {
        [self dismissCloseButton];
    }
}

- (void)addCommonEventsToButton:(UIButton *)button
{
    [self.backButton addTarget:self
                        action:@selector(buttonDown:)
              forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [self.backButton addTarget:self
                        action:@selector(buttonUp:)
              forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
}

- (UIButton *)backButton
{
    if (_backButton == nil) {
        self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *backButtonImage = [UIImage imageNamed:@"toolbarBackArrow_white"];
        [self.backButton setImage:backButtonImage
                         forState:UIControlStateNormal];
        [self.backButton setImage:backButtonImage
                         forState:UIControlStateHighlighted];

        [self.backButton addTarget:self
                            action:@selector(backButtonTouched:)
                  forControlEvents:UIControlEventTouchUpInside];
        [self addCommonEventsToButton:self.backButton];
        [self updateBackButton];
    }

    return _backButton;
}

- (UIButton *)closeButton
{
    if (_closeButton == nil) {
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *closeButtonImage = [UIImage imageNamed:@"toolbarClose"];
        [self.closeButton setImage:closeButtonImage
                         forState:UIControlStateNormal];

        [self.closeButton setImage:closeButtonImage
                         forState:UIControlStateHighlighted];

        [self.closeButton addTarget:self
                            action:@selector(closeButtonTouched:)
                  forControlEvents:UIControlEventTouchUpInside];

        [self addCommonEventsToButton:self.closeButton];
    }

    return _closeButton;
}

- (CGRect)backButtonFrame
{
    return CGRectMake(5,
                      8,
                      44,
                      44);
}

- (CGRect)closeButtonFrame
{
    return CGRectMake(self.view.bounds.size.width - 44 - 7,
                      8,
                      44,
                      44);
}

- (void)showCloseButton
{
    // TODO: transform animation
    if (!self.showsCloseButton) {
        return;
    }

    self.closeButton.userInteractionEnabled = YES;
    CGRect closeButtonFrame = [self closeButtonFrame];

    self.closeButton.frame = closeButtonFrame;
    [self.controllerStackContainer addSubview:self.closeButton];
    self.closeButton.alpha = 1;

    [CLKGfx animateView:self.closeButton
  easingBackAndComingIn:YES
           withDuration:0.36];
}

- (void)hideTitleLabel:(CLKBlurNavigationDirection)direction
{
    if (self.titleLabel == nil) {
        return;
    }

    [self transitionTitleLabel:self.titleLabel direction:direction remove:YES];
}

- (void)layoutTitleLabel
{
    CGFloat left = self.backButtonShowing ? self.backButton.right + 10 : 10;
    CGFloat right = self.closeButton ? self.closeButton.left - 10 : self.view.width - 10;
    self.titleLabel.width = right - left;
    [self.titleLabel sizeToFit];
    self.titleLabel.origin = CGPointMake(0.5 * (self.view.width - self.titleLabel.width), 30 - self.titleLabel.height * 0.5);
}

- (void)transitionTitleLabel:(UILabel *)label direction:(CLKBlurNavigationDirection)direction remove:(BOOL)remove
{

    [self layoutTitleLabel];

    CGRect frame = label.frame;
    CGRect newFrame = frame;
    label.alpha = remove ? 1 : 0;
    CGFloat offset = 40;
    switch (direction) {
        case CLKBlurNavigationDirectionTop:
            newFrame.origin.y -= offset;
            break;
        case CLKBlurNavigationDirectionBottom:
            newFrame.origin.y += offset;
            break;
        case CLKBlurNavigationDirectionLeft:
            newFrame.origin.x -= offset;
            break;
        case CLKBlurNavigationDirectionRight:
            newFrame.origin.x += offset;
            break;
        default:
            break;
    }
    label.frame = remove ? frame : newFrame;

    [UIView animateWithDuration:kCLKBlurNavigationTransitionDuration animations:^{
        label.alpha = remove ? 0 : 1;
        label.frame = remove ? newFrame : frame;
    } completion:^(BOOL finished) {
        if (remove) {
            [label removeFromSuperview];
        }
    }];
}

- (void)showTitleLabelWithTitle:(NSString *)title direction:(CLKBlurNavigationDirection)direction
{
    [self hideTitleLabel:[self directionOppositeOfDirection:direction]];

    if (title == nil) {
        return;
    }

    [self createTitleLabelWithTitle:title];
    [self transitionTitleLabel:self.titleLabel direction:direction remove:NO];
}

- (void)showBackButton
{
    if (self.backButtonShowing) {
        return;
    }

    self.backButton.userInteractionEnabled = YES;
    CGRect backButtonFrame = [self backButtonFrame];
    backButtonFrame.origin.x += 20;


    self.backButton.frame = backButtonFrame;
    self.backButton.alpha = 0;
    [self.controllerStackContainer addSubview:self.backButton];

    [UIView animateWithDuration:kCLKBlurNavigationTransitionDuration
                     animations:^{
                         self.backButton.frame = [self backButtonFrame];
                         self.backButton.alpha = 1.0;
                     }];
}

- (void)dismissBackButton
{
    if (!self.backButton) {
        return;
    }
    self.backButton.userInteractionEnabled = NO;
    [UIView animateWithDuration:kCLKBlurNavigationTransitionDuration
                     animations:^{
                         CGRect backButtonFrame = [self backButtonFrame];
                         backButtonFrame.origin.x -= 20;
                         self.backButton.frame = backButtonFrame;
                         self.backButton.alpha = 0.0;
                     }];
}

- (void)dismissCloseButton
{
    // TODO: transform animation
    if (!self.closeButton) {
        return;
    }
    self.closeButton.userInteractionEnabled = NO;
    [CLKGfx animateView:self.closeButton
  easingBackAndComingIn:NO
           withDuration:0.36];
}

#pragma mark -
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self performSelector:@selector(showBackButton)
               withObject:nil
               afterDelay:kCLKBlurNavigationTransitionDuration];
    [self performSelector:@selector(showCloseButton)
               withObject:nil
               afterDelay:kCLKBlurNavigationTransitionDuration];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self createBlurView];
    [self createControllerStackContainer];
}

- (void)createControllerStackContainer
{
    self.controllerStackContainer = [[UIView alloc] initWithFrame:[CLKGfx window].bounds];
    self.controllerStackContainer.backgroundColor = [UIColor clearColor];
    self.controllerStackContainer.clipsToBounds = NO;
    [self.view addSubview:self.controllerStackContainer];
}

- (void)createBlurView
{
    self.blurView = [[CLKBlurView alloc] init];
    self.blurView.frame = self.view.bounds;
    self.blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.blurView];
}

- (void)createTitleLabelWithTitle:(NSString *)title
{
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:18];
    self.titleLabel.text = title;
    [self.view addSubview:self.titleLabel];
}

#pragma mark - Direction methods
- (CGRect)offsetFrameForDirection:(CLKBlurNavigationDirection)direction
{
    CGRect frame = self.view.bounds;
    switch (direction) {
        case CLKBlurNavigationDirectionRight:
            frame.origin.x += self.view.width;
            break;
        case CLKBlurNavigationDirectionLeft:
            frame.origin.x -= self.view.width;
            break;
        case CLKBlurNavigationDirectionBottom:
            frame.origin.y += self.view.height;
            break;
        case CLKBlurNavigationDirectionTop:
            frame.origin.y -= self.view.height;
            break;
        default:
            break;
    }
    return frame;
}

- (CLKBlurNavigationDirection)directionOppositeOfDirection:(CLKBlurNavigationDirection)direction
{
    switch (direction) {
        case CLKBlurNavigationDirectionNone:
            return CLKBlurNavigationDirectionNone;
        case CLKBlurNavigationDirectionRight:
            return CLKBlurNavigationDirectionLeft;
        case CLKBlurNavigationDirectionLeft:
            return CLKBlurNavigationDirectionRight;
        case CLKBlurNavigationDirectionTop:
            return CLKBlurNavigationDirectionBottom;
        case CLKBlurNavigationDirectionBottom:
            return CLKBlurNavigationDirectionTop;
    }
}

@end
