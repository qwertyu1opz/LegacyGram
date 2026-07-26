#ifndef TG_LEGACY_TL_TLRPCPAYMENTS_CLEARSAVEDINFO_H
#define TG_LEGACY_TL_TLRPCPAYMENTS_CLEARSAVEDINFO_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPCpayments_clearSavedInfo : TLMetaRpc

@property (nonatomic) int32_t flags;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCpayments_clearSavedInfo$payments_clearSavedInfo : TLRPCpayments_clearSavedInfo


@end

#endif
