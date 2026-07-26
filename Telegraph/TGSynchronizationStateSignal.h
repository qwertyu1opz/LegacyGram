#import <Foundation/Foundation.h>
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

typedef enum {
    TGSynchronizationStateSynchronized,
    TGSynchronizationStateWaitingForNetwork,
    TGSynchronizationStateConnecting,
    TGSynchronizationStateConnectingToProxy,
    TGSynchronizationStateUpdating,
    TGSynchronizationStateProxyIssues,
} TGSynchronizationStateValue;

@interface TGSynchronizationStateSignal : NSObject

+ (SSignal *)synchronizationState;

@end
