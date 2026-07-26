#ifndef TG_LEGACY_TL_TLMESSAGERANGE_H
#define TG_LEGACY_TL_TLMESSAGERANGE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLMessageRange : NSObject <TLObject>

@property (nonatomic) int32_t min_id;
@property (nonatomic) int32_t max_id;

@end

@interface TLMessageRange$messageRange : TLMessageRange


@end

#endif
