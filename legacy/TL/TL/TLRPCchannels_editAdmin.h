#ifndef TG_LEGACY_TL_TLRPCCHANNELS_EDITADMIN_H
#define TG_LEGACY_TL_TLRPCCHANNELS_EDITADMIN_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;
@class TLInputUser;
@class TLChannelAdminRights;
@class TLUpdates;

@interface TLRPCchannels_editAdmin : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic, retain) TLInputUser *user_id;
@property (nonatomic, retain) TLChannelAdminRights *admin_rights;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_editAdmin$channels_editAdmin : TLRPCchannels_editAdmin


@end

#endif
