#ifndef TG_LEGACY_IOS6_COMPAT_OBJC_GUARD
#define TG_LEGACY_IOS6_COMPAT_OBJC_GUARD
#ifdef __OBJC__
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// SDK 6 compatibility classes must not reuse names that became system classes
// on iOS 7-10. The aliases keep the legacy fallback implementations private
// while preserving the existing source API for the old compiler.
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 70000
#define UIPercentDrivenInteractiveTransition TGIOS6PercentDrivenInteractiveTransition
#define NSURLSessionConfiguration TGIOS6URLSessionConfiguration
#define NSURLSession TGIOS6URLSession
#define NSURLSessionTask TGIOS6URLSessionTask
#define NSURLSessionDataTask TGIOS6URLSessionDataTask
#define UIKeyCommand TGIOS6KeyCommand
#define UICollectionViewTransitionLayout TGIOS6CollectionViewTransitionLayout
#define NSTextAttachment TGIOS6TextAttachment
#define NSLayoutManager TGIOS6LayoutManager
#define NSTextStorage TGIOS6TextStorage
#define NSTextContainer TGIOS6TextContainer
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 80000
#define UIAlertController TGIOS6AlertController
#define UIDocumentPickerViewController TGIOS6DocumentPickerViewController
#define PHObject TGIOS6PHObject
#define PHAsset TGIOS6PHAsset
#define PHAssetChangeRequest TGIOS6PHAssetChangeRequest
#define PHAssetCollection TGIOS6PHAssetCollection
#define PHCachingImageManager TGIOS6PHCachingImageManager
#define PHFetchOptions TGIOS6PHFetchOptions
#define PHImageManager TGIOS6PHImageManager
#define PHImageRequestOptions TGIOS6PHImageRequestOptions
#define PHPhotoLibrary TGIOS6PHPhotoLibrary
#define PHVideoRequestOptions TGIOS6PHVideoRequestOptions
#define WKFrameInfo TGIOS6WKFrameInfo
#define WKNavigation TGIOS6WKNavigation
#define WKNavigationAction TGIOS6WKNavigationAction
#define WKUserScript TGIOS6WKUserScript
#define WKPreferences TGIOS6WKPreferences
#define WKUserContentController TGIOS6WKUserContentController
#define WKWebViewConfiguration TGIOS6WKWebViewConfiguration
#define WKWebView TGIOS6WKWebView
#define WKNavigationDelegate TGIOS6WKNavigationDelegate
#define WKScriptMessageHandler TGIOS6WKScriptMessageHandler
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
#define PHAssetResource TGIOS6PHAssetResource
#define PHAssetResourceManager TGIOS6PHAssetResourceManager
#define PHLivePhotoRequestOptions TGIOS6PHLivePhotoRequestOptions
#define CNContactFormatter TGIOS6ContactFormatter
#define CNContactVCardSerialization TGIOS6ContactVCardSerialization
#define CNLabeledValue TGIOS6LabeledValue
#define CNMutableContact TGIOS6MutableContact
#define CNPhoneNumber TGIOS6PhoneNumber
#define WCSession TGIOS6WCSession
#define SFSafariViewController TGIOS6SafariViewController
#define SFSafariViewControllerDelegate TGIOS6SafariViewControllerDelegate
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 100000
#define UIImpactFeedbackGenerator TGIOS6ImpactFeedbackGenerator
#endif

#import <CoreLocation/CoreLocation.h>
#import <CoreText/CoreText.h>
#import <AVFoundation/AVFoundation.h>
#ifndef TG_LEGACY_NSARRAY_OBJECT_ACCESS_DECLS
#define TG_LEGACY_NSARRAY_OBJECT_ACCESS_DECLS
@interface NSArray (LegacyComponentsObjectAccessDeclarations)
@property (nonatomic, readonly) id firstObject;
@property (nonatomic, readonly) id lastObject;
@end
#endif

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "../WebKit/WebKit.h"


#ifndef TG_ENABLE_AUDIO_NOTES
#define TG_ENABLE_AUDIO_NOTES 1
#endif
#ifndef TG_LEGACY_FOUNDATION_MODERN_NAMES
#define TG_LEGACY_FOUNDATION_MODERN_NAMES
#ifndef NSCalendarIdentifierGregorian
#define NSCalendarIdentifierGregorian NSGregorianCalendar
#endif
#ifndef NSCalendarUnitEra
#define NSCalendarUnitEra NSEraCalendarUnit
#define NSCalendarUnitYear NSYearCalendarUnit
#define NSCalendarUnitMonth NSMonthCalendarUnit
#define NSCalendarUnitDay NSDayCalendarUnit
#define NSCalendarUnitHour NSHourCalendarUnit
#define NSCalendarUnitMinute NSMinuteCalendarUnit
#define NSCalendarUnitSecond NSSecondCalendarUnit
#define NSCalendarUnitWeekday NSWeekdayCalendarUnit
#define NSCalendarUnitWeekdayOrdinal NSWeekdayOrdinalCalendarUnit
#define NSCalendarUnitQuarter NSQuarterCalendarUnit
#define NSCalendarUnitWeekOfMonth NSWeekOfMonthCalendarUnit
#define NSCalendarUnitWeekOfYear NSWeekOfYearCalendarUnit
#define NSCalendarUnitYearForWeekOfYear NSYearForWeekOfYearCalendarUnit
#define NSCalendarUnitNanosecond NSNanosecondCalendarUnit
#define NSCalendarUnitCalendar NSCalendarCalendarUnit
#define NSCalendarUnitTimeZone NSTimeZoneCalendarUnit
#endif
#endif

#ifndef TG_LEGACY_FOUNDATION_MODERN_NAMES
#define TG_LEGACY_FOUNDATION_MODERN_NAMES
#ifndef NSCalendarIdentifierGregorian
#define NSCalendarIdentifierGregorian NSGregorianCalendar
#endif
#ifndef NSCalendarUnitEra
#define NSCalendarUnitEra NSEraCalendarUnit
#define NSCalendarUnitYear NSYearCalendarUnit
#define NSCalendarUnitMonth NSMonthCalendarUnit
#define NSCalendarUnitDay NSDayCalendarUnit
#define NSCalendarUnitHour NSHourCalendarUnit
#define NSCalendarUnitMinute NSMinuteCalendarUnit
#define NSCalendarUnitSecond NSSecondCalendarUnit
#define NSCalendarUnitWeekday NSWeekdayCalendarUnit
#define NSCalendarUnitWeekdayOrdinal NSWeekdayOrdinalCalendarUnit
#define NSCalendarUnitQuarter NSQuarterCalendarUnit
#define NSCalendarUnitWeekOfMonth NSWeekOfMonthCalendarUnit
#define NSCalendarUnitWeekOfYear NSWeekOfYearCalendarUnit
#define NSCalendarUnitYearForWeekOfYear NSYearForWeekOfYearCalendarUnit
#define NSCalendarUnitNanosecond NSNanosecondCalendarUnit
#define NSCalendarUnitCalendar NSCalendarCalendarUnit
#define NSCalendarUnitTimeZone NSTimeZoneCalendarUnit
#endif
#endif






