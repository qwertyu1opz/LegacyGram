#import "TGHacks.h"

#import "LegacyComponentsInternal.h"
#import "TGAnimationBlockDelegate.h"

#import "FreedomUIKit.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import <objc/runtime.h>
#import <objc/message.h>

#import "TGViewController.h"
#import "TGNavigationBar.h"
#import <QuartzCore/QuartzCore.h>

static float animationDurationFactor = 1.0f;
static float secondaryAnimationDurationFactor = 1.0f;
static bool forceSystemCurve = false;

static bool forceMovieAnimatedScaleMode = false;

static bool forcePerformWithAnimationFlag = false;

static void TGInstallCompatibilityInstanceMethod(Class cls, SEL selector, SEL fallbackSelector)
{
    if (class_getInstanceMethod(cls, selector) != NULL)
        return;

    Method fallbackMethod = class_getInstanceMethod(cls, fallbackSelector);
    if (fallbackMethod != NULL)
    {
        class_addMethod(cls, selector, method_getImplementation(fallbackMethod), method_getTypeEncoding(fallbackMethod));
    }
}

static void TGInstallCompatibilityClassMethod(Class cls, SEL selector, SEL fallbackSelector)
{
    if (class_getClassMethod(cls, selector) != NULL)
        return;

    Method fallbackMethod = class_getClassMethod(cls, fallbackSelector);
    if (fallbackMethod != NULL)
    {
        Class metaClass = object_getClass((id)cls);
        class_addMethod(metaClass, selector, method_getImplementation(fallbackMethod), method_getTypeEncoding(fallbackMethod));
    }
}

void SwizzleClassMethod(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getClassMethod(c, orig);
    Method newMethod = class_getClassMethod(c, new);
    
    c = object_getClass((id)c);
    
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}

void SwizzleInstanceMethod(Class c, SEL orig, SEL new)
{
    Method origMethod = nil, newMethod = nil;
    
    origMethod = class_getInstanceMethod(c, orig);
    newMethod = class_getInstanceMethod(c, new);
    if ((origMethod != nil) && (newMethod != nil))
    {
        if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
            class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
        else
            method_exchangeImplementations(origMethod, newMethod);
    }
    else
        NSLog(@"Attempt to swizzle nonexistent methods!");
}

void SwizzleInstanceMethodWithAnotherClass(Class c1, SEL orig, Class c2, SEL new)
{
    Method origMethod = nil, newMethod = nil;
    
    origMethod = class_getInstanceMethod(c1, orig);
    newMethod = class_getInstanceMethod(c2, new);
    if ((origMethod != nil) && (newMethod != nil))
    {
        if(class_addMethod(c1, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
            class_replaceMethod(c1, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
        else
            method_exchangeImplementations(origMethod, newMethod);
    }
    else
        NSLog(@"Attempt to swizzle nonexistent methods!");
}

void InjectClassMethodFromAnotherClass(Class toClass, Class fromClass, SEL fromSelector, SEL toSeletor)
{
    Method method = class_getClassMethod(fromClass, fromSelector);
    if (method != nil)
    {
        if (!class_addMethod(toClass, toSeletor, method_getImplementation(method), method_getTypeEncoding(method)))
            NSLog(@"Attempt to add method failed");
    }
    else
        NSLog(@"Attempt to add nonexistent method");
}

void InjectInstanceMethodFromAnotherClass(Class toClass, Class fromClass, SEL fromSelector, SEL toSeletor)
{
    Method method = class_getInstanceMethod(fromClass, fromSelector);
    if (method != nil)
    {
        if (!class_addMethod(toClass, toSeletor, method_getImplementation(method), method_getTypeEncoding(method)))
            NSLog(@"Attempt to add method failed");
    }
    else
        NSLog(@"Attempt to add nonexistent method");
}

@interface UIView (TGHacks)

+ (void)telegraph_setAnimationDuration:(NSTimeInterval)duration;
+ (void)TG_performWithoutAnimation:(void (^)(void))actionsWithoutAnimation;

- (UIView *)TG_snapshotViewAfterScreenUpdates:(BOOL)afterUpdates;
- (UIView *)TG_resizableSnapshotViewFromRect:(CGRect)rect afterScreenUpdates:(BOOL)afterUpdates withCapInsets:(UIEdgeInsets)capInsets;

@end

@implementation UIView (TGHacks)

+ (void)telegraph_setAnimationDuration:(NSTimeInterval)duration
{
    [self telegraph_setAnimationDuration:(duration * animationDurationFactor)];
}

+ (void)telegraph_animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
    if (forceSystemCurve) {
        options |= (7 << 16);
    }
    [self telegraph_animateWithDuration:duration * secondaryAnimationDurationFactor delay:delay options:options animations:animations completion:completion];
}

+ (void)TG_performWithoutAnimation:(void (^)(void))actionsWithoutAnimation
{
    float lastDurationFactor = animationDurationFactor;
    animationDurationFactor = 0.0f;
    
    bool animationsWereEnabled = [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:false];
    
    if (actionsWithoutAnimation)
        actionsWithoutAnimation();
    
    [UIView setAnimationsEnabled:animationsWereEnabled];
    animationDurationFactor = lastDurationFactor;
}

+ (void)TG_performWithoutAnimation_maybeNot:(void (^)(void))actionsWithoutAnimation
{
    if (actionsWithoutAnimation)
    {
        if (forcePerformWithAnimationFlag)
            actionsWithoutAnimation();
        else
            [self TG_performWithoutAnimation_maybeNot:actionsWithoutAnimation];
    }
}

- (UIView *)TG_snapshotViewAfterScreenUpdates:(BOOL)__unused afterUpdates
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0f);
    
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (image != nil)
        return [[UIImageView alloc] initWithImage:image];
    
    return nil;
}

