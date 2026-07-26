#ifndef TG_LEGACY_TL_TLRPCCONTACTS_GETREQUESTS_H
#define TG_LEGACY_TL_TLRPCCONTACTS_GETREQUESTS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLcontacts_Requests;

@interface TLRPCcontacts_getRequests : TLMetaRpc

@property (nonatomic) int32_t offset;
@property (nonatomic) int32_t limit;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_getRequests$contacts_getRequests : TLRPCcontacts_getRequests


@end

#endif
