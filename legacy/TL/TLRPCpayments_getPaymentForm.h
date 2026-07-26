#ifndef TG_LEGACY_TL_TLRPCPAYMENTS_GETPAYMENTFORM_H
#define TG_LEGACY_TL_TLRPCPAYMENTS_GETPAYMENTFORM_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLpayments_PaymentForm;

@interface TLRPCpayments_getPaymentForm : TLMetaRpc

@property (nonatomic) int32_t msg_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCpayments_getPaymentForm$payments_getPaymentForm : TLRPCpayments_getPaymentForm


@end

#endif
