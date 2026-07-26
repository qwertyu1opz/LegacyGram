#ifndef TG_LEGACY_TL_TLHTTPWAIT_H
#define TG_LEGACY_TL_TLHTTPWAIT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLHttpWait : NSObject <TLObject>

@property (nonatomic) int32_t max_delay;
@property (nonatomic) int32_t wait_after;
@property (nonatomic) int32_t max_wait;

@end

@interface TLHttpWait$http_wait : TLHttpWait


@end

#endif
