#ifndef TG_LEGACY_TL_TLRPCACCOUNT_UNREGISTERDEVICE_H
#define TG_LEGACY_TL_TLRPCACCOUNT_UNREGISTERDEVICE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPCaccount_unregisterDevice : TLMetaRpc

@property (nonatomic) int32_t token_type;
@property (nonatomic, retain) NSString *token;
@property (nonatomic, retain) NSArray *other_uids;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCaccount_unregisterDevice$account_unregisterDevice : TLRPCaccount_unregisterDevice


@end

#endif