#ifndef NSUnderlinePatternSolid
#define NSUnderlinePatternSolid 0x0000
#define NSUnderlinePatternDot 0x0100
#define NSUnderlinePatternDash 0x0200
#define NSUnderlinePatternDashDot 0x0300
#define NSUnderlinePatternDashDotDot 0x0400
#endif

#ifndef TG_LEGACY_COMMON_DECLS
#define TG_LEGACY_COMMON_DECLS
@class TGLocalization;
@class NSUserActivity;
@class UIApplicationShortcutItem;
#ifdef __cplusplus
extern "C" {
#endif
TGLocalization *legacyEffectiveLocalization();
NSString *TGLocalized(NSString *s);
NSString *TGEncodeText(NSString *string, int key);
NSString *TGStringMD5(NSString *string);
NSArray *TGGetLogFilePaths(int count);
NSURL *TGFileURLWithPathRelativeToURL(NSString *path, NSURL *baseURL);
int cpuCoreCount();
extern int TGLocalizedStaticVersion;
TGLocalization *currentNativeLocalization();
TGLocalization *nativeEnglishLocalization(void);
TGLocalization *currentCustomLocalization();
void setCurrentCustomLocalization(TGLocalization *localization);
TGLocalization *effectiveLocalization();
void TGLog(NSString *format, ...);
void TGLogv(NSString *format, va_list args);
bool TGObjectCompare(id obj1, id obj2);
bool TGStringCompare(NSString *s1, NSString *s2);
void TGLegacyLog(NSString *format, ...);
int iosMajorVersion();
int iosMinorVersion();
void TGDispatchOnMainThread(dispatch_block_t block);
void TGDispatchAfter(double delay, dispatch_queue_t queue, dispatch_block_t block);
UIColor *TGSelectionColor();
UIColor *TGAccentColor(void);
UIColor *TGDestructiveAccentColor(void);
UIColor *TGSeparatorColor();
#ifdef __cplusplus
}
#endif
#ifndef UIColorRGB
#define UIColorRGB(rgb) ([[UIColor alloc] initWithRed:(((rgb >> 16) & 0xff) / 255.0f) green:(((rgb >> 8) & 0xff) / 255.0f) blue:(((rgb) & 0xff) / 255.0f) alpha:1.0f])
#endif
#ifndef UIColorRGBA
#define UIColorRGBA(rgb,a) ([[UIColor alloc] initWithRed:(((rgb >> 16) & 0xff) / 255.0f) green:(((rgb >> 8) & 0xff) / 255.0f) blue:(((rgb) & 0xff) / 255.0f) alpha:a])
#endif
#ifndef CGFloor
#ifdef __LP64__
#define CGFloor floor
#define CGRound round
#define CGCeil ceil
#define CGPow pow
#define CGSin sin
#define CGCos cos
#define CGSqrt sqrt
#else
#define CGFloor floorf
#define CGRound roundf
#define CGCeil ceilf
#define CGPow powf
#define CGSin sinf
#define CGCos cosf
#define CGSqrt sqrtf
#endif
#endif
#ifndef CGEven
#define CGEven(x) ((((int)x) & 1) ? (x + 1) : x)
#endif
#ifndef CGOdd
#define CGOdd(x) ((((int)x) & 1) ? x : (x + 1))
#endif
#endif

#ifndef TG_LEGACY_UIIMPACT_FEEDBACK_DECLS
#define TG_LEGACY_UIIMPACT_FEEDBACK_DECLS
typedef NSInteger UIImpactFeedbackStyle;
#ifndef UIImpactFeedbackStyleLight
#define UIImpactFeedbackStyleLight 0
#define UIImpactFeedbackStyleMedium 1
#define UIImpactFeedbackStyleHeavy 2
#endif
@interface UIImpactFeedbackGenerator : NSObject
- (instancetype)initWithStyle:(UIImpactFeedbackStyle)style;
- (void)impactOccurred;
- (void)prepare;
@end
@interface UISelectionFeedbackGenerator : NSObject
- (void)selectionChanged;
- (void)prepare;
@end
typedef NSInteger UINotificationFeedbackType;
#ifndef UINotificationFeedbackTypeSuccess
#define UINotificationFeedbackTypeSuccess 0
#define UINotificationFeedbackTypeWarning 1
#define UINotificationFeedbackTypeError 2
#endif
@interface UINotificationFeedbackGenerator : NSObject
- (void)notificationOccurred:(UINotificationFeedbackType)notificationType;
- (void)prepare;
@end
#endif

#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
#endif
#ifndef nullable
#define nullable
#endif
#ifndef null_unspecified
#define null_unspecified
#endif
#ifndef __nullable
#define __nullable
#endif
#ifndef __nonnull
#define __nonnull
#endif

#ifndef PKAddressFieldNone
typedef NSUInteger PKAddressField;
#define PKAddressFieldNone 0
#define PKAddressFieldPostalAddress 1
#define PKAddressFieldPhone 2
#define PKAddressFieldEmail 4
#define PKAddressFieldName 8
#endif

#ifndef TG_LEGACY_UIIMPACT_FEEDBACK_DECLS
#define TG_LEGACY_UIIMPACT_FEEDBACK_DECLS
typedef NSInteger UIImpactFeedbackStyle;
#ifndef UIImpactFeedbackStyleLight
#define UIImpactFeedbackStyleLight 0
#define UIImpactFeedbackStyleMedium 1
#define UIImpactFeedbackStyleHeavy 2
#endif
@interface UIImpactFeedbackGenerator : NSObject
- (instancetype)initWithStyle:(UIImpactFeedbackStyle)style;
- (void)impactOccurred;
- (void)prepare;
@end
typedef NSInteger UIScrollViewKeyboardDismissMode;
#ifndef UIScrollViewKeyboardDismissModeNone
#define UIScrollViewKeyboardDismissModeNone 0
#define UIScrollViewKeyboardDismissModeOnDrag 1
#define UIScrollViewKeyboardDismissModeInteractive 2
#endif
@interface UIScrollView (LegacyComponentsKeyboardDismissMode)
@property (nonatomic) UIScrollViewKeyboardDismissMode keyboardDismissMode;
@end
#endif

