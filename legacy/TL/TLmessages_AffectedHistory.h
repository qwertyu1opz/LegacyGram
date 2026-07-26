#ifndef TG_LEGACY_TL_TLMESSAGES_AFFECTEDHISTORY_H
#define TG_LEGACY_TL_TLMESSAGES_AFFECTEDHISTORY_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLmessages_AffectedHistory : NSObject <TLObject>

@property (nonatomic) int32_t pts;
@property (nonatomic) int32_t pts_count;
@property (nonatomic) int32_t offset;

@end

@interface TLmessages_AffectedHistory$messages_affectedHistory : TLmessages_AffectedHistory


@end

#endif
