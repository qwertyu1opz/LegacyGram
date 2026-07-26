#ifndef TG_LEGACY_TL_TLRPCMESSAGES_UNINSTALLSTICKERSET_H
#define TG_LEGACY_TL_TLRPCMESSAGES_UNINSTALLSTICKERSET_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputStickerSet;

@interface TLRPCmessages_uninstallStickerSet : TLMetaRpc

@property (nonatomic, retain) TLInputStickerSet *stickerset;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_uninstallStickerSet$messages_uninstallStickerSet : TLRPCmessages_uninstallStickerSet


@end

#endif