- (UIView *)TG_resizableSnapshotViewFromRect:(CGRect)rect afterScreenUpdates:(BOOL)__unused afterUpdates withCapInsets:(UIEdgeInsets)capInsets
{
    UIGraphicsBeginImageContextWithOptions(rect.size, self.opaque, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
    [self.layer renderInContext:context];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if (image == nil)
        return nil;

    if (!UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero))
        image = [image resizableImageWithCapInsets:capInsets];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height);
    return imageView;
}

@end

#pragma mark -

@implementation TGHacks

+ (void)load
{
    TGInstallCompatibilityInstanceMethod([UIView class], @selector(setAccessibilityIgnoresInvertColors:), @selector(tg_ios6_setAccessibilityIgnoresInvertColors:));
    TGInstallCompatibilityInstanceMethod([UIView class], @selector(accessibilityIgnoresInvertColors), @selector(tg_ios6_accessibilityIgnoresInvertColors));
    TGInstallCompatibilityClassMethod([UIView class], @selector(animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:), @selector(tg_ios6_animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:));

    TGInstallCompatibilityInstanceMethod([AVPlayer class], @selector(setMuted:), @selector(tg_ios6_setMuted:));
    TGInstallCompatibilityInstanceMethod([AVPlayer class], @selector(isMuted), @selector(tg_ios6_isMuted));
    TGInstallCompatibilityClassMethod([AVCaptureDevice class], @selector(authorizationStatusForMediaType:), @selector(tg_ios6_authorizationStatusForMediaType:));
    TGInstallCompatibilityClassMethod([AVCaptureDevice class], @selector(requestAccessForMediaType:completionHandler:), @selector(tg_ios6_requestAccessForMediaType:completionHandler:));
    TGInstallCompatibilityInstanceMethod([AVAudioSession class], @selector(requestRecordPermission:), @selector(tg_ios6_requestRecordPermission:));

    TGInstallCompatibilityInstanceMethod([NSString class], @selector(sizeWithAttributes:), @selector(tg_ios6_sizeWithAttributes:));
    TGInstallCompatibilityInstanceMethod([NSString class], @selector(drawAtPoint:withAttributes:), @selector(tg_ios6_drawAtPoint:withAttributes:));
    TGInstallCompatibilityInstanceMethod([NSString class], @selector(boundingRectWithSize:options:attributes:context:), @selector(tg_ios6_boundingRectWithSize:options:attributes:context:));
    TGInstallCompatibilityInstanceMethod([NSAttributedString class], @selector(boundingRectWithSize:options:context:), @selector(tg_ios6_boundingRectWithSize:options:context:));
    TGInstallCompatibilityInstanceMethod([NSAttributedString class], @selector(boundingRectWithSize:options:attributes:context:), @selector(tg_ios6_boundingRectWithSize:options:attributes:context:));

    TGInstallCompatibilityInstanceMethod([UICollectionView class], @selector(startInteractiveTransitionToCollectionViewLayout:completion:), @selector(tg_ios6_startInteractiveTransitionToCollectionViewLayout:completion:));
    TGInstallCompatibilityInstanceMethod([UICollectionView class], @selector(finishInteractiveTransition), @selector(tg_ios6_finishInteractiveTransition));
    TGInstallCompatibilityInstanceMethod([UIScrollView class], @selector(setContentInsetAdjustmentBehavior:), @selector(tg_ios6_setContentInsetAdjustmentBehavior:));
    TGInstallCompatibilityInstanceMethod([UIScrollView class], @selector(contentInsetAdjustmentBehavior), @selector(tg_ios6_contentInsetAdjustmentBehavior));
    TGInstallCompatibilityInstanceMethod([UIView class], @selector(setSemanticContentAttribute:), @selector(tg_ios6_setSemanticContentAttribute:));
    TGInstallCompatibilityInstanceMethod([UIView class], @selector(semanticContentAttribute), @selector(tg_ios6_semanticContentAttribute));

    TGInstallCompatibilityInstanceMethod([UIViewController class], @selector(prefersStatusBarHidden), @selector(tg_ios6_prefersStatusBarHidden));
    TGInstallCompatibilityInstanceMethod([UIViewController class], @selector(preferredScreenEdgesDeferringSystemGestures), @selector(tg_ios6_preferredScreenEdgesDeferringSystemGestures));
    TGInstallCompatibilityInstanceMethod([UIViewController class], @selector(setNeedsStatusBarAppearanceUpdate), @selector(tg_ios6_setNeedsStatusBarAppearanceUpdate));
    TGInstallCompatibilityInstanceMethod([UIViewController class], @selector(setNeedsUpdateOfHomeIndicatorAutoHidden), @selector(tg_ios6_setNeedsUpdateOfHomeIndicatorAutoHidden));

    TGInstallCompatibilityInstanceMethod([NSData class], @selector(initWithBase64EncodedString:options:), @selector(tg_ios6_initWithBase64EncodedString:options:));
    TGInstallCompatibilityInstanceMethod([NSData class], @selector(initWithBase64Encoding:), @selector(tg_ios6_initWithBase64Encoding:));
    TGInstallCompatibilityInstanceMethod([NSData class], @selector(base64Encoding), @selector(tg_ios6_base64Encoding));

    TGInstallCompatibilityInstanceMethod([UITextView class], @selector(layoutManager), @selector(tg_ios6_layoutManager));
    TGInstallCompatibilityInstanceMethod([UITextView class], @selector(textContainer), @selector(tg_ios6_textContainer));
    TGInstallCompatibilityInstanceMethod([UITextView class], @selector(textStorage), @selector(tg_ios6_textStorage));
    TGInstallCompatibilityInstanceMethod([UITextView class], @selector(textContainerInset), @selector(tg_ios6_textContainerInset));
    TGInstallCompatibilityInstanceMethod([UITextView class], @selector(setTextContainerInset:), @selector(tg_ios6_setTextContainerInset:));
    TGInstallCompatibilityInstanceMethod([UITextView class], @selector(isSelectable), @selector(tg_ios6_isSelectable));
    TGInstallCompatibilityInstanceMethod([UITextView class], @selector(setSelectable:), @selector(tg_ios6_setSelectable:));
    TGInstallCompatibilityInstanceMethod([UITextView class], @selector(initWithFrame:textContainer:), @selector(tg_ios6_initWithFrame:textContainer:));
}

