#ifndef TG_LEGACY_TL_TLRPCCHANNELS_JOINCHANNEL_H
#define TG_LEGACY_TL_TLRPCCHANNELS_JOINCHANNEL_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;
@class TLUpdates;

@interface TLRPCchannels_joinChannel : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_joinChannel$channels_joinChannel : TLRPCchannels_joinChannel


@end

#endif
