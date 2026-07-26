#ifndef TG_LEGACY_TL_TLRPCCONTACTS_GETSUGGESTED_H
#define TG_LEGACY_TL_TLRPCCONTACTS_GETSUGGESTED_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLcontacts_Suggested;

@interface TLRPCcontacts_getSuggested : TLMetaRpc

@property (nonatomic) int32_t limit;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_getSuggested$contacts_getSuggested : TLRPCcontacts_getSuggested


@end

#endif