+ (void)hackSetAnimationDuration
{
    SwizzleClassMethod([UIView class], @selector(setAnimationDuration:), @selector(telegraph_setAnimationDuration:));
    SwizzleClassMethod([UIView class], @selector(animateWithDuration:delay:options:animations:completion:), @selector(telegraph_animateWithDuration:delay:options:animations:completion:));
    
    if (iosMajorVersion() >= 7)
    {
        if (iosMajorVersion() >= 8)
        {
            SwizzleClassMethod([UIView class], @selector(performWithoutAnimation:), @selector(TG_performWithoutAnimation_maybeNot:));
        }
    }
    else
    {
        InjectClassMethodFromAnotherClass(object_getClass([UIView class]), object_getClass([UIView class]), @selector(TG_performWithoutAnimation:), @selector(performWithoutAnimation:));
        InjectInstanceMethodFromAnotherClass([UIView class], [UIView class], @selector(TG_snapshotViewAfterScreenUpdates:), @selector(snapshotViewAfterScreenUpdates:));
        InjectInstanceMethodFromAnotherClass([UIView class], [UIView class], @selector(TG_resizableSnapshotViewFromRect:afterScreenUpdates:withCapInsets:), @selector(resizableSnapshotViewFromRect:afterScreenUpdates:withCapInsets:));
    }
}

+ (void)setAnimationDurationFactor:(float)factor
{
    animationDurationFactor = factor;
}

+ (void)setSecondaryAnimationDurationFactor:(float)factor
{
    secondaryAnimationDurationFactor = factor;
}

+ (void)setForceSystemCurve:(bool)force {
    forceSystemCurve = force;
}

+ (CGFloat)applicationStatusBarAlpha
{
    CGFloat alpha = 1.0f;
    
    UIWindow *window = [[LegacyComponentsGlobals provider] applicationStatusBarWindow];
    if (window != nil) {
        alpha = window.alpha;
    }
    
    return alpha;
}

