#import <Foundation/Foundation.h>

@class TGRemoteRecentPeer;

@interface TGRemoteRecentPeerSet: NSObject

@property (nonatomic, strong, readonly) NSArray *peers;

- (instancetype)initWithPeers:(NSArray *)peers;

@end
