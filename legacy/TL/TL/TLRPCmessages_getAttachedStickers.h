#ifndef TG_LEGACY_TL_TLRPCMESSAGES_GETATTACHEDSTICKERS_H
#define TG_LEGACY_TL_TLRPCMESSAGES_GETATTACHEDSTICKERS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputStickeredMedia;
@class NSArray_StickerSetCovered;

@interface TLRPCmessages_getAttachedStickers : TLMetaRpc

@property (nonatomic, retain) TLInputStickeredMedia *media;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_getAttachedStickers$messages_getAttachedStickers : TLRPCmessages_getAttachedStickers


@end

#endif
