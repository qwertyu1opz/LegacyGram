#ifndef TG_LEGACY_TL_TLGEOPLACENAME_H
#define TG_LEGACY_TL_TLGEOPLACENAME_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLGeoPlaceName : NSObject <TLObject>

@property (nonatomic, retain) NSString *country;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *district;
@property (nonatomic, retain) NSString *street;

@end

@interface TLGeoPlaceName$geoPlaceName : TLGeoPlaceName


@end

#endif
