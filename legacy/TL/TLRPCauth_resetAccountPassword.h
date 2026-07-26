#ifndef TG_LEGACY_TL_TLRPCAUTH_RESETACCOUNTPASSWORD_H
#define TG_LEGACY_TL_TLRPCAUTH_RESETACCOUNTPASSWORD_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLauth_Authorization;

@interface TLRPCauth_resetAccountPassword : TLMetaRpc

@property (nonatomic, retain) NSString *first_name;
@property (nonatomic, retain) NSString *last_name;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCauth_resetAccountPassword$auth_resetAccountPassword : TLRPCauth_resetAccountPassword


@end

#endif
