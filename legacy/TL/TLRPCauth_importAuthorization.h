#ifndef TG_LEGACY_TL_TLRPCAUTH_IMPORTAUTHORIZATION_H
#define TG_LEGACY_TL_TLRPCAUTH_IMPORTAUTHORIZATION_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLauth_Authorization;

@interface TLRPCauth_importAuthorization : TLMetaRpc

@property (nonatomic) int32_t n_id;
@property (nonatomic, retain) NSData *bytes;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCauth_importAuthorization$auth_importAuthorization : TLRPCauth_importAuthorization


@end

#endif
