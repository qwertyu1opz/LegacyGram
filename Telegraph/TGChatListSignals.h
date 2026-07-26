#import <Foundation/Foundation.h>
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGChatListSignals : NSObject

+ (SSignal *)chatListWithLimit:(NSUInteger)limit;

@end
