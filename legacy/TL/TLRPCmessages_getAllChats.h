#ifndef TG_LEGACY_TL_TLRPCMESSAGES_GETALLCHATS_H
#define TG_LEGACY_TL_TLRPCMESSAGES_GETALLCHATS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLmessages_Chats;

@interface TLRPCmessages_getAllChats : TLMetaRpc

@property (nonatomic, retain) NSArray *except_ids;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_getAllChats$messages_getAllChats : TLRPCmessages_getAllChats


@end

#endif