#ifndef TG_LEGACY_KEYBOARD_DISMISS_MODE_DECLS
#define TG_LEGACY_KEYBOARD_DISMISS_MODE_DECLS
typedef NSInteger UIScrollViewKeyboardDismissMode;
#ifndef UIScrollViewKeyboardDismissModeNone
#define UIScrollViewKeyboardDismissModeNone 0
#define UIScrollViewKeyboardDismissModeOnDrag 1
#define UIScrollViewKeyboardDismissModeInteractive 2
#endif
@interface UIScrollView (LegacyComponentsKeyboardDismissMode)
@property (nonatomic) UIScrollViewKeyboardDismissMode keyboardDismissMode;
@end
#endif

#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
#endif
#ifndef nullable
#define nullable
#endif
#ifndef null_unspecified
#define null_unspecified
#endif
#ifndef __nullable
#define __nullable
#endif
#ifndef __nonnull
#define __nonnull
#endif
#ifndef _Nullable
#define _Nullable
#endif
#ifndef _Nonnull
#define _Nonnull
#endif
#ifndef _Null_unspecified
#define _Null_unspecified
#endif

#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
#endif
#ifndef NS_DESIGNATED_INITIALIZER
#define NS_DESIGNATED_INITIALIZER
#endif
#ifndef nullable
#define nullable
#endif
#ifndef null_unspecified
#define null_unspecified
#endif
#ifndef __nullable
#define __nullable
#endif
#ifndef __nonnull
#define __nonnull
#endif
#ifndef _Nullable
#define _Nullable
#endif
#ifndef _Nonnull
#define _Nonnull
#endif
#ifndef _Null_unspecified
#define _Null_unspecified
#endif
#ifndef PKAddressFieldNone
typedef NSUInteger PKAddressField;
#define PKAddressFieldNone 0
#define PKAddressFieldPostalAddress 1
#define PKAddressFieldPhone 2
#define PKAddressFieldEmail 4
#define PKAddressFieldName 8
#endif
#ifndef PKMerchantCapability3DS
typedef NSUInteger PKMerchantCapability;
#define PKMerchantCapability3DS 1
#define PKMerchantCapabilityEMV 2
#endif
#ifndef PKPaymentAuthorizationStatusSuccess
typedef NSInteger PKPaymentAuthorizationStatus;
#define PKPaymentAuthorizationStatusSuccess 0
#define PKPaymentAuthorizationStatusFailure 1
#endif
#ifndef TG_LEGACY_PASSKIT_APPLE_PAY_DECLS
#define TG_LEGACY_PASSKIT_APPLE_PAY_DECLS
static NSString *const PKPaymentNetworkAmex = @"AmEx";
static NSString *const PKPaymentNetworkMasterCard = @"MasterCard";
static NSString *const PKPaymentNetworkVisa = @"Visa";
static NSString *const PKPaymentNetworkDiscover = @"Discover";
@class PKPayment;
@class PKPaymentRequest;
@class PKPaymentSummaryItem;
@class PKShippingMethod;
@protocol PKPaymentAuthorizationViewControllerDelegate;
@interface PKPayment : NSObject
@property (nonatomic, readonly) NSString *transactionIdentifier;
@property (nonatomic, readonly) id token;
@end
@interface PKPaymentRequest : NSObject
@property (nonatomic, copy) NSString *merchantIdentifier;
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, copy) NSString *currencyCode;
@property (nonatomic, copy) NSArray *supportedNetworks;
@property (nonatomic) PKMerchantCapability merchantCapabilities;
@property (nonatomic) PKAddressField requiredShippingAddressFields;
@property (nonatomic) PKAddressField requiredBillingAddressFields;
@property (nonatomic, copy) NSArray *paymentSummaryItems;
@property (nonatomic, copy) NSArray *shippingMethods;
@end
@interface PKPaymentSummaryItem : NSObject
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSDecimalNumber *amount;
+ (instancetype)summaryItemWithLabel:(NSString *)label amount:(NSDecimalNumber *)amount;
@end
@interface PKShippingMethod : PKPaymentSummaryItem
@end
@interface PKPaymentAuthorizationViewController : UIViewController
+ (BOOL)canMakePayments;
+ (BOOL)canMakePaymentsUsingNetworks:(NSArray *)supportedNetworks;
- (instancetype)initWithPaymentRequest:(PKPaymentRequest *)paymentRequest;
@property (nonatomic, assign) id<PKPaymentAuthorizationViewControllerDelegate> delegate;
@end
@protocol PKPaymentAuthorizationViewControllerDelegate <NSObject>
@optional
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didAuthorizePayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus status))completion;
- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller;
@end
#endif