+ (void)setApplicationStatusBarAlpha:(CGFloat)alpha
{
    UIWindow *window = [[LegacyComponentsGlobals provider] applicationStatusBarWindow];
    window.alpha = alpha;
}

+ (CGFloat)applicationStatusBarOffset
{
    UIWindow *window = [[LegacyComponentsGlobals provider] applicationStatusBarWindow];
    return window.bounds.origin.y;
}

+ (void)setApplicationStatusBarOffset:(CGFloat)offset {
    UIWindow *window = [[LegacyComponentsGlobals provider] applicationStatusBarWindow];
    CGRect bounds = window.bounds;
    bounds.origin = CGPointMake(0.0f, -offset);
    window.bounds = bounds;
}

static UIView *findStatusBarView()
{
    static Class viewClass = nil;
    static SEL selector = NULL;
    if (selector == NULL)
    {
        NSString *str1 = @"rs`str";
        NSString *str2 = @"A`qVhmcnv";
        
        selector = NSSelectorFromString([[NSString alloc] initWithFormat:@"%@%@", TGEncodeText(str1, 1), TGEncodeText(str2, 1)]);
        
        viewClass = NSClassFromString(TGEncodeText(@"VJTubuvtCbs", -1));
    }
    
    UIWindow *window = [[LegacyComponentsGlobals provider] applicationStatusBarWindow];
    
    for (UIView *subview in window.subviews)
    {
        if ([subview isKindOfClass:viewClass])
        {
            return subview;
        }
    }
    
    return nil;
}

+ (void)animateApplicationStatusBarAppearance:(int)statusBarAnimation duration:(NSTimeInterval)duration completion:(void (^)())completion
{
    [self animateApplicationStatusBarAppearance:statusBarAnimation delay:0.0 duration:duration completion:completion];
}

+ (void)animateApplicationStatusBarAppearance:(int)statusBarAnimation delay:(NSTimeInterval)delay duration:(NSTimeInterval)duration completion:(void (^)())completion
{
    UIView *view = findStatusBarView();
        
    if (view != nil)
    {
        if ((statusBarAnimation & TGStatusBarAppearanceAnimationSlideDown) || (statusBarAnimation & TGStatusBarAppearanceAnimationSlideUp))
        {
            CGPoint startPosition = view.layer.position;
            CGPoint position = view.layer.position;
            
            CGPoint normalPosition = CGPointMake(CGFloor(view.frame.size.width / 2), CGFloor(view.frame.size.height / 2));
            
            CGFloat viewHeight = view.frame.size.height;
            
            if (statusBarAnimation & TGStatusBarAppearanceAnimationSlideDown)
            {
                startPosition = CGPointMake(CGFloor(view.frame.size.width / 2), CGFloor(view.frame.size.height / 2) - viewHeight);
                position = CGPointMake(CGFloor(view.frame.size.width / 2), CGFloor(view.frame.size.height / 2));
            }
            else if (statusBarAnimation & TGStatusBarAppearanceAnimationSlideUp)
            {
                startPosition = CGPointMake(CGFloor(view.frame.size.width / 2), CGFloor(view.frame.size.height / 2));
                position = CGPointMake(CGFloor(view.frame.size.width / 2), CGFloor(view.frame.size.height / 2) - viewHeight);
            }
            
            CABasicAnimation *animation = [[CABasicAnimation alloc] init];
            animation.duration = duration;
            animation.fromValue = [NSValue valueWithCGPoint:startPosition];
            animation.toValue = [NSValue valueWithCGPoint:position];
            animation.removedOnCompletion = true;
            animation.fillMode = kCAFillModeForwards;
            animation.beginTime = delay;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            
            TGAnimationBlockDelegate *delegate = [[TGAnimationBlockDelegate alloc] initWithLayer:view.layer];
            delegate.completion = ^(BOOL finished)
            {
                if (finished)
                    view.layer.position = normalPosition;
                if (completion)
                    completion();
            };
            animation.delegate = delegate;
            [view.layer addAnimation:animation forKey:@"position"];
            
            view.layer.position = position;
        }
        else if ((statusBarAnimation & TGStatusBarAppearanceAnimationFadeIn) || (statusBarAnimation & TGStatusBarAppearanceAnimationFadeOut))
        {
            float startOpacity = view.layer.opacity;
            float opacity = view.layer.opacity;
            
            if (statusBarAnimation & TGStatusBarAppearanceAnimationFadeIn)
            {
                startOpacity = 0.0f;
                opacity = 1.0f;
            }
            else if (statusBarAnimation & TGStatusBarAppearanceAnimationFadeOut)
            {
                startOpacity = 1.0f;
                opacity = 0.0f;
            }
            
            CABasicAnimation *animation = [[CABasicAnimation alloc] init];
            animation.duration = duration;
            animation.fromValue = @(startOpacity);
            animation.toValue = @(opacity);
            animation.removedOnCompletion = true;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            TGAnimationBlockDelegate *delegate = [[TGAnimationBlockDelegate alloc] initWithLayer:view.layer];
            delegate.completion = ^(__unused BOOL finished)
            {
                if (completion)
                    completion();
            };
            animation.delegate = delegate;
            
            [view.layer addAnimation:animation forKey:@"opacity"];
        }
    }
    else
    {
        if (completion)
            completion();
    }
}

