#ifndef TG_LEGACY_TL_TLRPCCHANNELS_DELETEUSERHISTORY_H
#define TG_LEGACY_TL_TLRPCCHANNELS_DELETEUSERHISTORY_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;
@class TLInputUser;
@class TLmessages_AffectedHistory;

@interface TLRPCchannels_deleteUserHistory : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic, retain) TLInputUser *user_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_deleteUserHistory$channels_deleteUserHistory : TLRPCchannels_deleteUserHistory


@end

#endif
