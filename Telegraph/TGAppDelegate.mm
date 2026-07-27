#import "TGAppDelegate.h"

#import <unistd.h>
#import <sys/utsname.h>
#import <QuartzCore/QuartzCore.h>
#include <stdlib.h>

#ifndef IOS6_NOOP_LOG
#define IOS6_NOOP_LOG(...) do { } while (0)
#endif

#import "../config.h"
#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGLegacyComponentsGlobalsProvider.h"
#import "TGNavigationBarMusicPlayerProvider.h"
#import "TGRemoteControlsManager.h"

#import "TGCommon.h"
#import "IOS6NotificationProbe.h"
#import "TGApplyUpdatesActor.h"
#import "TGPresentation.h"

@implementation NSArray (TGIOS6FirstObject)

- (id)firstObject
{
    return self.count == 0 ? nil : [self objectAtIndex:0];
}

@end

static NSString *TGIOS6PerfDeviceModel()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [[NSString alloc] initWithUTF8String:systemInfo.machine] ?: @"?";
}

static NSString *TGIOS6PerfDeviceMarketingName(NSString *machine)
{
    static NSDictionary *names = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        names = @{
            @"iPhone3,1": @"iPhone 4", @"iPhone3,2": @"iPhone 4", @"iPhone3,3": @"iPhone 4",
            @"iPhone4,1": @"iPhone 4S",
            @"iPhone5,1": @"iPhone 5", @"iPhone5,2": @"iPhone 5",
            @"iPhone5,3": @"iPhone 5c", @"iPhone5,4": @"iPhone 5c",
            @"iPhone6,1": @"iPhone 5s", @"iPhone6,2": @"iPhone 5s",
            @"iPad2,1": @"iPad 2", @"iPad2,2": @"iPad 2", @"iPad2,3": @"iPad 2", @"iPad2,4": @"iPad 2",
            @"iPad2,5": @"iPad mini", @"iPad2,6": @"iPad mini", @"iPad2,7": @"iPad mini",
            @"iPad3,1": @"iPad 3", @"iPad3,2": @"iPad 3", @"iPad3,3": @"iPad 3",
            @"iPad3,4": @"iPad 4", @"iPad3,5": @"iPad 4", @"iPad3,6": @"iPad 4",
            @"iPod5,1": @"iPod touch 5"
        };
    });
    NSString *name = [names objectForKey:machine];
    return name ?: machine ?: @"?";
}

static NSString *TGIOS6PerfDeviceDescription()
{
    NSString *machine = TGIOS6PerfDeviceModel();
    NSString *name = TGIOS6PerfDeviceMarketingName(machine);
    if ([name isEqualToString:machine])
        return machine;
    return [NSString stringWithFormat:@"%@ (%@)", name, machine];
}

static NSString *TGIOS6BotContext()
{
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?";
    NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"?";
    UIDevice *device = [UIDevice currentDevice];
    NSString *idiom = device.userInterfaceIdiom == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone";
    return [NSString stringWithFormat:@"version=%@ build=%@ os=%@ %@ idiom=%@ device=%@", version, build, device.systemName, device.systemVersion, idiom, TGIOS6PerfDeviceDescription()];
}

static bool TGIOS6PerfLoggingEnabled()
{
    return false;
}

// Temporary diagnostic bypass: notification preferences must not stop the
// iOS 6 background MTProto transport while background delivery is tested.
static const bool TGIOS6NotificationSettingsGateEnabled = false;

NSString *const TGIOS6BackgroundNotificationsEnabledKey = @"TGIOS6BackgroundNotificationsEnabled";
NSString *const TGIOS6APNsNotificationsEnabledKey = @"TGIOS6APNsNotificationsEnabled";

bool TGIOS6BackgroundNotificationsEnabled(void)
{
    id storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:TGIOS6BackgroundNotificationsEnabledKey];
    return storedValue == nil ? true : [storedValue boolValue];
}

bool TGIOS6APNsNotificationsEnabled(void)
{
    id storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:TGIOS6APNsNotificationsEnabledKey];
    // APNs is opt-in because a public build has no notification infrastructure.
    return storedValue == nil ? false : [storedValue boolValue];
}

static void TGIOS6PerfLogAppStart()
{
    if (!TGIOS6PerfLoggingEnabled())
        return;

    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?";
    NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"?";
    UIDevice *device = [UIDevice currentDevice];
    UIScreen *screen = [UIScreen mainScreen];
    CGSize screenSize = screen.bounds.size;
    NSString *idiom = device.userInterfaceIdiom == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone";
    while (false) NSLog(@"IOS6PERF appStart version=%@ build=%@ idiom=%@ model=%@ system=%@ %@ screen=%.0fx%.0f scale=%.1f", version, build, idiom, TGIOS6PerfDeviceDescription(), device.systemName, device.systemVersion, screenSize.width, screenSize.height, screen.scale);
}

static NSString *TGIOS6TrimVersionString(NSString *string)
{
    if (![string isKindOfClass:[NSString class]])
        return nil;
    
    NSString *trimmed = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0)
        return nil;
    
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
    NSRange badRange = [trimmed rangeOfCharacterFromSet:[allowed invertedSet]];
    if (badRange.location != NSNotFound)
        trimmed = [trimmed substringToIndex:badRange.location];
    
    return trimmed.length == 0 ? nil : trimmed;
}

static double TGIOS6VersionNumber(NSString *version)
{
    NSString *cleanVersion = TGIOS6TrimVersionString(version);
    if (cleanVersion.length == 0)
        return 0.0;
    return [cleanVersion doubleValue];
}

static bool TGIOS6ShouldExitForRemoteMinimumVersion()
{
    // Public source does not contact a private version-control endpoint.
    return false;
}

@interface TGIOS6MainThreadWatchdog : NSObject
{
    CADisplayLink *_displayLink;
    CFTimeInterval _lastTimestamp;
    CFTimeInterval _lastReport;
}
@end

@implementation TGIOS6MainThreadWatchdog

+ (instancetype)sharedWatchdog
{
    static TGIOS6MainThreadWatchdog *watchdog = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        watchdog = [[TGIOS6MainThreadWatchdog alloc] init];
    });
    return watchdog;
}

- (void)start
{
    if (_displayLink != nil)
        return;
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)tick:(CADisplayLink *)displayLink
{
    CFTimeInterval timestamp = displayLink.timestamp;
    if (_lastTimestamp > 0.0)
    {
        CFTimeInterval gap = timestamp - _lastTimestamp;
        CFTimeInterval now = CFAbsoluteTimeGetCurrent();
        if (gap > 0.75 && now - _lastReport > 20.0)
        {
            _lastReport = now;
            NSString *topController = @"?";
            @try
            {
                UIViewController *controller = TGAppDelegateInstance.rootController.presentedViewController ?: TGAppDelegateInstance.rootController.viewControllers.lastObject;
                topController = NSStringFromClass([controller class]) ?: @"?";
            }
            @catch (__unused NSException *exception)
            {
            }
            while (false) NSLog(@"IOS6HANG main_thread_stall %@ gap_ms=%.1f top=%@", TGIOS6BotContext(), gap * 1000.0, topController);
        }
    }
    _lastTimestamp = timestamp;
}

@end

#import "TGTelegraph.h"
#import "TGTelegramNetworking.h"

#import "../submodules/MtProtoKit/MTProtoKit/MTProtoKit.h"

#import "TGUserDefaults.h"
#import "TGDatabase.h"
#import "TGMessage+Telegraph.h"

#import "TGInterfaceManager.h"
#import "TGInterfaceAssets.h"

#import "TGSchema.h"
#import "TLRPCping.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGImageManager.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGCache.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGRemoteImageView.h"

#import "TGTelegraphDialogListCompanion.h"

#import "../submodules/LegacyComponents/LegacyComponents/SGraphListNode.h"
#import "TGImageDownloadActor.h"

#import "TGTelegraphConversationMessageAssetsSource.h"
#import "TGReusableLabel.h"

#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>
#import <ImageIO/ImageIO.h>

#import "RMIntroViewController.h"

#import "TGLoginPhoneController.h"
#import "TGLoginCodeController.h"
#import "TGLoginProfileController.h"

#import "TGApplication.h"

#import "TGPasscodeWindow.h"

#import "TGContentViewController.h"

#import "TGModernConversationController.h"
#import "TGGenericModernConversationCompanion.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGModernGalleryController.h"

#import "TGSecretModernConversationCompanion.h"

#import "TGForwardTargetController.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGTimerTarget.h"

#import "TGCustomAlertView.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGModernGalleryModel.h"

#import "TGConversationAddMessagesActor.h"

#import <pthread.h>
#import <mach/mach.h>

#import <objc/runtime.h>

static bool TGClassicIOS6NativeNavigationImageName(NSString *name)
{
    NSString *stem = [[name lastPathComponent] stringByDeletingPathExtension];
    return [stem hasPrefix:@"BackButton"] || [stem hasPrefix:@"HeaderButton"] || [stem hasPrefix:@"MenuButton"] || [stem hasPrefix:@"ActionMenuButton"];
}

static UIImage *TGClassicIOS6OriginalImageNamed(NSString *name)
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"TGClassicIOS6Style"] || name.length == 0 || TGClassicIOS6NativeNavigationImageName(name))
        return nil;

    static NSMutableDictionary *imageCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        imageCache = [[NSMutableDictionary alloc] init];
    });

    NSString *component = [name lastPathComponent];
    NSString *extension = component.pathExtension.length == 0 ? @"png" : component.pathExtension;
    NSString *stem = [component stringByDeletingPathExtension];
    bool hasExplicitScale = [stem rangeOfString:@"@2x"].location != NSNotFound || [stem rangeOfString:@"@3x"].location != NSNotFound;
    NSString *resourceName = hasExplicitScale ? stem : ([UIScreen mainScreen].scale > 1.5f ? [stem stringByAppendingFormat:@"%c2x", 64] : stem);
    NSString *path = [[NSBundle mainBundle] pathForResource:resourceName ofType:extension inDirectory:@"ClassicIOS6"];
    if (path.length == 0 && !hasExplicitScale)
    {
        resourceName = [stem stringByAppendingFormat:@"%c2x", 64];
        path = [[NSBundle mainBundle] pathForResource:resourceName ofType:extension inDirectory:@"ClassicIOS6"];
    }
    if (path.length == 0)
        return nil;

    UIImage *image = imageCache[path];
    if (image == nil)
    {
        image = [UIImage imageWithContentsOfFile:path];
        if (image != nil && [resourceName rangeOfString:@"@2x"].location != NSNotFound && image.CGImage != NULL)
            image = [UIImage imageWithCGImage:image.CGImage scale:2.0f orientation:UIImageOrientationUp];
        if (image != nil)
            imageCache[path] = image;
    }
    return image;
}

@interface UIImage (TwelviumClassicIOS6Resources)

@end
@implementation UIImage (TwelviumClassicIOS6Resources)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        Method original = class_getClassMethod(self, @selector(imageNamed:));
        Method replacement = class_getClassMethod(self, @selector(twelvium_classicIOS6ImageNamed:));
        method_exchangeImplementations(original, replacement);
    });
}

+ (UIImage *)twelvium_classicIOS6ImageNamed:(NSString *)name
{
    UIImage *classicImage = TGClassicIOS6OriginalImageNamed(name);
    return classicImage != nil ? classicImage : [self twelvium_classicIOS6ImageNamed:name];
}

@end

#import <AVFoundation/AVFoundation.h>

#include <inttypes.h>

#import "../submodules/LegacyComponents/LegacyComponents/TGProgressWindow.h"

#import "TGPasscodeSettingsController.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGPasscodeEntryController.h"

#import "TGDropboxHelper.h"

#import "TGStickersSignals.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
#import <LocalAuthentication/LocalAuthentication.h>
#endif

#import "TGStickerPackPreviewWindow.h"

#import "TGBotSignals.h"

#import "TGBridgeServer.h"
#import "TGBridgeRemoteHandler.h"

#import "TGAccountSignals.h"
#import "TGServiceSignals.h"
#import "TGPushActionsRequestBuilder.h"

#import "TGGroupManagementSignals.h"
#import "TGChannelManagementSignals.h"

#import "TGSendMessageSignals.h"
#import "TGChatMessageListSignal.h"

#import "TGAudioSessionManager.h"

#import "TGApplicationMainWindow.h"

#import "TGRootController.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
#import <CoreSpotlight/CoreSpotlight.h>
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
#import <ContactsUI/ContactsUI.h>
#endif

#import "TGRecentPeersSignals.h"
#import "TGGlobalMessageSearchSignals.h"
#import "TGDialogListRecentPeers.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGKeyCommandController.h"
#import "TGEmbedPIPController.h"

#import "TGStickersMenu.h"
#import "TGProxyMenu.h"

#import "TGGroupInviteSheet.h"

#import "TGLoginResetAccountProtectedController.h"
#import "TGCancelAccountResetController.h"
#import "TGHashtagOverviewController.h"

#import "TGMediaSignals.h"

#import "UIImage+ImageEffects.h"
#import "TGUpdateConfigActor.h"

#import "TGWebAppController.h"
#import "TGPassportRequestController.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
#import <Intents/Intents.h>
#endif
#import "../submodules/LegacyComponents/Pushkit/Pushkit.h"

#import "TGWebpageSignals.h"
#import "TGInstantPageController.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGCameraController.h"

#import "TGMessageUniqueIdContentProperty.h"

#import "TGCameraController+Shortcut.h"

#import "TGLegacyComponentsContext.h"

#import "TGGDPRNoticeController.h"
#import "TGUpdateAppController.h"

#import "TGPresentation.h"
#import "TGPassportSignals.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
#import <CloudKit/CloudKit.h>
#endif
#import "TGICloudEmergencyDataSignals.h"

NSString *TGDeviceProximityStateChangedNotification = @"TGDeviceProximityStateChangedNotification";

CFAbsoluteTime applicationStartupTimestamp = 0;
CFAbsoluteTime mainLaunchTimestamp = 0;

TGAppDelegate *TGAppDelegateInstance = nil;
TGTelegraph *telegraph = nil;

static NSString *TGIOS6CrashReportEndpoint()
{
    return @"";
}

static NSString *TGIOS6CrashReportSecret()
{
    return @"";
}

static NSString *TGIOS6CrashReportPath()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
    NSString *documentsPath = paths.count == 0 ? NSTemporaryDirectory() : [paths objectAtIndex:0];
    return [documentsPath stringByAppendingPathComponent:@"ios6_last_crash.txt"];
}

static NSString *TGIOS6SystemCrashMarkerPath()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
    NSString *documentsPath = paths.count == 0 ? NSTemporaryDirectory() : [paths objectAtIndex:0];
    return [documentsPath stringByAppendingPathComponent:@"ios6_last_system_crash.txt"];
}

static NSString *TGIOS6CrashEscape(NSString *string)
{
    if (string == nil)
        return @"";
    NSString *escaped = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
    return escaped;
}

static NSString *TGIOS6CrashNormalizedMessage(NSString *message)
{
    if (message.length == 0)
        return @"";
    NSError *regexError = nil;
    NSRegularExpression *longPointerRegex = [NSRegularExpression regularExpressionWithPattern:@"0x[0-9a-fA-F]{9,}" options:0 error:&regexError];
    if (longPointerRegex == nil)
        return message;
    return [longPointerRegex stringByReplacingMatchesInString:message options:0 range:NSMakeRange(0, message.length) withTemplate:@"0xADDR"];
}

static void TGIOS6UncaughtExceptionHandler(NSException *exception)
{
    NSString *stack = [[exception callStackSymbols] componentsJoinedByString:@"\n"];
    NSString *message = [NSString stringWithFormat:@"name=%@\nreason=%@\nstack=%@",
        exception.name ?: @"",
        exception.reason ?: @"",
        stack ?: @""];
    [message writeToFile:TGIOS6CrashReportPath() atomically:true encoding:NSUTF8StringEncoding error:nil];
}

static void TGIOS6InstallCrashReporter()
{
    // Private crash collection is disabled in the public source build.
}

static void TGIOS6OpenNotificationPeer(int64_t peerId)
{
    if (peerId != 0 && [TGDatabaseInstance() loadConversationWithId:peerId] != nil)
        [[TGInterfaceManager instance] navigateToConversationWithId:peerId conversation:nil performActions:nil atMessage:nil clearStack:true openKeyboard:false canOpenKeyboardWhileInTransition:false animated:false];
}

static void TGIOS6SendPendingCrashReport()
{
    // Private crash uploads are disabled in the public source build.
    return;

    NSString *path = TGIOS6CrashReportPath();
    NSString *message = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (message.length == 0)
        return;
    
    NSString *messageWithContext = [NSString stringWithFormat:@"%@\n%@", TGIOS6BotContext(), TGIOS6CrashNormalizedMessage(message)];
    NSString *bodyString = [NSString stringWithFormat:@"secret=%@&event=%@&message=%@",
        TGIOS6CrashEscape(TGIOS6CrashReportSecret()),
        TGIOS6CrashEscape(@"client_crash"),
        TGIOS6CrashEscape(messageWithContext)];
    NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:TGIOS6CrashReportEndpoint()];
    if (body == nil || url == nil)
        return;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        NSHTTPURLResponse *httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        NSString *responseBody = data.length == 0 ? @"" : [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        TGLog(@"IOS6CRASH report status=%d error=%@ body=%@", httpResponse != nil ? (int)httpResponse.statusCode : 0, connectionError, responseBody);
        if (connectionError == nil && httpResponse.statusCode >= 200 && httpResponse.statusCode < 300)
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }];
}

static void TGIOS6SendLatestSystemCrashReport()
{
    // Private crash uploads are disabled in the public source build.
    return;

    NSString *directory = @"/var/mobile/Library/Logs/CrashReporter";
    NSArray *entries = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
    if (entries.count == 0)
        return;

    NSString *lastSentName = [NSString stringWithContentsOfFile:TGIOS6SystemCrashMarkerPath() encoding:NSUTF8StringEncoding error:nil];
    NSString *latestName = nil;
    NSDate *latestDate = nil;
    for (NSString *name in entries)
    {
        NSString *extension = [[name pathExtension] lowercaseString];
        if (![name hasPrefix:@"Telegram"] || (![@"ips" isEqualToString:extension] && ![@"crash" isEqualToString:extension]))
            continue;

        NSString *path = [directory stringByAppendingPathComponent:name];
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        NSDate *date = [attributes objectForKey:NSFileModificationDate];
        if (date != nil && (latestDate == nil || [date compare:latestDate] == NSOrderedDescending))
        {
            latestDate = date;
            latestName = name;
        }
    }

    if (latestName.length == 0 || [latestName isEqualToString:lastSentName])
        return;

    NSString *path = [directory stringByAppendingPathComponent:latestName];
    NSString *report = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (report.length == 0)
        return;
    if ([report rangeOfString:@"com.example.LegacyGram"].location == NSNotFound)
        return;

    NSString *currentBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *jsonBuild = [NSString stringWithFormat:@"\"build_version\":\"%@\"", currentBuild ?: @""];
    NSString *jsonVersion = [NSString stringWithFormat:@"\"app_version\":\"%@\"", currentVersion ?: @""];
    NSString *legacyVersion = [NSString stringWithFormat:@"%@ (%@)", currentBuild ?: @"", currentVersion ?: @""];
    BOOL currentJSONReport = [report rangeOfString:jsonBuild].location != NSNotFound &&
        [report rangeOfString:jsonVersion].location != NSNotFound;
    BOOL currentLegacyReport = [report rangeOfString:legacyVersion].location != NSNotFound;
    if (!currentJSONReport && !currentLegacyReport)
    {
        // Do not label an old system crash as belonging to the newly installed
        // build. Remember it so it is not reopened on every launch.
        [latestName writeToFile:TGIOS6SystemCrashMarkerPath() atomically:true encoding:NSUTF8StringEncoding error:nil];
        return;
    }

    NSString *message = [NSString stringWithFormat:@"%@\nsystem_report=%@\n\n%@", TGIOS6BotContext(), latestName, report];
    NSString *bodyString = [NSString stringWithFormat:@"secret=%@&event=%@&message=%@",
        TGIOS6CrashEscape(TGIOS6CrashReportSecret()),
        TGIOS6CrashEscape(@"client_crash_full"),
        TGIOS6CrashEscape(message)];
    NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:TGIOS6CrashReportEndpoint()];
    if (body == nil || url == nil)
        return;

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15.0];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        NSHTTPURLResponse *httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        if (connectionError == nil && httpResponse.statusCode >= 200 && httpResponse.statusCode < 300)
            [latestName writeToFile:TGIOS6SystemCrashMarkerPath() atomically:true encoding:NSUTF8StringEncoding error:nil];
        else
            TGLog(@"IOS6CRASH full report status=%d error=%@", httpResponse != nil ? (int)httpResponse.statusCode : 0, connectionError);
    }];
}

@interface CMGestureManager : NSObject {
    id _internal;
}

@property (copy) void(^gestureHandler)(int a, int b);

+ (BOOL)isGestureServiceAvailable;
+ (BOOL)isGestureServiceEnabled;
+ (void)setGestureServiceEnabled:(BOOL)arg1;

- (void)dealloc;
- (id /* block */)gestureHandler;
- (id)init;
- (id)initWithPriority:(int)arg1;
- (void)setGestureHandler:(void(^)(int a, int b))arg1;

@end

@interface TGAppDelegate () <AVAudioPlayerDelegate, PKPushRegistryDelegate>
{
    bool _inBackground;
    bool _enteringForeground;
    
    NSTimer *_foregroundResumeTimer;
    
    TGProgressWindow *_progressWindow;
    
    bool _didBecomeInactive;
    
    TGPasscodeWindow *_passcodeWindow;
    UIWindow *_blurredContentWindow;
    
    SMetaDisposable *_deviceLockedRequestDisposable;
    bool _didUpdateDeviceLocked;
    
    TGUser *_currentInviteBot;
    NSString *_currentInviteBotPayload;
    
    TGUser *_currentStartGameBot;
    NSString *_currentStartGame;
    
    SMetaDisposable *_recentPeersDisposable;
    SMetaDisposable *_termsOfServiceDisposable;

    // iOS 6 serverless background notification transport health check.
    // This is deliberately limited to one lightweight request at a time and
    // never runs while the app is visible.
    SMetaDisposable *_ios6VoipHealthCheckDisposable;
    int32_t _ios6VoipHealthCheckGeneration;
    int32_t _ios6VoipHealthCheckAttempt;
    bool _ios6VoipHealthCheckPending;
    CFAbsoluteTime _ios6VoipLastTransportResetTime;
    CFAbsoluteTime _ios6VoipLastProactiveTransportRefreshTime;
    int32_t _ios6VoipLastPrimaryReceiveUptime;
    UIBackgroundTaskIdentifier _ios6VoipHealthCheckTaskIdentifier;
    bool _ios6VoipHealthCheckTaskActive;
    bool _ios6NotificationTransportAllowedForBackgroundSession;
    UIBackgroundTaskIdentifier _ios6ColdLaunchTaskIdentifier;
    bool _ios6ColdLaunchTaskActive;
    
    TGGroupInviteSheet *_groupInviteSheet;
    
    SVariable *_finishedLaunching;
    SVariable *_isActive;
    
    PKPushRegistry *_pushRegistry;
    SPipe *_localizationUpdatedPipe;
    SPipe *_statusBarPressedPipe;
}

@property (nonatomic) bool tokenAlreadyRequested;
@property (nonatomic) NSData *pushToken;
@property (nonatomic, strong) id<TGDeviceTokenListener> deviceTokenListener;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic, strong) NSTimer *backgroundTaskExpirationTimer;

@property (nonatomic, strong) NSMutableDictionary *loadedSoundSamples;

@property (nonatomic, strong) UIWebView *callingWebView;

@property (nonatomic, strong) AVAudioPlayer *currentAudioPlayer;
@property (nonatomic, strong) SMetaDisposable *currentAudioPlayerSession;


+ (void)movePathsToContainer;
+ (NSString *)documentsPath;
+ (NSString *)cachePath;

- (void)loadShowCallsTab;
- (void)_replyActionForPeerId:(int64_t)peerId mid:(int32_t)mid openKeyboard:(bool)openKeyboard responseInfo:(NSDictionary *)responseInfo completion:(void (^)())completion;
- (void)onBecomeInactive;
- (void)onBecomeActive;
- (bool)willBeLocked;
- (NSTimeInterval)ios6VoipHealthCheckInterval;
- (void)ios6PrimaryTransportReceivedData:(NSNotification *)notification;
- (bool)ios6NotificationTransportAllowedWithSystemTypes:(UIRemoteNotificationType *)systemTypes privateEnabled:(bool *)privateEnabled groupEnabled:(bool *)groupEnabled;
- (BOOL)ios6InstallVoipKeepAliveForApplication:(UIApplication *)application source:(NSString *)source;
- (void)ios6StopNotificationTransport;
- (void)ios6EndColdLaunchTask;
- (void)ios6EndVoipHealthCheckTask;
- (void)ios6StartVoipHealthProbe:(int32_t)generation attempt:(int32_t)attempt timeout:(NSTimeInterval)timeout;
- (void)ios6FinishVoipHealthCheck:(int32_t)generation attempt:(int32_t)attempt success:(bool)success reason:(NSString *)reason;
- (void)disableAPNsNotificationRegistration;

@property (nonatomic, strong) void (^onSuccessfulAuthorization)(void);

@property (nonatomic, strong) void (^onSuccessfulLogin)(void);

@end

@implementation TGAppDelegate

static NSString *TGAppDelegateDocumentsPathCompat()
{
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
        path = paths.count == 0 ? NSTemporaryDirectory() : [paths objectAtIndex:0];
    });
    
    return path;
}

static NSUserDefaults *TGAppDelegateUserDefaultsCompat()
{
    return [NSUserDefaults standardUserDefaults];
}

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        [[TGBridgeServer instanceSignal] startWithNext:nil];
        _localizationUpdatedPipe = [[SPipe alloc] init];
        _localizationUpdated = _localizationUpdatedPipe.signalProducer();
        _statusBarPressedPipe = [[SPipe alloc] init];
        _statusBarPressed = _statusBarPressedPipe.signalProducer();
        _finishedLaunching = [[SVariable alloc] init];
        _isActive = [[SVariable alloc] init];
        [_isActive set:[SSignal single:@true]];
        _ios6VoipHealthCheckTaskIdentifier = UIBackgroundTaskInvalid;
        _ios6ColdLaunchTaskIdentifier = UIBackgroundTaskInvalid;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ios6PrimaryTransportReceivedData:) name:@"TGIOS6PrimaryTransportReceivedData" object:nil];
    }
    return self;
}

- (TGNavigationController *)loginNavigationController
{
    if (_loginNavigationController == nil)
    {
        UIViewController *rootController = nil;
    
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleIdentifier isEqualToString:@"com.example.LegacyGram"]) {
            rootController = [[TGLoginPhoneController alloc] init];
        } else {
            rootController = [[RMIntroViewController alloc] init];
        }
        
        _loginNavigationController = [TGNavigationController navigationControllerWithControllers:@[rootController] navigationBarClass:[TGTransparentNavigationBar class] inhibitPresentation:true];
        _loginNavigationController.restrictLandscape = !TGIsPad();
        _loginNavigationController.disableInteractiveKeyboardTransition = true;
    }
    
    return _loginNavigationController;
}

static void overridenDrawRect(__unused id self, __unused SEL _cmd, __unused CGRect rect)
{
}

static unsigned int overrideIndexAbove(__unused id self, __unused SEL _cmd)
{
    return [(TGNavigationBar *)self indexAboveBackdropBackground];
}

- (bool)enableLogging
{
    NSNumber *logsEnabled = [[NSUserDefaults standardUserDefaults] objectForKey:@"__logsEnabled"];
    // INTERNAL_RELEASE used to enable verbose console and file logging by
    // default. Keep it opt-in on old devices; critical reports use their own
    // sender and are not affected by this switch.
    return [logsEnabled boolValue];
}

- (void)setEnableLogging:(bool)enableLogging
{
    [[NSUserDefaults standardUserDefaults] setObject:@(enableLogging) forKey:@"__logsEnabled"];
    TGLogSetEnabled(enableLogging);
}

- (UIResponder *)nextResponder
{
    if (_keyCommandController != nil)
        return _keyCommandController;
    else
        return [super nextResponder];
}

//static void reportMemoryUsage() {
//    struct task_basic_info info;
//    mach_msg_type_number_t size = sizeof(info);
//    kern_return_t kerr = task_info(mach_task_self(),
//                                   TASK_BASIC_INFO,
//                                   (task_info_t)&info,
//                                   &size);
//    if( kerr == KERN_SUCCESS ) {
//        TGLog(@"Memory in use (in MB): %f", ((CGFloat)info.resident_size / 1000000));
//    }
//}

+ (NSUserDefaults *)userDefaults
{
    static dispatch_once_t onceToken;
    static NSUserDefaults *userDefaults;
    dispatch_once(&onceToken, ^
    {
        if (iosMajorVersion() >= 8)
        {
            userDefaults = [self _containerDefaults];
            [self movePasscodeAttemptsToContainer];
        }
        else
        {
            userDefaults = [NSUserDefaults standardUserDefaults];;
        }
    });
    return userDefaults;
}

