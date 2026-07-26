#ifndef TG_LEGACY_TL_TLRPCGET_FUTURE_SALTS_H
#define TG_LEGACY_TL_TLRPCGET_FUTURE_SALTS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLFutureSalts;

@interface TLRPCget_future_salts : TLMetaRpc

@property (nonatomic) int32_t num;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCget_future_salts$get_future_salts : TLRPCget_future_salts


@end

#endif
