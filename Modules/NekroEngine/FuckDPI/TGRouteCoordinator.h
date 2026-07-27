#import <Foundation/Foundation.h>

typedef enum
{
    TGRouteStateDisabled,
    TGRouteStateSearching,
    TGRouteStateConnecting,
    TGRouteStateConnected,
    TGRouteStateFailed
} TGRouteState;

@interface TGRouteCoordinator : NSObject

@property (nonatomic, copy) void (^stateChanged)(TGRouteState state, NSString *message);

- (void)refreshState;
- (void)enable;
- (void)disable;

@end
