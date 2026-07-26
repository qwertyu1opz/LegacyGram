#ifndef TG_LEGACY_TL_TLRPCMESSAGES_GETFULLCHAT_H
#define TG_LEGACY_TL_TLRPCMESSAGES_GETFULLCHAT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLmessages_ChatFull;

@interface TLRPCmessages_getFullChat : TLMetaRpc

@property (nonatomic) int64_t chat_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_getFullChat$messages_getFullChat : TLRPCmessages_getFullChat


@end

#endif
