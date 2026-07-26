#ifndef TG_LEGACY_TL_TLRPCPAYMENTS_GETSAVEDINFO_H
#define TG_LEGACY_TL_TLRPCPAYMENTS_GETSAVEDINFO_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLpayments_SavedInfo;

@interface TLRPCpayments_getSavedInfo : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCpayments_getSavedInfo$payments_getSavedInfo : TLRPCpayments_getSavedInfo


@end

#endif