+ (NSUserDefaults *)_containerDefaults
{
    return [[NSUserDefaults alloc] initWithSuiteName:[@"group." stringByAppendingString:[[NSBundle mainBundle] bundleIdentifier]]];
}

+ (void)movePasscodeAttemptsToContainer
{
    if (iosMajorVersion() < 8)
        return;
    
    NSUserDefaults *localDefaults = [NSUserDefaults standardUserDefaults];
    NSUserDefaults *containerDefaults = [self _containerDefaults];
    
    NSNumber *attempts = [localDefaults objectForKey:@"Passcode_invalidAttempts"];
    if (attempts != nil)
    {
        [containerDefaults setObject:attempts forKey:@"Passcode_invalidAttempts"];
        
        NSNumber *attemptDate = [localDefaults objectForKey:@"Passcode_invalidAttemptDate"];
        if (attemptDate != nil)
            [containerDefaults setObject:attemptDate forKey:@"Passcode_invalidAttemptDate"];
        [containerDefaults synchronize];
    
        [localDefaults removeObjectForKey:@"Passcode_invalidAttempts"];
        [localDefaults removeObjectForKey:@"Passcode_invalidAttemptDate"];
        [localDefaults synchronize];
    }
}

#define PGTick   NSDate *startTime = [NSDate date]
#define PGTock   NSLog(@"!=========== %s Time: %f", __func__, -[startTime timeIntervalSinceNow])

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    bool ios6ColdBackgroundApplicationLaunch = [[UIDevice currentDevice].systemVersion intValue] <= 6 && application.applicationState == UIApplicationStateBackground;
    bool ios6ColdBackgroundLaunch = ios6ColdBackgroundApplicationLaunch && TGIOS6BackgroundNotificationsEnabled();
    if (ios6ColdBackgroundApplicationLaunch && !ios6ColdBackgroundLaunch)
    {
        _inBackground = true;
        _ios6NotificationTransportAllowedForBackgroundSession = false;
        [application clearKeepAliveTimeout];
    }
    if (ios6ColdBackgroundLaunch)
    {
        // UIKit does not persist a legacy VoIP keep-alive handler across
        // process termination.  Reinstall a provisional handler before the
        // asynchronous Telegram bootstrap starts, otherwise iOS can suspend a
        // cold background relaunch before MTProto is created.
        _inBackground = true;
        _ios6NotificationTransportAllowedForBackgroundSession = true;

        __block UIBackgroundTaskIdentifier coldLaunchTaskIdentifier = UIBackgroundTaskInvalid;
        coldLaunchTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^
        {
            IOS6NotificationProbe(@"LEASE", @"cold_launch_expiration id=%d", (int)coldLaunchTaskIdentifier);
            if ([NSThread isMainThread])
                [self ios6EndColdLaunchTask];
            else
                dispatch_async(dispatch_get_main_queue(), ^{ [self ios6EndColdLaunchTask]; });
        }];
        if (coldLaunchTaskIdentifier != UIBackgroundTaskInvalid)
        {
            _ios6ColdLaunchTaskIdentifier = coldLaunchTaskIdentifier;
            _ios6ColdLaunchTaskActive = true;
        }

        BOOL provisionalKeepAliveInstalled = [application setKeepAliveTimeout:600.0 handler:^
        {
            void (^wakeBlock)(void) = ^
            {
                if (_inBackground && [UIApplication sharedApplication].applicationState != UIApplicationStateActive)
                    [self ios6PerformVoipHealthCheck];
            };
            if ([NSThread isMainThread])
                wakeBlock();
            else
                dispatch_async(dispatch_get_main_queue(), wakeBlock);
        }];
        IOS6NotificationProbe(@"LIFECYCLE", @"cold_launch_guard task=%d keepAlive=%d remaining=%.1f",
                              (int)coldLaunchTaskIdentifier, provisionalKeepAliveInstalled ? 1 : 0,
                              application.backgroundTimeRemaining);
    }

    TGIOS6InstallCrashReporter();
    if (TGIOS6ShouldExitForRemoteMinimumVersion())
        _exit(0);
    
    //PGTick;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    if (iosMajorVersion() >= 9) {
        if ([effectiveLocalization().code isEqualToString:@"ar"]) {
            [UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        } else {
            [UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
    }
#endif
    [LegacyComponentsGlobals setProvider:[[TGLegacyComponentsGlobalsProvider alloc] init]];
    [TGViewController setDefaultContext:[TGLegacyComponentsContext shared]];
    [TGNavigationBar setMusicPlayerProvider:[[TGNavigationBarMusicPlayerProvider alloc] init]];
    
    TGIsRetina();
    TGLogSetEnabled([self enableLogging]);

    TGIOS6PerfLogAppStart();
    // [[TGIOS6MainThreadWatchdog sharedWatchdog] start];
    TGLog(@"didFinishLaunchingWithOptions state: %@, %ld", [UIApplication sharedApplication], (long)[UIApplication sharedApplication].applicationState);
    if ([[UIDevice currentDevice].systemVersion intValue] <= 6)
        IOS6NotificationProbe(@"SESSION", @"launch version=%@ build=%@ state=%d",
                              [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?",
                              [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"?",
                              (int)application.applicationState);
    TGIOS6SendPendingCrashReport();
    TGIOS6SendLatestSystemCrashReport();
    
    if ([TGAppDelegate respondsToSelector:@selector(movePathsToContainer)])
        [TGAppDelegate movePathsToContainer];
    
    NSString *documentsDirectory = TGAppDelegateDocumentsPathCompat();
    if (documentsDirectory.length != 0)
    {
        NSURL *documentsURL = [NSURL fileURLWithPath:documentsDirectory];
        if ([documentsURL respondsToSelector:@selector(setResourceValue:forKey:error:)])
        {
            @try
            {
                [documentsURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
            }
            @catch (__unused NSException *exception)
            {
            }
        }
    }
    
    [TGMessage registerMediaAttachmentParser:TGActionMediaAttachmentType parser:[[TGActionMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGImageMediaAttachmentType parser:[[TGImageMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGLocationMediaAttachmentType parser:[[TGLocationMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGLocalMessageMetaMediaAttachmentType parser:[[TGLocalMessageMetaMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGVideoMediaAttachmentType parser:[[TGVideoMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGContactMediaAttachmentType parser:[[TGContactMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGForwardedMessageMediaAttachmentType parser:[[TGForwardedMessageMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGUnsupportedMediaAttachmentType parser:[[TGUnsupportedMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGDocumentMediaAttachmentType parser:[[TGDocumentMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGAudioMediaAttachmentType parser:[[TGAudioMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGReplyMessageMediaAttachmentType parser:[[TGReplyMessageMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGWebPageMediaAttachmentType parser:[[TGWebPageMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGReplyMarkupAttachmentType parser:[[TGReplyMarkupAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGMessageEntitiesAttachmentType parser:[[TGMessageEntitiesAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGBotContextResultAttachmentType parser:[[TGBotContextResultAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGViaUserAttachmentType parser:[[TGViaUserAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGGameAttachmentType parser:[[TGGameMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGInvoiceMediaAttachmentType parser:[[TGInvoiceMediaAttachment alloc] init]];
    [TGMessage registerMediaAttachmentParser:TGAuthorSignatureMediaAttachmentType parser:[[TGAuthorSignatureMediaAttachment alloc] init]];
    
    TGLog(@"###### Early initialization ######");
    
    [TGDatabase setPasswordRequiredBlock:^TGDatabasePasswordCheckResultBlock (void (^verifyBlock)(NSString *), bool simple)
    {
        TGDispatchOnMainThread(^
        {
            if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
                [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
            if (_passcodeWindow == nil)
            {
                CGRect passcodeFrame = [UIScreen mainScreen].bounds;
                _passcodeWindow = [[TGPasscodeWindow alloc] initWithFrame:passcodeFrame];
                NSInteger initWithNumberOfInvalidAttempts = [[TGAppDelegateUserDefaultsCompat() objectForKey:@"Passcode_invalidAttempts"] integerValue];
                NSTimeInterval invalidAttemptDate = [[TGAppDelegateUserDefaultsCompat() objectForKey:@"Passcode_invalidAttemptDate"] doubleValue];
                TGPasscodeEntryController *controller = [[TGPasscodeEntryController alloc] initWithContext:[TGLegacyComponentsContext shared] style:TGPasscodeEntryControllerStyleTranslucent mode:simple ? TGPasscodeEntryControllerModeVerifySimple : TGPasscodeEntryControllerModeVerifyComplex cancelEnabled:false allowTouchId:false attemptData:[[TGPasscodeEntryAttemptData alloc] initWithNumberOfInvalidAttempts:initWithNumberOfInvalidAttempts dateOfLastInvalidAttempt:invalidAttemptDate] completion:^(NSString *passcode)
                {
                    verifyBlock(passcode);
                }];
                controller.updateAttemptData = ^(TGPasscodeEntryAttemptData *attemptData) {
                    [TGAppDelegateUserDefaultsCompat() setObject:@(attemptData.numberOfInvalidAttempts) forKey:@"Passcode_invalidAttempts"];
                    [TGAppDelegateUserDefaultsCompat() setObject:@(attemptData.dateOfLastInvalidAttempt) forKey:@"Passcode_invalidAttemptDate"];
                };
                
                _passcodeWindow.windowLevel = UIWindowLevelStatusBar - 0.0001f;
                TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[controller]];
                navigationController.restrictLandscape = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
                _passcodeWindow.rootViewController = navigationController;
                _passcodeWindow.hidden = false;
                [_passcodeWindow makeKeyAndVisible];
                [controller prepareForAppear];
            }
            else
            {
                _passcodeWindow.hidden = false;
                [_passcodeWindow makeKeyAndVisible];
                if (TGIsPad())
                    _passcodeWindow.frame = [UIScreen mainScreen].bounds;
                else
                    _passcodeWindow.frame = (CGRect){CGPointZero, TGScreenSize()};
                TGPasscodeEntryController *controller = (TGPasscodeEntryController *)(((TGNavigationController *)_passcodeWindow.rootViewController).topViewController);
                controller.completion = ^(NSString *passcode)
                {
                    verifyBlock(passcode);
                };
                controller.checkCurrentPasscode = nil;
                [controller resetMode:simple ? TGPasscodeEntryControllerModeVerifySimple : TGPasscodeEntryControllerModeVerifyComplex];
                [controller prepareForAppear];
            }
            
            [TGEmbedPIPController hide];
            
            [[[TGBridgeServer instanceSignal] onNext:^(TGBridgeServer *server) {
                [server startRunning];
            }] startWithNext:nil];
        });
        
        return ^(bool match)
        {
            TGDispatchOnMainThread(^
            {
                if (match)
                {
                    [_passcodeWindow endEditing:true];
                    TGPasscodeEntryController *controller = (TGPasscodeEntryController *)(((TGNavigationController *)_passcodeWindow.rootViewController).topViewController);
                    
                    [TGAppDelegateUserDefaultsCompat() removeObjectForKey:@"Passcode_invalidAttempts"];
                    [TGAppDelegateUserDefaultsCompat() removeObjectForKey:@"Passcode_invalidAttemptDate"];
                    [TGAppDelegateUserDefaultsCompat() synchronize];
                    
                    [controller prepareForDisappear];
                    
                    [UIView animateWithDuration:0.3 delay:0 options:[TGViewController preferredAnimationCurve] << 16 animations:^
                    {
                        _passcodeWindow.frame = CGRectOffset(_passcodeWindow.frame, 0.0f, _passcodeWindow.frame.size.height);
                    } completion:^(__unused BOOL finished)
                    {
                        _passcodeWindow.hidden = true;
                    }];
                    
                    if (self.rootController.presentedViewController != nil)
                        [self.rootController.presentedViewController viewDidAppear:false];
                        
                    [TGEmbedPIPController restore];
                    [self resetRemoteDeviceLocked];
                    
                    if (self.onSuccessfulAuthorization != nil)
                    {
                        self.onSuccessfulAuthorization();
                        self.onSuccessfulAuthorization = nil;
                    }
                }
                else
                {
                    TGPasscodeEntryController *controller = (TGPasscodeEntryController *)(((TGNavigationController *)_passcodeWindow.rootViewController).topViewController);
                    
                    [TGAppDelegateUserDefaultsCompat() setObject:@([controller invalidPasscodeAttempts] + 1) forKey:@"Passcode_invalidAttempts"];
                    [TGAppDelegateUserDefaultsCompat() setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"Passcode_invalidAttemptDate"];
                    [TGAppDelegateUserDefaultsCompat() synchronize];
                    
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                }
            });
        };
    }];
    __block TGProgressWindow *progressWindow = nil;
    [TGDatabase setUpgradingBlock:^TGDatabaseUpgradeCompletedBlock ()
    {
        TGDispatchOnMainThread(^
        {
            if (progressWindow != nil) {
                [progressWindow dismiss:false];
            }
            progressWindow = [[TGProgressWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            [progressWindow show:true];
        });
        
        return ^
        {
            TGDispatchOnMainThread(^
            {
                [progressWindow dismiss:true];
            });
        };
    }];
    
    [TGDatabase setLiveMessagesDispatchPath:@"/tg/conversations"];
    [TGDatabase setLiveUnreadCountDispatchPath:@"/tg/unreadCount"];
    
    [[TGDatabase instance] markAllPendingMessagesAsFailed];
    
    //[TGTelegramNetworking preload];
    
    _deviceProximityListeners = [[TGHolderSet alloc] init];
    _deviceProximityListeners.emptyStateChanged = ^(bool listenersExist)
    {
        if (listenersExist) {
            [UIDevice currentDevice].proximityMonitoringEnabled = true;
            bool deviceProximityState = [UIDevice currentDevice].proximityState;
            if (deviceProximityState) {
                _deviceProximityState = deviceProximityState;
                [[NSNotificationCenter defaultCenter] postNotificationName:TGDeviceProximityStateChangedNotification object:nil];
            }
        } else if (!TGAppDelegateInstance->_deviceProximityState) {
            [UIDevice currentDevice].proximityMonitoringEnabled = false;
            _deviceProximityState = false;
        }
    };
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceProximityStateDidChangeNotification object:[UIDevice currentDevice] queue:nil usingBlock:^(__unused NSNotification *notification)
    {
        _deviceProximityState = [UIDevice currentDevice].proximityState;
        if (!_deviceProximityState && _deviceProximityListeners.isEmpty) {
            [UIDevice currentDevice].proximityMonitoringEnabled = false;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:TGDeviceProximityStateChangedNotification object:nil];
    }];
    
    [FFNotificationCenter setShouldRotateBlock:^ bool()
    {
        bool restrictPasscodeWindow = false;
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone && _passcodeWindow != nil && !_passcodeWindow.hidden && [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
        {
            restrictPasscodeWindow = true;
        }
        return [_window.rootViewController shouldAutorotate] && !restrictPasscodeWindow;
    }];
    
    freedomInit();
    freedomUIKitInit();
    
    TGAppDelegateInstance = self;
    
    [TGPresentation refreshUIAppearance];
    
    if (!TGIsPad())
        [TGViewController disableAutorotation];
    
    _window = [[TGApplicationMainWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [(TGApplication *)application forceSetStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:false];
    
    if (iosMajorVersion() < 7)
    {
        FreedomDecoration instanceDecorations[] = {
            { .name = 0x7927c35dU,
              .imp = (IMP)&overridenDrawRect,
              .newIdentifier = FreedomIdentifierEmpty,
              .newEncoding = FreedomIdentifierEmpty
            },
            { .name = 0xc6dda86U,
              .imp = (IMP)&overrideIndexAbove,
              .newIdentifier = FreedomIdentifierEmpty,
              .newEncoding = FreedomIdentifierEmpty
            }
        };
        
        freedomClassAutoDecorate(0xf457bfb2U, NULL, 0, instanceDecorations, sizeof(instanceDecorations) / sizeof(instanceDecorations[0]));
    }
    
    _loadedSoundSamples = [[NSMutableDictionary alloc] init];
    
    _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:false];
    
    [ASActor registerActorClass:[TGImageDownloadActor class]];
    
    [TGInterfaceManager instance];
    
    telegraph = [[TGTelegraph alloc] init];
    
    [TGHacks hackSetAnimationDuration];
    
    [self loadShowCallsTab];
    
    //PGTock;
    //TGLog(@"before root controller");
    _rootController = [[TGRootController alloc] init];
    _rootController.mainTabsController.debugReady = ^{
        //PGTock;
        //TGLog(@"root controller ready");
    };
    self.window.rootViewController = _rootController;
    //PGTock;
    //TGLog(@"set root controller");
    
    self.window.backgroundColor = [UIColor blackColor];
    
    [self.window makeKeyAndVisible];
    
    if ([TGKeyCommandController keyCommandsSupported])
        _keyCommandController = [[TGKeyCommandController alloc] initWithRootController:_rootController];
    
    TGCache *sharedCache = [[TGCache alloc] init];
    [TGRemoteImageView setSharedCache:sharedCache];
    
    if (![TGDatabaseInstance() isEncryptionEnabled])
    {
        TGDispatchOnMainThread(^
        {
            [self displayUnlockWindowIfNeeded];
            TGPasscodeEntryController *controller = (TGPasscodeEntryController *)(((TGNavigationController *)_passcodeWindow.rootViewController).topViewController);
            [controller refreshTouchId];
        });
    }
    
    [[[TGBridgeServer instanceSignal] onNext:^(TGBridgeServer *server) {
        [server setPasscodeEnabled:[TGDatabaseInstance() isPasswordSet:NULL] passcodeEncrypted:[TGDatabaseInstance() isEncryptionEnabled]];
    }] startWithNext:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        [self loadSettings];
        
         [TGDatabaseInstance() loadConversationListFromDate:INT32_MAX limit:50 excludeConversationIds:nil folderId:0 completion:^(NSArray *dialogList, bool loadedAllRegular)
         {
             bool dialogListLoaded = [TGDatabaseInstance() customProperty:@"dialogListLoaded"].length != 0;
             
             NSMutableArray *filteredResult = [[NSMutableArray alloc] initWithArray:dialogList];
             [filteredResult sortUsingComparator:^NSComparisonResult(TGConversation *lhs, TGConversation *rhs) {
                 if (lhs.date > rhs.date) {
                     return NSOrderedAscending;
                 } else if (lhs.date < rhs.date) {
                     return NSOrderedDescending;
                 } else {
                     if (lhs.conversationId < rhs.conversationId) {
                         return NSOrderedDescending;
                     } else {
                         return NSOrderedAscending;
                     }
                 }
             }];
             
             if (!dialogListLoaded || !loadedAllRegular) {
                 while (filteredResult.count != 0 && (((TGConversation *)[filteredResult lastObject]).isChannel || ((TGConversation *)[filteredResult lastObject]).isBroadcast)) {
                     [filteredResult removeLastObject];
                 }
             }
             
             TGLog(@"###### Dialog list loaded ######");
             
             SGraphListNode *node = [[SGraphListNode alloc] init];
             node.items = filteredResult;
             
             //PGTock;
             //TGLog(@"loaded dialogs");
             
             _rootController.dialogListController.debugReady = ^{
                 //PGTock;
                 //TGLog(@"in dialog controller");
             };
             
             [ActionStageInstance() dispatchOnStageQueue:^
             {
                 [(id<ASWatcher>)_rootController.dialogListController.dialogListCompanion actorCompleted:ASStatusSuccess path:@"/tg/dialoglist/(0)" result:node];
                 TGLog(@"===== Dispatched dialog list");
                 if (!ios6ColdBackgroundLaunch)
                 {
                     [ActionStageInstance() requestActor:@"/tg/dialoglist/(0)" options:@{@"force": @true, @"limit": @50} watcher:(id<ASWatcher>)_rootController.dialogListController.dialogListCompanion];
                     TGLog(@"IOS6DLIST startup forced remote refresh limit=50");
                 }
                 
                 [TGTelegraphInstance.liveLocationManager restoreSessions];
                 [TGTelegraphInstance startPresenceUpdates];
                 
                 if (TGTelegraphInstance.clientUserId != 0)
                 {
                     [TGTelegraphInstance processAuthorizedWithUserId:TGTelegraphInstance.clientUserId clientIsActivated:TGTelegraphInstance.clientIsActivated];
                     
                     if (launchOptions[UIApplicationLaunchOptionsURLKey] != nil)
                     {
                         dispatch_async(dispatch_get_main_queue(), ^
                         {
                             [self handleOpenDocument:launchOptions[UIApplicationLaunchOptionsURLKey] animated:false keepStack:false bundleId:launchOptions[UIApplicationLaunchOptionsSourceApplicationKey]];
                         });
                     }
                     else if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] != nil)
                     {
                         dispatch_async(dispatch_get_main_queue(), ^
                         {
                             id nFromId = [launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] objectForKey:@"from_id"];
                             id nChatId = [launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] objectForKey:@"chat_id"];
                             id nContactId = [launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] objectForKey:@"contact_id"];
                             
                             int64_t peerId = 0;
                             
                             if (nFromId != nil && [TGSchema canCreateIntFromObject:nFromId])
                             {
                                 peerId = [TGSchema intFromObject:nFromId];
                             }
                             else if (nChatId != nil && [TGSchema canCreateIntFromObject:nChatId])
                             {
                                 peerId = -[TGSchema intFromObject:nChatId];
                             }
                             else if (nContactId != nil && [TGSchema canCreateIntFromObject:nContactId])
                             {
                                 peerId = [TGSchema intFromObject:nContactId];
                             }
                            
                             if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive)
                                 TGIOS6OpenNotificationPeer(peerId);
                         });
                     }
                     else if (launchOptions[UIApplicationLaunchOptionsLocalNotificationKey] != nil)
                     {
                         if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive)
                         {
                             dispatch_async(dispatch_get_main_queue(), ^
                             {
                                 if ([launchOptions respondsToSelector:@selector(objectForKeyedSubscript:)] && [launchOptions[UIApplicationLaunchOptionsLocalNotificationKey] respondsToSelector:@selector(objectForKey:)] && [launchOptions[UIApplicationLaunchOptionsLocalNotificationKey][@"cid"] respondsToSelector:@selector(longLongValue)])
                                 {
                                     int64_t peerId = [[launchOptions[UIApplicationLaunchOptionsLocalNotificationKey] objectForKey:@"cid"] longLongValue];
                                     TGIOS6OpenNotificationPeer(peerId);
                                 }
                             });
                         }
                     }
                     
                     TGDispatchOnMainThread(^
                     {
                         if (!TGIsPad())
                         {
                             [TGViewController enableAutorotation];
                             [TGViewController attemptAutorotation];
                         }
                     });
                 }
                 else
                 {
                     [TGTelegraphInstance processUnauthorized];
                     
                     NSDictionary *blockStateDict = [self loadLoginState];
                     
                     dispatch_async(dispatch_get_main_queue(), ^
                     {
                         NSDictionary *stateDict = blockStateDict;
                         
                         int currentDate = ((int)CFAbsoluteTimeGetCurrent());
                         int stateDate = [stateDict[@"date"] intValue];
                         if (currentDate - stateDate > 60 * 60 * 23 && blockStateDict[@"resetAccountState"] == nil)
                         {
                             stateDict = nil;
                             [self resetLoginState];
                         }
                         
                         [self presentLoginController:false animated:false phoneNumber:stateDict[@"phoneNumber"] phoneCode:stateDict[@"phoneCode"] phoneCodeHash:stateDict[@"phoneCodeHash"] codeSentToTelegram:[stateDict[@"codeSentToTelegram"] boolValue] codeSentViaPhone:[stateDict[@"codeSentViaPhone"] boolValue] profileFirstName:stateDict[@"firstName"] profileLastName:stateDict[@"lastName"] resetAccountState:blockStateDict[@"resetAccountState"] termsOfService:blockStateDict[@"termsOfService"]];
                         
                         if (!TGIsPad())
                         {
                             [TGViewController enableAutorotation];
                             [TGViewController attemptAutorotation];
                         }
                     });
                     
                     [[TGDatabase instance] dropDatabase];
                 }
                 
                 TGDispatchOnMainThread(^{
                    [_rootController.callsController initialize];
                 });
                 
                 if (filteredResult.count > 0)
                 {
                     int cachedUnreadChatsCount = [TGDatabaseInstance() unreadChatsCount];
                     int cachedUnreadChannelsCount = [TGDatabaseInstance() unreadChannelsCount];
                     
                     if (cachedUnreadChatsCount < 0 || cachedUnreadChannelsCount < 0)
                         [TGDatabaseInstance() transactionCalculateUnreadChats];
                 }
                 
                 [[TGTelegramNetworking instance] start];

                 if (ios6ColdBackgroundApplicationLaunch && !ios6ColdBackgroundLaunch)
                     [[TGTelegramNetworking instance] pause];
                 
                 [_finishedLaunching set:[SSignal single:@true]];

                 if (ios6ColdBackgroundLaunch)
                 {
                     TGDispatchOnMainThread(^{
                         IOS6NotificationProbe(@"LIFECYCLE", @"cold_launch_bootstrap_ready state=%d network=%d",
                                               (int)[UIApplication sharedApplication].applicationState,
                                               [[TGTelegramNetworking instance] isNetworkAvailable] ? 1 : 0);
                         if (_inBackground && [UIApplication sharedApplication].applicationState != UIApplicationStateActive)
                         {
                             [self ios6InstallVoipKeepAliveForApplication:[UIApplication sharedApplication] source:@"cold_launch_ready"];
                             if ([[TGTelegramNetworking instance] isNetworkAvailable])
                             {
                                 // Network availability only means that iOS has
                                 // a route.  After a VoIP cold relaunch MTProto
                                 // can still have no usable primary socket. Ask
                                 // for one catch-up now: it both opens the
                                 // transport and prevents the app from sleeping
                                 // with a falsely "ready" networking facade.
                                 int32_t coldBootstrapUptime = (int32_t)[[NSProcessInfo processInfo] systemUptime];
                                 IOS6NotificationProbe(@"UPDATES", @"catchup_requested source=cold_bootstrap");
                                 [TGTelegraphInstance stateUpdateRequired];

                                 // Give the normal connection path eight
                                 // seconds. Only if no primary bytes arrive do
                                 // one bounded reset and a second catch-up. This
                                 // runs once per cold relaunch, never while the
                                 // client is visible, so it adds no periodic
                                 // battery work.
                                 TGDispatchAfter(8.0, dispatch_get_main_queue(), ^
                                 {
                                     if (!_ios6ColdLaunchTaskActive ||
                                         !_inBackground ||
                                         [UIApplication sharedApplication].applicationState == UIApplicationStateActive)
                                     {
                                         [self ios6EndColdLaunchTask];
                                         return;
                                     }

                                     bool receivedPrimaryData = _ios6VoipLastPrimaryReceiveUptime >= coldBootstrapUptime;
                                     if (receivedPrimaryData)
                                     {
                                         [self ios6EndColdLaunchTask];
                                         return;
                                     }

                                     IOS6NotificationProbe(@"SOCKET", @"primary_reset reason=no_cold_bootstrap_rx source=cold_launch");
                                     [[TGTelegramNetworking instance] resume];
                                     [[[TGTelegramNetworking instance] mtProto] requestSecureTransportReset];

                                     TGDispatchAfter(0.35, dispatch_get_main_queue(), ^
                                     {
                                         if (_ios6ColdLaunchTaskActive &&
                                             _inBackground &&
                                             [UIApplication sharedApplication].applicationState != UIApplicationStateActive)
                                         {
                                             IOS6NotificationProbe(@"UPDATES", @"catchup_requested source=cold_bootstrap_reset");
                                             [TGTelegraphInstance stateUpdateRequired];
                                         }
                                     });

                                     TGDispatchAfter(5.0, dispatch_get_main_queue(), ^
                                     {
                                         [self ios6EndColdLaunchTask];
                                     });
                                 });
                             }
                             else
                             {
                                 // Reboots can relaunch us before Wi-Fi has a
                                 // route. Keep the one cold-launch lease for a
                                 // short bounded window and let normal MTProto
                                 // connection logic recover without resets.
                                 TGDispatchAfter(12.0, dispatch_get_main_queue(), ^
                                 {
                                     if (_inBackground &&
                                         [UIApplication sharedApplication].applicationState != UIApplicationStateActive &&
                                         [[TGTelegramNetworking instance] isNetworkAvailable])
                                     {
                                         IOS6NotificationProbe(@"UPDATES", @"catchup_requested source=cold_network_recovered");
                                         [TGTelegraphInstance stateUpdateRequired];
                                     }
                                     [self ios6EndColdLaunchTask];
                                 });
                             }
                         }
                         else
                             [self ios6EndColdLaunchTask];
                     });
                 }
                 
                 if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] != nil)
                     [self processPossibleConfigUpdateNotification:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]];
                 
                 [[[TGBridgeServer instanceSignal] onNext:^(TGBridgeServer *server) {
                     [server startRunning];
                 }] startWithNext:nil];
             }];
          }];
    });
    
    _foregroundResumeTimer = [TGTimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(checkForegroundResume) interval:2.0 repeat:true];
    
    TGDispatchAfter(1.0, dispatch_get_main_queue(), ^
    {
        @try
        {
            [UIView setAnimationsEnabled:true];
            [CATransaction commit];
        }
        @catch (__unused NSException *exception)
        {
        }
    });
    
    [[[TGBridgeServer instanceSignal] onNext:^(TGBridgeServer *server) {
        [server startServices];
    }] startWithNext:nil];

    if ([[UIDevice currentDevice].systemVersion intValue] <= 6)
    {
        [application beginReceivingRemoteControlEvents];
        [self becomeFirstResponder];
    }
    
    return true;
}

- (void)displayPrivacyNoticeIfNeeded
{
    if (_termsOfServiceDisposable == nil)
        _termsOfServiceDisposable = [[SMetaDisposable alloc] init];
    
    __weak TGAppDelegate *weakSelf = self;
    [_termsOfServiceDisposable setDisposable:[[[TGAccountSignals termsOfServiceUpdate] deliverOn:[SQueue mainQueue]] startWithNext:^(TGTermsOfService *termsOfService)
    {
        __strong TGAppDelegate *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        if (termsOfService != nil)
        {
            TGGDPRNoticeController *controller = [[TGGDPRNoticeController alloc] initWithTermsOfService:termsOfService];
            controller.presentation = strongSelf.rootController.presentation;
            
            TGNavigationController *navController = [TGNavigationController makeWithRootController:controller];
            navController.restrictLandscape = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
            [strongSelf.rootController presentViewController:navController animated:true completion:nil];
        }
    }]];
}

- (void)presentUpdateAppController:(TGUpdateAppInfo *)updateInfo
{
    TGUpdateAppController *controller = [[TGUpdateAppController alloc] initWithUpdateInfo:updateInfo];
    TGNavigationController *navController = [TGNavigationController makeWithRootController:controller];
    navController.restrictLandscape = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
    [self.rootController presentViewController:navController animated:true completion:nil];
}


- (void)checkForegroundResume
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        if (_passcodeWindow == nil || _passcodeWindow.hidden) {
            [[TGTelegramNetworking instance] resume];
        }
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)__unused application
{
    TGLog(@"******* Memory warning ******");
}

- (void)applicationWillResignActive:(UIApplication *)__unused application
{
    if ([[UIDevice currentDevice].systemVersion intValue] <= 6)
        IOS6NotificationProbe(@"LIFECYCLE", @"resign_active state=%d", (int)[UIApplication sharedApplication].applicationState);

    [ActionStageInstance() dispatchOnStageQueue:^
    {
        int unreadCount = [TGDatabaseInstance() databaseState].unreadCount;
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:unreadCount];
        });
    }];
    
    if ([self respondsToSelector:@selector(onBecomeInactive)])
        [self onBecomeInactive];
}

- (bool)isOrWillBeLocked
{
    NSNumber *nDeactivationDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"Passcode_deactivationDate"];
    bool displayByDeactivationTimeout = false;
    if (nDeactivationDate != nil)
    {
        int32_t lockTimeout = [self automaticLockTimeout];
        if (lockTimeout >= 0)
        {
            displayByDeactivationTimeout = [[NSDate date] timeIntervalSince1970] > ([nDeactivationDate doubleValue] + lockTimeout);
        }
    }
    
    return ([self isManuallyLocked] || displayByDeactivationTimeout || (_passcodeWindow != nil && !_passcodeWindow.hidden));
}

- (bool)isDisplayingPasscodeWindow
{
    return _passcodeWindow != nil && !_passcodeWindow.hidden;
}

- (void)displayUnlockWindowIfNeeded
{
    NSNumber *nDeactivationDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"Passcode_deactivationDate"];
    bool displayByDeactivationTimeout = false;
    if (nDeactivationDate != nil)
    {
        int32_t lockTimeout = [self automaticLockTimeout];
        if (lockTimeout >= 0)
        {
            displayByDeactivationTimeout = [[NSDate date] timeIntervalSince1970] > ([nDeactivationDate doubleValue] + lockTimeout);
        }
    }
    
    if ([self isManuallyLocked] || displayByDeactivationTimeout || [self willBeLocked])
    {
        bool isStrong = false;
        if ([TGDatabaseInstance() isPasswordSet:&isStrong])
        {
            if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
                [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
            
            TGPasscodeEntryControllerMode mode = (!isStrong) ? TGPasscodeEntryControllerModeVerifySimple : TGPasscodeEntryControllerModeVerifyComplex;
            if (_passcodeWindow == nil)
            {
                CGRect passcodeFrame = [UIScreen mainScreen].bounds;
                if (TGIsPad())
                    passcodeFrame = [UIScreen mainScreen].bounds;
                else
                    passcodeFrame = (CGRect){CGPointZero, TGScreenSize()};
                _passcodeWindow = [[TGPasscodeWindow alloc] initWithFrame:passcodeFrame];
                NSInteger initWithNumberOfInvalidAttempts = [[TGAppDelegateUserDefaultsCompat() objectForKey:@"Passcode_invalidAttempts"] integerValue];
                NSTimeInterval invalidAttemptDate = [[TGAppDelegateUserDefaultsCompat() objectForKey:@"Passcode_invalidAttemptDate"] doubleValue];
                TGPasscodeEntryController *controller = [[TGPasscodeEntryController alloc] initWithContext:[TGLegacyComponentsContext shared] style:TGPasscodeEntryControllerStyleTranslucent mode:mode cancelEnabled:false allowTouchId:[TGPasscodeSettingsController enableTouchId] attemptData:[[TGPasscodeEntryAttemptData alloc] initWithNumberOfInvalidAttempts:initWithNumberOfInvalidAttempts dateOfLastInvalidAttempt:invalidAttemptDate] completion:^(NSString *passcode)
                {
                    if ([TGDatabaseInstance() verifyPassword:passcode])
                    {
                        TGDispatchOnMainThread(^
                        {
                            [self setIsManuallyLocked:false];
                            
                            [_passcodeWindow endEditing:true];
                            TGPasscodeEntryController *controller = (TGPasscodeEntryController *)(((TGNavigationController *)_passcodeWindow.rootViewController).topViewController);
                            [controller prepareForDisappear];

                            [UIView animateWithDuration:0.3 delay:0 options:[TGViewController preferredAnimationCurve] << 16 animations:^
                            {
                                _passcodeWindow.frame = CGRectOffset(_passcodeWindow.frame, 0.0f, _passcodeWindow.frame.size.height);
                            } completion:^(__unused BOOL finished)
                            {
                                _passcodeWindow.hidden = true;
                            }];
                            
                            if (self.rootController.presentedViewController != nil)
                                [self.rootController.presentedViewController viewDidAppear:false];
                            
                            [TGEmbedPIPController restore];
                            [self resetRemoteDeviceLocked];
                            
                            if (self.onSuccessfulAuthorization != nil)
                            {
                                self.onSuccessfulAuthorization();
                                self.onSuccessfulAuthorization = nil;
                            }
                        });
                    }
                }];
                controller.updateAttemptData = ^(TGPasscodeEntryAttemptData *attemptData) {
                    [TGAppDelegateUserDefaultsCompat() setObject:@(attemptData.numberOfInvalidAttempts) forKey:@"Passcode_invalidAttempts"];
                    [TGAppDelegateUserDefaultsCompat() setObject:@(attemptData.dateOfLastInvalidAttempt) forKey:@"Passcode_invalidAttemptDate"];
                };
                controller.touchIdCompletion = ^
                {
                    TGDispatchOnMainThread(^
                    {
                        [self setIsManuallyLocked:false];
                        
                        [_passcodeWindow endEditing:true];
                        TGPasscodeEntryController *controller = (TGPasscodeEntryController *)(((TGNavigationController *)_passcodeWindow.rootViewController).topViewController);
                        [controller prepareForDisappear];
                        
                        [UIView animateWithDuration:0.3 delay:0 options:[TGViewController preferredAnimationCurve] << 16 animations:^
                        {
                            _passcodeWindow.frame = CGRectOffset(_passcodeWindow.frame, 0.0f, _passcodeWindow.frame.size.height);
                        } completion:^(__unused BOOL finished)
                        {
                            _passcodeWindow.hidden = true;
                        }];
                        
                        if (self.rootController.presentedViewController != nil)
                            [self.rootController.presentedViewController viewDidAppear:false];

                        [TGEmbedPIPController restore];
                        [self resetRemoteDeviceLocked];
                        
                        if (self.onSuccessfulAuthorization != nil)
                        {
                            self.onSuccessfulAuthorization();
                            self.onSuccessfulAuthorization = nil;
                        }
                    });
                };
                controller.checkCurrentPasscode = ^bool (NSString *passcode)
                {
                    return [TGDatabaseInstance() verifyPassword:passcode];
                };
                _passcodeWindow.windowLevel = UIWindowLevelStatusBar - 0.0001f;
                TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[controller]];
                navigationController.restrictLandscape = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
                _passcodeWindow.rootViewController = navigationController;
                _passcodeWindow.hidden = false;
                [_passcodeWindow makeKeyAndVisible];
                [controller prepareForAppear];
                
                if (!TGIsPad())
                {
                    navigationController.view.frame = (CGRect){CGPointZero, TGScreenSize()};;
                    controller.view.frame = (CGRect){CGPointZero, TGScreenSize()};;
                }
                
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
                    [controller refreshTouchId];
            }
            else if (_passcodeWindow.hidden)
            {
                TGPasscodeEntryController *controller = (TGPasscodeEntryController *)(((TGNavigationController *)_passcodeWindow.rootViewController).topViewController);
                controller.checkCurrentPasscode = ^(NSString *passcode)
                {
                    return [TGDatabaseInstance() verifyPassword:passcode];
                };
                controller.completion = ^(NSString *passcode)
                {
                    if ([TGDatabaseInstance() verifyPassword:passcode])
                    {
                        TGDispatchOnMainThread(^
                        {
                            [self setIsManuallyLocked:false];
                            
                            [_passcodeWindow endEditing:true];
                            TGPasscodeEntryController *controller = (TGPasscodeEntryController *)(((TGNavigationController *)_passcodeWindow.rootViewController).topViewController);
                            [controller prepareForDisappear];
                            
                            [UIView animateWithDuration:0.3 delay:0 options:[TGViewController preferredAnimationCurve] << 16 animations:^
                             {
                                 _passcodeWindow.frame = CGRectOffset(_passcodeWindow.frame, 0.0f, _passcodeWindow.frame.size.height);
                             } completion:^(__unused BOOL finished)
                             {
                                 _passcodeWindow.hidden = true;
                             }];
                            
                            if (self.rootController.presentedViewController != nil)
                                [self.rootController.presentedViewController viewDidAppear:false];
                            
                            [TGEmbedPIPController restore];
                            [self resetRemoteDeviceLocked];
                            
                            if (self.onSuccessfulAuthorization != nil)
                            {
                                self.onSuccessfulAuthorization();
                                self.onSuccessfulAuthorization = nil;
                            }
                        });
                    }
                };
                controller.touchIdCompletion = ^
                {
                    TGDispatchOnMainThread(^
                    {
                        [self setIsManuallyLocked:false];
                        
                        [_passcodeWindow endEditing:true];
                        TGPasscodeEntryController *controller = (TGPasscodeEntryController *)(((TGNavigationController *)_passcodeWindow.rootViewController).topViewController);
                        [controller prepareForDisappear];
                        
                        [UIView animateWithDuration:0.3 delay:0 options:[TGViewController preferredAnimationCurve] << 16 animations:^
                        {
                            _passcodeWindow.frame = CGRectOffset(_passcodeWindow.frame, 0.0f, _passcodeWindow.frame.size.height);
                        } completion:^(__unused BOOL finished)
                        {
                            _passcodeWindow.hidden = true;
                        }];
                        
                        if (self.rootController.presentedViewController != nil)
                            [self.rootController.presentedViewController viewDidAppear:false];
                        
                        [TGEmbedPIPController restore];
                        [self resetRemoteDeviceLocked];
                        
                        if (self.onSuccessfulAuthorization != nil)
                        {
                            self.onSuccessfulAuthorization();
                            self.onSuccessfulAuthorization = nil;
                        }
                    });
                };
                [controller resetMode:mode];
                if (TGIsPad())
                    _passcodeWindow.frame = [UIScreen mainScreen].bounds;
                else
                    _passcodeWindow.frame = (CGRect){CGPointZero, TGScreenSize()};
                _passcodeWindow.hidden = false;
                [_passcodeWindow makeKeyAndVisible];
                [controller prepareForAppear];
                
                controller.allowTouchId = [TGPasscodeSettingsController enableTouchId];
                
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
                    [controller refreshTouchId];
            }
            
            [TGEmbedPIPController hide];
        }
    }
}

- (void)displayBlurredContentIfNeeded {
    if (_blurredContentWindow == nil && ![TGUpdateConfigActor cachedExperimentalPasscodeBlurDisabled]) {
        _blurredContentWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        if (iosMajorVersion() >= 7) {
            CGSize size = _blurredContentWindow.bounds.size;
            UIGraphicsBeginImageContextWithOptions(CGSizeMake((int)(size.width / 2.0f), (int)(size.height / 2.0f)), true, 1.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextScaleCTM(context, 0.5f, 0.5f);
            [self.window drawViewHierarchyInRect:self.window.bounds afterScreenUpdates:false];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            image = [image applyScreenshotEffect];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
            imageView.contentMode = UIViewContentModeScaleToFill;
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [_blurredContentWindow addSubview:imageView];
        }
        
        _blurredContentWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _blurredContentWindow.windowLevel = 10000100.0f - 0.1f;
        _blurredContentWindow.backgroundColor = [UIColor whiteColor];
        _blurredContentWindow.hidden = false;
        
    }
}

- (void)hideBlurredContentIfNeeded {
    if (_blurredContentWindow != nil) {
        _blurredContentWindow.hidden = true;
        _blurredContentWindow = nil;
    }
}

- (void)applicationSignificantTimeChange:(UIApplication *)__unused application
{
    TGLog(@"***** Significant time change");
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        [ActionStageInstance() dispatchResource:@"/system/significantTimeChange" resource:nil];
    }];
    
    [TGDatabaseInstance() processAndScheduleSelfDestruct];
    [TGDatabaseInstance() processAndScheduleMediaCleanup];
    [TGDatabaseInstance() processAndScheduleMute];
}

- (SSignal *)isActive
{
    return _isActive.signal;
}

- (NSTimeInterval)ios6VoipHealthCheckInterval
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSHourCalendarUnit fromDate:[NSDate date]];
    NSInteger hour = [components hour];
    return (hour >= 23 || hour < 7) ? 60.0 * 60.0 : 30.0 * 60.0;
}

- (void)ios6PrimaryTransportReceivedData:(NSNotification *)__unused notification
{
    _ios6VoipLastPrimaryReceiveUptime = (int32_t)[[NSProcessInfo processInfo] systemUptime];
}

- (BOOL)ios6InstallVoipKeepAliveForApplication:(UIApplication *)application source:(NSString *)source
{
    if ([[UIDevice currentDevice].systemVersion intValue] > 6 ||
        _disableBackgroundMode ||
        application.applicationState == UIApplicationStateActive)
    {
        return false;
    }

    [self ios6CancelVoipHealthCheck];
    _ios6VoipLastProactiveTransportRefreshTime = CFAbsoluteTimeGetCurrent();

    UIRemoteNotificationType systemTypes = UIRemoteNotificationTypeNone;
    bool privateNotificationsEnabled = false;
    bool groupNotificationsEnabled = false;
    _ios6NotificationTransportAllowedForBackgroundSession = [self ios6NotificationTransportAllowedWithSystemTypes:&systemTypes privateEnabled:&privateNotificationsEnabled groupEnabled:&groupNotificationsEnabled];
    TGLog(@"IOS6PUSH notificationGate allowed=%d systemTypes=0x%x private=%d groups=%d activeCall=%d source=%@", _ios6NotificationTransportAllowedForBackgroundSession ? 1 : 0, (unsigned int)systemTypes, privateNotificationsEnabled ? 1 : 0, groupNotificationsEnabled ? 1 : 0, TGTelegraphInstance.callManager.hasActiveCall ? 1 : 0, source ?: @"unknown");

    if (!_ios6NotificationTransportAllowedForBackgroundSession)
    {
        [self ios6StopNotificationTransport];
        TGLog(@"IOS6PUSH voipKeepAlive disabled source=%@", source ?: @"unknown");
        return false;
    }

    __block CFAbsoluteTime lastScheduledHealthCheckTime = CFAbsoluteTimeGetCurrent();
    void (^performScheduledHealthCheck)(void) = ^
    {
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
        NSTimeInterval healthCheckInterval = [self ios6VoipHealthCheckInterval];
        if (now - lastScheduledHealthCheckTime + 1.0 < healthCheckInterval)
            return;

        lastScheduledHealthCheckTime = now;
        [self ios6PerformVoipHealthCheck];
    };

    BOOL keepAliveInstalled = [application setKeepAliveTimeout:600.0 handler:^
    {
        IOS6NotificationProbe(@"WAKE", @"keepalive_callback state=%d remaining=%.1f thread=%@",
                              (int)[UIApplication sharedApplication].applicationState,
                              [UIApplication sharedApplication].backgroundTimeRemaining,
                              [NSThread isMainThread] ? @"main" : @"worker");
        if ([NSThread isMainThread])
            performScheduledHealthCheck();
        else
            dispatch_async(dispatch_get_main_queue(), performScheduledHealthCheck);
    }];
    IOS6NotificationProbe(@"LIFECYCLE", @"keepalive_registered result=%d scheduler=600 healthInterval=%d source=%@",
                          keepAliveInstalled ? 1 : 0, (int)[self ios6VoipHealthCheckInterval], source ?: @"unknown");
    TGLog(@"IOS6PUSH voipKeepAlive installed=%d scheduler=600 healthInterval=%d source=%@", keepAliveInstalled ? 1 : 0, (int)[self ios6VoipHealthCheckInterval], source ?: @"unknown");
    return keepAliveInstalled;
}

- (void)ios6EndColdLaunchTask
{
    if (!_ios6ColdLaunchTaskActive)
        return;

    UIBackgroundTaskIdentifier identifier = _ios6ColdLaunchTaskIdentifier;
    _ios6ColdLaunchTaskIdentifier = UIBackgroundTaskInvalid;
    _ios6ColdLaunchTaskActive = false;
    if (identifier != UIBackgroundTaskInvalid)
    {
        IOS6NotificationProbe(@"LEASE", @"cold_launch_end id=%d", (int)identifier);
        [[UIApplication sharedApplication] endBackgroundTask:identifier];
    }
}

- (void)ios6CancelVoipHealthCheck
{
    _ios6VoipHealthCheckGeneration++;
    _ios6VoipHealthCheckAttempt = 0;
    _ios6VoipHealthCheckPending = false;
    if (_ios6VoipHealthCheckDisposable != nil)
        [_ios6VoipHealthCheckDisposable setDisposable:nil];
    [self ios6EndVoipHealthCheckTask];
}

- (bool)ios6NotificationTransportAllowedWithSystemTypes:(UIRemoteNotificationType *)systemTypes privateEnabled:(bool *)privateEnabled groupEnabled:(bool *)groupEnabled
{
    UIRemoteNotificationType enabledTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];

    if (!TGIOS6BackgroundNotificationsEnabled())
    {
        if (systemTypes != NULL)
            *systemTypes = enabledTypes;
        if (privateEnabled != NULL)
            *privateEnabled = false;
        if (groupEnabled != NULL)
            *groupEnabled = false;

        // Notification preferences must not tear down an active call.
        return TGTelegraphInstance.callManager.hasActiveCall;
    }

    if (!TGIOS6NotificationSettingsGateEnabled)
    {
        if (systemTypes != NULL)
            *systemTypes = enabledTypes;
        if (privateEnabled != NULL)
            *privateEnabled = true;
        if (groupEnabled != NULL)
            *groupEnabled = true;
        return true;
    }

    bool systemEnabled = (enabledTypes & (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)) != UIRemoteNotificationTypeNone;

    // Notification preferences must never tear down call signaling. Once the
    // call ends, the next keep-alive callback evaluates the normal gate again.
    if (TGTelegraphInstance.callManager.hasActiveCall)
    {
        if (systemTypes != NULL)
            *systemTypes = enabledTypes;
        if (privateEnabled != NULL)
            *privateEnabled = false;
        if (groupEnabled != NULL)
            *groupEnabled = false;
        return true;
    }

    if (!systemEnabled)
    {
        if (systemTypes != NULL)
            *systemTypes = enabledTypes;
        if (privateEnabled != NULL)
            *privateEnabled = false;
        if (groupEnabled != NULL)
            *groupEnabled = false;
        return false;
    }

    NSNumber *privateMuteUntil = nil;
    NSNumber *groupMuteUntil = nil;
    [TGDatabaseInstance() loadPeerNotificationSettings:INT_MAX - 1 soundId:NULL muteUntil:&privateMuteUntil previewText:NULL messagesMuted:NULL notFound:NULL];
    [TGDatabaseInstance() loadPeerNotificationSettings:INT_MAX - 2 soundId:NULL muteUntil:&groupMuteUntil previewText:NULL messagesMuted:NULL notFound:NULL];

    // The two Alert switches use INT_MAX for a permanent global mute. A
    // finite mute must keep the transport available so it can expire without
    // requiring the user to reopen the app.
    bool privateCategoryEnabled = privateMuteUntil == nil || privateMuteUntil.longLongValue < INT_MAX;
    bool groupCategoryEnabled = groupMuteUntil == nil || groupMuteUntil.longLongValue < INT_MAX;

    if (systemTypes != NULL)
        *systemTypes = enabledTypes;
    if (privateEnabled != NULL)
        *privateEnabled = privateCategoryEnabled;
    if (groupEnabled != NULL)
        *groupEnabled = groupCategoryEnabled;

    return systemEnabled && (privateCategoryEnabled || groupCategoryEnabled);
}

- (void)ios6StopNotificationTransport
{
    if (TGTelegraphInstance.callManager.hasActiveCall)
    {
        [self ios6CancelVoipHealthCheck];
        return;
    }

    _ios6NotificationTransportAllowedForBackgroundSession = false;
    [[UIApplication sharedApplication] clearKeepAliveTimeout];
    [self ios6CancelVoipHealthCheck];
    [self ios6EndColdLaunchTask];
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
        [[TGTelegramNetworking instance] pause];
}

- (void)applyIOS6BackgroundNotificationsEnabled:(bool)enabled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enabled forKey:TGIOS6BackgroundNotificationsEnabledKey];
    [defaults synchronize];

    UIApplication *application = [UIApplication sharedApplication];
    if (!enabled)
    {
        // Remove already queued banners as well as the transport that could
        // create new ones. Foreground MTProto remains untouched.
        [application cancelAllLocalNotifications];
        application.applicationIconBadgeNumber = 0;
        [self ios6StopNotificationTransport];
    }
    else if ([[UIDevice currentDevice].systemVersion intValue] <= 6 &&
             application.applicationState != UIApplicationStateActive)
    {
        [[TGTelegramNetworking instance] resume];
        [self ios6InstallVoipKeepAliveForApplication:application source:@"settings_enabled"];
    }
}

- (void)ios6EndVoipHealthCheckTask
{
    if (!_ios6VoipHealthCheckTaskActive)
        return;

    UIBackgroundTaskIdentifier identifier = _ios6VoipHealthCheckTaskIdentifier;
    _ios6VoipHealthCheckTaskIdentifier = UIBackgroundTaskInvalid;
    _ios6VoipHealthCheckTaskActive = false;
    if (identifier != UIBackgroundTaskInvalid)
    {
        IOS6NotificationProbe(@"LEASE", @"health_task_end id=%d", (int)identifier);
        [[UIApplication sharedApplication] endBackgroundTask:identifier];
    }
}

- (void)ios6FinishVoipHealthCheck:(int32_t)generation attempt:(int32_t)attempt success:(bool)success reason:(NSString *)reason
{
    if (generation != _ios6VoipHealthCheckGeneration ||
        attempt != _ios6VoipHealthCheckAttempt ||
        !_ios6VoipHealthCheckPending)
    {
        return;
    }

    if (!success && _ios6VoipLastPrimaryReceiveUptime > 0)
    {
        int32_t receiveAge = MAX(0, (int32_t)[[NSProcessInfo processInfo] systemUptime] - _ios6VoipLastPrimaryReceiveUptime);
        if (receiveAge <= 6 && [[TGTelegramNetworking instance] isNetworkAvailable])
        {
            success = true;
            reason = @"recent_rx";
        }
    }

    IOS6NotificationProbe(@"HEALTH", @"probe_result generation=%d attempt=%d success=%d reason=%@ network=%d connecting=%d updating=%d",
                          generation, attempt, success ? 1 : 0, reason ?: @"none",
                          [[TGTelegramNetworking instance] isNetworkAvailable] ? 1 : 0,
                          [[TGTelegramNetworking instance] isConnecting] ? 1 : 0,
                          [[TGTelegramNetworking instance] isUpdating] ? 1 : 0);

    if (_ios6VoipHealthCheckDisposable != nil)
        [_ios6VoipHealthCheckDisposable setDisposable:nil];

    // A callback can race with applicationWillEnterForeground. Never reset a
    // transport used by the visible client: normal MTProto recovery owns it.
    UIApplication *application = [UIApplication sharedApplication];
    if (!_inBackground || _disableBackgroundMode || application.applicationState == UIApplicationStateActive)
    {
        [self ios6CancelVoipHealthCheck];
        return;
    }

    if (success)
    {
        _ios6VoipHealthCheckPending = false;

        if (attempt != 0)
        {
            _ios6VoipLastProactiveTransportRefreshTime = CFAbsoluteTimeGetCurrent();
            TGLog(@"IOS6PUSH healthCheck recovered primary MTProto transport");
            IOS6NotificationProbe(@"UPDATES", @"catchup_requested source=recovered_transport");
            [TGTelegraphInstance stateUpdateRequired];

            TGDispatchAfter(1.5, dispatch_get_main_queue(), ^
            {
                [self ios6EndVoipHealthCheckTask];
            });
            return;
        }

        // This probe is only reached after a full day/night inactivity
        // interval. Catch up once after that genuine silence; normal recent
        // traffic skips the probe above and therefore never reaches here.
        IOS6NotificationProbe(@"UPDATES", @"catchup_requested source=long_silence");
        [TGTelegraphInstance stateUpdateRequired];
        TGDispatchAfter(1.5, dispatch_get_main_queue(), ^
        {
            [self ios6EndVoipHealthCheckTask];
        });
        return;
    }

    if (attempt != 0)
    {
        _ios6VoipHealthCheckPending = false;
        TGLog(@"IOS6PUSH healthCheck recovery failed (%@)", reason ?: @"unknown");
        [self ios6EndVoipHealthCheckTask];
        return;
    }

    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    static const CFTimeInterval minimumResetInterval = 120.0;
    if (_ios6VoipLastTransportResetTime > 0.0 && now - _ios6VoipLastTransportResetTime < minimumResetInterval)
    {
        _ios6VoipHealthCheckPending = false;
        IOS6NotificationProbe(@"HEALTH", @"reset_throttled reason=%@ age=%.1f", reason ?: @"failed", now - _ios6VoipLastTransportResetTime);
        TGLog(@"IOS6PUSH healthCheck %@; transport reset throttled", reason ?: @"failed");
        [self ios6EndVoipHealthCheckTask];
        return;
    }

    _ios6VoipLastTransportResetTime = now;
    IOS6NotificationProbe(@"SOCKET", @"primary_reset reason=%@ source=health", reason ?: @"failed");
    TGLog(@"IOS6PUSH healthCheck %@; resetting primary MTProto transport", reason ?: @"failed");
    _ios6VoipHealthCheckAttempt = 1;

    // The previous implementation reset the transport after an eight-second
    // timeout and then stopped.  iOS gives this handler only about ten seconds,
    // so the replacement socket had no request to open it and almost no time
    // to connect.  Resume, reset, then issue a second ping which both forces a
    // fresh connection and confirms that its VoIP-marked socket is usable.
    [[TGTelegramNetworking instance] resume];
    [[[TGTelegramNetworking instance] mtProto] requestSecureTransportReset];

    TGDispatchAfter(0.35, dispatch_get_main_queue(), ^
    {
        if (generation == _ios6VoipHealthCheckGeneration &&
            _ios6VoipHealthCheckPending &&
            _ios6VoipHealthCheckAttempt == 1 &&
            _inBackground &&
            !_disableBackgroundMode &&
            [UIApplication sharedApplication].applicationState != UIApplicationStateActive)
        {
            [self ios6StartVoipHealthProbe:generation attempt:1 timeout:4.0];
        }
    });
}

- (void)ios6StartVoipHealthProbe:(int32_t)generation attempt:(int32_t)attempt timeout:(NSTimeInterval)timeout
{
    UIApplication *application = [UIApplication sharedApplication];
    if (generation != _ios6VoipHealthCheckGeneration ||
        !_ios6VoipHealthCheckPending ||
        !_inBackground ||
        _disableBackgroundMode ||
        application.applicationState == UIApplicationStateActive)
    {
        return;
    }

    _ios6VoipHealthCheckAttempt = attempt;

    IOS6NotificationProbe(@"HEALTH", @"probe_start generation=%d attempt=%d timeout=%.1f network=%d connecting=%d updating=%d",
                          generation, attempt, timeout,
                          [[TGTelegramNetworking instance] isNetworkAvailable] ? 1 : 0,
                          [[TGTelegramNetworking instance] isConnecting] ? 1 : 0,
                          [[TGTelegramNetworking instance] isUpdating] ? 1 : 0);

    if (_ios6VoipHealthCheckDisposable == nil)
        _ios6VoipHealthCheckDisposable = [[SMetaDisposable alloc] init];

    TLRPCping$ping *ping = [[TLRPCping$ping alloc] init];
    ping.ping_id = (((int64_t)arc4random()) << 32) | (int64_t)arc4random();

    id<SDisposable> disposable = [[[[TGTelegramNetworking instance] requestSignal:ping requestClass:(TGRequestClassHidesActivityIndicator | TGRequestClassFailOnServerErrors | TGRequestClassFailOnFloodErrors | TGRequestClassFailOnServerErrorsImmediately)] take:1] startWithNext:^(__unused id next)
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self ios6FinishVoipHealthCheck:generation attempt:attempt success:true reason:nil];
        });
    } error:^(__unused id error)
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self ios6FinishVoipHealthCheck:generation attempt:attempt success:false reason:@"error"];
        });
    } completed:^
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self ios6FinishVoipHealthCheck:generation attempt:attempt success:true reason:nil];
        });
    }];
    [_ios6VoipHealthCheckDisposable setDisposable:disposable];

    TGDispatchAfter(timeout, dispatch_get_main_queue(), ^
    {
        [self ios6FinishVoipHealthCheck:generation attempt:attempt success:false reason:@"timeout"];
    });
}

- (void)ios6PerformVoipHealthCheck
{
    UIApplication *application = [UIApplication sharedApplication];
    if (!_inBackground || _disableBackgroundMode || application.applicationState == UIApplicationStateActive)
        return;

    _ios6NotificationTransportAllowedForBackgroundSession = [self ios6NotificationTransportAllowedWithSystemTypes:NULL privateEnabled:NULL groupEnabled:NULL];
    IOS6NotificationProbe(@"WAKE", @"health_begin state=%d network=%d connecting=%d updating=%d allowed=%d",
                          (int)application.applicationState,
                          [[TGTelegramNetworking instance] isNetworkAvailable] ? 1 : 0,
                          [[TGTelegramNetworking instance] isConnecting] ? 1 : 0,
                          [[TGTelegramNetworking instance] isUpdating] ? 1 : 0,
                          _ios6NotificationTransportAllowedForBackgroundSession ? 1 : 0);
    if (!_ios6NotificationTransportAllowedForBackgroundSession)
    {
        TGLog(@"IOS6PUSH healthCheck stopped by notification settings");
        [self ios6StopNotificationTransport];
        return;
    }

    int32_t currentUptime = (int32_t)[[NSProcessInfo processInfo] systemUptime];
    int32_t receiveAge = _ios6VoipLastPrimaryReceiveUptime > 0 ? MAX(0, currentUptime - _ios6VoipLastPrimaryReceiveUptime) : INT_MAX;
    if ([[TGTelegramNetworking instance] isNetworkAvailable] &&
        ![[TGTelegramNetworking instance] isConnecting] &&
        receiveAge <= (int32_t)[self ios6VoipHealthCheckInterval])
    {
        IOS6NotificationProbe(@"HEALTH", @"probe_skipped recentRx=%d", receiveAge);
        return;
    }

    [self ios6CancelVoipHealthCheck];
    _ios6VoipHealthCheckPending = true;
    int32_t generation = _ios6VoipHealthCheckGeneration;

    // Work started by a VoIP keep-alive callback is asynchronous.  Keep a
    // short UIKit background-task lease so the callback cannot return and have
    // iOS suspend us between the reset and the verification ping.
    __block UIBackgroundTaskIdentifier taskIdentifier = UIBackgroundTaskInvalid;
    taskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^
    {
        IOS6NotificationProbe(@"LEASE", @"health_task_expiration_handler id=%d", (int)taskIdentifier);
        if ([NSThread isMainThread])
        {
            if (_ios6VoipHealthCheckTaskActive && _ios6VoipHealthCheckTaskIdentifier == taskIdentifier)
                [self ios6CancelVoipHealthCheck];
        }
        else
        {
            dispatch_sync(dispatch_get_main_queue(), ^
            {
                if (_ios6VoipHealthCheckTaskActive && _ios6VoipHealthCheckTaskIdentifier == taskIdentifier)
                    [self ios6CancelVoipHealthCheck];
            });
        }
    }];
    if (taskIdentifier != UIBackgroundTaskInvalid)
    {
        _ios6VoipHealthCheckTaskIdentifier = taskIdentifier;
        _ios6VoipHealthCheckTaskActive = true;
        IOS6NotificationProbe(@"LEASE", @"health_task_begin id=%d remaining=%.1f", (int)taskIdentifier, application.backgroundTimeRemaining);
    }
    else
        IOS6NotificationProbe(@"LEASE", @"health_task_denied remaining=%.1f", application.backgroundTimeRemaining);

    // A paused MTProto ignores transaction requests.  This is cheap when it is
    // already running and prevents the keep-alive ping from waiting forever.
    [[TGTelegramNetworking instance] resume];

    [self ios6StartVoipHealthProbe:generation attempt:0 timeout:4.0];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
#if defined(DEBUG) || defined(INTERNAL_RELEASE)
    TGLogSynchronize();
#endif
    
    if ([[UIDevice currentDevice].systemVersion intValue] <= 6)
        IOS6NotificationProbe(@"LIFECYCLE", @"background_enter state=%d remaining=%.1f", (int)application.applicationState, application.backgroundTimeRemaining);

    _inBackground = true;

    _ios6NotificationTransportAllowedForBackgroundSession = TGIOS6BackgroundNotificationsEnabled() || TGTelegraphInstance.callManager.hasActiveCall;

    if ([[UIDevice currentDevice].systemVersion intValue] <= 6)
    {
        // A text field may have owned first-responder status while the app was
        // visible.  Reclaim it only after entering background so lock-screen
        // and headset buttons keep reaching the legacy iOS 6 event path.
        [application beginReceivingRemoteControlEvents];
        [self becomeFirstResponder];
        [self ios6InstallVoipKeepAliveForApplication:application source:@"background_enter"];
    }
    
    [_isActive set:[SSignal single:@false]];
    
    self.onSuccessfulAuthorization = nil;
    self.onSuccessfulLogin = nil;
    
    if (_backgroundTaskExpirationTimer != nil && [_backgroundTaskExpirationTimer isValid])
    {
        [_backgroundTaskExpirationTimer invalidate];
        _backgroundTaskExpirationTimer = nil;
    }
    
    _backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^
    {
        if ([[UIDevice currentDevice].systemVersion intValue] <= 6)
            IOS6NotificationProbe(@"LEASE", @"initial_task_expiration_handler id=%d", (int)_backgroundTaskIdentifier);
        if (_backgroundTaskExpirationTimer != nil)
        {
            if ([_backgroundTaskExpirationTimer isValid])
                [_backgroundTaskExpirationTimer invalidate];
            _backgroundTaskExpirationTimer = nil;
        }
        
        UIBackgroundTaskIdentifier identifier = _backgroundTaskIdentifier;
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        [application endBackgroundTask:identifier];
    }];
    if ([[UIDevice currentDevice].systemVersion intValue] <= 6)
        IOS6NotificationProbe(@"LEASE", @"initial_task_begin id=%d remaining=%.1f", (int)_backgroundTaskIdentifier, application.backgroundTimeRemaining);
    
    _enteredBackgroundTime = CFAbsoluteTimeGetCurrent();
    
    double systemRemainingTime = [application backgroundTimeRemaining];
    TGLog(@"System allowed background time remaining: %d m %d s", (int)(systemRemainingTime / 60.0), ((int)systemRemainingTime) % 60);
    
    double maxBackgroundTime = MAX(15.0, MIN(40.0, [application backgroundTimeRemaining] - 0.5 * 60.0));
    if (_disableBackgroundMode || ([[UIDevice currentDevice].systemVersion intValue] <= 6 && !_ios6NotificationTransportAllowedForBackgroundSession && !TGTelegraphInstance.callManager.hasActiveCall))
        maxBackgroundTime = 1;
    
#ifdef DEBUG
//    maxBackgroundTime = 7.0;
#endif
    
    TGLog(@"Background time remaining: %d m %d s", (int)(maxBackgroundTime / 60.0), ((int)maxBackgroundTime) % 60);
    
    _backgroundTaskExpirationTimer = [NSTimer timerWithTimeInterval:MAX(maxBackgroundTime - 3.5, 1.0) target:self selector:@selector(backgroundExpirationTimerEvent:) userInfo:nil repeats:false];
    [[NSRunLoop mainRunLoop] addTimer:_backgroundTaskExpirationTimer forMode:NSRunLoopCommonModes];
    
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        [ActionStageInstance() removeWatcher:TGTelegraphInstance fromPath:@"/tg/service/updatepresence/(online)"];
        [ActionStageInstance() removeWatcher:TGTelegraphInstance fromPath:@"/tg/service/updatepresence/(offline)"];
        [ActionStageInstance() requestActor:@"/tg/service/updatepresence/(timeout)" options:nil watcher:TGTelegraphInstance];
    }];
    
    _didBecomeInactive = true;
    
    if ([self isManuallyLocked]) {
        [self displayUnlockWindowIfNeeded];
    }
    
    if ([self respondsToSelector:@selector(onBecomeInactive)])
        [self onBecomeInactive];
}

- (void)backgroundExpirationTimerEvent:(NSTimer *)__unused timer
{
    bool isIos6 = [[UIDevice currentDevice].systemVersion intValue] <= 6;
    if (TGIOS6NotificationSettingsGateEnabled && isIos6 && _ios6NotificationTransportAllowedForBackgroundSession && !TGTelegraphInstance.callManager.hasActiveCall)
    {
        UIRemoteNotificationType enabledTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        if ((enabledTypes & (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)) == UIRemoteNotificationTypeNone)
        {
            _ios6NotificationTransportAllowedForBackgroundSession = false;
            [[UIApplication sharedApplication] clearKeepAliveTimeout];
        }
    }
    bool preserveIos6NotificationTransport = isIos6 && !_disableBackgroundMode && _ios6NotificationTransportAllowedForBackgroundSession;
    if (isIos6)
        IOS6NotificationProbe(@"LIFECYCLE", @"initial_task_expire preserve=%d network=%d connecting=%d updating=%d",
                              preserveIos6NotificationTransport ? 1 : 0,
                              [[TGTelegramNetworking instance] isNetworkAvailable] ? 1 : 0,
                              [[TGTelegramNetworking instance] isConnecting] ? 1 : 0,
                              [[TGTelegramNetworking instance] isUpdating] ? 1 : 0);
    if (preserveIos6NotificationTransport)
    {
        TGLog(@"IOS6PUSH voipKeepAlive preserving MTProto network after background task");
    }
    else if (!isIos6 || !TGTelegraphInstance.callManager.hasActiveCall)
    {
        [[TGTelegramNetworking instance] pause];
    }
    
    _backgroundTaskExpirationTimer = nil;
    
    UIBackgroundTaskIdentifier identifier = _backgroundTaskIdentifier;
    
    TGLog(@"Background: task %d end imminent", identifier);
    _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    if (identifier == UIBackgroundTaskInvalid)
        TGLog(@"***** Strange. *****");
    
    TGDispatchAfter(3.0, dispatch_get_main_queue(), ^
    {
        TGLog(@"Background: ended task it %d", identifier);
        [[UIApplication sharedApplication] endBackgroundTask:identifier];
    });
}

- (bool)backgroundTaskOngoing
{
    return (_backgroundTaskExpirationTimer != nil);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    if ([[UIDevice currentDevice].systemVersion intValue] <= 6)
        IOS6NotificationProbe(@"LIFECYCLE", @"foreground_enter network=%d connecting=%d updating=%d",
                              [[TGTelegramNetworking instance] isNetworkAvailable] ? 1 : 0,
                              [[TGTelegramNetworking instance] isConnecting] ? 1 : 0,
                              [[TGTelegramNetworking instance] isUpdating] ? 1 : 0);

    _enteringForeground = true;

    if ([[UIDevice currentDevice].systemVersion intValue] <= 6)
    {
        [application clearKeepAliveTimeout];
        [self ios6CancelVoipHealthCheck];
        [self ios6EndColdLaunchTask];
        _ios6VoipLastProactiveTransportRefreshTime = 0.0;
        _ios6NotificationTransportAllowedForBackgroundSession = false;
    }
    dispatch_async(dispatch_get_main_queue(), ^
    {
        _inBackground = false;
        _enteringForeground = false;
    });
    
    if (_backgroundTaskIdentifier != UIBackgroundTaskInvalid)
    {
        UIBackgroundTaskIdentifier identifier = _backgroundTaskIdentifier;
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        [application endBackgroundTask:identifier];
    }
    if (_backgroundTaskExpirationTimer != nil)
    {
        if ([_backgroundTaskExpirationTimer isValid])
            [_backgroundTaskExpirationTimer invalidate];
        _backgroundTaskExpirationTimer = nil;
    }
    
    if (_callingWebView != nil)
    {
        [_callingWebView stopLoading];
        _callingWebView = nil;
    }
    
    [[TGTelegramNetworking instance] resume];
}

- (void)applicationDidBecomeActive:(UIApplication *)__unused application
{
    // Covers the narrow foreground-transition race where a keep-alive block
    // was already queued when applicationWillEnterForeground cleared it.
    if ([[UIDevice currentDevice].systemVersion intValue] <= 6)
    {
        IOS6NotificationProbe(@"LIFECYCLE", @"became_active network=%d connecting=%d updating=%d",
                              [[TGTelegramNetworking instance] isNetworkAvailable] ? 1 : 0,
                              [[TGTelegramNetworking instance] isConnecting] ? 1 : 0,
                              [[TGTelegramNetworking instance] isUpdating] ? 1 : 0);
        [self ios6CancelVoipHealthCheck];
        [TGDatabaseInstance() ios6FlushDeferredBackgroundUpdates];
    }

    [self hideBlurredContentIfNeeded];
    
    [_isActive set:[SSignal single:@true]];
    
    if (_didBecomeInactive)
    {
        _didBecomeInactive = false;
        
        if ([self respondsToSelector:@selector(onBecomeActive)])
            [self onBecomeActive];
        
        if (_passcodeWindow != nil && [self isManuallyLocked])
        {
            [_window endEditing:true];
            
            TGPasscodeEntryController *controller = (TGPasscodeEntryController *)(((TGNavigationController *)_passcodeWindow.rootViewController).topViewController);
            [controller refreshTouchId];
        }
        
    }
    
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        if ([ActionStageInstance() executingActorWithPath:@"/tg/service/updatepresence/(timeout)"] != nil)
        {
            [ActionStageInstance() removeWatcher:TGTelegraphInstance fromPath:@"/tg/service/updatepresence/(timeout)"];
        }
        else
        {
            [TGTelegraphInstance updatePresenceNow];
        }
    }];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if ([[UIDevice currentDevice].systemVersion intValue] <= 6)
        [[TGRemoteControlsManager instance] handleLegacyRemoteControlEvent:event];
}

