#ifndef TG_LEGACY_TL_TLRPCAUTH_CHECKPHONE_H
#define TG_LEGACY_TL_TLRPCAUTH_CHECKPHONE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLauth_CheckedPhone;

@interface TLRPCauth_checkPhone : TLMetaRpc

@property (nonatomic, retain) NSString *phone_number;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCauth_checkPhone$auth_checkPhone : TLRPCauth_checkPhone


@end

#endif