#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
#endif
#ifndef NS_DESIGNATED_INITIALIZER
#define NS_DESIGNATED_INITIALIZER
#endif
#ifndef nullable
#define nullable
#endif
#ifndef null_unspecified
#define null_unspecified
#endif
#ifndef __nullable
#define __nullable
#endif
#ifndef __nonnull
#define __nonnull
#endif
#ifndef _Nullable
#define _Nullable
#endif
#ifndef _Nonnull
#define _Nonnull
#endif
#ifndef _Null_unspecified
#define _Null_unspecified
#endif
#ifndef PKAddressFieldNone
typedef NSUInteger PKAddressField;
#define PKAddressFieldNone 0
#define PKAddressFieldPostalAddress 1
#define PKAddressFieldPhone 2
#define PKAddressFieldEmail 4
#define PKAddressFieldName 8
#endif
#ifndef PKMerchantCapability3DS
typedef NSUInteger PKMerchantCapability;
#define PKMerchantCapability3DS 1
#define PKMerchantCapabilityEMV 2
#endif
#ifndef PKPaymentAuthorizationStatusSuccess
typedef NSInteger PKPaymentAuthorizationStatus;
#define PKPaymentAuthorizationStatusSuccess 0
#define PKPaymentAuthorizationStatusFailure 1
#endif
#ifndef TG_LEGACY_PASSKIT_APPLE_PAY_DECLS
#define TG_LEGACY_PASSKIT_APPLE_PAY_DECLS
static NSString *const PKPaymentNetworkAmex = @"AmEx";
static NSString *const PKPaymentNetworkMasterCard = @"MasterCard";
static NSString *const PKPaymentNetworkVisa = @"Visa";
static NSString *const PKPaymentNetworkDiscover = @"Discover";
@class PKPayment;
@class PKPaymentRequest;
@class PKPaymentSummaryItem;
@class PKShippingMethod;
@protocol PKPaymentAuthorizationViewControllerDelegate;
@interface PKPayment : NSObject
@property (nonatomic, readonly) NSString *transactionIdentifier;
@property (nonatomic, readonly) id token;
@end
@interface PKPaymentRequest : NSObject
@property (nonatomic, copy) NSString *merchantIdentifier;
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, copy) NSString *currencyCode;
@property (nonatomic, copy) NSArray *supportedNetworks;
@property (nonatomic) PKMerchantCapability merchantCapabilities;
@property (nonatomic) PKAddressField requiredShippingAddressFields;
@property (nonatomic) PKAddressField requiredBillingAddressFields;
@property (nonatomic, copy) NSArray *paymentSummaryItems;
@property (nonatomic, copy) NSArray *shippingMethods;
@end
@interface PKPaymentSummaryItem : NSObject
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSDecimalNumber *amount;
+ (instancetype)summaryItemWithLabel:(NSString *)label amount:(NSDecimalNumber *)amount;
@end
@interface PKShippingMethod : PKPaymentSummaryItem
@end
@interface PKPaymentAuthorizationViewController : UIViewController
+ (BOOL)canMakePayments;
+ (BOOL)canMakePaymentsUsingNetworks:(NSArray *)supportedNetworks;
- (instancetype)initWithPaymentRequest:(PKPaymentRequest *)paymentRequest;
@property (nonatomic, assign) id<PKPaymentAuthorizationViewControllerDelegate> delegate;
@end
@protocol PKPaymentAuthorizationViewControllerDelegate <NSObject>
@optional
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didAuthorizePayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus status))completion;
- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller;
@end
#endif
#ifndef TG_LEGACY_URLSESSION_DECLS
#define TG_LEGACY_URLSESSION_DECLS
typedef void (^NSURLSessionDataTaskCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);
@interface NSURLSessionTask : NSObject
- (void)resume;
- (void)cancel;
@end
@interface NSURLSessionDataTask : NSURLSessionTask
@end
@interface NSURLSessionConfiguration : NSObject
+ (instancetype)defaultSessionConfiguration;
@property (nonatomic, copy) NSDictionary *HTTPAdditionalHeaders;
@end
@interface NSURLSession : NSObject
+ (instancetype)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration;
+ (instancetype)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(id)delegate delegateQueue:(NSOperationQueue *)queue;
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request;
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(NSURLSessionDataTaskCompletionHandler)completionHandler;
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(NSURLSessionDataTaskCompletionHandler)completionHandler;
- (void)invalidateAndCancel;
@end
#endif

#ifndef TG_LEGACY_SSREADINGLIST_DECLS
#define TG_LEGACY_SSREADINGLIST_DECLS
@interface SSReadingList : NSObject
+ (instancetype)defaultReadingList;
- (BOOL)addReadingListItemWithURL:(NSURL *)URL title:(NSString *)title previewText:(NSString *)previewText error:(NSError **)error;
@end
#endif

#ifndef TG_LEGACY_OPTIONAL_SYSTEM_SELECTOR_DECLS
#define TG_LEGACY_OPTIONAL_SYSTEM_SELECTOR_DECLS
@interface NSObject (TGLegacyOptionalSystemSelectorDeclarations)
- (id)defaultReadingList;
- (BOOL)addReadingListItemWithURL:(NSURL *)url title:(NSString *)title previewText:(NSString *)previewText error:(NSError **)error;
- (void)setEffect:(id)effect;
- (id)effectWithStyle:(NSInteger)style;
- (id)summaryItemWithLabel:(NSString *)label amount:(NSDecimalNumber *)amount;
- (NSDecimalNumber *)amount;
- (BOOL)canMakePaymentsUsingNetworks:(NSArray *)supportedNetworks;
@end
#endif

#ifndef TG_LEGACY_CTFONT_FROM_UIFONT
#define TG_LEGACY_CTFONT_FROM_UIFONT
static inline CTFontRef TGIos6CreateCTFontFromUIFont(UIFont *font)
{
    return CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
}
#endif

