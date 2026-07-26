#ifndef TG_LEGACY_TL_TLRPCACCOUNT_GETAUTHORIZATIONS_H
#define TG_LEGACY_TL_TLRPCACCOUNT_GETAUTHORIZATIONS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLaccount_Authorizations;

@interface TLRPCaccount_getAuthorizations : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCaccount_getAuthorizations$account_getAuthorizations : TLRPCaccount_getAuthorizations


@end

#endif
