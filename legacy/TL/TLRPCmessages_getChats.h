#ifndef TG_LEGACY_TL_TLRPCMESSAGES_GETCHATS_H
#define TG_LEGACY_TL_TLRPCMESSAGES_GETCHATS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLmessages_Chats;

@interface TLRPCmessages_getChats : TLMetaRpc

@property (nonatomic, retain) NSArray *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_getChats$messages_getChats : TLRPCmessages_getChats


@end

#endif
