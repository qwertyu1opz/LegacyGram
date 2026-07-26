#ifndef TG_LEGACY_TL_TLRPCMESSAGES_GETSTICKERS_H
#define TG_LEGACY_TL_TLRPCMESSAGES_GETSTICKERS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLmessages_Stickers;

@interface TLRPCmessages_getStickers : TLMetaRpc

@property (nonatomic, retain) NSString *emoticon;
@property (nonatomic, assign) int32_t n_hash;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_getStickers$messages_getStickers : TLRPCmessages_getStickers


@end

#endif
