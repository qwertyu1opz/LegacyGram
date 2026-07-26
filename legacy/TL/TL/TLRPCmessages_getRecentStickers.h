#ifndef TG_LEGACY_TL_TLRPCMESSAGES_GETRECENTSTICKERS_H
#define TG_LEGACY_TL_TLRPCMESSAGES_GETRECENTSTICKERS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLmessages_RecentStickers;

@interface TLRPCmessages_getRecentStickers : TLMetaRpc

@property (nonatomic) int32_t flags;
@property (nonatomic) int32_t n_hash;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_getRecentStickers$messages_getRecentStickers : TLRPCmessages_getRecentStickers


@end

#endif