+ (void)animateApplicationStatusBarStyleTransitionWithDuration:(NSTimeInterval)duration
{
    UIView *view = findStatusBarView();
    
    if (view != nil)
    {
        UIView *snapshotView = [view snapshotViewAfterScreenUpdates:false];
        [view addSubview:snapshotView];
        
        [UIView animateWithDuration:duration animations:^
        {
            snapshotView.alpha = 0.0f;
        } completion:^(__unused BOOL finished)
        {
            [snapshotView removeFromSuperview];
        }];
    }
}

+ (CGFloat)statusBarHeightForOrientation:(UIInterfaceOrientation)orientation
{
    UIWindow *window = [[LegacyComponentsGlobals provider] applicationStatusBarWindow];
        
    Class statusBarClass = NSClassFromString(TGEncodeText(@"VJTubuvtCbs", -1));
    
    for (UIView *view in window.subviews)
    {
        if ([view isKindOfClass:statusBarClass])
        {
            SEL selector = NSSelectorFromString(TGEncodeText(@"dvssfouTuzmf", -1));
            NSMethodSignature *signature = [statusBarClass instanceMethodSignatureForSelector:selector];
            if (signature == nil)
            {
                TGLegacyLog(@"***** Method not found");
                return 20.0f;
            }
            
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:signature];
            [inv setSelector:selector];
            [inv setTarget:view];
            [inv invoke];
            
            NSInteger result = 0;
            [inv getReturnValue:&result];
            
            SEL selector2 = NSSelectorFromString(TGEncodeText(@"ifjhiuGpsTuzmf;psjfoubujpo;", -1));
            NSMethodSignature *signature2 = [statusBarClass methodSignatureForSelector:selector2];
            if (signature2 == nil)
            {
                TGLegacyLog(@"***** Method not found");
                return 20.0f;
            }
            NSInvocation *inv2 = [NSInvocation invocationWithMethodSignature:signature2];
            [inv2 setSelector:selector2];
            [inv2 setTarget:[view class]];
            [inv2 setArgument:&result atIndex:2];
            NSInteger argOrientation = orientation;
            [inv2 setArgument:&argOrientation atIndex:3];
            [inv2 invoke];
            
            CGFloat result2 = 0;
            [inv2 getReturnValue:&result2];
            
            return result2;
        }
    }
    
    return 20.0f;
}

+ (bool)isKeyboardVisible
{
    return [self isKeyboardVisibleAlt];
}

static bool keyboardHidden = true;

+ (bool)isKeyboardVisibleAlt
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *notification)
        {
            if (!freedomUIKitTest3())
                keyboardHidden = true;
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *notification)
        {
            keyboardHidden = false;
        }];
    });
    
    return !keyboardHidden;
}

+ (CGFloat)keyboardHeightForOrientation:(UIInterfaceOrientation)orientation
{
    static NSInvocation *invocation = nil;
    static Class keyboardClass = NULL;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        keyboardClass = NSClassFromString(TGEncodeText(@"VJLfzcpbse", -1));
        
        SEL selector = NSSelectorFromString(TGEncodeText(@"tj{fGpsJoufsgbdfPsjfoubujpo;", -1));
        NSMethodSignature *signature = [keyboardClass methodSignatureForSelector:selector];
        if (signature == nil)
            TGLegacyLog(@"***** Method not found");
        else
        {
            invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setSelector:selector];
        }
    });

    if (invocation != nil)
    {
        [invocation setTarget:[keyboardClass class]];
        [invocation setArgument:&orientation atIndex:2];
        [invocation invoke];
        
        CGSize result = CGSizeZero;
        [invocation getReturnValue:&result];
        
        return MIN(result.width, result.height);
    }
    
    return 0.0f;
}

