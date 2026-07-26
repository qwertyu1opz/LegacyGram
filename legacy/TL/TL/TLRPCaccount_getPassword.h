#ifndef TG_LEGACY_TL_TLRPCACCOUNT_GETPASSWORD_H
#define TG_LEGACY_TL_TLRPCACCOUNT_GETPASSWORD_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLaccount_Password;

@interface TLRPCaccount_getPassword : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCaccount_getPassword$account_getPassword : TLRPCaccount_getPassword


@end

#endif