- (void)applicationWillTerminate:(UIApplication *)__unused application
{
    if ([[UIDevice currentDevice].systemVersion intValue] <= 6)
        IOS6NotificationProbe(@"LIFECYCLE", @"will_terminate");
    TGLogSynchronize();
}

- (void)resetLocalization
{
    [TGDateUtils reset];
    
    [_rootController localizationUpdated];
    [[TGInterfaceManager instance] localizationUpdated];
    
//    [[[TGBridgeServer instanceSignal] onNext:^(TGBridgeServer *server) {
//        //[server putNext:@(TGIsCustomLocalizationActive()) forKey:@"localization"];
//    }] startWithNext:nil];
    
    _localizationUpdatedPipe.sink(@true);
}

- (void)performPhoneCall:(NSURL *)url
{
    NSURL *realUrl = url;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        if ([url.scheme isEqualToString:@"tel"])
        {
            realUrl = [NSURL URLWithString:[[url absoluteString] stringByReplacingOccurrencesOfString:@"tel:" withString:@"facetime:"]];
        }
    }
    //_callingWebView = [[UIWebView alloc] init];
    //[_callingWebView loadRequest:[NSURLRequest requestWithURL:realUrl]];
    
    [(TGApplication *)[TGApplication sharedApplication] nativeOpenURL:realUrl];
}

