#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@class TGMessage;

@interface TGExternalShareSignals : NSObject

+ (SSignal *)shareItemsForMessages:(NSArray *)messages;

@end