#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
#endif
#ifndef NS_DESIGNATED_INITIALIZER
#define NS_DESIGNATED_INITIALIZER
#endif
#ifndef nullable
#define nullable
#endif
#ifndef null_unspecified
#define null_unspecified
#endif
#ifndef __nullable
#define __nullable
#endif
#ifndef __nonnull
#define __nonnull
#endif
#ifndef _Nullable
#define _Nullable
#endif
#ifndef _Nonnull
#define _Nonnull
#endif
#ifndef _Null_unspecified
#define _Null_unspecified
#endif
#ifndef PKAddressFieldNone
typedef NSUInteger PKAddressField;
#define PKAddressFieldNone 0
#define PKAddressFieldPostalAddress 1
#define PKAddressFieldPhone 2
#define PKAddressFieldEmail 4
#define PKAddressFieldName 8
#endif
#ifndef PKMerchantCapability3DS
typedef NSUInteger PKMerchantCapability;
#define PKMerchantCapability3DS 1
#define PKMerchantCapabilityEMV 2
#endif
#ifndef PKPaymentAuthorizationStatusSuccess
typedef NSInteger PKPaymentAuthorizationStatus;
#define PKPaymentAuthorizationStatusSuccess 0
#define PKPaymentAuthorizationStatusFailure 1
#endif
#ifndef TG_LEGACY_PASSKIT_APPLE_PAY_DECLS
#define TG_LEGACY_PASSKIT_APPLE_PAY_DECLS
static NSString *const PKPaymentNetworkAmex = @"AmEx";
static NSString *const PKPaymentNetworkMasterCard = @"MasterCard";
static NSString *const PKPaymentNetworkVisa = @"Visa";
static NSString *const PKPaymentNetworkDiscover = @"Discover";
@class PKPayment;
@class PKPaymentRequest;
@class PKPaymentSummaryItem;
@class PKShippingMethod;
@protocol PKPaymentAuthorizationViewControllerDelegate;
@interface PKPayment : NSObject
@property (nonatomic, readonly) NSString *transactionIdentifier;
@property (nonatomic, readonly) id token;
@end
@interface PKPaymentRequest : NSObject
@property (nonatomic, copy) NSString *merchantIdentifier;
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, copy) NSString *currencyCode;
@property (nonatomic, copy) NSArray *supportedNetworks;
@property (nonatomic) PKMerchantCapability merchantCapabilities;
@property (nonatomic) PKAddressField requiredShippingAddressFields;
@property (nonatomic) PKAddressField requiredBillingAddressFields;
@property (nonatomic, copy) NSArray *paymentSummaryItems;
@property (nonatomic, copy) NSArray *shippingMethods;
@end
@interface PKPaymentSummaryItem : NSObject
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSDecimalNumber *amount;
+ (instancetype)summaryItemWithLabel:(NSString *)label amount:(NSDecimalNumber *)amount;
@end
@interface PKShippingMethod : PKPaymentSummaryItem
@end
@interface PKPaymentAuthorizationViewController : UIViewController
+ (BOOL)canMakePayments;
+ (BOOL)canMakePaymentsUsingNetworks:(NSArray *)supportedNetworks;
- (instancetype)initWithPaymentRequest:(PKPaymentRequest *)paymentRequest;
@property (nonatomic, assign) id<PKPaymentAuthorizationViewControllerDelegate> delegate;
@end
@protocol PKPaymentAuthorizationViewControllerDelegate <NSObject>
@optional
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didAuthorizePayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus status))completion;
- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller;
@end
#endif
#ifndef TG_LEGACY_URLSESSION_DECLS
#define TG_LEGACY_URLSESSION_DECLS
typedef void (^NSURLSessionDataTaskCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);
@interface NSURLSessionTask : NSObject
- (void)resume;
- (void)cancel;
@end
@interface NSURLSessionDataTask : NSURLSessionTask
@end
@interface NSURLSessionConfiguration : NSObject
+ (instancetype)defaultSessionConfiguration;
@property (nonatomic, copy) NSDictionary *HTTPAdditionalHeaders;
@end
@interface NSURLSession : NSObject
+ (instancetype)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration;
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request;
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(NSURLSessionDataTaskCompletionHandler)completionHandler;
@end
#endif

#ifndef TG_LEGACY_TRANSITION_COORDINATOR_DECLS
#define TG_LEGACY_TRANSITION_COORDINATOR_DECLS
@protocol UIViewControllerTransitionCoordinatorContext <NSObject>
@end
@protocol UIViewControllerTransitionCoordinator <NSObject>
- (BOOL)isCancelled;
- (void)animateAlongsideTransition:(void (^)(id<UIViewControllerTransitionCoordinatorContext> context))animation completion:(void (^)(id<UIViewControllerTransitionCoordinatorContext> context))completion;
@end
@interface UIViewController (LegacyTransitionCoordinatorDeclarations)
@property (nonatomic, readonly) id<UIViewControllerTransitionCoordinator> transitionCoordinator;
@end
#endif

#ifndef TG_LEGACY_SEMANTIC_CONTENT_DECLS
#define TG_LEGACY_SEMANTIC_CONTENT_DECLS
typedef NSInteger UISemanticContentAttribute;
#ifndef UISemanticContentAttributeUnspecified
#define UISemanticContentAttributeUnspecified 0
#define UISemanticContentAttributePlayback 1
#define UISemanticContentAttributeSpatial 2
#define UISemanticContentAttributeForceLeftToRight 3
#define UISemanticContentAttributeForceRightToLeft 4
#endif
@interface UIView (LegacySemanticContentDeclarations)
@property (nonatomic) UISemanticContentAttribute semanticContentAttribute;
+ (UIUserInterfaceLayoutDirection)userInterfaceLayoutDirectionForSemanticContentAttribute:(UISemanticContentAttribute)attribute;
@end
#endif

#ifndef NSAttachmentAttributeName
#define NSAttachmentAttributeName @"NSAttachment"
#endif
#ifndef NSAttachmentCharacter
#define NSAttachmentCharacter ((unichar)0xfffc)
#endif
#ifndef UIKeyboardAppearanceDark
#define UIKeyboardAppearanceDark UIKeyboardAppearanceAlert
#endif
#ifndef UIInterfaceOrientationUnknown
#define UIInterfaceOrientationUnknown ((UIInterfaceOrientation)0)
#endif

#ifndef UIUserInterfaceSizeClassUnspecified
typedef NSInteger UIUserInterfaceSizeClass;
#define UIUserInterfaceSizeClassUnspecified 0
#define UIUserInterfaceSizeClassCompact 1
#define UIUserInterfaceSizeClassRegular 2
#endif

#ifndef UIKeyInputUpArrow
#define UIKeyInputUpArrow @"\uF700"
#define UIKeyInputDownArrow @"\uF701"
#define UIKeyInputLeftArrow @"\uF702"
#define UIKeyInputRightArrow @"\uF703"
#endif

#ifndef UIKeyInputUpArrow
#define UIKeyInputUpArrow @"\uF700"
#define UIKeyInputDownArrow @"\uF701"
#define UIKeyInputLeftArrow @"\uF702"
#define UIKeyInputRightArrow @"\uF703"
#define UIKeyInputEscape @"\033"
#endif

#ifndef UIKeyInputEscape
#define UIKeyInputEscape @"\033"
#endif

