#import "TGNavigationBar.h"

#import "LegacyComponents.h"

#import "LegacyComponentsInternal.h"
#import "TGColor.h"

#import "TGViewController.h"
#import "TGNavigationController.h"

#import "TGHacks.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import <CoreMotion/CoreMotion.h>

@interface TGNavigationBarLayer : CALayer

@end

@implementation TGNavigationBarLayer

@end

#pragma mark -

@interface TGFixView : UIActivityIndicatorView

@end

@implementation TGFixView

- (void)setAlpha:(CGFloat)__unused alpha
{
    [super setAlpha:0.02f];
}

@end

@implementation TGBlackNavigationBar

@end

@implementation TGWhiteNavigationBar

@end

@implementation TGTransparentNavigationBar

@end

static id<TGNavigationBarMusicPlayerProvider> _musicPlayerProvider;

static bool TGNavigationBarClassicIOS6Style(void)
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"TGClassicIOS6Style"];
}

static void TGNavigationBarApplyClassicFontToLabels(UIView *view)
{
    if ([view isKindOfClass:[UILabel class]])
    {
        UILabel *label = (UILabel *)view;
        label.font = [UIFont boldSystemFontOfSize:12.0f];
    }

    for (UIView *subview in view.subviews)
        TGNavigationBarApplyClassicFontToLabels(subview);
}

static void TGNavigationBarApplyClassicEdgeButtonFonts(UINavigationBar *navigationBar, UIView *view)
{
    for (UIView *subview in view.subviews)
    {
        if ([subview isKindOfClass:[UIControl class]])
        {
            CGRect frame = [subview convertRect:subview.bounds toView:navigationBar];
            CGFloat centerX = CGRectGetMidX(frame);
            CGFloat width = navigationBar.bounds.size.width;
            if (frame.size.width < width * 0.48f && (centerX < width * 0.36f || centerX > width * 0.64f))
                TGNavigationBarApplyClassicFontToLabels(subview);
        }

        TGNavigationBarApplyClassicEdgeButtonFonts(navigationBar, subview);
    }
}

@interface TGNavigationBar () <UIGestureRecognizerDelegate>
{
    bool _shouldAddBackgdropBackgroundInitialized;
    bool _shouldAddBackgdropBackground;
    
    UIView *_musicPlayerContainer;
    CAGradientLayer *_classicIOS6GradientLayer;
    
    bool _showMusicPlayerView;
    
    SPipe *_hiddenPipe;
}

@property (nonatomic, strong) UIView *backgroundContainerView;
@property (nonatomic, strong) UIView *statusBarBackgroundView;

@property (nonatomic, strong) TGBackdropView *barBackgroundView;
@property (nonatomic, strong) UIView *stripeView;

@property (nonatomic) bool hiddenState;

@property (nonatomic) bool contractBackgroundContainer;

@end

@implementation TGNavigationBar

+ (void)setMusicPlayerProvider:(id<TGNavigationBarMusicPlayerProvider>)provider {
    _musicPlayerProvider = provider;
}

+ (id<TGNavigationBarMusicPlayerProvider>)musicPlayerProvider {
    return _musicPlayerProvider;
}

+ (Class)layerClass
{
    return [TGNavigationBarLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        [self commonInit:UIBarStyleDefault];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit:[self isKindOfClass:[TGBlackNavigationBar class]] ? UIBarStyleBlackTranslucent : UIBarStyleDefault];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame barStyle:(UIBarStyle)barStyle
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit:barStyle];
    }
    return self;
}

- (SSignal *)hiddenSignal
{
    return _hiddenPipe.signalProducer();
}

