#ifndef TG_LEGACY_TL_TLRPCMESSAGES_MIGRATECHAT_H
#define TG_LEGACY_TL_TLRPCMESSAGES_MIGRATECHAT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLUpdates;

@interface TLRPCmessages_migrateChat : TLMetaRpc

@property (nonatomic) int32_t chat_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_migrateChat$messages_migrateChat : TLRPCmessages_migrateChat


@end

#endif
