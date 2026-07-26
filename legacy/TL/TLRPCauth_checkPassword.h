#ifndef TG_LEGACY_TL_TLRPCAUTH_CHECKPASSWORD_H
#define TG_LEGACY_TL_TLRPCAUTH_CHECKPASSWORD_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLauth_Authorization;
@class TLInputCheckPasswordSRP;

@interface TLRPCauth_checkPassword : TLMetaRpc

@property (nonatomic, retain) TLInputCheckPasswordSRP *password;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCauth_checkPassword$auth_checkPassword : TLRPCauth_checkPassword


@end

#endif
