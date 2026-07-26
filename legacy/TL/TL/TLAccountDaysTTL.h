#ifndef TG_LEGACY_TL_TLACCOUNTDAYSTTL_H
#define TG_LEGACY_TL_TLACCOUNTDAYSTTL_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLAccountDaysTTL : NSObject <TLObject>

@property (nonatomic) int32_t days;

@end

@interface TLAccountDaysTTL$accountDaysTTL : TLAccountDaysTTL


@end

#endif
