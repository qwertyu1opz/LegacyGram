#ifndef TG_LEGACY_TL_TLRPCCHANNELS_READHISTORY_H
#define TG_LEGACY_TL_TLRPCCHANNELS_READHISTORY_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;

@interface TLRPCchannels_readHistory : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic) int32_t max_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_readHistory$channels_readHistory : TLRPCchannels_readHistory


@end

#endif
