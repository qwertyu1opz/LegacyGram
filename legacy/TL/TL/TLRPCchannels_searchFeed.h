#ifndef TG_LEGACY_TL_TLRPCCHANNELS_SEARCHFEED_H
#define TG_LEGACY_TL_TLRPCCHANNELS_SEARCHFEED_H

#import "TLMetaRpc.h"

#import "TL/TLMetaScheme.h"

@interface TLRPCchannels_searchFeed : TLMetaRpc

@property (nonatomic) int32_t feed_id;
@property (nonatomic, strong) NSString *q;
@property (nonatomic) int32_t offset_date;
@property (nonatomic, strong) TLInputPeer *offset_peer;
@property (nonatomic) int32_t offset_id;
@property (nonatomic) int32_t limit;

@end

#endif
