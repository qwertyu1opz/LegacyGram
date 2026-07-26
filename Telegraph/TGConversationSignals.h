#import <Foundation/Foundation.h>
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGConversationSignals : NSObject

+ (SSignal *)conversationWithPeerId:(int64_t)peerId full:(bool)full;

@end
