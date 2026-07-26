#ifndef TG_LEGACY_TL_TLRPCACCOUNT_UPDATESTATUS_H
#define TG_LEGACY_TL_TLRPCACCOUNT_UPDATESTATUS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPCaccount_updateStatus : TLMetaRpc

@property (nonatomic) bool offline;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCaccount_updateStatus$account_updateStatus : TLRPCaccount_updateStatus


@end

#endif
