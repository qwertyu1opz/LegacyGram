#import "TGSharedMediaUtils.h"

#import "TGMediaStoreContext.h"
#import <sys/utsname.h>

static bool TGIOS6SlowSharedMediaDevice()
{
    static bool result = false;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *machine = [[NSString alloc] initWithUTF8String:systemInfo.machine] ?: @"";
        result = [machine hasPrefix:@"iPhone2,"] || [machine hasPrefix:@"iPhone3,"] || [machine hasPrefix:@"iPod4,"] || [machine hasPrefix:@"iPad1,"];
    });
    return result;
}

@implementation TGSharedMediaUtils

+ (TGMemoryImageCache *)sharedMediaMemoryImageCache
{
    static TGMemoryImageCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        float factor = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 3.0f : 1.0f;
        instance = [[TGMemoryImageCache alloc] initWithSoftMemoryLimit:(NSUInteger)(2 * 1024 * 1024 * factor) hardMemoryLimit:(NSUInteger)(3 * 1024 * 1024 * factor)];
    });
    return instance;
}

+ (EMInMemoryImageCache *)inMemoryImageCache
{
    static EMInMemoryImageCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        float factor = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 3.0f : 1.0f;
        instance = [[EMInMemoryImageCache alloc] initWithMaxResidentSize:(NSUInteger)(4 * 1024 * 1024 * factor)];
    });
    return instance;
}

+ (SThreadPool *)sharedMediaImageProcessingThreadPool
{
    static SThreadPool *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        if (TGIOS6SlowSharedMediaDevice())
            instance = [[SThreadPool alloc] initWithThreadCount:1 threadPriority:0.25];
        else
            instance = [[SThreadPool alloc] init];
    });
    return instance;
}

+ (TGModernCache *)sharedMediaTemporaryPersistentCache
{
    return [[TGMediaStoreContext instance] temporaryFilesCache];
}

@end
