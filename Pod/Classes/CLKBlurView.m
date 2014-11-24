#import "CLKBlurView.h"
#import "CLKGfx.h"
#import "FXBlurView.h"

#define kCLKBlurViewDefaultTintStyle CLKBlurViewTintDark

@interface CLKBlurView ()

@property (nonatomic, strong) UIView *blurView;
@property (nonatomic, strong) UIView *tintView;

@end

@implementation CLKBlurView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initializeWithTintStyle:kCLKBlurViewDefaultTintStyle];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initializeWithTintStyle:kCLKBlurViewDefaultTintStyle];
    }
    return self;
}

- (instancetype)initWithTintStyle:(CLKBlurViewTintStyle)style
{
    self = [super init];
    if (self) {
        [self initializeWithTintStyle:style];
    }
    return self;
}

- (instancetype)initWithTintStyle:(CLKBlurViewTintStyle)style
                  andBlurBehavior:(CLKBlurViewBlurBehavior)behavior
{
    self = [super init];
    if (self) {
        [self initializeWithTintStyle:style
                      andBlurBehavior:behavior];
    }
    return self;
}

- (void)initializeWithTintStyle:(CLKBlurViewTintStyle)style
{
    [self initializeWithTintStyle:style
                  andBlurBehavior:CLKBlurViewDefaultBehavior];
}

- (void)initializeWithTintStyle:(CLKBlurViewTintStyle)style
                andBlurBehavior:(CLKBlurViewBlurBehavior)behavior
{
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    
    if ([UIVisualEffectView class]) {  // only available in iOS 8 and later
        UIBlurEffectStyle blurStyle = UIBlurEffectStyleDark;
        switch (style) {
            case CLKBlurViewTintExtraLight:
                blurStyle = UIBlurEffectStyleExtraLight;
                break;
            case CLKBlurViewTintLight:
                blurStyle = UIBlurEffectStyleLight;
                break;
            case CLKBlurViewTintDark:
                blurStyle = UIBlurEffectStyleDark;
        }
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:blurStyle];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        _blurView = blurEffectView;
        [self addSubview:_blurView];
    } else {  // using iOS 7
        [self initializeForIOS7WithTintStyle:style
                             andBlurBehavior:behavior];
    }
}

- (void)initializeForIOS7WithTintStyle:(CLKBlurViewTintStyle)style
                       andBlurBehavior:(CLKBlurViewBlurBehavior)behavior
{
    if (![CLKGfx is4InchDisplay] && behavior != CLKBlurViewForceDynamicBlur) {
        [self initializeForLowMemoryIOS7WithTintStyle:style];
    } else {
        [self setClipsToBounds:YES];
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        UIBarStyle blurStyle = UIBarStyleBlack;
        switch (style) {
            case CLKBlurViewTintExtraLight:
                blurStyle = UIBarStyleDefault;
                toolbar.barTintColor = [UIColor colorWithWhite:1.f
                                                         alpha:.5f];
                break;
            case CLKBlurViewTintLight:
                blurStyle = UIBarStyleDefault;
                break;
            case CLKBlurViewTintDark:
                blurStyle = UIBarStyleBlack;
        }
        toolbar.barStyle = blurStyle;
        _blurView = toolbar;
        [self.layer insertSublayer:toolbar.layer
                           atIndex:0];
    }
}

- (void)initializeForLowMemoryIOS7WithTintStyle:(CLKBlurViewTintStyle)style
{
    FXBlurView *fxBlurView = [[FXBlurView alloc] init];
    fxBlurView.blurRadius = 25.f;
    fxBlurView.dynamic = NO;
    fxBlurView.tintColor = [UIColor clearColor];
    fxBlurView.underlyingView = [CLKGfx window];
    
    self.tintView = [[UIView alloc] init];
    switch (style) {
        case CLKBlurViewTintDark:
            self.tintView.backgroundColor = [UIColor colorWithWhite:0.f
                                                              alpha:.5f];
            break;
        case CLKBlurViewTintLight:
            self.tintView.backgroundColor = [UIColor colorWithWhite:1.f
                                                              alpha:.5f];
            break;
        case CLKBlurViewTintExtraLight:
            self.tintView.backgroundColor = [UIColor colorWithWhite:1.f
                                                              alpha:.75f];
    }
    [fxBlurView addSubview:self.tintView];
    _blurView = fxBlurView;
    [self addSubview:_blurView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.blurView.frame = self.bounds;
    if (self.tintView) {
        self.tintView.frame = self.bounds;
    }
}

@end
