#ifndef TG_LEGACY_TL_TLRPCMESSAGES_TOGGLECHATADMINS_H
#define TG_LEGACY_TL_TLRPCMESSAGES_TOGGLECHATADMINS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLUpdates;

@interface TLRPCmessages_toggleChatAdmins : TLMetaRpc

@property (nonatomic) int32_t chat_id;
@property (nonatomic) bool enabled;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_toggleChatAdmins$messages_toggleChatAdmins : TLRPCmessages_toggleChatAdmins


@end

#endif
