#ifndef TG_LEGACY_TL_TLUPDATES_STATE_H
#define TG_LEGACY_TL_TLUPDATES_STATE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLupdates_State : NSObject <TLObject>

@property (nonatomic) int32_t pts;
@property (nonatomic) int32_t qts;
@property (nonatomic) int32_t date;
@property (nonatomic) int32_t seq;
@property (nonatomic) int32_t unread_count;

@end

@interface TLupdates_State$updates_state : TLupdates_State


@end

#endif
