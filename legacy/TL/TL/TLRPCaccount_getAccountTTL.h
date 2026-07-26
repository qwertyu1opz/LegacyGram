#ifndef TG_LEGACY_TL_TLRPCACCOUNT_GETACCOUNTTTL_H
#define TG_LEGACY_TL_TLRPCACCOUNT_GETACCOUNTTTL_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLAccountDaysTTL;

@interface TLRPCaccount_getAccountTTL : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCaccount_getAccountTTL$account_getAccountTTL : TLRPCaccount_getAccountTTL


@end

#endif