- (void)presentLoginController:(bool)clearControllerStates animated:(bool)animated phoneNumber:(NSString *)phoneNumber phoneCode:(NSString *)phoneCode phoneCodeHash:(NSString *)phoneCodeHash codeSentToTelegram:(bool)codeSentToTelegram codeSentViaPhone:(bool)codeSentViaPhone profileFirstName:(NSString *)profileFirstName profileLastName:(NSString *)profileLastName resetAccountState:(TGResetAccountState *)resetAccountState termsOfService:(TGTermsOfService *)termsOfService
{
    if (![[NSThread currentThread] isMainThread])
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self presentLoginController:clearControllerStates animated:animated phoneNumber:phoneNumber phoneCode:phoneCode phoneCodeHash:phoneCodeHash codeSentToTelegram:codeSentToTelegram codeSentViaPhone:codeSentViaPhone profileFirstName:profileFirstName profileLastName:profileLastName resetAccountState:resetAccountState termsOfService:termsOfService];
        });
        
        return;
    }
    else
    {
        TGNavigationController *loginNavigationController = [self loginNavigationController];
        //if (iosMajorVersion() >= 12)
        //    loginNavigationController.navigationBar.tintColor = TGAccentColor();
        NSMutableArray *viewControllers = [[loginNavigationController viewControllers] mutableCopy];
        
        if (phoneNumber.length != 0)
        {
            UIViewController *firstController = viewControllers.firstObject;
            [viewControllers removeAllObjects];
            if (firstController != nil) {
                [viewControllers addObject:firstController];
            }
            
            TGLoginPhoneController *phoneController = [[TGLoginPhoneController alloc] init];
            [(TGLoginPhoneController *)phoneController setPhoneNumber:phoneNumber];
            [viewControllers addObject:phoneController];
            
            NSMutableString *cleanPhone = [[NSMutableString alloc] init];
            for (int i = 0; i < (int)phoneNumber.length; i++)
            {
                unichar c = [phoneNumber characterAtIndex:i];
                if (c >= '0' && c <= '9')
                    [cleanPhone appendString:[[NSString alloc] initWithCharacters:&c length:1]];
            }
            
            if (resetAccountState != nil) {
                [viewControllers addObject:[[TGLoginResetAccountProtectedController alloc] initWithPhoneNumber:resetAccountState.phoneNumber protectedUntilDate:resetAccountState.protectedUntilDate]];
            } else if (phoneCode.length != 0 && phoneCodeHash.length != 0) {
                TGLoginProfileController *profileController = [[TGLoginProfileController alloc] initWithShowKeyboard:true phoneNumber:cleanPhone phoneCodeHash:phoneCodeHash phoneCode:phoneCode termsOfService:termsOfService];
                [viewControllers addObject:profileController];
            }
            else if (phoneCodeHash.length != 0)
            {
                TGLoginCodeController *codeController = [[TGLoginCodeController alloc] initWithShowKeyboard:true phoneNumber:cleanPhone phoneCodeHash:phoneCodeHash phoneTimeout:60.0 messageSentToTelegram:codeSentToTelegram messageSentViaPhone:codeSentViaPhone termsOfService:termsOfService];
                [viewControllers addObject:codeController];
            }
        }
        
        [loginNavigationController setViewControllers:viewControllers animated:animated];
        
        if (TGAppDelegateInstance.rootController.presentedViewController != nil)
        {
            if (TGAppDelegateInstance.rootController.presentedViewController == loginNavigationController)
                return;
            
            [TGAppDelegateInstance.rootController dismissViewControllerAnimated:true completion:nil];
            TGDispatchAfter(0.5, dispatch_get_main_queue(), ^
            {
                [TGAppDelegateInstance.rootController presentViewController:loginNavigationController animated:[[UIApplication sharedApplication] applicationState] == UIApplicationStateActive completion:nil];
            });
        }
        else
        {
            [TGAppDelegateInstance.rootController resetControllers];
            [TGAppDelegateInstance.rootController presentViewController:loginNavigationController animated:[[UIApplication sharedApplication] applicationState] == UIApplicationStateActive completion:nil];
        }
        
        if (clearControllerStates)
        {
            TGDispatchAfter(0.5, dispatch_get_main_queue(), ^
            {
                [_rootController.mainTabsController setSelectedIndex:2];
                
                [_rootController.dialogListController.dialogListCompanion clearData];
                [_rootController.contactsController clearData];
                [_rootController.callsController clearData];
                
                [TGAppDelegateInstance.rootController clearContentControllers];
                
                [TGAppDelegateInstance resetControllerStack];
            });
        }
    }
}

- (void)presentMainController
{
    if (![[NSThread currentThread] isMainThread])
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self presentMainController];
        });
        
        return;
    }
    
    self.loginNavigationController = nil;
    
    UIViewController *presentedViewController = nil;
    presentedViewController = TGAppDelegateInstance.rootController.presentedViewController;
    
    if ([presentedViewController respondsToSelector:@selector(isBeingDismissed)] && ([presentedViewController isBeingDismissed] || [presentedViewController isBeingPresented]))
    {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        TGDispatchAfter(0.1, dispatch_get_main_queue(), ^
        {
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            
            [self presentMainController];
        });
    }
    else
    {
        [TGAppDelegateInstance.rootController dismissViewControllerAnimated:[[UIApplication sharedApplication] applicationState] == UIApplicationStateActive completion:nil];
        
        if (self.onSuccessfulLogin != nil)
        {
            self.onSuccessfulLogin();
            self.onSuccessfulLogin = nil;
        }
    }
}

- (void)presentContentController:(UIViewController *)controller
{
    _contentWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _contentWindow.windowLevel = UIWindowLevelStatusBar - 0.1f;
    
    _contentWindow.rootViewController = controller;
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [_contentWindow makeKeyAndVisible];
    });
}

- (void)dismissContentController
{
    if ([_contentWindow.rootViewController conformsToProtocol:@protocol(TGContentViewController)])
    {
        [(id<TGContentViewController>)_contentWindow.rootViewController contentControllerWillBeDismissed];
    }
    
    [_contentWindow.rootViewController viewWillDisappear:false];
    [_contentWindow.rootViewController viewDidDisappear:false];
    _contentWindow.rootViewController = nil;
    if (_contentWindow.isKeyWindow)
        [_contentWindow resignKeyWindow];
    [_window makeKeyWindow];
    _contentWindow = nil;
    
    UIViewController *topViewController = TGAppDelegateInstance.rootController.viewControllers.lastObject;
    if ([topViewController conformsToProtocol:@protocol(TGDestructableViewController)] && [topViewController respondsToSelector:@selector(contentControllerWillBeDismissed)]) {
        [(id<TGDestructableViewController>)topViewController contentControllerWillBeDismissed];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        if (!_window.isKeyWindow)
            [_window makeKeyWindow];
    });
}

- (void)openURLNative:(NSURL *)url
{
    [(TGApplication *)[UIApplication sharedApplication] openURL:url forceNative:true];
}

#pragma mark -

- (NSDictionary *)loadLoginState
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    NSString *documentsDirectory = TGAppDelegateDocumentsPathCompat();
    NSData *stateData = [[NSData alloc] initWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"state.data"]];
    
    if (stateData.length != 0)
    {
        NSInputStream *is = [[NSInputStream alloc] initWithData:stateData];
        [is open];
        
        uint8_t version = 0;
        [is read:(uint8_t *)&version maxLength:1];
        
        {
            int date = [is readInt32];
            if (date != 0)
                dict[@"date"] = @(date);
        }
        
        {
            NSString *phoneNumber = [is readString];
            if (phoneNumber.length != 0)
                dict[@"phoneNumber"] = phoneNumber;
        }
        
        {
            NSString *phoneCode = [is readString];
            if (phoneCode.length != 0)
                dict[@"phoneCode"] = phoneCode;
        }
        
        {
            NSString *phoneCodeHash = [is readString];
            if (phoneCodeHash.length != 0)
                dict[@"phoneCodeHash"] = phoneCodeHash;
        }
        
        {
            NSString *firstName = [is readString];
            if (firstName.length != 0)
                dict[@"firstName"] = firstName;
        }
        
        {
            NSString *lastName = [is readString];
            if (lastName.length != 0)
                dict[@"lastName"] = lastName;
        }
        
        {
            NSData *photo = [is readBytes];
            if (photo.length != 0)
                dict[@"photo"] = photo;
        }
        
        if (version >= 1)
        {
            dict[@"codeSentToTelegram"] = @([is readInt32] != 0);
            
            if (version >= 2) {
                dict[@"codeSentViaPhone"] = @([is readInt32] != 0);
                
                if (version >= 3) {
                    int32_t length = [is readInt32];
                    if (length != 0) {
                        TGResetAccountState *resetAccountState = [NSKeyedUnarchiver unarchiveObjectWithData:[is readData:length]];
                        if ([resetAccountState isKindOfClass:[TGResetAccountState class]]) {
                            dict[@"resetAccountState"] = resetAccountState;
                        }
                    }
                }
            }
        }
        
        [is close];
    }
    
    return dict;
}

- (void)resetLoginState
{
    NSString *documentsDirectory = TGAppDelegateDocumentsPathCompat();
    [[NSFileManager defaultManager] removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"state.data"] error:nil];
}

- (void)saveLoginStateWithDate:(int)date phoneNumber:(NSString *)phoneNumber phoneCode:(NSString *)phoneCode phoneCodeHash:(NSString *)phoneCodeHash codeSentToTelegram:(bool)codeSentToTelegram codeSentViaPhone:(bool)codeSentViaPhone firstName:(NSString *)firstName lastName:(NSString *)lastName photo:(NSData *)photo resetAccountState:(TGResetAccountState *)resetAccountState
{
    NSOutputStream *os = [[NSOutputStream alloc] initToMemory];
    [os open];
    
    uint8_t version = 3;
    [os write:&version maxLength:1];
    
    [os writeInt32:date];
    
    [os writeString:phoneNumber];
    [os writeString:phoneCode];
    [os writeString:phoneCodeHash];
    [os writeString:firstName];
    [os writeString:lastName];
    [os writeBytes:photo];
    [os writeInt32:codeSentToTelegram ? 1 : 0];
    [os writeInt32:codeSentViaPhone ? 1 : 0];
    
    if (resetAccountState != nil) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:resetAccountState];
        int32_t length = (int32_t)data.length;
        [os writeInt32:length];
        [os writeData:data];
    } else {
        [os writeInt32:0];
    }
    
    [os close];
    
    NSData *data = [os currentBytes];
    NSString *documentsDirectory = TGAppDelegateDocumentsPathCompat();
    [data writeToFile:[documentsDirectory stringByAppendingPathComponent:@"state.data"] atomically:true];
}

- (void)migrateSettings
{
    NSUserDefaults *legacyUserDefaults = [NSUserDefaults standardUserDefaults];
    TGUserDefaults *userDefaults = [TGUserDefaults standard];
    
    NSArray *keys = @
    [
     @"telegraphUserId",
     @"telegraphUserActivated",
     @"soundEnabled",
     @"outgoingSoundEnabled",
     @"vibrationEnabled",
     @"bannerEnabled",
     @"exclusiveConversationControllers",
     @"saveEditedPhotos",
     @"customChatBackground",
     @"useDifferentBackend",
     @"autoSavePhotosMode",
     @"autoPlayAudio",
     @"autoPlayAnimations",
     @"alwaysShowStickersMode",
     @"allowSecretWebpages",
     @"allowSecretWebpagesInitialized",
     @"secretInlineBotsInitialized",
     @"callsDataUsageMode",
     @"callsDisableP2P",
     @"callsDisableCallKit",
     @"callsUseProxy",
     @"contactsInhibitSync",
     @"stickersSuggestMode"
    ];
    
    for (NSString *key in keys)
    {
        id value = nil;
        if ((value = [legacyUserDefaults objectForKey:key]) != nil)
            [userDefaults setObject:value forKey:key];
    }
    [userDefaults synchronize];
    
    for (NSString *key in keys)
    {
        [legacyUserDefaults removeObjectForKey:key];
    }
    [legacyUserDefaults synchronize];
}