+ (void)applyCurrentKeyboardAutocorrectionVariant
{
    static Class keyboardClass = NULL;
    static SEL currentInstanceSelector = NULL;
    static SEL applyVariantSelector = NULL;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        keyboardClass = NSClassFromString(TGEncodeText(@"VJLfzcpbse", -1));
        
        currentInstanceSelector = NSSelectorFromString(TGEncodeText(@"bdujwfLfzcpbse", -1));
        applyVariantSelector = NSSelectorFromString(TGEncodeText(@"bddfquBvupdpssfdujpo", -1));
    });
    
    if ([keyboardClass respondsToSelector:currentInstanceSelector])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id currentInstance = [keyboardClass performSelector:currentInstanceSelector];
        if ([currentInstance respondsToSelector:applyVariantSelector])
            [currentInstance performSelector:applyVariantSelector];
#pragma clang diagnostic pop
    }
}

+ (UIWindow *)applicationKeyboardWindow
{
    return [[LegacyComponentsGlobals provider] applicationKeyboardWindow];
}

+ (void)setApplicationKeyboardOffset:(CGFloat)offset
{
    UIWindow *keyboardWindow = [self applicationKeyboardWindow];
    keyboardWindow.frame = CGRectOffset(keyboardWindow.bounds, 0.0f, offset);
}

+ (UIView *)applicationKeyboardView
{
    static Class keyboardViewClass = Nil;
    static Class keyboardViewContainerClass = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        keyboardViewClass = NSClassFromString(TGEncodeText(@"VJJoqvuTfuIptuWjfx", -1));
        keyboardViewContainerClass = NSClassFromString(TGEncodeText(@"VJJoqvuTfuDpoubjofsWjfx", -1));
    });
    
    for (UIView *view in [self applicationKeyboardWindow].subviews)
    {
        if ([view isKindOfClass:keyboardViewContainerClass])
        {
            for (UIView *subview in view.subviews)
            {
                if ([subview isKindOfClass:keyboardViewClass])
                    return subview;
            }
        }
    }
    
    return nil;
}

+ (void)setForceMovieAnimatedScaleMode:(bool)force
{
    forceMovieAnimatedScaleMode = force;
}

+ (void)forcePerformWithAnimation:(dispatch_block_t)block
{
    if (block)
    {
        bool flag = forcePerformWithAnimationFlag;
        forcePerformWithAnimationFlag = true;
        block();
        forcePerformWithAnimationFlag = flag;
    }
}

@end

#if TARGET_IPHONE_SIMULATOR
extern float UIAnimationDragCoefficient(void);
#endif

CGFloat TGAnimationSpeedFactor()
{
#if TARGET_IPHONE_SIMULATOR
    return UIAnimationDragCoefficient();
#endif
    
    return 1.0f;
}


@implementation UIView (LegacyComponentsInvertColorsCompatibility)

- (void)tg_ios6_setAccessibilityIgnoresInvertColors:(BOOL)__unused accessibilityIgnoresInvertColors
{
}

- (BOOL)tg_ios6_accessibilityIgnoresInvertColors
{
    return false;
}

@end


@implementation UIView (LegacyComponentsSpringAnimationCompatibility)

+ (void)tg_ios6_animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay usingSpringWithDamping:(CGFloat)__unused dampingRatio initialSpringVelocity:(CGFloat)__unused velocity options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
    [self animateWithDuration:duration delay:delay options:options animations:animations completion:completion];
}

@end


@implementation AVPlayer (LegacyComponentsMutedCompatibility)

- (void)tg_ios6_setMuted:(BOOL)__unused muted
{
}

- (BOOL)tg_ios6_isMuted
{
    return false;
}

@end

@implementation AVCaptureDevice (LegacyComponentsAuthorizationCompatibility)

+ (AVAuthorizationStatus)tg_ios6_authorizationStatusForMediaType:(NSString *)__unused mediaType
{
    return AVAuthorizationStatusAuthorized;
}

+ (void)tg_ios6_requestAccessForMediaType:(NSString *)__unused mediaType completionHandler:(void (^)(BOOL granted))handler
{
    if (handler != nil)
        handler(true);
}

@end

@implementation AVAudioSession (LegacyComponentsRecordPermissionCompatibility)

- (void)tg_ios6_requestRecordPermission:(void (^)(BOOL granted))response
{
    if (response != nil)
        response(true);
}

@end


@implementation NSString (LegacyComponentsDrawingCompatibility)

- (CGSize)tg_ios6_sizeWithAttributes:(NSDictionary *)attrs
{
    UIFont *font = [attrs objectForKey:NSFontAttributeName];
    if (font == nil)
        font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    return [self sizeWithFont:font];
}

- (void)tg_ios6_drawAtPoint:(CGPoint)point withAttributes:(NSDictionary *)attrs
{
    UIFont *font = [attrs objectForKey:NSFontAttributeName];
    UIColor *color = [attrs objectForKey:NSForegroundColorAttributeName];
    if (font == nil)
        font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    if (color != nil)
        [color set];
    [self drawAtPoint:point withFont:font];
}

