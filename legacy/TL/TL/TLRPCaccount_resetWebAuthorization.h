#ifndef TG_LEGACY_TL_TLRPCACCOUNT_RESETWEBAUTHORIZATION_H
#define TG_LEGACY_TL_TLRPCACCOUNT_RESETWEBAUTHORIZATION_H

#import "TLMetaRpc.h"

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPCaccount_resetWebAuthorization : TLMetaRpc

@property (nonatomic) int64_t n_hash;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCaccount_resetWebAuthorization$account_resetWebAuthorization : TLRPCaccount_resetWebAuthorization


@end

#endif
