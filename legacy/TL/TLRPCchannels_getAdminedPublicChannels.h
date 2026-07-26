#ifndef TG_LEGACY_TL_TLRPCCHANNELS_GETADMINEDPUBLICCHANNELS_H
#define TG_LEGACY_TL_TLRPCCHANNELS_GETADMINEDPUBLICCHANNELS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLmessages_Chats;

@interface TLRPCchannels_getAdminedPublicChannels : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_getAdminedPublicChannels$channels_getAdminedPublicChannels : TLRPCchannels_getAdminedPublicChannels


@end

#endif
