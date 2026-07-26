#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#undef UIPercentDrivenInteractiveTransition
#undef UIKeyCommand
#undef UIAlertController
#undef UIDocumentPickerViewController
#undef PHObject
#undef PHAsset
#undef PHAssetChangeRequest
#undef PHAssetCollection
#undef PHAssetResource
#undef PHAssetResourceManager
#undef PHCachingImageManager
#undef PHFetchOptions
#undef PHImageManager
#undef PHImageRequestOptions
#undef PHLivePhotoRequestOptions
#undef PHPhotoLibrary
#undef PHVideoRequestOptions

@interface UIPercentDrivenInteractiveTransition : NSObject
@end
@implementation UIPercentDrivenInteractiveTransition
- (void)updateInteractiveTransition:(CGFloat)percentComplete {}
- (void)cancelInteractiveTransition {}
- (void)finishInteractiveTransition {}
@end

@interface UIKeyCommand : NSObject
+ (instancetype)keyCommandWithInput:(NSString *)input modifierFlags:(NSUInteger)modifierFlags action:(SEL)action;
@end
@implementation UIKeyCommand
+ (instancetype)keyCommandWithInput:(NSString *)input modifierFlags:(NSUInteger)modifierFlags action:(SEL)action
{
    return [[self alloc] init];
}
@end

@interface UIAlertController : UIViewController
@end
@implementation UIAlertController
@end

@interface UIDocumentPickerViewController : UIViewController
@end
@implementation UIDocumentPickerViewController
@end

@interface PHObject : NSObject
@end
@implementation PHObject
@end

@interface PHAsset : PHObject
@end
@implementation PHAsset
@end

@interface PHAssetChangeRequest : NSObject
@end
@implementation PHAssetChangeRequest
@end

@interface PHAssetCollection : PHObject
@end
@implementation PHAssetCollection
@end

@interface PHAssetResource : NSObject
@end
@implementation PHAssetResource
@end

@interface PHAssetResourceManager : NSObject
@end
@implementation PHAssetResourceManager
+ (instancetype)defaultManager
{
    return [[self alloc] init];
}
@end

@interface PHCachingImageManager : NSObject
@end
@implementation PHCachingImageManager
@end

@interface PHFetchOptions : NSObject
@end
@implementation PHFetchOptions
@end

@interface PHImageManager : NSObject
@end
@implementation PHImageManager
+ (instancetype)defaultManager
{
    return [[self alloc] init];
}
@end

@interface PHImageRequestOptions : NSObject
@end
@implementation PHImageRequestOptions
@end

@interface PHLivePhotoRequestOptions : NSObject
@end
@implementation PHLivePhotoRequestOptions
@end

@interface PHPhotoLibrary : NSObject
@end
@implementation PHPhotoLibrary
@end

@interface PHVideoRequestOptions : NSObject
@end
@implementation PHVideoRequestOptions
@end

@implementation TGIOS6WKFrameInfo
@end

@implementation TGIOS6WKNavigation
@end

@implementation TGIOS6WKNavigationAction
- (NSURLRequest *)request
{
    return nil;
}
- (TGIOS6WKFrameInfo *)targetFrame
{
    return nil;
}
@end

@implementation TGIOS6WKUserScript
- (instancetype)initWithSource:(NSString *)source injectionTime:(NSInteger)injectionTime forMainFrameOnly:(BOOL)forMainFrameOnly
{
    return [super init];
}
@end

@implementation TGIOS6WKPreferences
@synthesize javaScriptEnabled = _javaScriptEnabled;
@end

@implementation TGIOS6WKUserContentController
- (void)addUserScript:(TGIOS6WKUserScript *)userScript {}
- (void)addScriptMessageHandler:(id)scriptMessageHandler name:(NSString *)name {}
@end

@implementation TGIOS6WKWebViewConfiguration
@synthesize userContentController = _userContentController;
@synthesize preferences = _preferences;
@synthesize allowsInlineMediaPlayback = _allowsInlineMediaPlayback;
@synthesize requiresUserActionForMediaPlayback = _requiresUserActionForMediaPlayback;
@synthesize mediaPlaybackRequiresUserAction = _mediaPlaybackRequiresUserAction;
@synthesize allowsPictureInPictureMediaPlayback = _allowsPictureInPictureMediaPlayback;
- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _userContentController = [[TGIOS6WKUserContentController alloc] init];
        _preferences = [[TGIOS6WKPreferences alloc] init];
    }
    return self;
}
@end

@interface TGIOS6WKWebView () <UIWebViewDelegate>
@property (nonatomic, strong) UIWebView *innerWebView;
@property (nonatomic, weak) id storedNavigationDelegate;
@end

@implementation TGIOS6WKWebView
- (instancetype)initWithFrame:(CGRect)frame configuration:(TGIOS6WKWebViewConfiguration *)configuration
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _innerWebView = [[UIWebView alloc] initWithFrame:self.bounds];
        _innerWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_innerWebView];
    }
    return self;
}
- (UIScrollView *)scrollView
{
    return _innerWebView.scrollView;
}
- (double)estimatedProgress
{
    return _innerWebView.loading ? 0.5 : 1.0;
}
- (id)navigationDelegate
{
    return _storedNavigationDelegate;
}
- (void)setNavigationDelegate:(id)navigationDelegate
{
    _storedNavigationDelegate = navigationDelegate;
}
- (TGIOS6WKNavigation *)loadRequest:(NSURLRequest *)request
{
    [_innerWebView loadRequest:request];
    return [[TGIOS6WKNavigation alloc] init];
}
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id result, NSError *error))completionHandler
{
    NSString *result = [_innerWebView stringByEvaluatingJavaScriptFromString:javaScriptString];
    if (completionHandler != nil)
        completionHandler(result, nil);
}
@end