#ifndef UIKeyModifierAlphaShift
typedef NSUInteger UIKeyModifierFlags;
@interface UIKeyCommand : NSObject
@property (nonatomic, readonly) NSString *input;
@property (nonatomic, readonly) UIKeyModifierFlags modifierFlags;
+ (instancetype)keyCommandWithInput:(NSString *)input modifierFlags:(UIKeyModifierFlags)modifierFlags action:(SEL)action;
@end
#define UIKeyModifierAlphaShift (1 << 16)
#define UIKeyModifierShift (1 << 17)
#define UIKeyModifierControl (1 << 18)
#define UIKeyModifierAlternate (1 << 19)
#define UIKeyModifierCommand (1 << 20)
#define UIKeyModifierNumericPad (1 << 21)
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 70000
@protocol CAAnimationDelegate;
@class NSTextContainer;
@interface NSTextAttachment : NSObject
- (instancetype)initWithData:(NSData *)contentData ofType:(NSString *)uti;
- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex;
@end
@interface NSLayoutManager : NSObject
@property (nonatomic) BOOL allowsNonContiguousLayout;
- (void)addTextContainer:(NSTextContainer *)container;
- (void)showCGGlyphs:(const CGGlyph *)glyphs positions:(const CGPoint *)positions count:(NSUInteger)glyphCount font:(UIFont *)font matrix:(CGAffineTransform)textMatrix attributes:(NSDictionary *)attributes inContext:(CGContextRef)context;
@end
@interface NSTextStorage : NSMutableAttributedString
- (void)addLayoutManager:(NSLayoutManager *)layoutManager;
@end
@interface NSTextContainer : NSObject
@property (nonatomic, readonly) NSLayoutManager *layoutManager;
@property (nonatomic) BOOL widthTracksTextView;
- (instancetype)initWithSize:(CGSize)size;
@end
@interface UITextView (LegacyComponentsTextKitDeclarations)
@property (nonatomic, readonly) NSLayoutManager *layoutManager;
@property (nonatomic, readonly) NSTextContainer *textContainer;
@property (nonatomic, readonly) NSTextStorage *textStorage;
@property (nonatomic, getter=isSelectable) BOOL selectable;
@property (nonatomic) UIEdgeInsets textContainerInset;
- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer;
@end
#define UIScreenEdgePanGestureRecognizer UIPanGestureRecognizer
#ifndef UIModalPresentationPopover
#define UIModalPresentationPopover ((UIModalPresentationStyle)7)
#endif
@interface UINavigationController (LegacyComponentsInteractivePopDeclarations)
@property (nonatomic, readonly) UIGestureRecognizer *interactivePopGestureRecognizer;
@end
@interface UINavigationBar (LegacyComponentsLargeTitleDeclarations)
@property (nonatomic) BOOL prefersLargeTitles;
@end
@interface UIPercentDrivenInteractiveTransition : NSObject
@property (nonatomic, readonly) CGFloat percentComplete;
- (void)updateInteractiveTransition:(CGFloat)percentComplete;
- (void)cancelInteractiveTransition;
- (void)finishInteractiveTransition;
@end
#endif

#ifndef __IPHONE_9_0
@protocol UIViewControllerPreviewingDelegate <NSObject>
@end
typedef NSInteger UIDocumentPickerMode;
#ifndef UIDocumentPickerModeOpen
#define UIDocumentPickerModeImport 0
#define UIDocumentPickerModeOpen 1
#define UIDocumentPickerModeExportToService 2
#define UIDocumentPickerModeMoveToService 3
#endif
@class UIDocumentPickerViewController;
@protocol UIDocumentPickerDelegate <NSObject>
@optional
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url;
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray *)urls;
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller;
@end
@interface UIDocumentPickerViewController : UIViewController
@property (nonatomic, assign) id<UIDocumentPickerDelegate> delegate;
- (instancetype)initWithDocumentTypes:(NSArray *)allowedUTIs inMode:(UIDocumentPickerMode)mode;
@end
@protocol UIPreviewActionItem <NSObject>
@end
typedef NSInteger UIPreviewActionStyle;
#ifndef UIPreviewActionStyleDefault
#define UIPreviewActionStyleDefault 0
#define UIPreviewActionStyleSelected 1
#define UIPreviewActionStyleDestructive 2
#endif
@interface UIPreviewAction : NSObject <UIPreviewActionItem>
+ (instancetype)actionWithTitle:(NSString *)title style:(UIPreviewActionStyle)style handler:(void (^)(UIPreviewAction *action, UIViewController *previewViewController))handler;
@end
#endif

#ifndef UIForceTouchCapabilityAvailable
typedef NSInteger UIForceTouchCapability;
#define UIForceTouchCapabilityUnknown 0
#define UIForceTouchCapabilityUnavailable 1
#define UIForceTouchCapabilityAvailable 2
@interface UITraitCollection : NSObject
@property (nonatomic, readonly) UIForceTouchCapability forceTouchCapability;
@property (nonatomic, readonly) UIUserInterfaceSizeClass horizontalSizeClass;
@end
@protocol UIViewControllerPreviewing <NSObject>
@property (nonatomic) CGRect sourceRect;
@property (nonatomic, retain) UIView *sourceView;
@end
@interface UIViewController (LegacyComponentsPreviewingDeclarations)
- (UIStatusBarStyle)preferredStatusBarStyle;
- (void)setAutomaticallyAdjustsScrollViewInsets:(BOOL)value;
@property (nonatomic, readonly) id topLayoutGuide;
@property (nonatomic, readonly) id bottomLayoutGuide;
@property (nonatomic) CGSize preferredContentSize;
@property (nonatomic, readonly) UITraitCollection *traitCollection;
- (id)registerForPreviewingWithDelegate:(id)delegate sourceView:(UIView *)sourceView;
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection;
@end

#endif


#ifndef TG_LEGACY_AVAUDIOSESSION_INPUT_DECLS
#define TG_LEGACY_AVAUDIOSESSION_INPUT_DECLS
@interface AVAudioSession (LegacyComponentsInputsDeclarations)
@property (nonatomic, readonly) NSArray *availableInputs;
- (void)requestRecordPermission:(void (^)(BOOL granted))response;
@end
#endif

#ifndef TG_LEGACY_LOCATION_MANAGER_DECLS
#define TG_LEGACY_LOCATION_MANAGER_DECLS
@interface CLLocationManager (LegacyLocationDeclarations)
@property (nonatomic) BOOL allowsBackgroundLocationUpdates;
- (void)requestAlwaysAuthorization;
- (void)requestWhenInUseAuthorization;
- (void)requestLocation;
@end
#endif

#ifndef TG_LEGACY_SNAPSHOT_DECLS
#define TG_LEGACY_SNAPSHOT_DECLS
@interface UIView (LegacyComponentsSnapshotDeclarations)
- (UIView *)snapshotViewAfterScreenUpdates:(BOOL)afterUpdates;
- (UIView *)resizableSnapshotViewFromRect:(CGRect)rect afterScreenUpdates:(BOOL)afterUpdates withCapInsets:(UIEdgeInsets)capInsets;
- (BOOL)drawViewHierarchyInRect:(CGRect)rect afterScreenUpdates:(BOOL)afterUpdates;
@end
#endif

