#import "TGModernConversationControllerDynamicTypeSignals.h"

@implementation TGModernConversationControllerDynamicTypeSignals

+ (SSignal *)dynamicTypeBaseFontPointSize
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    return [[SSignal alloc] initWithGenerator:^(SSubscriber *subscriber)
    {
        CGFloat pointSize = [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize;
        [subscriber putNext:@(pointSize)];
        
        id observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(__unused NSNotification *notification)
        {
            TGDispatchOnMainThread(^
            {
                [subscriber putNext:@([UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize)];
            });
        }];
        
        return [[SBlockDisposable alloc] initWithBlock:^
        {
            TGDispatchOnMainThread(^
            {
                [[NSNotificationCenter defaultCenter] removeObserver:observer];
            });
        }];
    }];
#else
    return [SSignal single:@(16.0f)];
#endif
}

@end
