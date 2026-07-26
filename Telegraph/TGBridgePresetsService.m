#import "TGBridgePresetsService.h"
#import "TGBridgeCommon.h"

#import "TGTelegraph.h"

#import <CommonCrypto/CommonCrypto.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

NSString *const TGBridgePresetsPipeKey = @"presets";
NSString *const TGBridgePresetsDefaultsKey = @"TG_presets";

static bool TGWatchIOS6PerfLoggingEnabled()
{
    return false;
}

static NSString *TGWatchIOS6PerfDeviceName(NSString *machine)
{
    if ([machine hasPrefix:@"iPad2,1"] || [machine hasPrefix:@"iPad2,2"] || [machine hasPrefix:@"iPad2,3"] || [machine hasPrefix:@"iPad2,4"])
        return @"iPad 2";
    if ([machine hasPrefix:@"iPad2,5"] || [machine hasPrefix:@"iPad2,6"] || [machine hasPrefix:@"iPad2,7"])
        return @"iPad mini";
    if ([machine hasPrefix:@"iPad3,1"] || [machine hasPrefix:@"iPad3,2"] || [machine hasPrefix:@"iPad3,3"])
        return @"iPad 3";
    if ([machine hasPrefix:@"iPad3,4"] || [machine hasPrefix:@"iPad3,5"] || [machine hasPrefix:@"iPad3,6"])
        return @"iPad 4";
    if ([machine hasPrefix:@"iPhone4,1"])
        return @"iPhone 4S";
    if ([machine hasPrefix:@"iPhone5,1"] || [machine hasPrefix:@"iPhone5,2"])
        return @"iPhone 5";
    if ([machine hasPrefix:@"iPhone5,3"] || [machine hasPrefix:@"iPhone5,4"])
        return @"iPhone 5c";
    if ([machine hasPrefix:@"iPhone6,1"] || [machine hasPrefix:@"iPhone6,2"])
        return @"iPhone 5s";
    if ([machine hasPrefix:@"iPod5,1"])
        return @"iPod touch 5";
    return machine ?: @"?";
}

static NSString *TGWatchIOS6PerfBuildTag()
{
    static NSString *tag = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?";
        NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"?";
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *machine = [[NSString alloc] initWithUTF8String:systemInfo.machine] ?: @"?";
        UIDevice *device = [UIDevice currentDevice];
        tag = [[NSString alloc] initWithFormat:@"version=%@ build=%@ os=%@ %@ device=%@ (%@)", version, build, device.systemName, device.systemVersion, TGWatchIOS6PerfDeviceName(machine), machine];
    });
    return tag;
}

static NSString *TGWatchIOS6PerfEscape(NSString *string)
{
    if (string == nil)
        return @"";
    NSString *escaped = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
    return escaped;
}

static void TGWatchIOS6PerfReportToBot(NSString *event, NSString *message)
{
    if (!TGWatchIOS6PerfLoggingEnabled())
        return;
    
    static NSMutableDictionary *lastReports = nil;
    static NSLock *reportLock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        lastReports = [[NSMutableDictionary alloc] init];
        reportLock = [[NSLock alloc] init];
    });
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    [reportLock lock];
    NSNumber *last = [lastReports objectForKey:event ?: @""];
    if (last != nil && now - [last doubleValue] < 300.0)
    {
        [reportLock unlock];
        return;
    }
    [lastReports setObject:@(now) forKey:event ?: @""];
    [reportLock unlock];
    
    NSString *bodyString = [NSString stringWithFormat:@"secret=%@&event=%@&message=%@",
        TGWatchIOS6PerfEscape(@""),
        TGWatchIOS6PerfEscape(event),
        TGWatchIOS6PerfEscape(message)];
    NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:@""];
    if (url == nil || body == nil)
        return;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:nil];
}

static void TGWatchIOS6PerfLogIfSlow(NSString *event, CFAbsoluteTime start, NSUInteger count, double thresholdMs)
{
    if (!TGWatchIOS6PerfLoggingEnabled())
        return;
    
    CFAbsoluteTime elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1000.0;
    if (elapsedMs < thresholdMs)
        return;
    
    while (false) NSLog(@"IOS6PERF %@ %@ count=%lu ms=%.1f", event, TGWatchIOS6PerfBuildTag(), (unsigned long)count, elapsedMs);
    if (elapsedMs >= MAX(1000.0, thresholdMs * 5.0))
        TGWatchIOS6PerfReportToBot([NSString stringWithFormat:@"perf_%@", event], [NSString stringWithFormat:@"%@\ncount=%lu ms=%.1f", TGWatchIOS6PerfBuildTag(), (unsigned long)count, elapsedMs]);
}

