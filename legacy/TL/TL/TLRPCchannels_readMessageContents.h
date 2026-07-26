#ifndef TG_LEGACY_TL_TLRPCCHANNELS_READMESSAGECONTENTS_H
#define TG_LEGACY_TL_TLRPCCHANNELS_READMESSAGECONTENTS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;

@interface TLRPCchannels_readMessageContents : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic, retain) NSArray *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_readMessageContents$channels_readMessageContents : TLRPCchannels_readMessageContents


@end

#endif
