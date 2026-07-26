#ifndef TG_LEGACY_TL_TLRPCAUTH_SIGNIN_H
#define TG_LEGACY_TL_TLRPCAUTH_SIGNIN_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLauth_Authorization;

@interface TLRPCauth_signIn : TLMetaRpc

@property (nonatomic, retain) NSString *phone_number;
@property (nonatomic, retain) NSString *phone_code_hash;
@property (nonatomic, retain) NSString *phone_code;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCauth_signIn$auth_signIn : TLRPCauth_signIn


@end

#endif
