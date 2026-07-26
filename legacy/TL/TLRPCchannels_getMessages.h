#ifndef TG_LEGACY_TL_TLRPCCHANNELS_GETMESSAGES_H
#define TG_LEGACY_TL_TLRPCCHANNELS_GETMESSAGES_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;
@class TLmessages_Messages;

@interface TLRPCchannels_getMessages : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic, retain) NSArray *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_getMessages$channels_getMessages : TLRPCchannels_getMessages


@end

#endif
