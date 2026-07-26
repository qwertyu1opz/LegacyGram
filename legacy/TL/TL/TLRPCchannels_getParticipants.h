#ifndef TG_LEGACY_TL_TLRPCCHANNELS_GETPARTICIPANTS_H
#define TG_LEGACY_TL_TLRPCCHANNELS_GETPARTICIPANTS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;
@class TLChannelParticipantsFilter;
@class TLchannels_ChannelParticipants;

@interface TLRPCchannels_getParticipants : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic, retain) TLChannelParticipantsFilter *filter;
@property (nonatomic) int32_t offset;
@property (nonatomic) int32_t limit;
@property (nonatomic) int32_t n_hash;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_getParticipants$channels_getParticipants : TLRPCchannels_getParticipants


@end

#endif
