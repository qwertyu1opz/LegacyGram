#import <Foundation/Foundation.h>

#import "../submodules/LegacyComponents/LegacyComponents/PSCoding.h"

@interface TGUnseenPeerMentionsMessageIdsState : NSObject <PSCoding>

@property (nonatomic, readonly) int32_t maxCachedId;

- (instancetype)initWithMaxCachedId:(int32_t)maxCachedId;

@end