- (void)loadSettings
{
    NSUserDefaults *legacyUserDefaults = [NSUserDefaults standardUserDefaults];
    TGUserDefaults *userDefaults = [TGUserDefaults standard];
    
    int32_t userId = [[userDefaults objectForKey:@"telegraphUserId"] intValue];
    int32_t legacyUserId = [[legacyUserDefaults objectForKey:@"telegraphUserId"] intValue];
    
    if (userId == 0 && legacyUserId != 0)
        [self migrateSettings];

	    TGTelegraphInstance.clientUserId = [[userDefaults objectForKey:@"telegraphUserId"] intValue];
	    TGTelegraphInstance.clientIsActivated = [[userDefaults objectForKey:@"telegraphUserActivated"] boolValue];
	    
	    TGLog(@"Activated = %d", TGTelegraphInstance.clientIsActivated ? 1 : 0);
        TGLog(@"IOS6AUTH settings.load userId=%d activated=%d legacyUserId=%d migrated=%d", TGTelegraphInstance.clientUserId, TGTelegraphInstance.clientIsActivated ? 1 : 0, legacyUserId, (userId == 0 && legacyUserId != 0) ? 1 : 0);
    
    id value = nil;
    if ((value = [userDefaults objectForKey:@"soundEnabled"]) != nil)
        _soundEnabled = [value boolValue];
    else
        _soundEnabled = true;
    
    if ((value = [userDefaults objectForKey:@"outgoingSoundEnabled"]) != nil)
        _outgoingSoundEnabled = [value boolValue];
    else
        _outgoingSoundEnabled = true;
    
    if ((value = [userDefaults objectForKey:@"vibrationEnabled"]) != nil)
        _vibrationEnabled = [value boolValue];
    else
        _vibrationEnabled = false;
    
    if ((value = [userDefaults objectForKey:@"bannerEnabled"]) != nil)
        _bannerEnabled = [value boolValue];
    else
        _bannerEnabled = true;
    
    if ((value = [userDefaults objectForKey:@"exclusiveConversationControllers"]) != nil)
        _exclusiveConversationControllers = [value boolValue];
    else
        _exclusiveConversationControllers = true;
    
    if ((value = [userDefaults objectForKey:@"saveEditedPhotos"]) != nil)
        _saveEditedPhotos = [value boolValue];
    else
        _saveEditedPhotos = true;
    
    _saveCapturedMedia = true;

    if ((value = [userDefaults objectForKey:@"customChatBackground"]) != nil)
        _customChatBackground = [value boolValue];
    else
    {
        _customChatBackground = false;
        
        NSString *imageUrl = @"wallpaper-original-pattern-default";
        NSString *thumbnailUrl = @"local://wallpaper-thumb-pattern-default";
        NSString *filePath = [[NSBundle mainBundle] pathForResource:imageUrl ofType:@"jpg"];
        int tintColor = 0x0c3259;
        
        if (filePath != nil)
        {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSString *documentsDirectory = TGAppDelegateDocumentsPathCompat();
            NSString *wallpapersPath = [documentsDirectory stringByAppendingPathComponent:@"wallpapers"];
            [fileManager createDirectoryAtPath:wallpapersPath withIntermediateDirectories:true attributes:nil error:nil];
            
            [fileManager copyItemAtPath:filePath toPath:[wallpapersPath stringByAppendingPathComponent:@"_custom.jpg"] error:nil];
            [[thumbnailUrl dataUsingEncoding:NSUTF8StringEncoding] writeToFile:[wallpapersPath stringByAppendingPathComponent:@"_custom-meta"] atomically:true];
            
            [(tintColor == -1 ? [NSData data] : [[NSData alloc] initWithBytes:&tintColor length:4]) writeToFile:[wallpapersPath stringByAppendingPathComponent:@"_custom_mono.dat"] atomically:true];
            
            _customChatBackground = true;
        }
    }

    if ((value = [userDefaults objectForKey:@"useDifferentBackend"]) != nil)
        _useDifferentBackend = [value boolValue];
    else
        _useDifferentBackend = true;
    
    if ((value = [userDefaults objectForKey:@"autoSavePhotosMode"]) != nil)
        _autoSavePhotosMode = (TGAutoDownloadMode)[value intValue];
    
    _autoDownloadPreferences = [self loadAutoDownloadPreferences];
    
    if ((value = [userDefaults objectForKey:@"autoPlayAudio"]) != nil)
        _autoPlayAudio = [value boolValue];
    else
        _autoPlayAudio = false;
    
    if ((value = [userDefaults objectForKey:@"autoPlayAnimations"]) != nil)
        _autoPlayAnimations = [value boolValue];
    else
        _autoPlayAnimations = cpuCoreCount() > 1;
    
    if ((value = [userDefaults objectForKey:@"alwaysShowStickersMode"]) != nil)
        _alwaysShowStickersMode = [value intValue];
    else
        _alwaysShowStickersMode = false;
    
    if ((value = [userDefaults objectForKey:@"allowSecretWebpages"]) != nil)
        _allowSecretWebpages = [value intValue];
    else
        _allowSecretWebpages = false;
    
    if ((value = [userDefaults objectForKey:@"allowSecretWebpagesInitialized"]) != nil)
        _allowSecretWebpagesInitialized = [value intValue];
    else
        _allowSecretWebpagesInitialized = false;
    
    if ((value = [userDefaults objectForKey:@"secretInlineBotsInitialized"]) != nil)
        _secretInlineBotsInitialized = [value intValue];
    else
        _secretInlineBotsInitialized = false;
    
    if ((value = [userDefaults objectForKey:@"callsDataUsageMode"]) != nil)
        _callsDataUsageMode = [value intValue];
    else
        _callsDataUsageMode = 0;
    
    if ((value = [userDefaults objectForKey:@"callsDisableP2P"]) != nil)
        _callsP2PMode = [value intValue];
    else
        _callsP2PMode = false;
    
    if ((value = [userDefaults objectForKey:@"callsDisableCallKit"]) != nil)
        _callsDisableCallKit = [value boolValue];
    else
        _callsDisableCallKit = false;
    
    if ((value = [userDefaults objectForKey:@"callsUseProxy"]) != nil)
        _callsUseProxy = [value boolValue];
    else
        _callsUseProxy = false;
    
    if ((value = [userDefaults objectForKey:@"contactsInhibitSync"]) != nil)
        _contactsInhibitSync = [value boolValue];
    else
        _contactsInhibitSync = false;
    
    if ((value = [userDefaults objectForKey:@"stickersSuggestMode"]) != nil)
        _stickersSuggestMode = [value intValue];
    else
        _stickersSuggestMode = 0;
}

- (NSString *)autoDownloadPreferencesPath
{
    return [TGAppDelegateDocumentsPathCompat() stringByAppendingPathComponent:@"autoDownload.pref"];
}

- (TGAutoDownloadPreferences *)loadAutoDownloadPreferences
{
    TGAutoDownloadPreferences *preferences = [TGAutoDownloadPreferences defaultPreferences];
    
    NSData *preferencesData = [[NSData alloc] initWithContentsOfFile:[self autoDownloadPreferencesPath]];
    if (preferencesData.length != 0)
    {
        TGAutoDownloadPreferences *loadedPreferences = nil;
        @try {
            loadedPreferences = [NSKeyedUnarchiver unarchiveObjectWithData:preferencesData];
        } @catch (NSException *e) {
        }
        
        if (loadedPreferences != nil)
            preferences = loadedPreferences;
    }
    
    return preferences;
}

- (void)setAutoDownloadPreferences:(TGAutoDownloadPreferences *)autoDownloadPreferences
{
    if (autoDownloadPreferences == nil)
        return;
    
    _autoDownloadPreferences = autoDownloadPreferences;
    [[NSKeyedArchiver archivedDataWithRootObject:autoDownloadPreferences] writeToFile:[self autoDownloadPreferencesPath] atomically:true];
}

- (void)setAutoSavePhotosMode:(TGAutoDownloadMode)autoSavePhotosMode
{
    _autoSavePhotosMode = autoSavePhotosMode;
    
    TGUserDefaults *userDefaults = [TGUserDefaults standard];
    [userDefaults setObject:[NSNumber numberWithInt:_autoSavePhotosMode] forKey:@"autoSavePhotosMode"];
    [userDefaults synchronize];
}

- (void)saveSettings
{
    if (_autoDownloadPreferences == nil)
        return;
    
    TGUserDefaults *userDefaults = [TGUserDefaults standard];
    
	    [userDefaults setObject:[[NSNumber alloc] initWithInt:TGTelegraphInstance.clientUserId] forKey:@"telegraphUserId"];
	    [userDefaults setObject:[[NSNumber alloc] initWithBool:TGTelegraphInstance.clientIsActivated] forKey:@"telegraphUserActivated"];
        TGLog(@"IOS6AUTH settings.save userId=%d activated=%d", TGTelegraphInstance.clientUserId, TGTelegraphInstance.clientIsActivated ? 1 : 0);
    
    [userDefaults setObject:[NSNumber numberWithBool:_soundEnabled] forKey:@"soundEnabled"];
    [userDefaults setObject:[NSNumber numberWithBool:_outgoingSoundEnabled] forKey:@"outgoingSoundEnabled"];
    [userDefaults setObject:[NSNumber numberWithBool:_vibrationEnabled] forKey:@"vibrationEnabled"];
    [userDefaults setObject:[NSNumber numberWithBool:_bannerEnabled] forKey:@"bannerEnabled"];
    [userDefaults setObject:[NSNumber numberWithBool:_exclusiveConversationControllers] forKey:@"exclusiveConversationControllers"];
    
    [userDefaults setObject:[NSNumber numberWithBool:_saveEditedPhotos] forKey:@"saveEditedPhotos"];
    [userDefaults setObject:[NSNumber numberWithBool:_saveCapturedMedia] forKey:@"saveCapturedMedia"];
    [userDefaults setObject:[NSNumber numberWithBool:_customChatBackground] forKey:@"customChatBackground"];

    [userDefaults setObject:[NSNumber numberWithBool:_useDifferentBackend] forKey:@"useDifferentBackend"];

    [userDefaults setObject:[NSNumber numberWithInt:TGBaseFontSize] forKey:@"baseFontSize"];
    
    [userDefaults setObject:[NSNumber numberWithBool:_autoPlayAudio] forKey:@"autoPlayAudio"];
    [userDefaults setObject:[NSNumber numberWithBool:_autoPlayAnimations] forKey:@"autoPlayAnimations"];
    
    [userDefaults setObject:[NSNumber numberWithInt:_alwaysShowStickersMode] forKey:@"alwaysShowStickersMode"];
    
    [userDefaults setObject:[NSNumber numberWithInt:_allowSecretWebpages] forKey:@"allowSecretWebpages"];
    [userDefaults setObject:[NSNumber numberWithInt:_allowSecretWebpagesInitialized] forKey:@"allowSecretWebpagesInitialized"];
    
    [userDefaults setObject:[NSNumber numberWithInt:_secretInlineBotsInitialized] forKey:@"secretInlineBotsInitialized"];
    
    [userDefaults setObject:[NSNumber numberWithInt:_callsDataUsageMode] forKey:@"callsDataUsageMode"];
    
    [userDefaults setObject:[NSNumber numberWithInt:_callsP2PMode] forKey:@"callsDisableP2P"];
    [userDefaults setObject:[NSNumber numberWithBool:_callsDisableCallKit] forKey:@"callsDisableCallKit"];
    [userDefaults setObject:[NSNumber numberWithBool:_callsUseProxy] forKey:@"callsUseProxy"];
    
    [userDefaults setObject:[NSNumber numberWithBool:_contactsInhibitSync] forKey:@"contactsInhibitSync"];
    
    [userDefaults setObject:[NSNumber numberWithInt:_stickersSuggestMode] forKey:@"stickersSuggestMode"];
    
    [userDefaults synchronize];
}

#pragma mark -

- (NSArray *)modernAlertSoundTitles
{
    return @[
        TGLocalized(@"NotificationsSound.None"),
        TGLocalized(@"NotificationsSound.Note"),
        TGLocalized(@"NotificationsSound.Aurora"),
        TGLocalized(@"NotificationsSound.Bamboo"),
        TGLocalized(@"NotificationsSound.Chord"),
        TGLocalized(@"NotificationsSound.Circles"),
        TGLocalized(@"NotificationsSound.Complete"),
        TGLocalized(@"NotificationsSound.Hello"),
        TGLocalized(@"NotificationsSound.Input"),
        TGLocalized(@"NotificationsSound.Keys"),
        TGLocalized(@"NotificationsSound.Popcorn"),
        TGLocalized(@"NotificationsSound.Pulse"),
        TGLocalized(@"NotificationsSound.Synth")
    ];
}

- (NSArray *)classicAlertSoundTitles
{
    return @[
        TGLocalized(@"NotificationsSound.Tritone"),
        TGLocalized(@"NotificationsSound.Tremolo"),
        TGLocalized(@"NotificationsSound.Alert"),
        TGLocalized(@"NotificationsSound.Bell"),
        TGLocalized(@"NotificationsSound.Calypso"),
        TGLocalized(@"NotificationsSound.Chime"),
        TGLocalized(@"NotificationsSound.Glass"),
        TGLocalized(@"NotificationsSound.Telegraph")
    ];
    static NSArray *soundArray = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [array addObject:@"Tri-tone"];
        [array addObject:@"Tremolo"];
        [array addObject:@"Alert"];
        [array addObject:@"Bell"];
        [array addObject:@"Calypso"];
        [array addObject:@"Chime"];
        [array addObject:@"Glass"];
        [array addObject:@"Telegraph"];
        soundArray = array;
    });
    
    return soundArray;
}

- (void)playSound:(NSString *)name vibrate:(bool)vibrate
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
            return;
        
        if (name != nil && TGAppDelegateInstance.soundEnabled)
        {
            static NSMutableDictionary *soundPlayed = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                soundPlayed = [[NSMutableDictionary alloc] init];
            });
            
            double lastTimeSoundPlayed = [[soundPlayed objectForKey:name] doubleValue];
            
            CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
            if (currentTime - lastTimeSoundPlayed < 0.25)
                return;
        
            [soundPlayed setObject:[[NSNumber alloc] initWithDouble:currentTime] forKey:name];
        
            NSNumber *soundId = [_loadedSoundSamples objectForKey:name];
            if (soundId == nil)
            {
                NSString *path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], name];
                NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
                SystemSoundID sound;
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &sound);
                soundId = [NSNumber numberWithUnsignedLong:sound];
                [_loadedSoundSamples setObject:soundId forKey:name];
            }
            
            CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
            AudioServicesPlaySystemSound((SystemSoundID)[soundId unsignedLongValue]);
            TGLog(@"sound time: %f ms", (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0);
        }
        
        if (vibrate && TGAppDelegateInstance.vibrationEnabled)
        {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
    });
}

- (void)playNotificationSound:(NSString *)name
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        _currentAudioPlayer.delegate = nil;
        _currentAudioPlayer = nil;
        
        NSError *error = nil;
        AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:name withExtension:@"m4a"] error:&error];
        if (error == nil)
        {
            if (_currentAudioPlayerSession == nil)
                _currentAudioPlayerSession = [[SMetaDisposable alloc] init];
            [_currentAudioPlayerSession setDisposable:[[TGAudioSessionManager instance] requestSessionWithType:TGAudioSessionTypePlayMusic interrupted:^
            {
                _currentAudioPlayer.delegate = nil;
                [_currentAudioPlayer stop];
                _currentAudioPlayer = nil;
            }]];
            
            _currentAudioPlayer = audioPlayer;
            audioPlayer.delegate = self;
            [audioPlayer play];
        }
    });
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)__unused flag
{
    if (player == _currentAudioPlayer)
    {
        _currentAudioPlayer.delegate = nil;
        _currentAudioPlayer = nil;
        
        [_currentAudioPlayerSession setDisposable:nil];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)__unused player error:(NSError *)__unused error
{
    if (player == _currentAudioPlayer)
    {
        _currentAudioPlayer.delegate = nil;
        _currentAudioPlayer = nil;
    }
}

#pragma mark -

- (void)requestDeviceToken:(id<TGDeviceTokenListener>)listener
{
    TGLog(@"IOS6PUSH request bundle=%@ state=%d alreadyRequested=%d hasToken=%d",
        [[NSBundle mainBundle] bundleIdentifier],
        (int)[UIApplication sharedApplication].applicationState,
        _tokenAlreadyRequested ? 1 : 0,
        _pushToken != nil ? 1 : 0);

    if (!TGIOS6APNsNotificationsEnabled())
    {
        [listener deviceTokenRequestCompleted:nil];
        [self disableAPNsNotificationRegistration];
        return;
    }

    if (_tokenAlreadyRequested)
    {
        TGLog(@"IOS6PUSH request skipped reason=alreadyRequested");
        NSString *token = nil;
        if (_pushToken != nil)
        {
            token = [[_pushToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
            token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
        }
        [listener deviceTokenRequestCompleted:token];
        return;
    }
    
    _deviceTokenListener = listener;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIMutableUserNotificationCategory *muteActionCategory = [[UIMutableUserNotificationCategory alloc] init];
        [muteActionCategory setIdentifier:@"m"];
        
        UIMutableUserNotificationCategory *replyActionCategory = [[UIMutableUserNotificationCategory alloc] init];
        [replyActionCategory setIdentifier:@"r"];
        
        UIMutableUserNotificationCategory *channelActionCategory = [[UIMutableUserNotificationCategory alloc] init];
        [channelActionCategory setIdentifier:@"c"];
        
        UIMutableUserNotificationCategory *callActionCategory = [[UIMutableUserNotificationCategory alloc] init];
        [callActionCategory setIdentifier:@"p"];

        bool exclusiveQuickReplySupported = ((iosMajorVersion() == 9 && iosMinorVersion() >= 1) || iosMajorVersion() > 9);
        {
            UIMutableUserNotificationAction *replyAction = [[UIMutableUserNotificationAction alloc] init];
            [replyAction setTitle:TGLocalized(@"Notification.Reply")];
            [replyAction setIdentifier:@"reply"];
            [replyAction setDestructive:false];
            if (iosMajorVersion() >= 9)
            {
                [replyAction setAuthenticationRequired:false];
                [replyAction setBehavior:UIUserNotificationActionBehaviorTextInput];
                [replyAction setActivationMode:UIUserNotificationActivationModeBackground];
            }
            else
            {
                [replyAction setAuthenticationRequired:true];
                [replyAction setActivationMode:UIUserNotificationActivationModeForeground];
            }
            
            UIMutableUserNotificationAction *muteAction = [[UIMutableUserNotificationAction alloc] init];
            [muteAction setActivationMode:UIUserNotificationActivationModeBackground];
            [muteAction setTitle:TGLocalized(@"Notification.Mute1h")];
            [muteAction setIdentifier:@"mute"];
            [muteAction setDestructive:true];
            [muteAction setAuthenticationRequired:false];
            
            if (exclusiveQuickReplySupported)
            {
                [muteActionCategory setActions:@[replyAction] forContext:UIUserNotificationActionContextDefault];
            }
            else
            {
                [muteActionCategory setActions:@[replyAction, muteAction] forContext:UIUserNotificationActionContextDefault];
            }
        }
        {
            UIMutableUserNotificationAction *replyAction = [[UIMutableUserNotificationAction alloc] init];
            [replyAction setTitle:TGLocalized(@"Notification.Reply")];
            [replyAction setIdentifier:@"reply"];
            [replyAction setDestructive:false];
            if (iosMajorVersion() >= 9)
            {
                [replyAction setAuthenticationRequired:false];
                [replyAction setBehavior:UIUserNotificationActionBehaviorTextInput];
                [replyAction setActivationMode:UIUserNotificationActivationModeBackground];
            }
            else
            {
                [replyAction setAuthenticationRequired:true];
                [replyAction setActivationMode:UIUserNotificationActivationModeForeground];
            }
            
            UIMutableUserNotificationAction *muteAction = [[UIMutableUserNotificationAction alloc] init];
            [muteAction setActivationMode:UIUserNotificationActivationModeBackground];
            [muteAction setTitle:TGLocalized(@"Notification.Mute1hMin")];
            [muteAction setIdentifier:@"mute"];
            [muteAction setDestructive:true];
            [muteAction setAuthenticationRequired:false];
            
            if (exclusiveQuickReplySupported)
            {
                [muteActionCategory setActions:@[replyAction] forContext:UIUserNotificationActionContextMinimal];
            }
            else
            {
                [muteActionCategory setActions:@[replyAction, muteAction] forContext:UIUserNotificationActionContextMinimal];
            }
        }
        
        {
            UIMutableUserNotificationAction *replyAction = [[UIMutableUserNotificationAction alloc] init];
            [replyAction setTitle:TGLocalized(@"Notification.Reply")];
            [replyAction setIdentifier:@"reply"];
            [replyAction setDestructive:false];
            if (iosMajorVersion() >= 9)
            {
                [replyAction setAuthenticationRequired:false];
                [replyAction setBehavior:UIUserNotificationActionBehaviorTextInput];
                [replyAction setActivationMode:UIUserNotificationActivationModeBackground];
            }
            else
            {
                [replyAction setAuthenticationRequired:true];
                [replyAction setActivationMode:UIUserNotificationActivationModeForeground];
            }
            
            UIMutableUserNotificationAction *likeAction = [[UIMutableUserNotificationAction alloc] init];
            [likeAction setActivationMode:UIUserNotificationActivationModeBackground];
            [likeAction setTitle:@"👍"];
            [likeAction setIdentifier:@"like"];
            [likeAction setDestructive:false];
            [likeAction setAuthenticationRequired:false];
            
            if (exclusiveQuickReplySupported)
            {
                [replyActionCategory setActions:@[replyAction] forContext:UIUserNotificationActionContextDefault];
            }
            else
            {
                [replyActionCategory setActions:@[replyAction, likeAction] forContext:UIUserNotificationActionContextDefault];
            }
        }
        {
            UIMutableUserNotificationAction *replyAction = [[UIMutableUserNotificationAction alloc] init];
            [replyAction setTitle:TGLocalized(@"Notification.Reply")];
            [replyAction setIdentifier:@"reply"];
            [replyAction setDestructive:false];
            if (iosMajorVersion() >= 9)
            {
                [replyAction setAuthenticationRequired:false];
                [replyAction setBehavior:UIUserNotificationActionBehaviorTextInput];
                [replyAction setActivationMode:UIUserNotificationActivationModeBackground];
            }
            else
            {
                [replyAction setAuthenticationRequired:true];
                [replyAction setActivationMode:UIUserNotificationActivationModeForeground];
            }
            
            UIMutableUserNotificationAction *likeAction = [[UIMutableUserNotificationAction alloc] init];
            [likeAction setActivationMode:UIUserNotificationActivationModeBackground];
            [likeAction setTitle:@"👍"];
            [likeAction setIdentifier:@"like"];
            [likeAction setDestructive:false];
            [likeAction setAuthenticationRequired:false];
            
            if (exclusiveQuickReplySupported)
            {
                [replyActionCategory setActions:@[replyAction] forContext:UIUserNotificationActionContextMinimal];
            }
            else
            {
                [replyActionCategory setActions:@[replyAction, likeAction] forContext:UIUserNotificationActionContextMinimal];
            }
        }
        
        {
            UIMutableUserNotificationAction *mute1Action = [[UIMutableUserNotificationAction alloc] init];
            [mute1Action setActivationMode:UIUserNotificationActivationModeBackground];
            [mute1Action setTitle:TGLocalized(@"Notification.Mute1h")];
            [mute1Action setIdentifier:@"mute"];
            [mute1Action setDestructive:true];
            [mute1Action setAuthenticationRequired:false];
            
            UIMutableUserNotificationAction *mute8Action = [[UIMutableUserNotificationAction alloc] init];
            [mute8Action setActivationMode:UIUserNotificationActivationModeBackground];
            [mute8Action setTitle:[effectiveLocalization() getPluralized:@"MuteFor.Hours" count:8]];
            [mute8Action setIdentifier:@"mute8h"];
            [mute8Action setDestructive:true];
            [mute8Action setAuthenticationRequired:false];
            
            [channelActionCategory setActions:@[mute1Action, mute8Action] forContext:UIUserNotificationActionContextDefault];
        }
        {
            UIMutableUserNotificationAction *muteAction = [[UIMutableUserNotificationAction alloc] init];
            [muteAction setActivationMode:UIUserNotificationActivationModeBackground];
            [muteAction setTitle:TGLocalized(@"Notification.Mute1hMin")];
            [muteAction setIdentifier:@"mute"];
            [muteAction setDestructive:true];
            [muteAction setAuthenticationRequired:false];
            
            [channelActionCategory setActions:@[muteAction] forContext:UIUserNotificationActionContextMinimal];
        }
        
        {
            UIMutableUserNotificationAction *callAction = [[UIMutableUserNotificationAction alloc] init];
            [callAction setTitle:TGLocalized(@"Notification.CallBack")];
            [callAction setIdentifier:@"call"];
            [callAction setDestructive:false];
            [callAction setAuthenticationRequired:true];
            [callAction setActivationMode:UIUserNotificationActivationModeForeground];
            
            UIMutableUserNotificationAction *replyAction = [[UIMutableUserNotificationAction alloc] init];
            [replyAction setTitle:TGLocalized(@"Notification.Reply")];
            [replyAction setIdentifier:@"reply"];
            [replyAction setDestructive:false];
            [replyAction setAuthenticationRequired:true];
            [replyAction setActivationMode:UIUserNotificationActivationModeForeground];
            
            [callActionCategory setActions:@[callAction, replyAction] forContext:UIUserNotificationActionContextDefault];
        }
        {
            UIMutableUserNotificationAction *callAction = [[UIMutableUserNotificationAction alloc] init];
            [callAction setTitle:TGLocalized(@"Notification.CallBack")];
            [callAction setIdentifier:@"call"];
            [callAction setDestructive:false];
            [callAction setAuthenticationRequired:true];
            [callAction setActivationMode:UIUserNotificationActivationModeForeground];
            
            UIMutableUserNotificationAction *replyAction = [[UIMutableUserNotificationAction alloc] init];
            [replyAction setTitle:TGLocalized(@"Notification.Reply")];
            [replyAction setIdentifier:@"reply"];
            [replyAction setDestructive:false];
            [replyAction setAuthenticationRequired:true];
            [replyAction setActivationMode:UIUserNotificationActivationModeForeground];
            
            [callActionCategory setActions:@[callAction, replyAction] forContext:UIUserNotificationActionContextMinimal];
        }
        
        NSSet *categories = [NSSet setWithObjects:muteActionCategory, replyActionCategory, channelActionCategory, callActionCategory, nil];
        UIUserNotificationType types = (UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge);
        
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:categories];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        
        _pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
        _pushRegistry.delegate = self;
        _pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    }
    else
#endif
    {
        TGLog(@"IOS6PUSH register legacy types bundle=%@", [[NSBundle mainBundle] bundleIdentifier]);
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)__unused notificationSettings
{
    if (TGIOS6APNsNotificationsEnabled())
        [application registerForRemoteNotifications];
    else
        [self disableAPNsNotificationRegistration];
}

- (void)application:(UIApplication*)__unused application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    if (!TGIOS6APNsNotificationsEnabled())
    {
        [_deviceTokenListener deviceTokenRequestCompleted:nil];
        _deviceTokenListener = nil;
        [self disableAPNsNotificationRegistration];
        return;
    }

    _tokenAlreadyRequested = true;
    _pushToken = deviceToken;
    
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    TGLog(@"IOS6PUSH token success bundle=%@ bytes=%d hexLength=%d", [[NSBundle mainBundle] bundleIdentifier], (int)deviceToken.length, (int)token.length);
    
    [_deviceTokenListener deviceTokenRequestCompleted:token];
    _deviceTokenListener = nil;
}

- (void)application:(UIApplication*)__unused application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    _tokenAlreadyRequested = true;
    
	TGLog(@"IOS6PUSH token failure bundle=%@ domain=%@ code=%d error=%@", [[NSBundle mainBundle] bundleIdentifier], error.domain, (int)error.code, error);
    [_deviceTokenListener deviceTokenRequestCompleted:nil];
    _deviceTokenListener = nil;
}