- (void)setPallete:(TGNavigationBarPallete *)pallete
{
    bool classicStyle = TGNavigationBarClassicIOS6Style();
    if (classicStyle && _backgroundContainerView != nil)
    {
        if (_classicIOS6GradientLayer == nil)
        {
            _classicIOS6GradientLayer = [CAGradientLayer layer];
            _classicIOS6GradientLayer.colors = @[(id)UIColorRGB(0x8eabc7).CGColor, (id)UIColorRGB(0x496e95).CGColor];
            _classicIOS6GradientLayer.locations = @[@0.0f, @1.0f];
            [_backgroundContainerView.layer insertSublayer:_classicIOS6GradientLayer above:_barBackgroundView.layer];
        }
        _classicIOS6GradientLayer.hidden = false;
        _barBackgroundView.backgroundColor = [UIColor clearColor];
        _stripeView.backgroundColor = UIColorRGB(0x294768);
        // On iOS 6 tintColor controls the actual glossy UIBarButtonItem skin.
        // White made the native buttons look like unfinished white cut-outs.
        self.tintColor = iosMajorVersion() <= 6 ? UIColorRGB(0x4b7097) : [UIColor whiteColor];
    }
    else
    {
        _classicIOS6GradientLayer.hidden = true;
        _barBackgroundView.backgroundColor = pallete.backgroundColor;
        _stripeView.backgroundColor = pallete.separatorColor;
        self.tintColor = pallete.tintColor;
    }
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    attributes[UITextAttributeTextColor] = classicStyle ? [UIColor whiteColor] : pallete.titleColor;
    attributes[UITextAttributeTextShadowColor] = classicStyle ? UIColorRGBA(0x203b58, 0.9f) : [UIColor clearColor];
    if (classicStyle)
        attributes[UITextAttributeTextShadowOffset] = [NSValue valueWithUIOffset:UIOffsetMake(0.0f, -1.0f)];
    if (iosMajorVersion() < 7 || classicStyle)
        attributes[UITextAttributeFont] = TGBoldSystemFontOfSize(17.0f);
    
    [self setTitleTextAttributes:attributes];
}

- (void)commonInit:(UIBarStyle)barStyle
{
    _hiddenPipe = [[SPipe alloc] init];
    
    if (iosMajorVersion() >= 7 && iosMajorVersion() < 10 && [TGViewController isWidescreen] && false)
    {
        TGFixView *activityIndicator = [[TGFixView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityIndicator.alpha = 0.02f;
        [self addSubview:activityIndicator];
        [activityIndicator startAnimating];
    }
    
    CGFloat backgroundOverflow = iosMajorVersion() >= 7 ? 20.0f : 0.0f;
    if (![self isKindOfClass:[TGTransparentNavigationBar class]])
    {
        _backgroundContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, -backgroundOverflow, self.bounds.size.width, backgroundOverflow + self.bounds.size.height)];
        _backgroundContainerView.userInteractionEnabled = false;
        [super insertSubview:_backgroundContainerView atIndex:0];
        
        _barBackgroundView = [TGBackdropView viewWithLightNavigationBarStyle];
        if ([self isKindOfClass:[TGWhiteNavigationBar class]])
            _barBackgroundView.backgroundColor = [UIColor whiteColor];
        _barBackgroundView.frame = _backgroundContainerView.bounds;
        [_backgroundContainerView addSubview:_barBackgroundView];
        
        if (barStyle == UIBarStyleDefault)
        {
            _stripeView = [[UIView alloc] init];
            _stripeView.backgroundColor = UIColorRGB(0xb2b2b2);
            [_backgroundContainerView addSubview:_stripeView];
        }
    }
    
    if (barStyle == UIBarStyleDefault)
    {
        self.tintColor = TGAccentColor();
    }
    
    if (iosMajorVersion() < 7)
    {
        _contractBackgroundContainer = true;
        _progressView = [[UIView alloc] init];
    }

    // This project is linked with the iOS 6 SDK, so UIKit keeps the old
    // opaque navigation-bar default even on iOS 7+. TGViewController already
    // accounts for the status and navigation bars in controllerInset.
    self.translucent = true;
    
    [self setBackgroundColor:[UIColor clearColor]];
}

- (void)setBackgroundColor:(UIColor *)__unused backgroundColor
{
    static UIColor *clearColor = nil;
    if (clearColor == nil)
        clearColor = [UIColor clearColor];
    [super setBackgroundColor:clearColor];
}

- (void)dealloc
{
}

- (void)layoutSubviews
{
    [self updateLayout];
    
    [super layoutSubviews];

    // UIAppearance does not reach UINavigationButton's private label on all
    // supported iOS versions.  Restrict the fallback to edge controls so the
    // central conversation title keeps its normal size.
    if (TGNavigationBarClassicIOS6Style())
        TGNavigationBarApplyClassicEdgeButtonFonts(self, self);
}

