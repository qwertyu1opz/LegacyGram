#ifndef TG_LEGACY_TL_TLRPCUPDATES_GETDIFFERENCE_H
#define TG_LEGACY_TL_TLRPCUPDATES_GETDIFFERENCE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLupdates_Difference;

@interface TLRPCupdates_getDifference : TLMetaRpc

@property (nonatomic) int32_t flags;
@property (nonatomic) int32_t pts;
@property (nonatomic) int32_t pts_limit;
@property (nonatomic) int32_t pts_total_limit;
@property (nonatomic) int32_t date;
@property (nonatomic) int32_t qts;
@property (nonatomic) int32_t qts_limit;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCupdates_getDifference$updates_getDifference : TLRPCupdates_getDifference

- (void)TLserialize:(NSOutputStream *)os;

@end

#endif
