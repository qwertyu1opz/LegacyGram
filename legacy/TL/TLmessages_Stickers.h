#ifndef TG_LEGACY_TL_TLMESSAGES_STICKERS_H
#define TG_LEGACY_TL_TLMESSAGES_STICKERS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLmessages_Stickers : NSObject <TLObject>


@end

@interface TLmessages_Stickers$messages_stickersNotModified : TLmessages_Stickers


@end

@interface TLmessages_Stickers$messages_stickers : TLmessages_Stickers

@property (nonatomic) int32_t n_hash;
@property (nonatomic, retain) NSArray *stickers;

@end

#endif
