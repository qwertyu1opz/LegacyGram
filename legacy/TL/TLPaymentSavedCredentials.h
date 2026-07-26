#ifndef TG_LEGACY_TL_TLPAYMENTSAVEDCREDENTIALS_H
#define TG_LEGACY_TL_TLPAYMENTSAVEDCREDENTIALS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLPaymentSavedCredentials : NSObject <TLObject>

@property (nonatomic, retain) NSString *n_id;
@property (nonatomic, retain) NSString *title;

@end

@interface TLPaymentSavedCredentials$paymentSavedCredentialsCard : TLPaymentSavedCredentials


@end

#endif
