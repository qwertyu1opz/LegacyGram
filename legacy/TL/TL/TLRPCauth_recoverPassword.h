#ifndef TG_LEGACY_TL_TLRPCAUTH_RECOVERPASSWORD_H
#define TG_LEGACY_TL_TLRPCAUTH_RECOVERPASSWORD_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLauth_Authorization;

@interface TLRPCauth_recoverPassword : TLMetaRpc

@property (nonatomic, retain) NSString *code;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCauth_recoverPassword$auth_recoverPassword : TLRPCauth_recoverPassword


@end

#endif
