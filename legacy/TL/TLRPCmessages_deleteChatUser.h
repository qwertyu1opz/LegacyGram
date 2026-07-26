#ifndef TG_LEGACY_TL_TLRPCMESSAGES_DELETECHATUSER_H
#define TG_LEGACY_TL_TLRPCMESSAGES_DELETECHATUSER_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputUser;
@class TLUpdates;

@interface TLRPCmessages_deleteChatUser : TLMetaRpc

@property (nonatomic) int32_t chat_id;
@property (nonatomic, retain) TLInputUser *user_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_deleteChatUser$messages_deleteChatUser : TLRPCmessages_deleteChatUser


@end

#endif