- (void)updateLayout
{
    if (_backgroundContainerView != nil)
    {
        CGFloat backgroundOverflow = iosMajorVersion() >= 7 ? 20.0f : 0.0f;
        if (iosMajorVersion() >= 11 && [self.superview respondsToSelector:@selector(safeAreaInsets)])
        {
            UIEdgeInsets (*safeAreaInsetsImp)(id, SEL) = (UIEdgeInsets (*)(id, SEL))[self.superview methodForSelector:@selector(safeAreaInsets)];
            UIEdgeInsets safeAreaInsets = safeAreaInsetsImp(self.superview, @selector(safeAreaInsets));
            if (safeAreaInsets.top > FLT_EPSILON)
                backgroundOverflow = safeAreaInsets.top;
        }
        
        _backgroundContainerView.frame = CGRectMake(0, -backgroundOverflow, self.bounds.size.width, backgroundOverflow + self.bounds.size.height);
        
        if (_barBackgroundView != nil)
            _barBackgroundView.frame = _backgroundContainerView.bounds;

        if (_classicIOS6GradientLayer != nil)
            _classicIOS6GradientLayer.frame = _backgroundContainerView.bounds;
    }
    
    if (_stripeView != nil)
    {
        CGFloat stripeHeight = TGScreenPixel;
        _stripeView.frame = CGRectMake(0, _backgroundContainerView.bounds.size.height - stripeHeight, _backgroundContainerView.bounds.size.width, stripeHeight);
    }
}

- (void)setBarStyle:(UIBarStyle)barStyle
{
    [self setBarStyle:barStyle animated:false];
}

- (void)setBarStyle:(UIBarStyle)__unused barStyle animated:(bool)__unused animated
{
    if (iosMajorVersion() < 7)
    {
        if (self.barStyle != UIBarStyleBlackTranslucent || barStyle != UIBarStyleBlackTranslucent)
            barStyle = UIBarStyleBlackTranslucent;
    }
    
    [super setBarStyle:barStyle];
}

- (void)setBarStyle:(UIBarStyle)barStyle animated:(bool)animated duration:(NSTimeInterval)duration
{
    UIBarStyle previousBarStyle = self.barStyle;
    
    if (previousBarStyle != barStyle)
        [self updateBarStyle:barStyle previousBarStyle:previousBarStyle animated:animated duration:duration];
    
    [super setBarStyle:barStyle];
}

- (void)resetBarStyle
{
}

- (void)setCenter:(CGPoint)center
{    
    bool shouldFix = (iosMajorVersion() >= 7);
    if (shouldFix)
    {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            static Class fixClassName = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                fixClassName = NSClassFromString(@"TGTabletMainView");
            });
            if (fixClassName != nil) {
                shouldFix = [[[[self superview] superview] superview] isKindOfClass:[fixClassName class]];
            }
        }
        else if (iosMajorVersion() >= 11)
        {
            shouldFix = false;
        }
    }
    
    if (shouldFix && center.y <= self.frame.size.height / 2)
        center.y = center.y + 20.0f;
    
    center.y += self.verticalOffset;
    
    [super setCenter:center];
    
    if (_statusBarBackgroundView != nil && _statusBarBackgroundView.superview != nil)
    {
        _statusBarBackgroundView.frame = CGRectMake(0, -self.frame.origin.y, self.frame.size.width, 20);
    }
    
    _musicPlayerContainer.alpha = center.y < 0.0f ? 0.0f : 1.0f;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    if (_statusBarBackgroundView != nil && _statusBarBackgroundView.superview != nil)
    {
        _statusBarBackgroundView.frame = CGRectMake(0, -self.frame.origin.y, self.frame.size.width, 20);
    }
    
    _musicPlayerContainer.alpha = frame.origin.y < 0.0f ? 0.0f : 1.0f;
    _musicPlayerContainer.frame = CGRectMake(0.0f, frame.size.height + self.musicPlayerOffset, frame.size.width, 37.0f);
    
    [self updateLayout];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    _musicPlayerContainer.frame = CGRectMake(0.0f, bounds.size.height + self.musicPlayerOffset, bounds.size.width, 37.0f);
}

