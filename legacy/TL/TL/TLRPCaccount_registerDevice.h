#ifndef TG_LEGACY_TL_TLRPCACCOUNT_REGISTERDEVICE_H
#define TG_LEGACY_TL_TLRPCACCOUNT_REGISTERDEVICE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPCaccount_registerDevice : TLMetaRpc

@property (nonatomic) int32_t flags;
@property (nonatomic) int32_t token_type;
@property (nonatomic, retain) NSString *token;
@property (nonatomic) bool app_sandbox;
@property (nonatomic, retain) NSData *secret;
@property (nonatomic, retain) NSArray *other_uids;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCaccount_registerDevice$account_registerDevice : TLRPCaccount_registerDevice


@end

#endif
