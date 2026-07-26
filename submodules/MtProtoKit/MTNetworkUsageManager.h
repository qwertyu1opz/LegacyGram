#import <Foundation/Foundation.h>

@class MTSignal;
@class MTNetworkUsageCalculationInfo;

typedef enum {
    MTNetworkUsageManagerInterfaceWWAN,
    MTNetworkUsageManagerInterfaceOther
} MTNetworkUsageManagerInterface;

typedef struct {
    NSUInteger incomingBytes;
    NSUInteger outgoingBytes;
} MTNetworkUsageManagerInterfaceStats;

@interface MTNetworkUsageManager : NSObject

- (instancetype)initWithInfo:(MTNetworkUsageCalculationInfo *)info;

- (void)addIncomingBytes:(NSUInteger)incomingBytes interface:(MTNetworkUsageManagerInterface)interface;
- (void)addOutgoingBytes:(NSUInteger)outgoingBytes interface:(MTNetworkUsageManagerInterface)interface;

- (void)resetKeys:(NSArray *)keys setKeys:(NSDictionary *)setKeys completion:(void (^)())completion;
- (MTSignal *)currentStatsForKeys:(NSArray *)keys;

@end
