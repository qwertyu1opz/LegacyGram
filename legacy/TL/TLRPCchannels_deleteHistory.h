#ifndef TG_LEGACY_TL_TLRPCCHANNELS_DELETEHISTORY_H
#define TG_LEGACY_TL_TLRPCCHANNELS_DELETEHISTORY_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;

@interface TLRPCchannels_deleteHistory : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic) int32_t max_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_deleteHistory$channels_deleteHistory : TLRPCchannels_deleteHistory


@end

#endif
