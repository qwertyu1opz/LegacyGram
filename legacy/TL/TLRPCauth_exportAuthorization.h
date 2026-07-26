#ifndef TG_LEGACY_TL_TLRPCAUTH_EXPORTAUTHORIZATION_H
#define TG_LEGACY_TL_TLRPCAUTH_EXPORTAUTHORIZATION_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLauth_ExportedAuthorization;

@interface TLRPCauth_exportAuthorization : TLMetaRpc

@property (nonatomic) int32_t dc_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCauth_exportAuthorization$auth_exportAuthorization : TLRPCauth_exportAuthorization


@end

#endif
