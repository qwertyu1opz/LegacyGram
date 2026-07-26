#ifndef TG_LEGACY_TL_TLRPCCHANNELS_INVITETOCHANNEL_H
#define TG_LEGACY_TL_TLRPCCHANNELS_INVITETOCHANNEL_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;
@class TLUpdates;

@interface TLRPCchannels_inviteToChannel : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic, retain) NSArray *users;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_inviteToChannel$channels_inviteToChannel : TLRPCchannels_inviteToChannel


@end

#endif
