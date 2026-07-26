#ifndef TG_LEGACY_TL_TLRPCCHANNELS_TOGGLESIGNATURES_H
#define TG_LEGACY_TL_TLRPCCHANNELS_TOGGLESIGNATURES_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;
@class TLUpdates;

@interface TLRPCchannels_toggleSignatures : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic) bool enabled;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_toggleSignatures$channels_toggleSignatures : TLRPCchannels_toggleSignatures


@end

#endif
