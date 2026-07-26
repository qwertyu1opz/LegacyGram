#ifndef TG_LEGACY_TL_TLMESSAGES_FOUNDSTICKERSETS_H
#define TG_LEGACY_TL_TLMESSAGES_FOUNDSTICKERSETS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLmessages_FoundStickerSets : NSObject <TLObject>


@end

@interface TLmessages_FoundStickerSets$messages_foundStickerSets : TLmessages_FoundStickerSets

@property (nonatomic) int32_t n_hash;
@property (nonatomic, retain) NSArray *sets;

@end

#endif
