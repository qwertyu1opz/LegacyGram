#ifndef TG_LEGACY_TL_TLRPCCONTACTS_DECLINEREQUEST_H
#define TG_LEGACY_TL_TLRPCCONTACTS_DECLINEREQUEST_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputUser;
@class TLcontacts_Link;

@interface TLRPCcontacts_declineRequest : TLMetaRpc

@property (nonatomic, retain) TLInputUser *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_declineRequest$contacts_declineRequest : TLRPCcontacts_declineRequest


@end

#endif
