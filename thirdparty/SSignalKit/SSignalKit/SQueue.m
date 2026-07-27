#import "SQueue.h"
#import <sys/utsname.h>

static const void *SQueueSpecificKey = &SQueueSpecificKey;

static NSString *SQueueIOS6PerfBuildTag()
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
        tag = [[NSString alloc] initWithFormat:@"version=%@ build=%@ device=%@", version, build, machine];
    });
    return tag;
}

static void SQueueIOS6PerfMaybeLog(NSString *queueName, id queue, bool synchronous, CFAbsoluteTime elapsedMs)
{
    if (elapsedMs < 250.0)
        return;
    
    static CFAbsoluteTime lastLogTime = 0.0;
    static int skipped = 0;
    int skippedNow = 0;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    @synchronized([SQueue class])
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
    
    NSLog(@"IOS6PERF slowQueue %@ queue=%@ ptr=%p sync=%d ms=%.1f skipped=%d", SQueueIOS6PerfBuildTag(), queueName, queue, synchronous ? 1 : 0, elapsedMs, skippedNow);
}

@interface SQueue ()
{
    dispatch_queue_t _queue;
    void *_queueSpecific;
    bool _specialIsMainQueue;
}

@end

@implementation SQueue

+ (SQueue *)mainQueue
{
    static SQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        queue = [[SQueue alloc] initWithNativeQueue:dispatch_get_main_queue() queueSpecific:NULL];
        queue->_specialIsMainQueue = true;
    });
    
    return queue;
}

+ (SQueue *)concurrentDefaultQueue
{
    static SQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        queue = [[SQueue alloc] initWithNativeQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) queueSpecific:NULL];
    });
    
    return queue;
}

+ (SQueue *)concurrentBackgroundQueue
{
    static SQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        queue = [[SQueue alloc] initWithNativeQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) queueSpecific:NULL];
    });
    
    return queue;
}

+ (SQueue *)wrapConcurrentNativeQueue:(dispatch_queue_t)nativeQueue
{
    return [[SQueue alloc] initWithNativeQueue:nativeQueue queueSpecific:NULL];
}

- (instancetype)init
{
    dispatch_queue_t queue = dispatch_queue_create(NULL, NULL);
    dispatch_queue_set_specific(queue, SQueueSpecificKey, (__bridge void *)self, NULL);
    return [self initWithNativeQueue:queue queueSpecific:(__bridge void *)self];
}

- (instancetype)initWithNativeQueue:(dispatch_queue_t)queue queueSpecific:(void *)queueSpecific
{
    self = [super init];
    if (self != nil)
    {
        _queue = queue;
        _queueSpecific = queueSpecific;
    }
    return self;
}

- (dispatch_queue_t)_dispatch_queue
{
    return _queue;
}

- (void)dispatch:(dispatch_block_t)block
{
    if (_queueSpecific != NULL && dispatch_get_specific(SQueueSpecificKey) == _queueSpecific)
    {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        block();
        SQueueIOS6PerfMaybeLog(@"current", self, false, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
    }
    else if (_specialIsMainQueue && [NSThread isMainThread])
    {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        block();
        SQueueIOS6PerfMaybeLog(@"main-inline", self, false, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
    }
    else
        dispatch_async(_queue, ^
        {
            CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
            block();
            SQueueIOS6PerfMaybeLog(_specialIsMainQueue ? @"main" : (_queueSpecific == NULL ? @"concurrent" : @"serial"), self, false, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
        });
}

- (void)dispatchSync:(dispatch_block_t)block
{
    if (_queueSpecific != NULL && dispatch_get_specific(SQueueSpecificKey) == _queueSpecific)
    {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        block();
        SQueueIOS6PerfMaybeLog(@"current", self, true, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
    }
    else if (_specialIsMainQueue && [NSThread isMainThread])
    {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        block();
        SQueueIOS6PerfMaybeLog(@"main-inline", self, true, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
    }
    else
        dispatch_sync(_queue, ^
        {
            CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
            block();
            SQueueIOS6PerfMaybeLog(_specialIsMainQueue ? @"main" : (_queueSpecific == NULL ? @"concurrent" : @"serial"), self, true, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
        });
}

- (void)dispatch:(dispatch_block_t)block synchronous:(bool)synchronous {
    if (_queueSpecific != NULL && dispatch_get_specific(SQueueSpecificKey) == _queueSpecific)
    {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        block();
        SQueueIOS6PerfMaybeLog(@"current", self, synchronous, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
    }
    else if (_specialIsMainQueue && [NSThread isMainThread])
    {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        block();
        SQueueIOS6PerfMaybeLog(@"main-inline", self, synchronous, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
    }
    else {
        if (synchronous) {
            dispatch_sync(_queue, ^
            {
                CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
                block();
                SQueueIOS6PerfMaybeLog(_specialIsMainQueue ? @"main" : (_queueSpecific == NULL ? @"concurrent" : @"serial"), self, true, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
            });
        } else {
            dispatch_async(_queue, ^
            {
                CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
                block();
                SQueueIOS6PerfMaybeLog(_specialIsMainQueue ? @"main" : (_queueSpecific == NULL ? @"concurrent" : @"serial"), self, false, (CFAbsoluteTimeGetCurrent() - start) * 1000.0);
            });
        }
    }
}

- (bool)isCurrentQueue
{
    if (_queueSpecific != NULL && dispatch_get_specific(SQueueSpecificKey) == _queueSpecific)
        return true;
    else if (_specialIsMainQueue && [NSThread isMainThread])
        return true;
    return false;
}

@end
