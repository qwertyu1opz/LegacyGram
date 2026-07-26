#ifndef TG_LEGACY_TL_TLRPCAUTH_LOGOUT_H
#define TG_LEGACY_TL_TLRPCAUTH_LOGOUT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPCauth_logOut : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCauth_logOut$auth_logOut : TLRPCauth_logOut


@end

#endif
