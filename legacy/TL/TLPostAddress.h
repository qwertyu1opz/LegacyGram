#ifndef TG_LEGACY_TL_TLPOSTADDRESS_H
#define TG_LEGACY_TL_TLPOSTADDRESS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLPostAddress : NSObject <TLObject>

@property (nonatomic, retain) NSString *street_line1;
@property (nonatomic, retain) NSString *street_line2;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *country_iso2;
@property (nonatomic, retain) NSString *post_code;

@end

@interface TLPostAddress$postAddress : TLPostAddress


@end

#endif
