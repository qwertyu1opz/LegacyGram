#import <Foundation/Foundation.h>
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGSearchPeersSignals : NSObject

+ (SSignal *)searchPeersWithQuery:(NSString *)query;

@end
