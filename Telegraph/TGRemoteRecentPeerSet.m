#import "TGRemoteRecentPeerSet.h"

@implementation TGRemoteRecentPeerSet

- (instancetype)initWithPeers:(NSArray *)peers {
    self = [super init];
    if (self != nil) {
        _peers = peers;
    }
    return self;
}

@end