- (CGRect)tg_ios6_boundingRectWithSize:(CGSize)size options:(NSStringDrawingOptions)__unused options attributes:(NSDictionary *)attributes context:(id)__unused context
{
    UIFont *font = [attributes objectForKey:NSFontAttributeName];
    if (font == nil)
        font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGSize result = [self sizeWithFont:font constrainedToSize:size lineBreakMode:NSLineBreakByWordWrapping];
    return CGRectMake(0.0f, 0.0f, result.width, result.height);
}

@end

@implementation NSAttributedString (LegacyComponentsDrawingCompatibility)

- (CGRect)tg_ios6_boundingRectWithSize:(CGSize)size options:(NSStringDrawingOptions)__unused options context:(id)__unused context
{
    CGSize result = [self.string sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]] constrainedToSize:size lineBreakMode:NSLineBreakByWordWrapping];
    return CGRectMake(0.0f, 0.0f, result.width, result.height);
}

- (CGRect)tg_ios6_boundingRectWithSize:(CGSize)size options:(NSStringDrawingOptions)options attributes:(NSDictionary *)attributes context:(id)context
{
    return [self.string boundingRectWithSize:size options:options attributes:attributes context:context];
}

@end


@implementation UICollectionViewTransitionLayout

@synthesize currentLayout = _currentLayout;
@synthesize nextLayout = _nextLayout;
@synthesize transitionProgress = _transitionProgress;

- (instancetype)initWithCurrentLayout:(UICollectionViewLayout *)currentLayout nextLayout:(UICollectionViewLayout *)newLayout
{
    self = [super init];
    if (self != nil)
    {
        _currentLayout = currentLayout;
        _nextLayout = newLayout;
    }
    return self;
}

@end

@implementation UICollectionView (LegacyComponentsTransitionCompatibility)

- (UICollectionViewTransitionLayout *)tg_ios6_startInteractiveTransitionToCollectionViewLayout:(UICollectionViewLayout *)layout completion:(UICollectionViewLayoutInteractiveTransitionCompletion)completion
{
    UICollectionViewTransitionLayout *transitionLayout = [[UICollectionViewTransitionLayout alloc] initWithCurrentLayout:self.collectionViewLayout nextLayout:layout];
    [self setCollectionViewLayout:layout animated:false];
    if (completion != nil)
        completion(true, true);
    return transitionLayout;
}

- (void)tg_ios6_finishInteractiveTransition
{
}

@end

@implementation UIScrollView (LegacyComponentsContentInsetAdjustmentCompatibility)

- (void)tg_ios6_setContentInsetAdjustmentBehavior:(UIScrollViewContentInsetAdjustmentBehavior)__unused contentInsetAdjustmentBehavior
{
}

- (UIScrollViewContentInsetAdjustmentBehavior)tg_ios6_contentInsetAdjustmentBehavior
{
    return UIScrollViewContentInsetAdjustmentNever;
}

@end

@implementation UIView (LegacyComponentsSemanticContentCompatibility)

- (void)tg_ios6_setSemanticContentAttribute:(UISemanticContentAttribute)__unused semanticContentAttribute
{
}

- (UISemanticContentAttribute)tg_ios6_semanticContentAttribute
{
    return UISemanticContentAttributeForceLeftToRight;
}

@end


@implementation UIViewController (LegacyComponentsStatusBarCompatibility)

- (BOOL)tg_ios6_prefersStatusBarHidden
{
    return false;
}

- (UIRectEdge)tg_ios6_preferredScreenEdgesDeferringSystemGestures
{
    return UIRectEdgeNone;
}

- (void)tg_ios6_setNeedsStatusBarAppearanceUpdate
{
}

- (void)tg_ios6_setNeedsUpdateOfHomeIndicatorAutoHidden
{
}

@end


@implementation NSData (LegacyComponentsBase64Compatibility)

- (instancetype)tg_ios6_initWithBase64EncodedString:(NSString *)base64String options:(NSDataBase64DecodingOptions)__unused options
{
    return [self tg_ios6_initWithBase64Encoding:base64String];
}

