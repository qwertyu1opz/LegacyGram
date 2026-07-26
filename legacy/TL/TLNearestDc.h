#ifndef TG_LEGACY_TL_TLNEARESTDC_H
#define TG_LEGACY_TL_TLNEARESTDC_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLNearestDc : NSObject <TLObject>

@property (nonatomic, retain) NSString *country;
@property (nonatomic) int32_t this_dc;
@property (nonatomic) int32_t nearest_dc;

@end

@interface TLNearestDc$nearestDc : TLNearestDc


@end

#endif
