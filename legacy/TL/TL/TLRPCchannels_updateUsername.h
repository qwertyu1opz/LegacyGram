#ifndef TG_LEGACY_TL_TLRPCCHANNELS_UPDATEUSERNAME_H
#define TG_LEGACY_TL_TLRPCCHANNELS_UPDATEUSERNAME_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;

@interface TLRPCchannels_updateUsername : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic, retain) NSString *username;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_updateUsername$channels_updateUsername : TLRPCchannels_updateUsername


@end

#endif