- (instancetype)tg_ios6_initWithBase64Encoding:(NSString *)base64String
{
    static unsigned char table[256];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        memset(table, 0x80, sizeof(table));
        const char *chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        for (int i = 0; i < 64; i++)
            table[(unsigned char)chars[i]] = (unsigned char)i;
        table[(unsigned char)'='] = 0;
    });
    
    NSMutableData *result = [[NSMutableData alloc] init];
    const char *input = [base64String UTF8String];
    int val = 0;
    int valb = -8;
    for (const unsigned char *c = (const unsigned char *)input; *c != 0; c++)
    {
        if (*c == '=')
            break;
        unsigned char decoded = table[*c];
        if (decoded & 0x80)
            continue;
        val = (val << 6) | decoded;
        valb += 6;
        if (valb >= 0)
        {
            unsigned char byte = (unsigned char)((val >> valb) & 0xff);
            [result appendBytes:&byte length:1];
            valb -= 8;
        }
    }
    return [self initWithData:result];
}

- (NSString *)tg_ios6_base64Encoding
{
    static const char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    const unsigned char *input = (const unsigned char *)[self bytes];
    NSUInteger length = [self length];
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:((length + 2) / 3) * 4];
    for (NSUInteger i = 0; i < length; i += 3)
    {
        NSUInteger value = input[i] << 16;
        if (i + 1 < length)
            value |= input[i + 1] << 8;
        if (i + 2 < length)
            value |= input[i + 2];
        [result appendFormat:@"%c%c%c%c",
            table[(value >> 18) & 0x3f],
            table[(value >> 12) & 0x3f],
            (i + 1 < length) ? table[(value >> 6) & 0x3f] : '=',
            (i + 2 < length) ? table[value & 0x3f] : '='];
    }
    return result;
}

@end


#if __IPHONE_OS_VERSION_MAX_ALLOWED < 70000
@implementation NSTextAttachment
- (instancetype)initWithData:(NSData *)__unused contentData ofType:(NSString *)__unused uti
{
    return [self init];
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)__unused textContainer proposedLineFragment:(CGRect)__unused lineFrag glyphPosition:(CGPoint)__unused position characterIndex:(NSUInteger)__unused charIndex
{
    return CGRectZero;
}
@end

@implementation NSLayoutManager
- (void)addTextContainer:(NSTextContainer *)__unused container
{
}
@end

@implementation NSTextStorage
- (NSString *)string
{
    return @"";
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)__unused location effectiveRange:(NSRangePointer)__unused range
{
    return nil;
}

- (void)replaceCharactersInRange:(NSRange)__unused range withString:(NSString *)__unused str
{
}

- (void)setAttributes:(NSDictionary *)__unused attrs range:(NSRange)__unused range
{
}

- (void)addLayoutManager:(NSLayoutManager *)__unused layoutManager
{
}
@end

@implementation NSTextContainer
- (instancetype)initWithSize:(CGSize)__unused size
{
    return [self init];
}
@end

@implementation UITextView (LegacyComponentsTextKitDeclarations)
- (NSLayoutManager *)tg_ios6_layoutManager
{
    return nil;
}

- (NSTextContainer *)tg_ios6_textContainer
{
    return nil;
}

- (NSTextStorage *)tg_ios6_textStorage
{
    return nil;
}

- (UIEdgeInsets)tg_ios6_textContainerInset
{
    return self.contentInset;
}

- (void)tg_ios6_setTextContainerInset:(UIEdgeInsets)textContainerInset
{
    self.contentInset = textContainerInset;
}

- (BOOL)tg_ios6_isSelectable
{
    return self.editable;
}

- (void)tg_ios6_setSelectable:(BOOL)__unused selectable
{
}

- (instancetype)tg_ios6_initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)__unused textContainer
{
    return [self initWithFrame:frame];
}
@end
#endif


@implementation WKFrameInfo
@end

@implementation WKNavigation
@end

@implementation WKNavigationAction
- (NSURLRequest *)request
{
    return nil;
}

- (WKFrameInfo *)targetFrame
{
    return nil;
}
@end

@implementation WKUserScript
- (instancetype)initWithSource:(NSString *)__unused source injectionTime:(WKUserScriptInjectionTime)__unused injectionTime forMainFrameOnly:(BOOL)__unused forMainFrameOnly
{
    return [self init];
}
@end

@implementation WKPreferences
@end

@implementation WKUserContentController
- (void)addUserScript:(WKUserScript *)__unused userScript
{
}

- (void)addScriptMessageHandler:(id<WKScriptMessageHandler>)__unused scriptMessageHandler name:(NSString *)__unused name
{
}
@end

@implementation WKWebViewConfiguration
@end

@implementation WKWebView
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)__unused configuration
{
    return [super initWithFrame:frame];
}

- (UIScrollView *)scrollView
{
    return nil;
}

- (double)estimatedProgress
{
    return 0.0;
}

- (WKNavigation *)loadRequest:(NSURLRequest *)__unused request
{
    return nil;
}

- (void)evaluateJavaScript:(NSString *)__unused javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler
{
    if (completionHandler != nil)
        completionHandler(nil, nil);
}
@end
