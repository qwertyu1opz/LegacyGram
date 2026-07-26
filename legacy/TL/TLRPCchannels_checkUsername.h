#ifndef TG_LEGACY_TL_TLRPCCHANNELS_CHECKUSERNAME_H
#define TG_LEGACY_TL_TLRPCCHANNELS_CHECKUSERNAME_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;

@interface TLRPCchannels_checkUsername : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic, retain) NSString *username;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_checkUsername$channels_checkUsername : TLRPCchannels_checkUsername


@end

#endif
