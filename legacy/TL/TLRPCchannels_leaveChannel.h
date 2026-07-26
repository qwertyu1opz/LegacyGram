#ifndef TG_LEGACY_TL_TLRPCCHANNELS_LEAVECHANNEL_H
#define TG_LEGACY_TL_TLRPCCHANNELS_LEAVECHANNEL_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;
@class TLUpdates;

@interface TLRPCchannels_leaveChannel : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_leaveChannel$channels_leaveChannel : TLRPCchannels_leaveChannel


@end

#endif
