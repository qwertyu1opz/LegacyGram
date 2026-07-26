#ifndef TG_LEGACY_TL_TLRPCCHANNELS_GETFULLCHANNEL_H
#define TG_LEGACY_TL_TLRPCCHANNELS_GETFULLCHANNEL_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;
@class TLmessages_ChatFull;

@interface TLRPCchannels_getFullChannel : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_getFullChannel$channels_getFullChannel : TLRPCchannels_getFullChannel


@end

#endif
