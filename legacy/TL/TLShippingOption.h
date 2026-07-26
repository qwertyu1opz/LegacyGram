#ifndef TG_LEGACY_TL_TLSHIPPINGOPTION_H
#define TG_LEGACY_TL_TLSHIPPINGOPTION_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLShippingOption : NSObject <TLObject>

@property (nonatomic, retain) NSString *n_id;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSArray *prices;

@end

@interface TLShippingOption$shippingOption : TLShippingOption


@end

#endif
