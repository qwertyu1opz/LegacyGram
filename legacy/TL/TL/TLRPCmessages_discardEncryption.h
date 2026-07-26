#ifndef TG_LEGACY_TL_TLRPCMESSAGES_DISCARDENCRYPTION_H
#define TG_LEGACY_TL_TLRPCMESSAGES_DISCARDENCRYPTION_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPCmessages_discardEncryption : TLMetaRpc

@property (nonatomic) int32_t chat_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_discardEncryption$messages_discardEncryption : TLRPCmessages_discardEncryption


@end

#endif
