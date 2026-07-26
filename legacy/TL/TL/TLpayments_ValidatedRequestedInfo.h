#ifndef TG_LEGACY_TL_TLPAYMENTS_VALIDATEDREQUESTEDINFO_H
#define TG_LEGACY_TL_TLPAYMENTS_VALIDATEDREQUESTEDINFO_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLpayments_ValidatedRequestedInfo : NSObject <TLObject>

@property (nonatomic) int32_t flags;
@property (nonatomic, retain) NSString *n_id;
@property (nonatomic, retain) NSArray *shipping_options;

@end

@interface TLpayments_ValidatedRequestedInfo$payments_validatedRequestedInfoMeta : TLpayments_ValidatedRequestedInfo


@end

#endif
