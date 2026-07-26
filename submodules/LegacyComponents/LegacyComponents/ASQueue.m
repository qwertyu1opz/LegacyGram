

#import "ASQueue.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

static bool ASQueueIOS6PerfLoggingEnabled()
{
    return false;
}

static NSString *ASQueueIOS6PerfDeviceName(NSString *machine)
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

static NSString *ASQueueIOS6PerfBuildTag()
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
        tag = [[NSString alloc] initWithFormat:@"version=%@ build=%@ os=%@ %@ device=%@ (%@)", version, build, device.systemName, device.systemVersion, ASQueueIOS6PerfDeviceName(machine), machine];
    });
    return tag;
}

static NSString *ASQueueIOS6PerfEscape(NSString *string)
{
    if (string == nil)
        return @"";
    NSString *escaped = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
    return escaped;
}

static NSString *ASQueueIOS6PerfCallStack()
{
    NSArray *symbols = [NSThread callStackSymbols];
    if (symbols.count == 0)
        return @"";
    
    NSUInteger count = MIN((NSUInteger)12, symbols.count);
    NSMutableArray *frames = [[NSMutableArray alloc] initWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++)
        [frames addObject:[symbols objectAtIndex:i]];
    
    return [frames componentsJoinedByString:@"\n"];
}

static void ASQueueIOS6PerfReportToBot(const char *name, bool synchronous, CFAbsoluteTime elapsedMs, int skipped)
{
    if (!ASQueueIOS6PerfLoggingEnabled())
        return;
    
    if (elapsedMs < 1000.0)
        return;
    
    static CFAbsoluteTime lastReportTime = 0.0;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    @synchronized([ASQueue class])
    {
        if (now - lastReportTime < 300.0)
            return;
        lastReportTime = now;
    }
    
    NSString *message = [NSString stringWithFormat:@"%@\nqueue=%s sync=%d ms=%.1f skipped=%d\nstack:\n%@", ASQueueIOS6PerfBuildTag(), name != NULL ? name : "main", synchronous ? 1 : 0, elapsedMs, skipped, ASQueueIOS6PerfCallStack()];
    NSString *bodyString = [NSString stringWithFormat:@"secret=%@&event=%@&message=%@",
        ASQueueIOS6PerfEscape(@""),
        ASQueueIOS6PerfEscape(@"perf_as_queue_slow"),
        ASQueueIOS6PerfEscape(message)];
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

static void ASQueueIOS6PerfMaybeLog(const char *name, id queue, bool synchronous, CFAbsoluteTime elapsedMs)
{
    if (!ASQueueIOS6PerfLoggingEnabled())
        return;
    
    if (elapsedMs < 250.0)
        return;
    
    static CFAbsoluteTime lastLogTime = 0.0;
    static int skipped = 0;
    int skippedNow = 0;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    @synchronized([ASQueue class])
    {
        if (now - lastLogTime < 2.0)
        {
            skipped++;
            return;
        }
        skippedNow = skipped;
        skipped = 0;
        lastLogTime = now;
    }
    
    while (false) NSLog(@"IOS6PERF slowASQueue %@ queue=%s ptr=%p sync=%d ms=%.1f skipped=%d", ASQueueIOS6PerfBuildTag(), name != NULL ? name : "main", queue, synchronous ? 1 : 0, elapsedMs, skippedNow);
    ASQueueIOS6PerfReportToBot(name, synchronous, elapsedMs, skippedNow);
}

@interface ASQueue ()
{
    bool _isMainQueue;
    dispatch_queue_t _queue;
    
    const char *_name;
}

@end

@implementation ASQueue

- (instancetype)initWithName:(const char *)name
{
    self = [super init];
    if (self != nil)
    {
        _name = name;
        
        _queue = dispatch_queue_create(_name, 0);
        dispatch_queue_set_specific(_queue, _name, (void *)_name, NULL);
    }
    return self;
}

- (void)dealloc
{
#if !OS_OBJECT_HAVE_OBJC_SUPPORT
    dispatch_release(_queue);
#endif
    _queue = nil;
}

+ (ASQueue *)mainQueue
{
    static ASQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        queue = [[ASQueue alloc] init];
        queue->_queue = dispatch_get_main_queue();
        queue->_isMainQueue = true;
    });
    return queue;
}

- (dispatch_queue_t)nativeQueue
{
    return _queue;
}

- (bool)isCurrentQueue
{
    if (_queue == nil)
        return false;
    
    if (_isMainQueue)
        return [NSThread isMainThread];
    else
        return dispatch_get_specific(_name) == _name;
}

- (void)dispatchOnQueue:(dispatch_block_t)block
{
    [self dispatchOnQueue:block synchronous:false];
}

- (void)dispatchOnQueue:(dispatch_block_t)block synchronous:(bool)synchronous
{
    if (block == nil)
        return;
    
    if (_queue != nil)
    {
        if (_isMainQueue)
        {
            if ([NSThread isMainThread])
            {
                CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
                block();
                ASQueueIOS6PerfMaybeLog("main-inline", self, synchronous, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
            }
            else if (synchronous)
                dispatch_sync(_queue, ^
                {
                    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
                    block();
                    ASQueueIOS6PerfMaybeLog("main", self, true, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
                });
            else
                dispatch_async(_queue, ^
                {
                    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
                    block();
                    ASQueueIOS6PerfMaybeLog("main", self, false, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
                });
        }
        else
        {
            if (dispatch_get_specific(_name) == _name)
            {
                CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
                block();
                ASQueueIOS6PerfMaybeLog(_name, self, synchronous, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
            }
            else if (synchronous)
                dispatch_sync(_queue, ^
                {
                    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
                    block();
                    ASQueueIOS6PerfMaybeLog(_name, self, true, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
                });
            else
                dispatch_async(_queue, ^
                {
                    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
                    block();
                    ASQueueIOS6PerfMaybeLog(_name, self, false, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
                });
        }
    }
}

@end