- (void)pushRegistry:(PKPushRegistry *)__unused registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type
{
    if (type != PKPushTypeVoIP)
        return;
    if (!TGIOS6APNsNotificationsEnabled())
    {
        [self disableAPNsNotificationRegistration];
        return;
    }
    
    NSString *token = [[credentials.token description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    TGLog(@"Device VoIP token received (%d hex characters)", (int)token.length);
    
    [[TGAccountSignals registerDeviceToken:token voip:true] startWithNext:nil];
}

- (void)pushRegistry:(PKPushRegistry *)__unused registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)__unused type
{
#ifdef INTERNAL_RELEASE
    TGLog(@"voip push: %@", payload.dictionaryPayload);
#endif
    
    [self processPossibleAnnouncement:payload.dictionaryPayload];
    [self processPossibleLiveLocationRequest:payload.dictionaryPayload];
    [self processPossibleCallRequest:payload.dictionaryPayload];
    [self processPossibleConfigUpdateNotification:payload.dictionaryPayload];
}

- (void)application:(UIApplication *)__unused application didReceiveLocalNotification:(UILocalNotification *)notification
{
    if (iosMajorVersion() >= 8 && [notification.category isEqualToString:@"wr"])
    {
        [TGBridgeRemoteHandler handleLocalNotification:notification.userInfo];
        return;
    }
    
    if (!_inBackground || [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return;
    
    int64_t peerId = [[notification.userInfo objectForKey:@"cid"] longLongValue];
    TGIOS6OpenNotificationPeer(peerId);
}

- (void)application:(UIApplication *)__unused application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    TGLog(@"IOS6PUSH remote received state=%d inBackground=%d keys=%@",
        (int)[UIApplication sharedApplication].applicationState,
        _inBackground ? 1 : 0,
        [[userInfo allKeys] componentsJoinedByString:@","]);
#ifdef DEBUG
    TGLog(@"remoteNotification: %@", userInfo);
#endif
    
    [self processPossibleCloudKitNotification:userInfo];
    [self processPossibleConfigUpdateNotification:userInfo];
    [self processPossibleAnnouncement:userInfo];
    
    if (!_inBackground)
        return;
    
    [self processRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)__unused application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self processPossibleCloudKitNotification:userInfo];
    [self processPossibleConfigUpdateNotification:userInfo];
    [self processPossibleAnnouncement:userInfo];
    
    if ([application applicationState] != UIApplicationStateActive)
    {
        if ([self isCurrentlyLocked] && (_passcodeWindow == nil || _passcodeWindow.hidden))
            [self displayUnlockWindowIfNeeded];
        
        [[TGTelegramNetworking instance] resume];
        
        if (completionHandler != nil)
        {
            [[TGTelegramNetworking instance] wakeUpWithCompletion:^
            {
                TGDispatchOnMainThread(^
                {
                    if (_inBackground)
                    {
                        if (!TGTelegraphInstance.callManager.hasActiveCall)
                        {
                            [[TGTelegramNetworking instance] pause];
                            TGLog(@"paused network");
                        }
                        
                        NSTimeInterval remainingTime = [[UIApplication sharedApplication] backgroundTimeRemaining];
                        if (remainingTime > 2.0) {
                            TGDispatchAfter(MIN(remainingTime, 5.0), dispatch_get_main_queue(), ^
                            {
                                TGLog(@"completed fetch");
                                completionHandler(UIBackgroundFetchResultNewData);
                            });
                        } else {
                            completionHandler(UIBackgroundFetchResultNewData);
                        }
                    }
                });
            }];
        }
    }
    else if (completionHandler != nil)
        completionHandler(UIBackgroundFetchResultNewData);
    
    if (!_inBackground || !_enteringForeground)
        return;
    
    [self processRemoteNotification:userInfo];
}

- (void)processRemoteNotification:(NSDictionary *)userInfo
{
    [self processRemoteNotification:userInfo removeView:nil];
}

- (void)processRemoteNotification:(NSDictionary *)userInfo removeView:(UIView *)removeView
{
    if (TGTelegraphInstance.clientUserId == 0)
    {
        [removeView removeFromSuperview];
        return;
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return;
    
    id nFromId = [userInfo objectForKey:@"from_id"];
    id nChatId = [userInfo objectForKey:@"chat_id"];
    id nContactId = [userInfo objectForKey:@"contact_id"];
    id nChannelId = [userInfo objectForKey:@"channel_id"];
    
    int64_t conversationId = 0;
    
    if (nFromId != nil && [TGSchema canCreateIntFromObject:nFromId])
    {
        conversationId = [TGSchema intFromObject:nFromId];
    }
    else if (nChatId != nil && [TGSchema canCreateIntFromObject:nChatId])
    {
        conversationId = -[TGSchema intFromObject:nChatId];
    }
    else if (nContactId != nil && [TGSchema canCreateIntFromObject:nContactId])
    {
        conversationId = [TGSchema intFromObject:nContactId];
    }
    else if (nChannelId != nil && [TGSchema canCreateIntFromObject:nChannelId])
    {
        conversationId = TGPeerIdFromChannelId([TGSchema intFromObject:nChannelId]);
    }
    else
    {
        [removeView removeFromSuperview];
    }
    
    TGIOS6OpenNotificationPeer(conversationId);
}

- (void)processPossibleAnnouncement:(NSDictionary *)dict {
    if ([dict[@"announcement"] respondsToSelector:@selector(intValue)]) {
        NSDictionary *aps = dict[@"aps"];
        if ([aps respondsToSelector:@selector(objectForKey:)] && [aps[@"alert"] respondsToSelector:@selector(characterAtIndex:)]) {
            NSNumber *globalMessageSoundIdVal = nil;
            NSNumber *globalMessagePreviewTextVal = nil;
            NSNumber *globalMessageMuteUntilVal = nil;
            
            int globalMessageSoundId = 1;
            bool globalMessagePreviewText = true;
            int globalMessageMuteUntil = 0;
            bool notFound = false;
            [TGDatabaseInstance() loadPeerNotificationSettings:INT_MAX - 1 soundId:&globalMessageSoundIdVal muteUntil:&globalMessageMuteUntilVal previewText:&globalMessagePreviewTextVal messagesMuted:NULL notFound:&notFound];
            if (notFound) {
                globalMessageSoundId = 1;
                globalMessagePreviewText = true;
            }
            else {
                globalMessageSoundId = globalMessageSoundIdVal ? globalMessageSoundIdVal.intValue : 1;
                globalMessagePreviewText = globalMessagePreviewTextVal ? globalMessagePreviewTextVal.boolValue : true;
                globalMessageMuteUntil = globalMessageMuteUntilVal ? globalMessageMuteUntilVal.intValue : 0;
            }
            
            NSNumber *globalGroupSoundIdVal = nil;
            NSNumber *globalGroupPreviewTextVal = nil;
            NSNumber *globalGroupMuteUntilVal = nil;
            
            int globalGroupSoundId = 1;
            bool globalGroupPreviewText = true;
            int globalGroupMuteUntil = 0;
            notFound = false;
            [TGDatabaseInstance() loadPeerNotificationSettings:INT_MAX - 2 soundId:&globalGroupSoundIdVal muteUntil:&globalGroupMuteUntilVal previewText:&globalGroupPreviewTextVal messagesMuted:NULL notFound:&notFound];
            if (notFound) {
                globalGroupSoundId = 1;
                globalGroupPreviewText = true;
            } else {
                globalGroupSoundId = globalGroupSoundIdVal ? globalGroupSoundIdVal.intValue : 1;
                globalGroupPreviewText = globalGroupPreviewTextVal ? globalGroupPreviewTextVal.boolValue : true;
                globalGroupMuteUntil = globalGroupMuteUntilVal ? globalGroupMuteUntilVal.intValue : 0;
            }
            
            NSString *alert = aps[@"alert"];
            int32_t timestamp = (int32_t)[[NSDate date] timeIntervalSince1970];
            
            int uid = [TGTelegraphInstance createServiceUserIfNeeded];
            int32_t uniqueId = [dict[@"announcement"] intValue];
            
            [TGDatabaseInstance() loadMessagesFromConversation:uid maxMid:INT32_MAX maxDate:INT32_MAX maxLocalMid:INT32_MAX atMessageId:0 limit:20 extraUnread:false completion:^(NSArray *messages, __unused bool historyExistsBelow) {
                TGDispatchOnMainThread(^{
                    bool found = false;
                    for (TGMessage *message in messages) {
                        TGMessageUniqueIdContentProperty *prop = message.contentProperties[@"uniqueId"];
                        if (prop.value == uniqueId) {
                            found = true;
                            break;
                        }
                    }
                    
                    if (!found) {
                        TGMessage *message = [[TGMessage alloc] init];
                        message.mid = [[[TGDatabaseInstance() generateLocalMids:1] objectAtIndex:0] intValue];
                        
                        message.fromUid = uid;
                        message.toUid = TGTelegraphInstance.clientUserId;
                        message.date = timestamp;
                        message.outgoing = false;
                        message.cid = uid;
                        
                        message.text = alert;
                        message.contentProperties = @{@"uniqueId": [[TGMessageUniqueIdContentProperty alloc] initWithValue: uniqueId]};
                        
                        [TGDatabaseInstance() transactionAddMessages:@[message] updateConversationDatas:@{} notifyAdded:true];
                        
                        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                            return;
                        }
                        
                        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                        if (localNotification == nil) {
                            return;
                        }
                        
                        TGUser *user = nil;
                        NSString *chatName = nil;
                        
                        int64_t notificationPeerId = 0;
                        
                        if (message.cid <= INT_MIN)
                        {
                            notificationPeerId = [TGDatabaseInstance() encryptedParticipantIdForConversationId:message.cid];
                        }
                        else if (message.cid > 0)
                        {
                            user = [TGDatabaseInstance() loadUser:(int)message.cid];
                            notificationPeerId = message.cid;
                        }
                        else
                        {
                            if (message.containsMention)
                                notificationPeerId = message.fromUid;
                            else
                                notificationPeerId = message.cid;
                            user = [TGDatabaseInstance() loadUser:(int)message.fromUid];
                            TGConversation *conversation = [TGDatabaseInstance() loadConversationWithIdCached:message.cid];
                            if (conversation != nil)
                                chatName = conversation.chatTitle;
                            else
                                chatName = [TGDatabaseInstance() loadConversationWithId:message.cid].chatTitle;
                        }
                        
                        if ([TGDatabaseInstance() isPeerMuted:notificationPeerId])
                            return;
                        
                        NSNumber *soundIdVal = nil;
                        int soundId = 1;
                        [TGDatabaseInstance() loadPeerNotificationSettings:notificationPeerId soundId:&soundIdVal muteUntil:NULL previewText:NULL messagesMuted:NULL notFound:NULL];
                        
                        if (soundIdVal != nil) {
                            soundId = soundIdVal.intValue;
                        } else {
                            soundId = (message.cid > 0 || message.cid <= INT_MIN) ? globalMessageSoundId : globalGroupSoundId;
                        }
                        
                        NSString *text = message.text;
                        bool attachmentFound = false;
                        
                        if (soundId > 0)
                            localNotification.soundName = [[NSString alloc] initWithFormat:@"%d.m4a", soundId];
                        
                        if (message.cid <= INT_MIN)
                        {
                            text = [[NSString alloc] initWithFormat:TGLocalized(@"ENCRYPTED_MESSAGE"), @""];
                        }
                        else if (message.cid > 0)
                        {
                            if (globalMessagePreviewText && !attachmentFound)
                                text = [[NSString alloc] initWithFormat:@"%@: %@", user.displayName, message.text];
                            else if (!attachmentFound)
                                text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_NOTEXT"), user.displayName];
                        }
                        else
                        {
                            if (globalGroupPreviewText && !attachmentFound)
                                text = [[NSString alloc] initWithFormat:@"%@@%@: %@", user.displayName, chatName, message.text];
                            else if (!attachmentFound)
                                text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_NOTEXT"), user.displayName, chatName];
                        }
                        
                        bool isLocked = [TGAppDelegateInstance isCurrentlyLocked];
                        if (isLocked)
                        {
                            text = [[NSString alloc] initWithFormat:TGLocalized(@"LOCKED_MESSAGE"), @""];
                        }
                        
#ifdef INTERNAL_RELEASE
                        text = [@"[L] " stringByAppendingString:text];
#endif
                        localNotification.userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithLongLong:message.cid], @"cid", @(message.mid), @"mid", nil];
                        
                        if (iosMajorVersion() >= 8 && !isLocked)
                        {
                            if (TGPeerIdIsGroup(message.cid))
                                localNotification.category = @"m";
                            else if (TGPeerIdIsChannel(message.cid))
                                localNotification.category = @"c";
                            else if (message.cid > INT_MIN)
                                localNotification.category = @"r";
                        }
                        
                        [TGApplyUpdatesActor presentSafeLocalNotification:localNotification text:text];
                    }
                });
            }];
        }
    }
}

- (void)processPossibleLiveLocationRequest:(NSDictionary *)dict
{
    if (!([dict[@"aps"][@"alert"] isKindOfClass:[NSDictionary class]] && [dict[@"aps"][@"alert"][@"loc-key"] isEqualToString:@"GEO_LIVE_PENDING"]))
        return;
    
    [TGTelegraphInstance.liveLocationManager performInfrequentLocationUpdate:^(bool willPerform)
    {
        TGDispatchOnMainThread(^
        {
            if (willPerform)
            {
                if (_backgroundTaskIdentifier != UIBackgroundTaskInvalid)
                {
                    UIBackgroundTaskIdentifier identifier = _backgroundTaskIdentifier;
                    _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                    [[UIApplication sharedApplication] endBackgroundTask:identifier];
                }
                if (_backgroundTaskExpirationTimer != nil)
                {
                    if ([_backgroundTaskExpirationTimer isValid])
                        [_backgroundTaskExpirationTimer invalidate];
                    _backgroundTaskExpirationTimer = nil;
                }
            }
        });
    }];
}

- (void)processPossibleCallRequest:(NSDictionary *)dict
{
    if (dict[@"call_id"] == nil)
        return;
    
    UIApplication *application = [UIApplication sharedApplication];
    if ([application applicationState] != UIApplicationStateActive)
    {
        UIBackgroundTaskIdentifier taskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^
        {
            if (_inBackground)
            {
                [[TGTelegramNetworking instance] pause];
                TGLog(@"Paused network on task expiration after VoIP notification");
            }
        }];
        
        if (_backgroundTaskIdentifier != UIBackgroundTaskInvalid)
        {
            UIBackgroundTaskIdentifier identifier = _backgroundTaskIdentifier;
            _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            [application endBackgroundTask:identifier];
        }
        if (_backgroundTaskExpirationTimer != nil)
        {
            if ([_backgroundTaskExpirationTimer isValid])
                [_backgroundTaskExpirationTimer invalidate];
            _backgroundTaskExpirationTimer = nil;
        }
        
        [[[[[TGTelegraphInstance.callManager incomingCallInternalIds] take:1] mapToSignal:^SSignal *(NSNumber *internalId) {
            return [[TGTelegraphInstance.callManager endedIncomingCallInternalIds] filter:^bool(NSNumber *endedInternalId) {
                return [internalId isEqual:endedInternalId];
            }];
        }] deliverOn:[SQueue mainQueue]] startWithNext:^(__unused id next)
        {
            [application endBackgroundTask:taskIdentifier];
            
            TGDispatchAfter(2.0, dispatch_get_main_queue(), ^
            {
                if (_inBackground)
                {
                    [[TGTelegramNetworking instance] pause];
                    TGLog(@"Paused network after VoIP notification");
                }
            });
        }];
        
        [[TGTelegramNetworking instance] resume];
        [[TGTelegramNetworking instance] wakeUpWithCompletion:^{}];
    }
}

- (void)processPossibleCloudKitNotification:(NSDictionary *)userInfo {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if (iosMajorVersion() >= 10) {
        CKNotification *notification = [CKNotification notificationFromRemoteNotificationDictionary:userInfo];
        if (notification != nil) {
            [TGICloudEmergencyDataSignals processNotification:notification];
        }
    }
#else
    (void)userInfo;
#endif
}

- (void)processPossibleConfigUpdateNotification:(NSDictionary *)userInfo
{
    if (userInfo[@"dc"] != nil && [userInfo[@"dc"] respondsToSelector:@selector(intValue)] && userInfo[@"addr"] != nil && [userInfo[@"addr"] respondsToSelector:@selector(rangeOfString:)])
    {
        int datacenterId = [userInfo[@"dc"] intValue];
        
        NSString *addr = userInfo[@"addr"];
        NSRange range = [addr rangeOfString:@":"];
        if (range.location != NSNotFound)
        {
            NSString *ip = [addr substringWithRange:NSMakeRange(0, range.location)];
            int port = [[addr substringWithRange:NSMakeRange(range.location + 1, addr.length - range.location - 1)] intValue];
            
            TGLog(@"===== Updating dc%d: %@:%d", datacenterId, ip, port);
            
            if (ip.length != 0)
            {
                NSData *secret = nil;
                if ([userInfo[@"sec"] respondsToSelector:@selector(characterAtIndex:)]) {
                    secret = [(NSString *)userInfo[@"sec"] dataByDecodingHexString];
                }
                [[TGTelegramNetworking instance] mergeDatacenterAddress:datacenterId address:[[MTDatacenterAddress alloc] initWithIp:ip port:(uint16_t)(port == 0 ? 443 : port) preferForMedia:false restrictToTcp:false cdn:false preferForProxy:false secret:secret]];
            }
        }
    }
}

- (NSUInteger)application:(UIApplication *)__unused application supportedInterfaceOrientationsForWindow:(UIWindow *)__unused window
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? UIInterfaceOrientationMaskAllButUpsideDown : UIInterfaceOrientationMaskAll;
}

- (void)reloadSettingsController:(int)uid
{
    TGAccountSettingsController *accountSettingsController = [[TGAccountSettingsController alloc] initWithUid:uid];
    
    int index = -1;
    for (id controller in _rootController.mainTabsController.viewControllers)
    {
        index++;
        if ([controller isKindOfClass:[TGAccountSettingsController class]])
            break;
    }
    
    if (index != -1)
    {
        NSMutableArray *viewControllers = [_rootController.mainTabsController.viewControllers mutableCopy];
        [viewControllers replaceObjectAtIndex:index withObject:accountSettingsController];
        [_rootController.mainTabsController setViewControllers:viewControllers];
        _rootController.accountSettingsController = accountSettingsController;
    }
}

- (BOOL)application:(UIApplication *)__unused application openURL:(NSURL *)url sourceApplication:(NSString *)__unused sourceApplication annotation:(id)__unused annotation
{
    [self handleOpenDocument:url animated:false keepStack:false bundleId:sourceApplication];
    
    return true;
}

- (BOOL)application:(UIApplication *)__unused application openURL:(NSURL *)url options:(NSDictionary *)__unused options {
    [self handleOpenDocument:url animated:false keepStack:false bundleId:options[UIApplicationOpenURLOptionsSourceApplicationKey]];
    
    return true;
}

- (void)resetControllerStack
{
    [TGAppDelegateInstance.rootController clearContentControllers];
}

- (void)handleOpenDocument:(NSURL *)url animated:(bool)animated {
    [self handleOpenDocument:url animated:animated keepStack:false];
}

- (void)handleOpenDocument:(NSURL *)url animated:(bool)__unused animated keepStack:(bool)keepStack {
    [self handleOpenDocument:url animated:animated keepStack:keepStack bundleId:nil];
}