- (void)setHiddenState:(bool)hidden animated:(bool)animated
{
    _hiddenPipe.sink(@(hidden));
    
    if (animated)
    {
        if (_hiddenState != hidden)
        {
            if (iosMajorVersion() < 7)
            {
                _hiddenState = hidden;
                
                if (_statusBarBackgroundView == nil)
                {
                    _statusBarBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, -self.frame.origin.y, self.frame.size.width, 20)];
                    _statusBarBackgroundView.backgroundColor = [UIColor blackColor];
                }
                else
                    _statusBarBackgroundView.frame = CGRectMake(0, -self.frame.origin.y, self.frame.size.width, 20);
                
                [self addSubview:_statusBarBackgroundView];
                
                [UIView animateWithDuration:0.3 animations:^
                 {
                     _progressView.alpha = hidden ? 0.0f : 1.0f;
                 } completion:^(BOOL finished)
                 {
                     if (finished)
                         [_statusBarBackgroundView removeFromSuperview];
                 }];
            }
        }
        else
        {
            _progressView.alpha = hidden ? 0.0f : 1.0f;
        }
    }
    else
    {
        _hiddenState = hidden;
        
        _progressView.alpha = hidden ? 0.0f : 1.0f;
    }
}

- (bool)isBackgroundView:(UIView *)view {
    NSString *viewClass = NSStringFromClass([view class]);
    if ([viewClass isEqualToString:@"_UINavigationBarBackground"] || [viewClass isEqualToString:@"_UIBarBackground"]) {
        return true;
    }
    return false;
}

- (UIView *)findBackground:(UIView *)view
{
    if (view == nil)
        return nil;
    
    if ([self isBackgroundView:view]) {
        return view;
    }
    
    for (UIView *subview in view.subviews)
    {
        UIView *result = [self findBackground:subview];
        if (result != nil)
            return result;
    }
    
    return nil;
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    
    if (!hidden)
    {
        UIView *backgroundView = [self findBackground:self];
        backgroundView.hidden = true;
        [backgroundView removeFromSuperview];
    }
}

- (void)addSubview:(UIView *)view {
    if ([self isBackgroundView:view]) {
        view.hidden = true;
        return;
    }
    [super addSubview:view];
}

- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index
{
    if ([self isBackgroundView:view]) {
        view.hidden = true;
        return;
    }
    if (view != self.additionalView)
        [super insertSubview:view atIndex:MIN((int)self.subviews.count, MAX(index, 2))];
    else
        [super insertSubview:view atIndex:index];
}

- (bool)shouldAddBackdropBackground
{
    if (!_shouldAddBackgdropBackgroundInitialized)
    {
        _shouldAddBackgdropBackground = false;
        _shouldAddBackgdropBackgroundInitialized = true;
    }
    
    return _shouldAddBackgdropBackground;
}

- (unsigned int)indexAboveBackdropBackground
{
    if ([self shouldAddBackdropBackground])
    {
        static unsigned int (*nativeImpl)(id, SEL) = NULL;
        static SEL nativeSelector = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            freedomImpl(self, 0xc6dda86U, &nativeSelector);
            if (nativeSelector != NULL)
                nativeImpl = (unsigned int (*)(id, SEL))freedomNativeImpl(object_getClass(self), nativeSelector);
        });
        
        if (nativeImpl != NULL)
            return nativeImpl(self, nativeSelector);
    }

    return 1;
}

- (void)updateBarStyle:(UIBarStyle)__unused barStyle previousBarStyle:(UIBarStyle)__unused previousBarStyle animated:(bool)__unused animated duration:(NSTimeInterval)__unused duration
{
}

#pragma mark -

- (void)tapGestureRecognized:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint point = [recognizer locationInView:self];
        
        if (point.x >= 100 && point.x < self.frame.size.width - 100)
        {
            __strong UINavigationController *navigationController = _navigationController;
            UIViewController *viewController = navigationController.topViewController;
            if ([viewController conformsToProtocol:@protocol(TGViewControllerNavigationBarAppearance)] && [viewController respondsToSelector:@selector(navigationBarAction)])
            {
                [(id<TGViewControllerNavigationBarAppearance>)viewController navigationBarAction];
            }
        }
    }
}

- (void)swipeGestureRecognized:(UISwipeGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        __strong UINavigationController *navigationController = _navigationController;
        UIViewController *viewController = navigationController.topViewController;
        if ([viewController conformsToProtocol:@protocol(TGViewControllerNavigationBarAppearance)] && [viewController respondsToSelector:@selector(navigationBarSwipeDownAction)])
        {
            [(id<TGViewControllerNavigationBarAppearance>)viewController navigationBarSwipeDownAction];
        }
    }
}

