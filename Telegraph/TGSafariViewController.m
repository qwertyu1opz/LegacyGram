#import "TGSafariViewController.h"
#import "TGApplication.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
@implementation SFSafariViewController

- (instancetype)initWithURL:(NSURL *)URL
{
    return [self initWithURL:URL entersReaderIfAvailable:false];
}

- (instancetype)initWithURL:(NSURL *)URL entersReaderIfAvailable:(BOOL)__unused entersReaderIfAvailable
{
    self = [super init];
    if (self != nil)
    {
        UIApplication *application = [UIApplication sharedApplication];
        if ([application respondsToSelector:@selector(nativeOpenURL:)])
            [(TGApplication *)application nativeOpenURL:URL];
        else
            [application openURL:URL];
    }
    return self;
}

- (NSArray *)previewActionItems
{
    return @[];
}

@end
#endif


@implementation TGSafariViewController

- (NSArray *)previewActionItems {
    if (self.externalPreviewActionItems != nil)
        return self.externalPreviewActionItems();
    
    return [super previewActionItems];
}

@end