#ifndef TG_LEGACY_ACCESSIBILITY_INVERT_COLORS_DECLS
#define TG_LEGACY_ACCESSIBILITY_INVERT_COLORS_DECLS
#ifndef UIViewKeyframeAnimationOptionCalculationModeLinear
typedef NSUInteger UIViewKeyframeAnimationOptions;
#define UIViewKeyframeAnimationOptionCalculationModeLinear 0
#endif
@interface UIView (LegacyComponentsInvertColorsDeclarations)
@property (nonatomic) BOOL accessibilityIgnoresInvertColors;
+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay usingSpringWithDamping:(CGFloat)dampingRatio initialSpringVelocity:(CGFloat)velocity options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
+ (void)performWithoutAnimation:(void (^)(void))actionsWithoutAnimation;
+ (void)animateKeyframesWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewKeyframeAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
+ (void)addKeyframeWithRelativeStartTime:(double)frameStartTime relativeDuration:(double)frameDuration animations:(void (^)(void))animations;
@end
#endif


#ifndef TG_LEGACY_NSARRAY_FIRST_LAST_DECLS
#define TG_LEGACY_NSARRAY_FIRST_LAST_DECLS
@interface NSArray (LegacyComponentsFirstLastDeclarations)
@property (nonatomic, readonly) id firstObject;
@property (nonatomic, readonly) id lastObject;
@end
#endif





#ifndef TG_LEGACY_NSData_BASE64_DECLS
#define TG_LEGACY_NSData_BASE64_DECLS
typedef NSUInteger NSDataBase64DecodingOptions;
typedef NSUInteger NSDataBase64EncodingOptions;
#ifndef NSDataBase64DecodingIgnoreUnknownCharacters
#define NSDataBase64DecodingIgnoreUnknownCharacters 1
#endif
@interface NSData (LegacyComponentsBase64Declarations)
- (instancetype)initWithBase64EncodedString:(NSString *)base64String options:(NSDataBase64DecodingOptions)options;
- (instancetype)initWithBase64Encoding:(NSString *)base64String;
- (NSString *)base64Encoding;
@end
#endif

#ifndef TG_LEGACY_GALLERY_CONTROLLER_DECLS
#define TG_LEGACY_GALLERY_CONTROLLER_DECLS
typedef NSUInteger UIRectEdge;
#ifndef UIRectEdgeNone
#define UIRectEdgeNone 0
#define UIRectEdgeTop (1 << 0)
#define UIRectEdgeLeft (1 << 1)
#define UIRectEdgeBottom (1 << 2)
#define UIRectEdgeRight (1 << 3)
#define UIRectEdgeAll 15
#endif
#ifndef UIStatusBarStyleLightContent
#define UIStatusBarStyleLightContent ((UIStatusBarStyle)1)
#endif
#ifndef UIKeyInputLeftArrow
#define UIKeyInputLeftArrow @"UIKeyInputLeftArrow"
#define UIKeyInputRightArrow @"UIKeyInputRightArrow"
#define UIKeyInputEscape @"UIKeyInputEscape"
#endif
@interface UIAlertController : UIViewController
@end
typedef NSInteger UIAlertActionStyle;
#ifndef UIAlertActionStyleDefault
#define UIAlertActionStyleDefault 0
#define UIAlertActionStyleCancel 1
#define UIAlertActionStyleDestructive 2
#endif
@interface UIAlertAction : NSObject
+ (instancetype)actionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^)(UIAlertAction *action))handler;
@end

@interface UIViewController (LegacyComponentsStatusBarDeclarations)
- (BOOL)prefersStatusBarHidden;
- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures;
- (void)setNeedsStatusBarAppearanceUpdate;
- (void)setNeedsUpdateOfHomeIndicatorAutoHidden;
- (NSArray *)previewActionItems;
- (void)loadViewIfNeeded;
@end
#endif

#ifndef TG_LEGACY_COLLECTION_TRANSITION_DECLS
#define TG_LEGACY_COLLECTION_TRANSITION_DECLS
typedef void (^UICollectionViewLayoutInteractiveTransitionCompletion)(BOOL completed, BOOL finish);
typedef NSInteger UIScrollViewContentInsetAdjustmentBehavior;
#ifndef UIScrollViewContentInsetAdjustmentNever
#define UIScrollViewContentInsetAdjustmentNever 2
#endif
#ifndef UISemanticContentAttributeForceLeftToRight
#define UISemanticContentAttributeForceLeftToRight 3
#define UISemanticContentAttributeForceRightToLeft 4
#endif
@interface UICollectionViewTransitionLayout : UICollectionViewLayout
@property (nonatomic, readonly) UICollectionViewLayout *currentLayout;
@property (nonatomic, readonly) UICollectionViewLayout *nextLayout;
@property (nonatomic) CGFloat transitionProgress;
- (instancetype)initWithCurrentLayout:(UICollectionViewLayout *)currentLayout nextLayout:(UICollectionViewLayout *)newLayout;
@end
@interface UICollectionViewLayoutAttributes (LegacyComponentsBoundsDeclarations)
@property (nonatomic) CGRect bounds;
@end
@interface UICollectionView (LegacyComponentsTransitionDeclarations)
- (UICollectionViewTransitionLayout *)startInteractiveTransitionToCollectionViewLayout:(UICollectionViewLayout *)layout completion:(UICollectionViewLayoutInteractiveTransitionCompletion)completion;
- (void)finishInteractiveTransition;
@end
@interface UIScrollView (LegacyComponentsContentInsetAdjustmentDeclarations)
@property (nonatomic) UIScrollViewContentInsetAdjustmentBehavior contentInsetAdjustmentBehavior;
@end
@interface UIView (LegacyComponentsSemanticContentDeclarations)
@property (nonatomic, retain) UIColor *tintColor;
@property (nonatomic) UISemanticContentAttribute semanticContentAttribute;
@property (nonatomic, readonly) UIEdgeInsets safeAreaInsets;
@end
#endif

#ifndef TG_LEGACY_NSCHARACTERSET_URL_DECLS
#define TG_LEGACY_NSCHARACTERSET_URL_DECLS
@interface NSCharacterSet (TGLegacyURLCharacterSetDeclarations)
+ (NSCharacterSet *)URLQueryAllowedCharacterSet;
@end
#endif