- (CGRect)musicPlayerFrameForContainerSize:(CGSize)containerSize
{
    return CGRectMake(0.0f, _minimizedMusicPlayer ? -34.0f : 0.0f, containerSize.width, containerSize.height);
}

- (void)showMusicPlayerView:(bool)show animation:(void (^)())animation
{
    _showMusicPlayerView = show;
    if (show)
    {
        if (_musicPlayerContainer == nil)
        {
            _musicPlayerContainer = [[UIView alloc] init];
            _musicPlayerContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            _musicPlayerContainer.clipsToBounds = true;
            _musicPlayerContainer.frame = CGRectMake(0.0f, self.frame.size.height + self.musicPlayerOffset, self.frame.size.width, 37.0f);
            
            _musicPlayerView = [_musicPlayerProvider makeMusicPlayerView:_navigationController];
            if (_musicPlayerView != nil) {
                _musicPlayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                _musicPlayerView.frame = CGRectOffset(_musicPlayerContainer.bounds, 0.0f, -_musicPlayerContainer.frame.size.height);
                [_musicPlayerContainer addSubview:_musicPlayerView];
                [self addSubview:_musicPlayerContainer];
            }
        }
        _musicPlayerContainer.userInteractionEnabled = true;
        [UIView animateWithDuration:0.3 delay:0.0 options:7 << 16 animations:^
        {
            _musicPlayerView.frame = [self musicPlayerFrameForContainerSize:_musicPlayerContainer.bounds.size];
            
            if (animation)
                animation();
        } completion:nil];
    }
    else if (_musicPlayerView != nil)
    {
        _musicPlayerContainer.userInteractionEnabled = false;
        [UIView animateWithDuration:0.3 delay:0.0 options:7 << 16 animations:^
        {
            _musicPlayerView.frame = CGRectOffset(_musicPlayerContainer.bounds, 0.0f, -_musicPlayerContainer.frame.size.height);
            if (animation)
                animation();
        } completion:nil];
    }
}

- (void)setMusicPlayerOffset:(CGFloat)musicPlayerOffset
{
    _musicPlayerOffset = musicPlayerOffset;
    _musicPlayerContainer.frame = CGRectMake(0.0f, self.frame.size.height + self.musicPlayerOffset, self.frame.size.width, 37.0f);
}

- (void)setMinimizedMusicPlayer:(bool)minimizedMusicPlayer
{
    if (_minimizedMusicPlayer != minimizedMusicPlayer)
    {
        _minimizedMusicPlayer = minimizedMusicPlayer;
        if (_showMusicPlayerView)
        {
            [UIView animateWithDuration:0.25 delay:0.0 options:7 << 16 animations:^
            {
                _musicPlayerView.frame = [self musicPlayerFrameForContainerSize:_musicPlayerContainer.bounds.size];
            } completion:nil];
        }
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *result = [_musicPlayerContainer hitTest:CGPointMake(point.x - _musicPlayerContainer.frame.origin.x, point.y - _musicPlayerContainer.frame.origin.y) withEvent:event];
    if (result != nil && self.alpha > FLT_EPSILON)
        return result;
    
    if (self.topItem.titleView != nil)
    {
        if (CGRectContainsPoint(self.bounds, point))
        {
            UIView *result = [self.topItem.titleView hitTest:[self convertPoint:point toView:self.topItem.titleView] withEvent:event];
            if (result != nil)
                return result;
        }
    }
    
    if (self.additionalView != nil)
    {
        UIView *result = [self.additionalView hitTest:CGPointMake(point.x - self.additionalView.frame.origin.x, point.y - self.additionalView.frame.origin.y) withEvent:event];
        if (result != nil)
            return result;
    }
    
    return [super hitTest:point withEvent:event];
}

- (void)setAlpha:(CGFloat)alpha {
    if (!_keepAlpha) {
        [super setAlpha:alpha];
    }
}

@end


@implementation TGNavigationBarPallete

+ (instancetype)palleteWithBackgroundColor:(UIColor *)backgroundColor separatorColor:(UIColor *)separatorColor titleColor:(UIColor *)titleColor tintColor:(UIColor *)tintColor
{
    TGNavigationBarPallete *pallete = [[TGNavigationBarPallete alloc] init];
    pallete->_backgroundColor = backgroundColor;
    pallete->_separatorColor = separatorColor;
    pallete->_titleColor = titleColor;
    pallete->_tintColor = tintColor;
    return pallete;
}

@end
