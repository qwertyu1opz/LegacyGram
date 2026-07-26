#import <Foundation/Foundation.h>

#import "TGRemoteRecentPeerCategories.h"

@interface TGPeerRatingUpdates : NSObject

@property (nonatomic, readonly) int64_t peerId;
@property (nonatomic, readonly) TGPeerRatingCategory category;
@property (nonatomic, strong, readonly) NSArray *timestamps;

- (instancetype)initWithPeerId:(int64_t)peerId category:(TGPeerRatingCategory)category timestamps:(NSArray *)timestamps;

@end