#ifndef TG_LEGACY_NSSTRING_DRAWING_DECLS
#define TG_LEGACY_NSSTRING_DRAWING_DECLS
#ifndef NSStringDrawingUsesLineFragmentOrigin
#define NSStringDrawingUsesLineFragmentOrigin (1 << 0)
#define NSStringDrawingUsesFontLeading (1 << 1)
#define NSStringDrawingUsesDeviceMetrics (1 << 3)
#define NSStringDrawingTruncatesLastVisibleLine (1 << 5)
#endif
@interface NSString (LegacyComponentsDrawingDeclarations)
- (CGSize)sizeWithAttributes:(NSDictionary *)attrs;
- (void)drawAtPoint:(CGPoint)point withAttributes:(NSDictionary *)attrs;
- (void)drawWithRect:(CGRect)rect options:(NSInteger)options attributes:(NSDictionary *)attributes context:(id)context;
- (NSString *)stringByAddingPercentEncodingWithAllowedCharacters:(NSCharacterSet *)allowedCharacters;
- (CGRect)boundingRectWithSize:(CGSize)size options:(NSStringDrawingOptions)options attributes:(NSDictionary *)attributes context:(id)context;
@end
@interface NSAttributedString (LegacyComponentsDrawingDeclarations)
- (void)drawWithRect:(CGRect)rect options:(NSStringDrawingOptions)options context:(id)context;
- (CGRect)boundingRectWithSize:(CGSize)size options:(NSStringDrawingOptions)options context:(id)context;
- (CGRect)boundingRectWithSize:(CGSize)size options:(NSStringDrawingOptions)options attributes:(NSDictionary *)attributes context:(id)context;
@end
#endif



#ifndef TG_LEGACY_APP_DELEGATE_IOS8_DECLS
#define TG_LEGACY_APP_DELEGATE_IOS8_DECLS
typedef NSUInteger UIBackgroundFetchResult;
#ifndef UIBackgroundFetchResultNewData
#define UIBackgroundFetchResultNewData 0
#define UIBackgroundFetchResultNoData 1
#define UIBackgroundFetchResultFailed 2
#endif
@interface UIUserNotificationSettings : NSObject
@end
@interface UIApplication (TGLegacyRemoteNotificationDeclarations)
- (void)registerForRemoteNotifications;
@end
@interface UILocalNotification (TGLegacyCategoryDeclarations)
@property (nonatomic, copy) NSString *category;
@end
@interface NSUserDefaults (TGLegacySuiteDeclarations)
- (instancetype)initWithSuiteName:(NSString *)suiteName;
@end
@interface NSFileManager (TGLegacySecurityApplicationGroupDeclarations)
- (NSURL *)containerURLForSecurityApplicationGroupIdentifier:(NSString *)groupIdentifier;
@end
#ifndef UIApplicationOpenURLOptionsSourceApplicationKey
#define UIApplicationOpenURLOptionsSourceApplicationKey UIApplicationLaunchOptionsSourceApplicationKey
#endif
#endif

#ifndef TG_LEGACY_POPOVER_PRESENTATION_DECLS
#define TG_LEGACY_POPOVER_PRESENTATION_DECLS
@class UIPopoverPresentationController;
@protocol UIPopoverPresentationControllerDelegate <NSObject>
@optional
- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view;
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController;
@end
@interface UIPopoverPresentationController : NSObject
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, assign) id<UIPopoverPresentationControllerDelegate> delegate;
@property (nonatomic) UIPopoverArrowDirection permittedArrowDirections;
@property (nonatomic, retain) UIBarButtonItem *barButtonItem;
@property (nonatomic, retain) UIView *sourceView;
@property (nonatomic) CGRect sourceRect;
@end
@interface UIViewController (LegacyComponentsPopoverPresentationDeclarations)
@property (nonatomic, readonly) UIPopoverPresentationController *popoverPresentationController;
@end
@interface UIPopoverController (LegacyComponentsPopoverBackgroundDeclarations)
@property (nonatomic, retain) UIColor *backgroundColor;
@end
#endif


#ifndef TG_LEGACY_MORE_UIKIT_DECLS_FROM_PCH
#define TG_LEGACY_MORE_UIKIT_DECLS_FROM_PCH
@interface UIActivityViewController (TGLegacyPopoverDeclarations)
@property (nonatomic, readonly) UIPopoverPresentationController *popoverPresentationController;
@end
@interface UITableView (TGLegacySeparatorInsetDeclarations)
@property (nonatomic) UIEdgeInsets separatorInset;
@end
@interface UIViewController (TGLegacyScrollInsetDeclarations)
- (void)setAutomaticallyAdjustsScrollViewInsets:(BOOL)value;
@end
@interface NSObject (TGLegacyTextContainerInsetDeclarations)
- (UIEdgeInsets)textContainerInset;
- (void)setTextContainerInset:(UIEdgeInsets)inset;
@end
#endif

#ifndef kCLAuthorizationStatusAuthorizedWhenInUse
#define kCLAuthorizationStatusAuthorizedWhenInUse kCLAuthorizationStatusAuthorized
#endif
#ifndef kCLAuthorizationStatusAuthorizedAlways
#define kCLAuthorizationStatusAuthorizedAlways kCLAuthorizationStatusAuthorized
#endif

#ifndef UIApplicationUserDidTakeScreenshotNotification
#define UIApplicationUserDidTakeScreenshotNotification @"UIApplicationUserDidTakeScreenshotNotification"
#endif

#ifndef TG_TIMESTAMP_DEFINE
#define TG_TIMESTAMP_DEFINE(s)
#endif
#ifndef TG_TIMESTAMP_MEASURE
#define TG_TIMESTAMP_MEASURE(s)
#endif

#ifndef TG_LEGACY_AV_DECLS
#define TG_LEGACY_AV_DECLS
typedef NSInteger AVAuthorizationStatus;
#ifndef AVAuthorizationStatusNotDetermined
#define AVAuthorizationStatusNotDetermined 0
#define AVAuthorizationStatusRestricted 1
#define AVAuthorizationStatusDenied 2
#define AVAuthorizationStatusAuthorized 3
#endif
@interface AVPlayer (LegacyComponentsMutedDeclarations)
@property (nonatomic, getter=isMuted) BOOL muted;
@end
@interface AVCaptureDevice (LegacyComponentsAuthorizationDeclarations)
+ (AVAuthorizationStatus)authorizationStatusForMediaType:(NSString *)mediaType;
+ (void)requestAccessForMediaType:(NSString *)mediaType completionHandler:(void (^)(BOOL granted))handler;
@end
@interface AVAudioSession (LegacyComponentsRecordPermissionDeclarations)
- (void)requestRecordPermission:(void (^)(BOOL granted))response;
@end
#endif

#ifndef AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps
typedef NSInteger AVCaptureSessionInterruptionReason;
#define AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps 1
#define AVCaptureSessionInterruptionReasonKey @"AVCaptureSessionInterruptionReasonKey"
#endif

#endif
#endif
