#import <Foundation/Foundation.h>
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGGroupedUserOnlineInfo : NSObject

@property (nonatomic, readonly) NSUInteger totalCount;
@property (nonatomic, readonly) NSUInteger onlineCount;

@end

@interface TGGroupedUserOnlineSignals : NSObject

+ (SSignal *)groupedOnlineInfoForUserList:(SSignal *)userList;

@end
