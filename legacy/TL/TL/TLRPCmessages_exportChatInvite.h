#ifndef TG_LEGACY_TL_TLRPCMESSAGES_EXPORTCHATINVITE_H
#define TG_LEGACY_TL_TLRPCMESSAGES_EXPORTCHATINVITE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLExportedChatInvite;

@interface TLRPCmessages_exportChatInvite : TLMetaRpc

@property (nonatomic) int32_t chat_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_exportChatInvite$messages_exportChatInvite : TLRPCmessages_exportChatInvite


@end

#endif