- (void)handleOpenDocument:(NSURL *)url animated:(bool)__unused animated keepStack:(bool)keepStack bundleId:(NSString *)bundleId
{
    bool isProxy = false;
    bool isPassport = false;
    
    if ([url.scheme isEqualToString:@"telegram"] || [url.scheme isEqualToString:@"tg"]) {
        NSDictionary *dict = [TGStringUtils argumentDictionaryInUrlString:[url query]];
        
        if ([url.resourceSpecifier hasPrefix:@"//socks?"] || [url.resourceSpecifier hasPrefix:@"//proxy?"]) {
            isProxy = true;
        }
        
        if ([url.resourceSpecifier hasPrefix:@"//passport?"] || [url.resourceSpecifier hasPrefix:@"//passport/?"] || (([url.resourceSpecifier hasPrefix:@"//resolve?"] || [url.resourceSpecifier hasPrefix:@"//resolve/?"]) && [dict[@"domain"] respondsToSelector:@selector(characterAtIndex:)] && [dict[@"domain"] isEqualToString:@"telegrampassport"])) {
            isPassport = true;
        }
    }

    
    if ((TGTelegraphInstance.clientUserId != 0 && TGTelegraphInstance.clientIsActivated) || isProxy || isPassport)
    {
        if ([url isFileURL])
        {
            [self resetControllerStack];
            
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:nil];
            
            if (attributes != nil)
            {
                int fileSize = [[attributes objectForKey:NSFileSize] intValue];
                
                TGForwardTargetController *forwardController = [[TGForwardTargetController alloc] initWithDocumentFile:url size:fileSize];
                TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[forwardController]];
                [TGAppDelegateInstance.rootController dismissViewControllerAnimated:false completion:nil];
                
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [TGAppDelegateInstance.rootController presentViewController:navigationController animated:false completion:nil];
                });
            }
        }
        else if ([url.scheme isEqualToString:@"telegram"] || [url.scheme isEqualToString:@"tg"])
        {
            NSDictionary *dict = [TGStringUtils argumentDictionaryInUrlString:[url query]];
            
            if ([url.host isEqualToString:@"share"])
            {
                NSMutableArray *uploadFileArray = [[NSMutableArray alloc] init];
                NSMutableArray *forwardMessageArray = [[NSMutableArray alloc] init];
                NSMutableArray *sendMessageArray = [[NSMutableArray alloc] init];
                
                NSString *groupName = [@"group." stringByAppendingString:[[NSBundle mainBundle] bundleIdentifier]];
                
                NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupName];
                if (groupURL != nil)
                {
                    NSURL *inboxUrl = [groupURL URLByAppendingPathComponent:@"share-inbox" isDirectory:true];
                    
                    [[NSFileManager defaultManager] createDirectoryAtURL:inboxUrl withIntermediateDirectories:true attributes:nil error:nil];
                    
                    NSUInteger counter = 0;
                    while (true)
                    {
                        NSString *fileId = [[NSString alloc] initWithFormat:@"f%d", (int)counter];
                        if (dict[fileId] != nil)
                        {
                            NSURL *fileUrl = [inboxUrl URLByAppendingPathComponent:dict[fileId]];
                            
                            NSString *fileType = @"raw";
                            NSString *rawFileType = dict[[[NSString alloc] initWithFormat:@"t%d", (int)counter]];
                            
                            if ([rawFileType isEqualToString:@"i"])
                                fileType = @"image";
                            else if ([rawFileType isEqualToString:@"v"])
                                fileType = @"video";
                            
                            NSString *fileName = dict[[[NSString alloc] initWithFormat:@"n%d", (int)counter]];
                            
                            [uploadFileArray addObject:@{@"url": fileUrl, @"type": fileType, @"fileName": fileName == nil ? @"" : fileName}];
                            
                            counter++;
                        }
                        else
                        {
                            NSString *internalMessageIdString = dict[[[NSString alloc] initWithFormat:@"m%d", (int)counter]];
                            if (internalMessageIdString != nil)
                            {
                                TGMessage *message = [TGDatabaseInstance() loadMessageWithMid:[internalMessageIdString intValue] peerId:0];
                                if (message == nil)
                                {
                                    message = [TGDatabaseInstance() loadMediaMessageWithMid:[internalMessageIdString intValue]];
                                }
                                
                                if (message != nil)
                                    [forwardMessageArray addObject:message];
                                
                                counter++;
                            }
                            else
                            {
                                NSString *urlString = dict[[[NSString alloc] initWithFormat:@"u%d", (int)counter]];
                                if (urlString != nil)
                                {
                                    TGMessage *message = [[TGMessage alloc] init];
                                    message.text = urlString;
                                    [sendMessageArray addObject:message];
                                    
                                    counter++;
                                }
                                else
                                    break;
                            }
                        }
                    }
                }
                
                if (uploadFileArray.count != 0)
                {
                    TGForwardTargetController *forwardController = [[TGForwardTargetController alloc] initWithDocumentFiles:uploadFileArray];
                    forwardController.controllerTitle = TGLocalized(@"Share.Title");
                    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[forwardController]];
                    
                    [_rootController clearContentControllers];
                    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                    {
                        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
                        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^
                    {
                        [_rootController presentViewController:navigationController animated:false completion:nil];
                    });
                }
                else if (forwardMessageArray.count != 0 || sendMessageArray.count != 0)
                {
                    TGForwardTargetController *forwardController = [[TGForwardTargetController alloc] initWithForwardMessages:forwardMessageArray sendMessages:sendMessageArray shareLink:nil showSecretChats:true];
                    
                    forwardController.controllerTitle = TGLocalized(@"Share.Title");
                    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[forwardController]];
                    
                    [_rootController clearContentControllers];
                    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                    {
                        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
                        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^
                    {
                        [_rootController presentViewController:navigationController animated:false completion:nil];
                    });
                }
            }
            else if ([url.host isEqualToString:@"msg"])
            {
                std::map<int, int> phoneIdToUid;
                [TGDatabaseInstance() loadRemoteContactUidsContactIds:phoneIdToUid];
                
                if ([dict[@"to"] respondsToSelector:@selector(characterAtIndex:)] && [(NSString *)dict[@"to"] length] != 0)
                {
                    int32_t phoneId = phoneMatchHash(dict[@"to"]);
                    
                    for (auto it : phoneIdToUid)
                    {
                        if (it.first == phoneId)
                        {
                            NSDictionary *actions = nil;
                            if ([dict[@"text"] respondsToSelector:@selector(characterAtIndex:)] && [(NSString *)dict[@"text"] length] != 0)
                            {
                                actions = @{@"text": dict[@"text"]};
                            }
                            [[TGInterfaceManager instance] navigateToConversationWithId:it.second conversation:nil performActions:actions animated:false];
                            
                            break;
                        }
                    }
                }
                else if ([dict[@"text"] respondsToSelector:@selector(characterAtIndex:)] && [(NSString *)dict[@"text"] length] != 0)
                {
                    TGMessage *message = [[TGMessage alloc] init];
                    message.text = dict[@"text"];
                    
                    TGForwardTargetController *forwardController = [[TGForwardTargetController alloc] initWithForwardMessages:nil sendMessages:@[message] shareLink:nil showSecretChats:true];
                    
                    [self resetControllerStack];
                    
                    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[forwardController]];
                    
                    [_rootController clearContentControllers];
                    [_rootController dismissViewControllerAnimated:false completion:nil];
                    
                    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                    {
                        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
                        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                    }
                    
                    [_rootController presentViewController:navigationController animated:false completion:nil];
                }
            }
            else if ([url.host isEqualToString:@"download-language"])
            {
                if ([dict[@"url"] respondsToSelector:@selector(characterAtIndex:)])
                {
                    [ActionStageInstance() requestActor:[[NSString alloc] initWithFormat:@"/tg/downloadLocalization/(%d)", murMurHash32(dict[@"url"])] options:@{@"url": dict[@"url"]} flags:0 watcher:TGTelegraphInstance];
                }
            }
            else if (isPassport)
            {
                int32_t botId = [dict[@"bot_id"] respondsToSelector:@selector(intValue)] ? [dict[@"bot_id"] intValue] : 0;
                NSString *scope = [dict[@"scope"] respondsToSelector:@selector(characterAtIndex:)] ? dict[@"scope"] : nil;
                
                NSString *callbackUrl = dict[@"callback_url"];
                NSString *publicKey = dict[@"public_key"];
                
                NSString *payload = dict[@"payload"];
                NSString *nonce = dict[@"nonce"];
                
                __weak TGAppDelegate *weakSelf = self;
                void (^displayRequestBlock)(void) =
                ^{
                    __strong TGAppDelegate *strongSelf = weakSelf;
                    if (strongSelf == nil)
                        return;
                    
                    TGRootController *rootController = strongSelf->_rootController;
                    if ([rootController.presentedViewController isKindOfClass:[TGNavigationController class]])
                    {
                        TGNavigationController *navigationController = (TGNavigationController *)rootController.presentedViewController;
                        if ([navigationController.topViewController isKindOfClass:[TGPassportRequestController class]])
                            return;
                    }
                    
                    TGPassportFormRequest *formRequest = [[TGPassportFormRequest alloc] initWithBotId:botId scope:scope publicKey:publicKey bundleId:bundleId callbackUrl:callbackUrl nonce:nonce payload:payload];
                    TGPassportRequestController *controller = [[TGPassportRequestController alloc] initWithFormRequest:formRequest];
                    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[controller]];
                    navigationController.restrictLandscape = true;
                    [rootController clearContentControllers];
                    [rootController dismissViewControllerAnimated:false completion:nil];
                    
                    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                    {
                        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
                        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                    }
                    
                    [rootController presentViewController:navigationController animated:true completion:nil];
                };
                
                if (TGTelegraphInstance.clientUserId != 0)
                {
                    dispatch_async(dispatch_get_main_queue(), ^
                    {
                        [TGCustomAlertView dismissAllAlertViews];
                    });
                    displayRequestBlock();
                }
                else
                {
                    NSString *error = @"USER_NOT_LOGGED_IN";
                    NSString *errorText = TGLocalized(@"Passport.NotLoggedInMessage");
                    
                    TGCustomAlertView *alertView = [TGCustomAlertView presentAlertWithTitle:nil message:errorText cancelButtonTitle:TGLocalized(@"Common.NotNow") okButtonTitle:TGLocalized(@"Common.OK") completionBlock:^(bool okButtonPressed)
                     {
                         if (okButtonPressed)
                         {
                             TGNavigationController *presentedController = (TGNavigationController *)TGAppDelegateInstance.rootController.presentedViewController;
                             if ([presentedController isKindOfClass:[TGNavigationController class]])
                             {
                                 if ([presentedController.topViewController isKindOfClass:[RMIntroViewController class]])
                                 {
                                     TGLoginPhoneController *phoneController = [[TGLoginPhoneController alloc] init];
                                     [presentedController pushViewController:phoneController animated:true];
                                 }
                             }
                             self.onSuccessfulLogin = [displayRequestBlock copy];
                         }
                         else if (callbackUrl.length > 0)
                         {
                             NSString *url = nil;
                             if ([callbackUrl hasPrefix:@"tgbot"]) {
                                 url = [NSString stringWithFormat:@"tgbot%d://passport/error?error=%@", botId, error];
                             } else {
                                 url = [TGPassportRequestController urlString:callbackUrl byAppendingQueryString:[NSString stringWithFormat:@"tg_passport=error&error=%@", error]];
                             }
                             [(TGApplication *)[TGApplication sharedApplication] nativeOpenURL:[NSURL URLWithString:url]];
                         }
                     }];
                    alertView.noActionOnDimTap = true;
                }
            }
            else if ([url.host isEqualToString:@"resolve"])
            {
                if ([dict[@"domain"] respondsToSelector:@selector(characterAtIndex:)])
                {
                    if (!keepStack || ![_rootController.presentedViewController isKindOfClass:[TGHashtagOverviewController class]])
                        [_rootController dismissViewControllerAnimated:false completion:nil];
                    
                    NSMutableDictionary *arguments = [[NSMutableDictionary alloc] init];
                    if (dict[@"start"] != nil)
                        arguments[@"start"] = dict[@"start"];
                    if (dict[@"startgroup"] != nil)
                        arguments[@"startgroup"] = dict[@"startgroup"];
                    if (dict[@"game"] != nil)
                        arguments[@"game"] = dict[@"game"];
                    if (dict[@"post"] != nil) {
                        arguments[@"messageId"] = @([dict[@"post"] intValue]);
                    }
                    if ([url.absoluteString rangeOfString:@"&single"].location != NSNotFound)
                        arguments[@"single"] = @true;
                    
                    [ActionStageInstance() requestActor:[[NSString alloc] initWithFormat:@"/resolveDomain/(%@)", dict[@"domain"]] options:@{@"domain": dict[@"domain"], @"arguments": arguments, @"keepStack": @(keepStack)} flags:0 watcher:TGTelegraphInstance];
                }
            }
            else if ([url.host isEqualToString:@"join"])
            {
                if ([dict[@"invite"] respondsToSelector:@selector(characterAtIndex:)])
                {
                    [_rootController dismissViewControllerAnimated:false completion:nil];
                    
                    TGProgressWindow *progressWindow = [[TGProgressWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                    [progressWindow show:true];
                    
                    [[[[TGGroupManagementSignals groupInvitationLinkInfo:dict[@"invite"]] deliverOn:[SQueue mainQueue]] onDispose:^
                    {
                        TGDispatchOnMainThread(^
                        {
                            [progressWindow dismiss:true];
                        });
                    }] startWithNext:^(TGGroupInvitationInfo *invitationInfo)
                    {
                        if (invitationInfo.alreadyAccepted && !invitationInfo.left)
                        {
                            if (invitationInfo.peerId != 0) {
                                [[TGInterfaceManager instance] navigateToConversationWithId:invitationInfo.peerId conversation:nil performActions:nil atMessage:nil clearStack:!keepStack openKeyboard:false canOpenKeyboardWhileInTransition:false animated:true];
                            } else {
                                NSString *format = TGLocalized(@"GroupInfo.InvitationLinkAlreadyAccepted");
                                NSString *text = [[NSString alloc] initWithFormat:format, invitationInfo.title];
                                [TGCustomAlertView presentAlertWithTitle:nil message:text cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
                            }
                        }
                        else
                        {
                            if (invitationInfo.users != nil && (!invitationInfo.isChannel || invitationInfo.isChannelGroup)) {
                                [_groupInviteSheet dismissAnimated:true completion:nil];
                                
                                _groupInviteSheet = [[TGGroupInviteSheet alloc] initWithTitle:invitationInfo.title photoUrlSmall:[invitationInfo.avatarInfo closestImageUrlWithSize:CGSizeZero resultingSize:NULL] userCount:invitationInfo.userCount users:invitationInfo.users join:^{
                                    TGProgressWindow *progressWindow = [[TGProgressWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                                    [progressWindow show:true];
                                    
                                    [[[[TGGroupManagementSignals acceptGroupInvitationLink:dict[@"invite"]] deliverOn:[SQueue mainQueue]] onDispose:^
                                      {
                                          TGDispatchOnMainThread(^
                                                                 {
                                                                     [progressWindow dismiss:true];
                                                                 });
                                      }] startWithNext:^(TGConversation *conversation)
                                     {
                                         [[TGInterfaceManager instance] navigateToConversationWithId:conversation.conversationId conversation:conversation.isChannel ? conversation : nil performActions:nil atMessage:nil clearStack:!keepStack openKeyboard:false canOpenKeyboardWhileInTransition:false animated:true];
                                     } error:^(__unused id error)
                                     {
                                         NSString *text = TGLocalized(@"GroupInfo.InvitationLinkDoesNotExist");
                                         if ([error respondsToSelector:@selector(characterAtIndex:)])
                                         {
                                             if ([error isEqualToString:@"USERS_TOO_MUCH"])
                                                 text = TGLocalized(@"GroupInfo.InvitationLinkGroupFull");
                                         }
                                        [TGCustomAlertView presentAlertWithTitle:nil message:text cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
                                     } completed:nil];
                                }];
                                _groupInviteSheet.dismissalBlock = ^{
                                    TGAppDelegateInstance->_groupInviteSheet.rootViewController = nil;
                                    TGAppDelegateInstance->_groupInviteSheet = nil;
                                };
                                
                                _groupInviteSheet.view.cancel = ^{
                                    [TGAppDelegateInstance->_groupInviteSheet dismissAnimated:true completion:nil];
                                    TGAppDelegateInstance->_groupInviteSheet = nil;
                                };
                                
                                [_groupInviteSheet showAnimated:true completion:nil];
                            } else {
                                NSString *format = TGLocalized(@"GroupInfo.InvitationLinkAcceptChannel");
                                NSString *text = [[NSString alloc] initWithFormat:format, invitationInfo.title];
                                [TGCustomAlertView presentAlertWithTitle:nil message:text cancelButtonTitle:TGLocalized(@"Common.Cancel") okButtonTitle:TGLocalized(@"Common.OK") completionBlock:^(bool okButtonPressed)
                                {
                                    if (okButtonPressed)
                                    {
                                        TGProgressWindow *progressWindow = [[TGProgressWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                                        [progressWindow show:true];
                                        
                                        [[[[TGGroupManagementSignals acceptGroupInvitationLink:dict[@"invite"]] deliverOn:[SQueue mainQueue]] onDispose:^
                                        {
                                            TGDispatchOnMainThread(^
                                            {
                                                [progressWindow dismiss:true];
                                            });
                                        }] startWithNext:^(TGConversation *conversation)
                                        {
                                            [[TGInterfaceManager instance] navigateToConversationWithId:conversation.conversationId conversation:conversation.isChannel ? conversation : nil performActions:nil atMessage:nil clearStack:!keepStack openKeyboard:false canOpenKeyboardWhileInTransition:false animated:true];
                                        } error:^(__unused id error)
                                        {
                                            NSString *text = TGLocalized(@"GroupInfo.InvitationLinkDoesNotExist");
                                            if ([error respondsToSelector:@selector(characterAtIndex:)])
                                            {
                                                if ([error isEqualToString:@"USERS_TOO_MUCH"])
                                                    text = TGLocalized(@"GroupInfo.InvitationLinkGroupFull");
                                            }
                                            [TGCustomAlertView presentAlertWithTitle:nil message:text cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
                                        } completed:nil];
                                    }
                                }];
                            }
                        }
                    } error:^(id error)
                    {
                        NSString *text = TGLocalized(@"GroupInfo.InvitationLinkDoesNotExist");
                        if ([error respondsToSelector:@selector(characterAtIndex:)])
                        {
                            if ([error isEqualToString:@"USER_ALREADY_PARTICIPANT"])
                                text = TGLocalized(@"GroupInfo.InvitationLinkAlreadyAccepted");
                        }
                        [TGCustomAlertView presentAlertWithTitle:nil message:text cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
                    } completed:nil];
                }
            }
            else if ([url.host isEqualToString:@"addstickers"])
            {
                IOS6_NOOP_LOG(@"IOS6STICKER app.addstickers url=%@ set=%@", url.absoluteString, dict[@"set"]);
                if ([dict[@"set"] respondsToSelector:@selector(characterAtIndex:)])
                {
                    TGStickerPackShortnameReference *packReference = [[TGStickerPackShortnameReference alloc] initWithShortName:dict[@"set"]];
                    IOS6_NOOP_LOG(@"IOS6STICKER app.addstickers.preview shortName=%@ ref=%@", dict[@"set"], packReference);
                    [self previewStickerPackWithReference:packReference];
                }
                else
                    IOS6_NOOP_LOG(@"IOS6STICKER app.addstickers.badSet dict=%@", dict);
            }
            else if ([url.host isEqualToString:@"msg_url"])
            {
                if ([dict[@"url"] respondsToSelector:@selector(characterAtIndex:)]) {
                    NSMutableDictionary *linkInfo = [[NSMutableDictionary alloc] init];
                    NSString *url = dict[@"url"];
                    if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) {
                        void (^presentForwardController)(TGForwardTargetController *) = ^(TGForwardTargetController *forwardController)
                        {
                            forwardController.skipConfirmation = true;
                            
                            [self resetControllerStack];
                            
                            TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[forwardController]];
                            
                            [_rootController clearContentControllers];
                            [_rootController dismissViewControllerAnimated:false completion:nil];
                            
                            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                            {
                                navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
                                navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                            }
                            
                            [_rootController presentViewController:navigationController animated:false completion:nil];
                        };
                        
                        NSURL *concreteURL = [NSURL URLWithString:url];
                        if ([concreteURL.host isEqualToString:@"telesco.pe"])
                        {
                            if (concreteURL.pathComponents.count >= 3)
                            {
                                NSString *username = concreteURL.pathComponents[1];
                                int32_t messageId = (int32_t)[concreteURL.pathComponents[2] integerValue];
                                
                                if (username.length > 0 && messageId != 0)
                                {
                                    TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
                                    [progressWindow showWithDelay:0.2];
                                    
                                    [[[TGChannelManagementSignals resolveChannelWithUsername:username] mapToSignal:^SSignal *(TGConversation *channel) {
                                        return [TGChannelManagementSignals preloadedChannelAtMessage:channel.conversationId messageId:messageId];
                                    }] startWithNext:^(TGConversation *channel)
                                    {
                                        TGMessage *message = [TGDatabaseInstance() loadMessageWithMid:messageId peerId:channel.conversationId];
                                        if (message != nil)
                                        {
                                            TGDispatchOnMainThread(^
                                            {
                                                [progressWindow dismiss:true];
                                                TGForwardTargetController *forwardController = [[TGForwardTargetController alloc] initWithForwardMessages:@[ message ] sendMessages:nil shareLink:nil showSecretChats:true];
                                                presentForwardController(forwardController);
                                            });
                                        }
                                    } error:^(__unused id error)
                                    {
                                        TGDispatchOnMainThread(^
                                        {
                                            [progressWindow dismiss:true];
                                        });
                                    } completed:nil];
                                    return;
                                }
                            }
                        }

                        linkInfo[@"url"] = url;
                        
                        if ([dict[@"text"] respondsToSelector:@selector(characterAtIndex:)]) {
                            linkInfo[@"text"] = dict[@"text"];
                        }
                        
                        TGForwardTargetController *forwardController = [[TGForwardTargetController alloc] initWithForwardMessages:nil sendMessages:nil shareLink:linkInfo showSecretChats:true];
                        presentForwardController(forwardController);
                    }
                }
            }
            else if ([url.host isEqualToString:@"confirmphone"])
            {
                if ([dict[@"hash"] respondsToSelector:@selector(characterAtIndex:)]) {
                    TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
                    [progressWindow showWithDelay:0.1];
                    [[[[TGAccountSignals requestConfirmationForPhoneWithHash:dict[@"hash"]] deliverOn:[SQueue mainQueue]] onDispose:^{
                        TGDispatchOnMainThread(^{
                            [progressWindow dismiss:true];
                        });
                    }] startWithNext:^(TGConfirmationCodeData *codeData) {
                        TGCancelAccountResetController *cancelResetController = [[TGCancelAccountResetController alloc] initWithPhoneHash:codeData.codeHash timeout:codeData.timeout];
                        
                        TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[cancelResetController]];
                        
                        [_rootController dismissViewControllerAnimated:false completion:nil];
                        
                        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                        {
                            navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
                            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                        }
                        
                        [_rootController presentViewController:navigationController animated:true completion:nil];
                    } error:^(__unused id error) {
                        [TGCustomAlertView presentAlertWithTitle:nil message:TGLocalized(@"Login.UnknownError") cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
                    } completed:nil];
                }
            }
            else if ([url.host isEqualToString:@"user"])
            {
                if ([dict[@"id"] respondsToSelector:@selector(characterAtIndex:)])
                {
                    NSInteger uid = [dict[@"id"] integerValue];
                    [[TGInterfaceManager instance] navigateToConversationWithId:uid conversation:nil performActions:nil animated:false];
                }
            }
            else if ([url.host isEqualToString:@"gshare"])
            {
                if ([dict[@"h"] respondsToSelector:@selector(characterAtIndex:)])
                {
                    int64_t randomId = [(NSString *)dict[@"h"] longLongValue];
                    TGWebAppControllerShareGameData *shareData = ((TGApplication *)[UIApplication sharedApplication]).gameShareDict[@(randomId)];
                    if (shareData != nil) {
                        UIViewController *topController = self.rootController.viewControllers.lastObject;
                        if (self.rootController.presentedViewController != nil) {
                            topController = self.rootController.presentedViewController;
                        }
                        if (topController != nil) {
                            [TGWebAppController presentShare:shareData parentController:topController withScore:true];
                        }
                    }
                }
            }
            else if ([url.host isEqualToString:@"socks"]) {
                if ([dict[@"server"] respondsToSelector:@selector(characterAtIndex:)] && [dict[@"port"] respondsToSelector:@selector(intValue)]) {
                    NSString *username = nil;
                    NSString *password = nil;
                    
                    if ([dict[@"user"] respondsToSelector:@selector(characterAtIndex:)] && [dict[@"pass"] respondsToSelector:@selector(characterAtIndex:)]) {
                        username = dict[@"user"];
                        password = dict[@"pass"];
                    }
                    
                    TGProxyItem *proxy = [[TGProxyItem alloc] initWithServer:dict[@"server"] port:(uint16_t)[dict[@"port"] intValue] username:username password:password secret:nil];
                    UIViewController *controller = self.rootController;
                    if (controller.presentedViewController != nil)
                        controller = controller.presentedViewController;
                    __weak UIView *weakSourceView = controller.view;
                    [TGProxyMenu presentInParentController:(TGViewController *)controller menuController:nil proxy:proxy sourceView:controller.view sourceRect:^CGRect
                    {
                        __strong UIView *strongSourceView = weakSourceView;
                        return CGRectMake(CGRectGetMidX(strongSourceView.frame), CGRectGetMidY(strongSourceView.frame), 0, 0);
                    }];
                }
            }
            else if ([url.host isEqualToString:@"proxy"]) {
                [self.rootController.view endEditing:true];
                
                NSDictionary *dict = [TGStringUtils argumentDictionaryInUrlString:[url query]];
                if ([dict[@"server"] respondsToSelector:@selector(characterAtIndex:)] && [dict[@"port"] respondsToSelector:@selector(intValue)]) {
                    NSString *secret = nil;
                    if ([dict[@"secret"] respondsToSelector:@selector(characterAtIndex:)]) {
                        secret = dict[@"secret"];
                    }
                    
                    TGProxyItem *proxy = [[TGProxyItem alloc] initWithServer:dict[@"server"] port:(uint16_t)[dict[@"port"] intValue] username:nil password:nil secret:secret];
                    UIViewController *controller = self.rootController;
                    if (controller.presentedViewController != nil)
                        controller = controller.presentedViewController;
                    __weak UIView *weakSourceView = controller.view;
                    [TGProxyMenu presentInParentController:(TGViewController *)controller menuController:nil proxy:proxy sourceView:controller.view sourceRect:^CGRect
                    {
                        __strong UIView *strongSourceView = weakSourceView;
                        return CGRectMake(CGRectGetMidX(strongSourceView.frame), CGRectGetMidY(strongSourceView.frame), 0, 0);
                    }];
                }
            }
            else {
                NSString *path = url.host;
                
                TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
                [progressWindow showWithDelay:0.1];

                [[[[TGServiceSignals deepLinkInfo:path] deliverOn:[SQueue mainQueue]] onDispose:^{
                    TGDispatchOnMainThread(^{
                        [progressWindow dismiss:true];
                    });
                }] startWithNext:^(TGDeepLinkInfo *linkInfo) {
                    NSString *cancelTitle = linkInfo.updateNeeded ? TGLocalized(@"Common.NotNow") : TGLocalized(@"Common.OK");
                    NSString *okTitle = linkInfo.updateNeeded ? TGLocalized(@"Application.Update") : nil;
                    [TGCustomAlertView presentAlertWithTitle:nil message:linkInfo.message cancelButtonTitle:cancelTitle okButtonTitle:okTitle completionBlock:^(bool okButtonPressed)
                    {
                        if (okButtonPressed)
                        {
                            NSNumber *appStoreId = @686449807;
#ifdef TELEGRAM_APPSTORE_ID
                            appStoreId = TELEGRAM_APPSTORE_ID;
#endif
                            NSURL *appStoreURL = [NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@", appStoreId]];
                            [[UIApplication sharedApplication] openURL:appStoreURL];
                        }
                    }];
                } error:^(__unused id error) {
                    [TGCustomAlertView presentAlertWithTitle:nil message:TGLocalized(@"Login.UnknownError") cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
                } completed:nil];
            }
        }
        else if ([url.scheme isEqualToString:[TGDropboxHelper dropboxURLScheme]])
        {
            [TGDropboxHelper handleOpenURL:url];
        }
    }
}

- (NSString *)stickerPackShortname:(TGStickerPack *)stickerPack
{
    NSString *shortName = nil;
    if ([stickerPack.packReference isKindOfClass:[TGStickerPackIdReference class]])
        shortName = ((TGStickerPackIdReference *)stickerPack.packReference).shortName;
    else if ([stickerPack.packReference isKindOfClass:[TGStickerPackShortnameReference class]])
        shortName = ((TGStickerPackShortnameReference *)stickerPack.packReference).shortName;
    return shortName;
}

- (void)previewStickerPackWithReference:(id<TGStickerPackReference>)packReference
{
    UIViewController *controller = self.rootController;
    if (controller.presentedViewController != nil)
        controller = controller.presentedViewController;
    
    IOS6_NOOP_LOG(@"IOS6STICKER app.previewPack ref=%@ controller=%@ presented=%@", packReference, controller, self.rootController.presentedViewController);
    [controller.view endEditing:true];
    [TGStickersMenu presentInParentController:(TGViewController *)controller stickerPackReference:packReference showShareAction:false sendSticker:nil stickerPackRemoved:nil stickerPackHidden:nil sourceView:controller.view centered:true];
}

- (void)readyToApplyLocalizationFromFile:(NSString *)filePath warnings:(NSString *)warnings
{
    [TGCustomAlertView presentAlertWithTitle:nil message:warnings.length == 0 ? @"Apply Localization?" : [NSString stringWithFormat:@"%@\n\nApply Localization?", warnings] cancelButtonTitle:TGLocalized(@"Common.Cancel") okButtonTitle:TGLocalized(@"Common.OK") completionBlock:^(bool okButtonPressed)
    {
        if (okButtonPressed)
        {
            TGSetLocalizationFromFile(filePath);
            [TGAppDelegateInstance resetLocalization];
            
            [self resetControllerStack];
        }
    }];
}

- (BOOL)application:(UIApplication *)__unused application willContinueUserActivityWithType:(NSString *)userActivityType
{
    if ([userActivityType isEqualToString:@"com.example.LegacyGram.conversation"]) {
        if (_progressWindow != nil) {
            [_progressWindow dismiss:true];
        }
        
        _progressWindow = [[TGProgressWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_progressWindow show:true];
    }
    
    return true;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (BOOL)application:(UIApplication *)__unused application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))__unused restorationHandler
{
    [_progressWindow dismiss:true];
    
    if ([userActivity.activityType isEqualToString:@"NSUserActivityTypeBrowsingWeb"]) {
        [application openURL:userActivity.webpageURL];
    } else if ([userActivity.activityType isEqualToString:@"com.example.LegacyGram.conversation"]) {
        if ([userActivity.userInfo[@"user_id"] intValue] == TGTelegraphInstance.clientUserId)
        {
            int64_t peerId = 0;
            
            if ([userActivity.userInfo[@"peer"][@"type"] isEqual:@"user"])
                peerId = [userActivity.userInfo[@"peer"][@"id"] intValue];
            else if ([userActivity.userInfo[@"peer"][@"type"] isEqual:@"group"])
                peerId = -[userActivity.userInfo[@"peer"][@"id"] intValue];
            
            if (peerId != 0)
            {
                [[TGInterfaceManager instance] navigateToConversationWithId:peerId conversation:nil performActions:userActivity.userInfo[@"text"] == nil ? nil : @{@"text": userActivity.userInfo[@"text"]} animated:false];
                
                bool didSetText = false;
                TGModernConversationController *controller = [[TGInterfaceManager instance] currentControllerWithPeerId:peerId];
                if (controller != nil)
                    didSetText = TGStringCompare(userActivity.userInfo[@"text"], [controller inputText]);
                
                if (didSetText)
                {
                    [userActivity getContinuationStreamsWithCompletionHandler:^(__unused NSInputStream *inputStream, NSOutputStream *outputStream, NSError *error)
                    {
                        if (error == nil)
                        {
                            @try {
                                [outputStream open];
                                [outputStream close];
                            }
                            @catch (NSException *exception) {
                            }
                            @finally {
                            }
                        }
                    }];
                }
            }
        }
    } else if ([userActivity.activityType isEqual:CSSearchableItemActionType]) {
        NSString *uniqueIdentifier = userActivity.userInfo[CSSearchableItemActivityIdentifier];
        if (uniqueIdentifier != nil) {
            int64_t peerId = [uniqueIdentifier longLongValue];
            if (peerId != 0) {
                if (peerId != 0) {
                    [[TGInterfaceManager instance] navigateToConversationWithId:peerId conversation:nil performActions:nil animated:false];
                }
            }
        }
    } else if ([userActivity.activityType isEqualToString:INStartAudioCallIntentIdentifier]) {
        INInteraction *interaction = [userActivity interaction];
        if ([interaction.intent isKindOfClass:[INStartAudioCallIntent class]])
        {
            NSString *handle = userActivity.userInfo[@"handle"];
            if (handle == nil)
            {
                INPerson *person = [[(INStartAudioCallIntent *)(interaction.intent) contacts] firstObject];
                handle = person.personHandle.value;
            }
            
            int32_t peerId = 0;
            if ([handle hasPrefix:@"TGCA"])
            {
                peerId = [[handle substringFromIndex:@"TGCA".length] intValue];
            }
            else
            {
                NSArray *users = [TGDatabaseInstance() contactUsersMatchingPhone:handle];
                peerId = ((TGUser *)users.firstObject).uid;
            }
            
            [[_finishedLaunching.signal deliverOn:[SQueue mainQueue]] startWithNext:^(__unused id next)
            {
                if ([self isOrWillBeLocked])
                {
                    self.onSuccessfulAuthorization = ^
                    {
                        [[TGInterfaceManager instance] callPeerWithId:peerId];
                    };
                }
                else
                {
                    [[TGInterfaceManager instance] callPeerWithId:peerId];
                }
            }];
        }
    }
    
    return true;
}

#endif

- (void)handleOpenInstantView:(NSString *)url disableActions:(bool)disableActions {
    TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
    [progressWindow showWithDelay:0.1];
    
    SSignal *signal = disableActions ? [TGWebpageSignals updatedWebpageForUrl:url] : [TGWebpageSignals webpagePreview:url];
    
    [[[[signal take:1] onDispose:^{
        TGDispatchOnMainThread(^{
            [progressWindow dismiss:true];
        });
    }] deliverOn:[SQueue mainQueue]] startWithNext:^(TGWebPageMediaAttachment *webpage) {
        if (webpage.instantPage != nil) {
            if (TGAppDelegateInstance.rootController.presentedViewController != nil && ![TGAppDelegateInstance.rootController.presentedViewController isKindOfClass:[TGNavigationController class]]) {
                [TGAppDelegateInstance.rootController dismissViewControllerAnimated:false completion:nil];
            }
            TGInstantPageController *controller = [[TGInstantPageController alloc] initWithWebPage:webpage anchor:[url urlAnchorPart] peerId:0 messageId:0];
            controller.disableActions = disableActions;
            
            if ([TGAppDelegateInstance.rootController.presentedViewController isKindOfClass:[TGNavigationController class]])
            {
                [(TGNavigationController *)TGAppDelegateInstance.rootController.presentedViewController pushViewController:controller animated:true];
            }
            else
            {
                [TGAppDelegateInstance.rootController pushContentController:controller];
            }
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }
    } error:^(__unused id error) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    } completed:nil];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (void)application:(UIApplication *)__unused application didFailToContinueUserActivityWithType:(NSString *)__unused userActivityType error:(NSError *)__unused error
{
    [_progressWindow dismiss:true];
}

#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
- (void)application:(UIApplication *)__unused application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    [_rootController.mainTabsController setSelectedIndex:2];
    
    if (_rootController.associatedWindowStack.count > 0)
    {
        for (TGOverlayControllerWindow *window in _rootController.associatedWindowStack)
        {
            if ([window isKindOfClass:[TGOverlayControllerWindow class]])
                [window dismiss];
        }
    }
    
    if ([shortcutItem.type isEqualToString:@"compose"])
    {
        [_rootController clearContentControllers];
        [_rootController.dialogListController.dialogListCompanion composeMessageAndOpenSearch:false];
    }
    else if ([shortcutItem.type isEqualToString:@"search"])
    {
        [_rootController clearContentControllers];
        [_rootController.dialogListController startSearch];
    }
    else if ([shortcutItem.type isEqualToString:@"camera"])
    {
        [_rootController clearContentControllers];
        [TGCameraController startShortcutCamera];
    }
    else if ([shortcutItem.type isEqualToString:@"conversation"])
    {
        NSDictionary *userInfo = shortcutItem.userInfo;
        NSNumber *cidValue = userInfo[@"cid"];
        if (cidValue != nil)
            [[TGInterfaceManager instance] navigateToConversationWithId:cidValue.longLongValue conversation:nil performActions:nil animated:false];
    }
    
    if (completionHandler != nil)
        completionHandler(true);
}

- (void)application:(UIApplication *)__unused application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler
{
    [self application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:@{} completionHandler:completionHandler];
}

- (void)application:(UIApplication *)__unused application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:( NSDictionary *)responseInfo completionHandler:( void (^)())completionHandler
{
    id nFromId = [userInfo objectForKey:@"from_id"];
    id nChatId = [userInfo objectForKey:@"chat_id"];
    id nContactId = [userInfo objectForKey:@"contact_id"];
    id nChannelId = [userInfo objectForKey:@"channel_id"];
    id nMid = [userInfo objectForKey:@"msg_id"];
    
    int64_t peerId = 0;
    int32_t mid = 0;
    
    if (nFromId != nil && [TGSchema canCreateIntFromObject:nFromId])
        peerId = [TGSchema intFromObject:nFromId];
    else if (nChatId != nil && [TGSchema canCreateIntFromObject:nChatId])
        peerId = -[TGSchema intFromObject:nChatId];
    else if (nContactId != nil && [TGSchema canCreateIntFromObject:nContactId])
        peerId = [TGSchema intFromObject:nContactId];
    else if (nChannelId != nil && [TGSchema canCreateIntFromObject:nChannelId])
        peerId = TGPeerIdFromChannelId([TGSchema intFromObject:nChannelId]);
    
    if (nMid != nil && [TGSchema canCreateIntFromObject:nMid])
        mid = [TGSchema intFromObject:nMid];
    
    [[_finishedLaunching.signal deliverOn:[SQueue mainQueue]] startWithNext:^(__unused id next)
    {
        if ([identifier isEqualToString:@"reply"])
            [self _replyActionForPeerId:peerId mid:mid openKeyboard:true responseInfo:responseInfo completion:completionHandler];
        else if ([identifier isEqualToString:@"like"])
            [self _likeActionForPeerId:peerId completion:completionHandler];
        else if ([identifier isEqualToString:@"mute"])
            [self _muteActionForPeerId:peerId duration:1 completion:completionHandler];
        else if ([identifier isEqualToString:@"mute8h"])
            [self _muteActionForPeerId:peerId duration:8 completion:completionHandler];
        else if ([identifier isEqualToString:@"call"])
            [self _callActionForPeerId:peerId completion:completionHandler];
        else if (completionHandler)
            completionHandler();
    }];
}

- (void)application:(UIApplication *)__unused application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler
{
    [self application:application handleActionWithIdentifier:identifier forLocalNotification:notification withResponseInfo:@{} completionHandler:completionHandler];
}

- (void)application:(UIApplication *)__unused application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:( NSDictionary *)responseInfo completionHandler:( void (^)())completionHandler
{
    int64_t peerId = [notification.userInfo[@"cid"] longLongValue];
    int32_t mid = [notification.userInfo[@"mid"] intValue];
    
    [[_finishedLaunching.signal deliverOn:[SQueue mainQueue]] startWithNext:^(__unused id next)
    {
        if ([identifier isEqualToString:@"reply"])
            [self _replyActionForPeerId:peerId mid:mid openKeyboard:true responseInfo:responseInfo completion:completionHandler];
        else if ([identifier isEqualToString:@"like"])
            [self _likeActionForPeerId:peerId completion:completionHandler];
        else if ([identifier isEqualToString:@"mute"])
            [self _muteActionForPeerId:peerId duration:1 completion:completionHandler];
        else if ([identifier isEqualToString:@"mute8h"])
            [self _muteActionForPeerId:peerId duration:8 completion:completionHandler];
        else if ([identifier isEqualToString:@"call"])
            [self _callActionForPeerId:peerId completion:completionHandler];
        else if (completionHandler)
            completionHandler();
    }];
}

- (void)_callActionForPeerId:(int64_t)peerId completion:(void (^)())completion
{
    if (peerId != 0)
        [[TGInterfaceManager instance] callPeerWithId:peerId];
    
    if (completion != nil)
        completion();
}

- (void)_replyActionForPeerId:(int64_t)peerId mid:(int32_t)mid openKeyboard:(bool)openKeyboard responseInfo:(NSDictionary *)responseInfo completion:(void (^)())completion
{
    if (iosMajorVersion() >= 9 && openKeyboard)
    {
        if (peerId == 0)
            return;
        
        int32_t replyToMid = 0;
        if (TGPeerIdIsGroup(peerId) || TGPeerIdIsChannel(peerId))
            replyToMid = mid;
        
        void (^suspendBlock)(bool) = ^(bool succeed)
        {
            if (succeed)
            {
                TGDispatchOnMainThread(^
                {
                    [self applicationDidEnterBackground:[UIApplication sharedApplication]];
                    
                    if (completion)
                        completion();
                });
            }
            else
            {
                [[TGTelegramNetworking instance] wakeUpWithCompletion:^
                {
                    TGDispatchOnMainThread(^
                    {
                        if (_inBackground && !TGTelegraphInstance.callManager.hasActiveCall)
                        {
                            [[TGTelegramNetworking instance] pause];
                            if (completion)
                                completion();
                        }
                    });
                }];
            }
        };
        
        NSString *text = responseInfo[UIUserNotificationActionResponseTypedTextKey];
        if ([text hasNonWhitespaceCharacters])
        {
            [[[[TGSendMessageSignals sendTextMessageWithPeerId:peerId text:text replyToMid:replyToMid] then:[[TGChatMessageListSignal readChatMessageListWithPeerId:peerId] delay:1.5 onQueue:[SQueue mainQueue]]] catch:^SSignal *(__unused id error)
            {
                suspendBlock(false);
                return nil;
            }] startWithNext:nil completed:^
            {
                suspendBlock(true);
            }];
            
            if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
                [[TGTelegramNetworking instance] resume];
        }
        else
        {
            suspendBlock(false);
        }
    }
    else
    {
        if (peerId != 0 && [TGDatabaseInstance() loadConversationWithId:peerId] != nil)
        {
            [[TGInterfaceManager instance] navigateToConversationWithId:peerId conversation:nil performActions:nil atMessage:nil clearStack:true openKeyboard:openKeyboard && (_passcodeWindow == nil || _passcodeWindow.hidden) canOpenKeyboardWhileInTransition:false animated:false];
        }
        
        if (completion)
            completion();
    }
}

- (void)_likeActionForPeerId:(int64_t)peerId completion:(void (^)())completion
{
    void (^suspendBlock)(bool) = ^(bool succeed)
    {
        if (succeed)
        {
            TGDispatchOnMainThread(^
            {
                [self applicationDidEnterBackground:[UIApplication sharedApplication]];
                
                if (completion)
                    completion();
            });
        }
        else
        {
            [[TGTelegramNetworking instance] wakeUpWithCompletion:^
            {
                TGDispatchOnMainThread(^
                {
                    if (_inBackground && !TGTelegraphInstance.callManager.hasActiveCall)
                    {
                        [[TGTelegramNetworking instance] pause];
                        if (completion)
                            completion();
                    }
                });
            }];
        }
    };
    
    [[[[TGSendMessageSignals sendTextMessageWithPeerId:peerId text:@"👍" replyToMid:0] then:[[TGChatMessageListSignal readChatMessageListWithPeerId:peerId] delay:1.5 onQueue:[SQueue mainQueue]]] catch:^SSignal *(__unused id error)
    {
        suspendBlock(false);
        return nil;
    }] startWithNext:nil error: nil completed:^
    {
        suspendBlock(true);
    }];
    
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
        [[TGTelegramNetworking instance] resume];
}

- (void)_muteActionForPeerId:(int64_t)peerId duration:(NSInteger)duration completion:(void (^)())completion
{
    NSNumber *muteUntil = 0;
    [TGDatabaseInstance() loadPeerNotificationSettings:peerId soundId:NULL muteUntil:&muteUntil previewText:NULL messagesMuted:NULL notFound:NULL];
    
    int muteTime = (int)duration * 60 * 60;
    muteUntil = @(MAX(muteUntil.intValue, (int)[[TGTelegramNetworking instance] approximateRemoteTime] + muteTime));
    
    static int actionId = 0;
    
    void (^muteBlock)(int64_t, NSNumber *, NSNumber *) = ^(int64_t peerId, NSNumber *muteUntil, NSNumber *accessHash)
    {
        NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:@{ @"peerId": @(peerId), @"muteUntil": muteUntil }];
        if (accessHash != nil)
            options[@"accessHash"] = accessHash;
        
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/changePeerSettings/(%" PRId64 ")/(muteAction%d)", peerId, actionId++] options:options watcher:TGTelegraphInstance];
    };
    
    if (TGPeerIdIsChannel(peerId))
    {
        [[[TGDatabaseInstance() existingChannel:peerId] take:1] startWithNext:^(TGConversation *channel)
        {
            muteBlock(peerId, muteUntil, @(channel.accessHash));
        }];
    }
    else
    {
        muteBlock(peerId, muteUntil, nil);
    }

    
    TGDispatchAfter(9.0, dispatch_get_main_queue(), ^
    {
        if (completion)
            completion();
    });
    
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
    {
        [[TGTelegramNetworking instance] resume];
        
        if (completion != nil)
        {
            [[TGTelegramNetworking instance] wakeUpWithCompletion:^
            {
                TGDispatchOnMainThread(^
                {
                    if (_inBackground && !TGTelegraphInstance.callManager.hasActiveCall)
                    {
                        [[TGTelegramNetworking instance] pause];
                        
                        if (completion != nil)
                            completion();
                    }
                });
            }];
        }
    }
}

- (bool)isManuallyLocked
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"Passcode_lockManually"] boolValue];
}

- (int32_t)automaticLockTimeout
{
    NSNumber *nLockTimeout = [[NSUserDefaults standardUserDefaults] objectForKey:@"Passcode_lockTimeout"];
    if (nLockTimeout == nil)
        return 1 * 60 * 60;
    return (int32_t)[nLockTimeout intValue];
}

- (void)setAutomaticLockTimeout:(int32_t)automaticLockTimeout
{
    [[NSUserDefaults standardUserDefaults] setObject:@(automaticLockTimeout) forKey:@"Passcode_lockTimeout"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setIsManuallyLocked:(bool)isLocked
{
    [[NSUserDefaults standardUserDefaults] setObject:@(isLocked) forKey:@"Passcode_lockManually"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [ActionStageInstance() dispatchResource:@"/databasePasswordChanged" resource:nil];
}

- (bool)isCurrentlyLocked
{
    return [self isCurrentlyLocked:NULL canBeLocked:NULL];
}

- (bool)isCurrentlyLocked:(bool *)byTimeout canBeLocked:(bool *)canBeLocked
{
    if ([TGDatabaseInstance() isPasswordSet:NULL])
    {
        if (canBeLocked) {
           *canBeLocked = true;
        }
        NSNumber *nDeactivationDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"Passcode_deactivationDate"];
        bool displayByDeactivationTimeout = false;
        if (nDeactivationDate != nil)
        {
            int32_t lockTimeout = [self automaticLockTimeout];
            if (lockTimeout >= 0)
            {
                displayByDeactivationTimeout = [[NSDate date] timeIntervalSince1970] > ([nDeactivationDate doubleValue] + lockTimeout);
                if (byTimeout)
                   *byTimeout = displayByDeactivationTimeout;
            }
        }
        
        return [self isManuallyLocked] || displayByDeactivationTimeout;
    }
    
    return false;
}

- (bool)willBeLocked {
    if ([TGDatabaseInstance() isPasswordSet:NULL]) {
        return true;
    }
    
    return false;
}

- (bool)isDisplayingPasscodeWindow
{
    return _passcodeWindow != nil && !_passcodeWindow.hidden;
}

- (void)onBecomeInactive
{
    bool canBeLocked = false;
    bool isLocked = [self isCurrentlyLocked:NULL canBeLocked:&canBeLocked];
    if (isLocked)
    {
        [self setIsManuallyLocked:true];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Passcode_deactivationDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"Passcode_deactivationDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if ([TGDatabaseInstance() isPasswordSet:NULL])
    {
        if (TGTelegraphInstance.clientUserId != 0)
        {
            TLRPCaccount_updateDeviceLocked$account_updateDeviceLocked *updateDeviceLocked = [[TLRPCaccount_updateDeviceLocked$account_updateDeviceLocked alloc] init];
            if ([self isManuallyLocked])
                updateDeviceLocked.period = 0;
            else
                updateDeviceLocked.period = [self automaticLockTimeout];
            
            if (_deviceLockedRequestDisposable == nil)
                _deviceLockedRequestDisposable = [[SMetaDisposable alloc] init];
            
            [_deviceLockedRequestDisposable setDisposable:[[[TGTelegramNetworking instance] requestSignal:updateDeviceLocked] startWithNext:^(__unused id next)
            {
            }]];
            
            _didUpdateDeviceLocked = true;
        }
    }
    
    if ([self willBeLocked]) {
        [self displayBlurredContentIfNeeded];
    }
}

- (void)onBecomeActive
{
    [self hideBlurredContentIfNeeded];
    
    if (_didUpdateDeviceLocked)
    {
        _didUpdateDeviceLocked = false;
        
        if (![self isCurrentlyLocked]) {
            [self resetRemoteDeviceLocked];
        }
    }
    
    if ([self isCurrentlyLocked])
    {
        [self setIsManuallyLocked:true];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Passcode_deactivationDate"];
        
        [self displayUnlockWindowIfNeeded];
    }
}

- (void)resetRemoteDeviceLocked
{
    if (TGTelegraphInstance.clientUserId != 0)
    {        
        TLRPCaccount_updateDeviceLocked$account_updateDeviceLocked *updateDeviceLocked = [[TLRPCaccount_updateDeviceLocked$account_updateDeviceLocked alloc] init];
        updateDeviceLocked.period = -1;
        
        if (_deviceLockedRequestDisposable == nil)
            _deviceLockedRequestDisposable = [[SMetaDisposable alloc] init];
        
        [_deviceLockedRequestDisposable setDisposable:[[[TGTelegramNetworking instance] requestSignal:updateDeviceLocked] startWithNext:^(__unused id next)
        {
            
        }]];
    }
}

+ (void)movePathsToContainer
{
    if (iosMajorVersion() >= 8)
    {
        NSString *groupName = [@"group." stringByAppendingString:[[NSBundle mainBundle] bundleIdentifier]];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSURL *groupURL = [fileManager containerURLForSecurityApplicationGroupIdentifier:groupName];
        if (groupURL != nil)
        {
            NSString *documentsPath = [[groupURL path] stringByAppendingPathComponent:@"Documents"];
            
            [fileManager createDirectoryAtPath:documentsPath withIntermediateDirectories:true attributes:nil error:NULL];
            
            NSString *defaultDocumentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0];
            NSArray *documentItems = [fileManager contentsOfDirectoryAtPath:defaultDocumentsPath error:nil];
            int documentFileCount = 0;
            for (NSString *fileName in documentItems)
            {
                documentFileCount++;
                [fileManager moveItemAtPath:[defaultDocumentsPath stringByAppendingPathComponent:fileName] toPath:[documentsPath stringByAppendingPathComponent:fileName] error:nil];
            }
            
            NSString *localizationPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0] stringByAppendingPathComponent:@"localization"];
            
            [fileManager copyItemAtPath:localizationPath toPath:[documentsPath stringByAppendingPathComponent:@"localization"] error:nil];
            
            TGLog(@"Moved %d document items to container", documentFileCount);
            
            NSString *cachesPath = [[groupURL path] stringByAppendingPathComponent:@"Caches"];
            
            [fileManager createDirectoryAtPath:cachesPath withIntermediateDirectories:true attributes:nil error:NULL];
            
            NSString *defaultCachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true)[0];
            NSArray *cacheItems = [fileManager contentsOfDirectoryAtPath:defaultCachesPath error:nil];
            int cacheFileCount = 0;
            for (NSString *fileName in cacheItems)
            {
                cacheFileCount++;
                [fileManager moveItemAtPath:[defaultCachesPath stringByAppendingPathComponent:fileName] toPath:[cachesPath stringByAppendingPathComponent:fileName] error:nil];
            }
            
            TGLog(@"Moved %d cache items to container", cacheFileCount);
        }
    }
}

+ (NSString *)documentsPath
{
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        if (iosMajorVersion() >= 8)
        {
            NSString *groupName = [@"group." stringByAppendingString:[[NSBundle mainBundle] bundleIdentifier]];
            
            NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupName];
            if (groupURL != nil)
            {
                NSString *documentsPath = [[groupURL path] stringByAppendingPathComponent:@"Documents"];
                
                [[NSFileManager defaultManager] createDirectoryAtPath:documentsPath withIntermediateDirectories:true attributes:nil error:NULL];
                
                path = documentsPath;
            }
            else
                path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0];
        }
        else
            path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0];
    });
    
    return path;
}

