#ifndef TG_LEGACY_TL_TLRPCCHANNELS_EDITBANNED_H
#define TG_LEGACY_TL_TLRPCCHANNELS_EDITBANNED_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;
@class TLInputUser;
@class TLChannelBannedRights;
@class TLUpdates;

@interface TLRPCchannels_editBanned : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic, retain) TLInputUser *user_id;
@property (nonatomic, retain) TLChannelBannedRights *banned_rights;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_editBanned$channels_editBanned : TLRPCchannels_editBanned


@end

#endif
