#ifndef TG_LEGACY_TL_TLRPCAUTH_REQUESTPASSWORDRECOVERY_H
#define TG_LEGACY_TL_TLRPCAUTH_REQUESTPASSWORDRECOVERY_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLauth_PasswordRecovery;

@interface TLRPCauth_requestPasswordRecovery : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCauth_requestPasswordRecovery$auth_requestPasswordRecovery : TLRPCauth_requestPasswordRecovery


@end

#endif