+ (NSString *)cachePath
{
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        if (iosMajorVersion() >= 8)
        {
            NSString *groupName = [@"group." stringByAppendingString:[[NSBundle mainBundle] bundleIdentifier]];
            
            NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupName];
            if (groupURL != nil)
            {
                NSString *cachePath = [[groupURL path] stringByAppendingPathComponent:@"Caches"];
                
                [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:true attributes:nil error:NULL];
                
                path = cachePath;
            }
            else
                path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true)[0];
        }
        else
            path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true)[0];
    });
    
    return path;
}

- (void)inviteBotToGroup:(TGUser *)user payload:(NSString *)payload
{
    TGForwardTargetController *controller = [[TGForwardTargetController alloc] initWithSelectGroup];
    controller.watcherHandle = self.actionHandle;
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[controller] navigationBarClass:[TGWhiteNavigationBar class]];
    
    if ([_rootController.viewControllers.lastObject isKindOfClass:[TGModernConversationController class]]) {
        [(TGModernConversationController *)_rootController.viewControllers.lastObject endEditing];
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [self resetControllerStack];
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [_rootController presentViewController:navigationController animated:true completion:nil];
    });
    
    _currentInviteBot = user;
    _currentInviteBotPayload = payload;
}

- (void)startGameInConversation:(NSString *)shortName user:(TGUser *)user {
    TGForwardTargetController *controller = [[TGForwardTargetController alloc] initWithSelectTarget:false];
    controller.watcherHandle = self.actionHandle;
    controller.controllerTitle = TGLocalized(@"Share.Title");
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[controller] navigationBarClass:[TGWhiteNavigationBar class]];
    
    if ([_rootController.viewControllers.lastObject isKindOfClass:[TGModernConversationController class]]) {
        [(TGModernConversationController *)_rootController.viewControllers.lastObject endEditing];
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [self resetControllerStack];
        navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [_rootController presentViewController:navigationController animated:true completion:nil];
    });
    
    _currentStartGameBot = user;
    _currentStartGame = shortName;
}

#endif

- (void)setupShortcutItems
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    if (iosMajorVersion() >= 10)
        [self setupMenuShortcutItems];
    else
        [self setupChatShortcutItems];
#endif
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
- (void)setupMenuShortcutItems
{
    if (TGTelegraphInstance.clientUserId != 0 && TGTelegraphInstance.clientIsActivated)
    {
        UIApplicationShortcutItem *searchItem = [[UIApplicationShortcutItem alloc] initWithType:@"search" localizedTitle:TGLocalized(@"Common.Search") localizedSubtitle:nil icon:[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeSearch] userInfo:nil];
        
        UIApplicationShortcutItem *newItem = [[UIApplicationShortcutItem alloc] initWithType:@"compose" localizedTitle:TGLocalized(@"Compose.NewMessage") localizedSubtitle:nil icon:[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeCompose] userInfo:nil];
        
        UIApplicationShortcutItem *cameraItem = [[UIApplicationShortcutItem alloc] initWithType:@"camera" localizedTitle:TGLocalized(@"Camera.Title") localizedSubtitle:nil icon:[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeCapturePhoto] userInfo:nil];
        
        UIApplicationShortcutItem *cloudItem = [[UIApplicationShortcutItem alloc] initWithType:@"conversation" localizedTitle:TGLocalized(@"Conversation.SavedMessages") localizedSubtitle:nil icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"SavedMessagesIcon"] userInfo:@{ @"cid": @(TGTelegraphInstance.clientUserId) }];
        
        [UIApplication sharedApplication].shortcutItems = @[ searchItem, newItem, cameraItem, cloudItem ];
    }
    else
    {
        [UIApplication sharedApplication].shortcutItems = nil;
    }
}


- (void)setupChatShortcutItems
{
    if (iosMajorVersion() < 9 || [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPhone)
        return;
    
    if (TGTelegraphInstance.clientUserId != 0 && TGTelegraphInstance.clientIsActivated)
    {
        UIApplicationShortcutItem *composeItem = [[UIApplicationShortcutItem alloc] initWithType:@"compose" localizedTitle:TGLocalized(@"Compose.NewMessage") localizedSubtitle:nil icon:[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeCompose] userInfo:nil];
        
        NSArray *shortcuts = @[ composeItem ];
        [UIApplication sharedApplication].shortcutItems = shortcuts;
        
        if (![TGDatabaseInstance() isPasswordSet:NULL])
        {
            if (_recentPeersDisposable != nil)
                [_recentPeersDisposable dispose];
            
            _recentPeersDisposable = [[SMetaDisposable alloc] init];
            
            SSignal *updatedRecentPeers = [[TGRecentPeersSignals updateRecentPeers] mapToSignal:^SSignal *(__unused id next) {
                return [SSignal complete];
            }];
            
            [_recentPeersDisposable setDisposable:[[[[SSignal mergeSignals:@[[TGGlobalMessageSearchSignals recentPeerResults:^id (id item, __unused bool recent)
            {
                if ([item isKindOfClass:[TGConversation class]] && ((TGConversation *)item).conversationId == TGTelegraphInstance.clientUserId)
                    return nil;
                
                return item;
            } ratedPeers:true], updatedRecentPeers]] map:^id(NSArray *results)
            {
                if (results.count == 0)
                    return nil;
                
                NSMutableArray *sections = [[NSMutableArray alloc] init];
                for (id result in results)
                {
                    if ([result isKindOfClass:[TGDialogListRecentPeers class]])
                    {
                        TGDialogListRecentPeers *recentPeers = result;
                        [sections addObject:@{@"items": @[recentPeers], @"type": @"recent"}];
                    }
                }
                
                if (sections.count == 0)
                    return nil;
                
                NSMutableArray *chatItems = [[NSMutableArray alloc] init];
                for (NSDictionary *section in sections)
                {
                    TGDialogListRecentPeers *recentPeers = [section[@"items"] firstObject];
                    for (id peer in recentPeers.peers)
                    {
                        UIApplicationShortcutItem *item = [TGAppDelegate shortcutItemForPeer:peer];
                        if (item != nil)
                            [chatItems addObject:item];
                        
                        if (chatItems.count == 3)
                            break;
                    }
                }
                
                if (chatItems.count == 0)
                    return nil;
                
                return chatItems;
            }] deliverOn:[SQueue mainQueue]] startWithNext:^(NSArray *chatShortcuts)
            {
                NSArray *finalShortcuts = [shortcuts arrayByAddingObjectsFromArray:chatShortcuts];
                [UIApplication sharedApplication].shortcutItems = finalShortcuts;
            }]];
        }
    }
    else
    {
        [UIApplication sharedApplication].shortcutItems = nil;
        
        [_recentPeersDisposable dispose];
        _recentPeersDisposable = nil;
    }
}

+ (UIApplicationShortcutItem *)shortcutItemForPeer:(id)peer
{
    NSString *title = @"";
    CNMutableContact *contact = nil;
    
    int64_t peerId = 0;
    
    if ([peer isKindOfClass:[TGConversation class]])
    {
        TGConversation *conversation = peer;
        peerId = conversation.conversationId;
        
        if (conversation.additionalProperties[@"user"] != nil)
        {
            TGUser *user = conversation.additionalProperties[@"user"];
            title = user.displayName;
            
            contact.givenName = user.firstName;
            contact.familyName = user.lastName;
        }
        else
        {
            title = conversation.chatTitle;
            contact.givenName = title;
        }
    }
    else if ([peer isKindOfClass:[TGUser class]])
    {
        TGUser *user = peer;
        peerId = user.uid;
        title = user.displayName;
        
        contact.givenName = user.firstName;
        contact.familyName = user.lastName;
    }
    
    UIApplicationShortcutIcon *icon = [UIApplicationShortcutIcon iconWithContact:contact];
    UIApplicationShortcutItem *item = [[UIApplicationShortcutItem alloc] initWithType:@"conversation" localizedTitle:title localizedSubtitle:nil icon:icon userInfo:@{ @"cid": @(peerId) }];
    
    return item;
}

#endif

- (NSString *)_callsTabFilePath
{
    return [TGAppDelegateDocumentsPathCompat() stringByAppendingPathComponent:@"enablecalls.tab"];
}

- (bool)callsTabFileExists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self _callsTabFilePath]];
}

- (void)loadShowCallsTab
{
    NSData *data = [NSData dataWithContentsOfFile:[self _callsTabFilePath]];
    bool flag = false;
    if (data.length != 0)
    {
        uint8_t show = 0;
        [data getBytes:&show length:1];
        if (show > 0)
            flag = true;
    }
    _showCallsTab = flag;
}

- (void)setShowCallsTab:(int)showCallsTab
{
    _showCallsTab = showCallsTab;
    
    uint8_t show = showCallsTab ? 1: 0;
    NSData *data = [NSData dataWithBytes:&show length:1];
    [data writeToFile:[self _callsTabFilePath] atomically:true];
}

- (void)resetCallsTab
{
    _showCallsTab = false;
    [[NSFileManager defaultManager] removeItemAtPath:[self _callsTabFilePath] error:NULL];
}

- (void)actionStageActionRequested:(NSString *)action options:(id)options
{
    if ([action isEqualToString:@"userSelected"] || [action isEqualToString:@"conversationSelected"]) {
        if (_currentStartGame != nil) {
            int64_t peerId = 0;
            NSString *peerName = @"";
            if ([options isKindOfClass:[TGUser class]]) {
                peerId = ((TGUser *)options).uid;
                peerName = [((TGUser *)options) displayName];
            } else if ([options isKindOfClass:[TGConversation class]]) {
                peerId = ((TGConversation *)options).conversationId;
                peerName = [((TGConversation *)options) chatTitle];
            }
            
            NSString *formatString = TGPeerIdIsUser(peerId) ? TGLocalized(@"Target.ShareGameConfirmationPrivate") : TGLocalized(@"Target.ShareGameConfirmationGroup");
            [TGCustomAlertView presentAlertWithTitle:nil message:[NSString stringWithFormat:formatString, peerName] cancelButtonTitle:TGLocalized(@"Common.Cancel") okButtonTitle:TGLocalized(@"Common.OK") completionBlock:^(bool okButtonPressed) {
                if (okButtonPressed) {
                    TGProgressWindow *progressWindow = [[TGProgressWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                    [progressWindow show:true];
                    
                    [[[[TGBotSignals sendBotGame:_currentStartGame toPeerId:peerId botId:_currentStartGameBot.uid] deliverOn:[SQueue mainQueue]] onDispose:^
                    {
                        [progressWindow dismiss:true];
                    }] startWithNext:^(__unused id next)
                    {
                    } error:^(id error)
                    {
                        NSString *errorDescription = [[TGTelegramNetworking instance] extractNetworkErrorType:error];
                        NSString *alertText = TGLocalized(@"ConversationProfile.UnknownAddMemberError");
                        if ([errorDescription isEqualToString:@"USER_ALREADY_PARTICIPANT"])
                            alertText = TGLocalized(@"Target.InviteToGroupErrorAlreadyInvited");
                        else if ([errorDescription isEqualToString:@"CHAT_ADMIN_REQUIRED"]) {
                            TGUser *botUser = [TGDatabaseInstance() loadUser:_currentStartGameBot.uid];
                            alertText = TGLocalized(@"Group.Members.AddMemberBotErrorNotAllowed");
                        }
                        
                        [TGCustomAlertView presentAlertWithTitle:nil message:alertText cancelButtonTitle:TGLocalized(@"Common.OK")  okButtonTitle:nil completionBlock:nil];
                    } completed:^{
                        [_rootController dismissViewControllerAnimated:true completion:nil];
                        [[TGInterfaceManager instance] navigateToConversationWithId:peerId conversation:nil];
                    }];
                    _currentStartGame = nil;
                }
            }];
        }
    }
    else if ([action isEqualToString:@"willForwardMessages"])
    {
        if (_currentInviteBot != nil) {
            int32_t uid = _currentInviteBot.uid;
            NSString *payload = _currentInviteBotPayload;
            _currentInviteBot = nil;
            _currentInviteBotPayload = nil;
            if (uid != 0 && payload.length != 0)
            {
                TGConversation *conversation = options[@"target"];
                if (![conversation isKindOfClass:[TGConversation class]])
                    return;
                
                TGProgressWindow *progressWindow = [[TGProgressWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                [progressWindow show:true];
                
                [[[[TGBotSignals botInviteUserId:uid toPeerId:conversation.conversationId accessHash:conversation.accessHash payload:payload] deliverOn:[SQueue mainQueue]] onDispose:^
                {
                    [progressWindow dismiss:true];
                }] startWithNext:^(__unused id next)
                {
                    [[(UIViewController *)options[@"controller"] presentingViewController] dismissViewControllerAnimated:true completion:nil];
                    [[TGInterfaceManager instance] navigateToConversationWithId:conversation.conversationId conversation:nil];
                } error:^(id error)
                {
                    NSString *errorDescription = [[TGTelegramNetworking instance] extractNetworkErrorType:error];
                    NSString *alertText = TGLocalized(@"ConversationProfile.UnknownAddMemberError");
                    if ([errorDescription isEqualToString:@"USER_ALREADY_PARTICIPANT"])
                        alertText = TGLocalized(@"Target.InviteToGroupErrorAlreadyInvited");
                    else if ([errorDescription isEqualToString:@"CHAT_ADMIN_REQUIRED"]) {
                        alertText = TGLocalized(@"Group.Members.AddMemberBotErrorNotAllowed");
                    }
                    
                    [TGCustomAlertView presentAlertWithTitle:nil message:alertText cancelButtonTitle:TGLocalized(@"Common.OK")  okButtonTitle:nil completionBlock:nil];
                } completed:nil];
            }
        }
    }
}

- (void)updatePushRegistration {
    if (!TGIOS6APNsNotificationsEnabled()) {
        [self disableAPNsNotificationRegistration];
        return;
    }

    if (_pushToken != nil) {
        NSString *token = [[_pushToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
        token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        [[TGAccountSignals registerDeviceToken:token voip:false] startWithNext:nil];
    }
}

- (void)disableAPNsNotificationRegistration
{
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    _pushToken = nil;
    _tokenAlreadyRequested = false;

    if (_deviceTokenListener != nil)
        [_deviceTokenListener deviceTokenRequestCompleted:nil];
    _deviceTokenListener = nil;
}

- (void)applyIOS6APNsNotificationsEnabled:(bool)enabled
{
    bool effectiveEnabled = enabled;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:effectiveEnabled forKey:TGIOS6APNsNotificationsEnabledKey];
    [defaults synchronize];

    if (effectiveEnabled)
    {
        [ActionStageInstance() requestActor:@"/tg/service/settings/push/(subscribe)" options:nil watcher:TGTelegraphInstance];
    }
    else
    {
        NSString *token = nil;
        if (_pushToken != nil)
        {
            token = [[_pushToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
            token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
        }
        if (token.length != 0)
            [[TGAccountSignals unregisterDeviceToken:token voip:false] startWithNext:nil];
        [TGPushActionsRequestBuilder clearCachedDevicePushToken];
        [self disableAPNsNotificationRegistration];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    CGPoint location = [[event.allTouches anyObject] locationInView:self.window];
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    if (CGRectContainsPoint(statusBarFrame, location))
        _statusBarPressedPipe.sink(@true);
}

- (NSString *)applicationName
{
    NSString *appTitle = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (appTitle == nil) {
        appTitle = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    }
    if (appTitle == nil) {
        appTitle = @"Telegram";
    }
    return appTitle;
}

@end

@interface UICollectionViewDisableForwardToUICollectionViewSentinel : NSObject @end @implementation UICollectionViewDisableForwardToUICollectionViewSentinel @end