@interface TGBridgePresetsService ()
{
    SSignal *_presetsSignal;
    SMetaDisposable *_disposable;
}
@end

@implementation TGBridgePresetsService

- (instancetype)initWithServer:(TGBridgeServer *)server
{
    self = [super initWithServer:server];
    if (self != nil)
    {
        _presetsSignal = [[SSignal single:[TGBridgePresetsService currentPresets]] then:[server pipeForKey:TGBridgePresetsPipeKey]];
        
        __weak TGBridgePresetsService *weakSelf = self;
        _disposable = [[SMetaDisposable alloc] init];
        [_disposable setDisposable:[_presetsSignal startWithNext:^(NSDictionary *next)
        {
            __strong TGBridgePresetsService *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            if (![next isKindOfClass:[NSDictionary class]])
                return;
            
            NSURL *lastSentPresetsUrl = TGFileURLWithPathRelativeToURL(@"Presets.data", [strongSelf.server temporaryFilesURL]);

            NSData *presetsData = [NSKeyedArchiver archivedDataWithRootObject:next];
        
            NSString *currentPresetsHash = [TGBridgePresetsService md5OfData:presetsData];
            NSString *lastSentPresetsHash = [TGBridgePresetsService md5OfFileAtURL:lastSentPresetsUrl];
            
            if (lastSentPresetsUrl == nil || ![currentPresetsHash isEqualToString:lastSentPresetsHash])
            {
                CFAbsoluteTime sendStart = CFAbsoluteTimeGetCurrent();
                if ([[NSFileManager defaultManager] fileExistsAtPath:lastSentPresetsUrl.path])
                    [[NSFileManager defaultManager] removeItemAtURL:lastSentPresetsUrl error:nil];
        
                [presetsData writeToURL:lastSentPresetsUrl atomically:true];
                [strongSelf.server sendFileWithURL:lastSentPresetsUrl metadata:@{ TGBridgeIncomingFileIdentifierKey: @"presets" }];
                TGWatchIOS6PerfLogIfSlow(@"watchPresetsSendSlow", sendStart, next.count, 300.0);
            }
        }]];
    }
    return self;
}

+ (void)storePresets:(NSDictionary *)presets
{
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    if (TGTelegraphInstance.clientUserId == 0 || !TGTelegraphInstance.clientIsActivated)
        return;
    
    [[TGBridgeServer instanceSignal] startWithNext:^(TGBridgeServer *server) {
        [server putNext:presets forKey:TGBridgePresetsPipeKey];
    }];
    
    if (presets != nil)
        [[NSUserDefaults standardUserDefaults] setObject:presets forKey:[self userDefaultsKey]];
    else
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self userDefaultsKey]];
    
    TGWatchIOS6PerfLogIfSlow(@"watchPresetsStoreSlow", start, presets.count, 100.0);
}

+ (NSDictionary *)currentPresets
{
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    if (TGTelegraphInstance.clientUserId == 0 || !TGTelegraphInstance.clientIsActivated)
        return nil;
    
    NSDictionary *result = [[NSUserDefaults standardUserDefaults] objectForKey:[self userDefaultsKey]];
    TGWatchIOS6PerfLogIfSlow(@"watchPresetsLoadSlow", start, result.count, 100.0);
    return result;
}

+ (NSString *)userDefaultsKey
{
    return [NSString stringWithFormat:@"%@_%d", TGBridgePresetsDefaultsKey, TGTelegraphInstance.clientUserId];
}

+ (NSArray *)presetIdentifiers
{
    return @
    [
     @"Suggestion.OK",
     @"Suggestion.Thanks",
     @"Suggestion.WhatsUp",
     @"Suggestion.TalkLater",
     @"Suggestion.CantTalk",
     @"Suggestion.HoldOn",
     @"Suggestion.BRB",
     @"Suggestion.OnMyWay"
    ];
}

+ (NSString *)md5OfData:(NSData *)data
{
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(data.bytes, (uint32_t)data.length, md5Buffer);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

+ (NSString *)md5OfFileAtURL:(NSURL *)url
{
    NSError *error;
    NSData *data = [NSData dataWithContentsOfURL:url options:NSMappedRead error:&error];
    if (error != nil)
        return nil;

    return [self md5OfData:data];
}

@end
