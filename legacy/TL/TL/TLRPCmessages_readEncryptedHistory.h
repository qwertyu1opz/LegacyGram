#ifndef TG_LEGACY_TL_TLRPCMESSAGES_READENCRYPTEDHISTORY_H
#define TG_LEGACY_TL_TLRPCMESSAGES_READENCRYPTEDHISTORY_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputEncryptedChat;

@interface TLRPCmessages_readEncryptedHistory : TLMetaRpc

@property (nonatomic, retain) TLInputEncryptedChat *peer;
@property (nonatomic) int32_t max_date;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_readEncryptedHistory$messages_readEncryptedHistory : TLRPCmessages_readEncryptedHistory


@end

#endif
