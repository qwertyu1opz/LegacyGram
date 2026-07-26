#ifndef TG_LEGACY_TL_TLMESSAGEGROUP_H
#define TG_LEGACY_TL_TLMESSAGEGROUP_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLMessageGroup : NSObject <TLObject>

@property (nonatomic) int32_t min_id;
@property (nonatomic) int32_t max_id;
@property (nonatomic) int32_t count;
@property (nonatomic) int32_t date;

@end

@interface TLMessageGroup$messageGroup : TLMessageGroup


@end

#endif
