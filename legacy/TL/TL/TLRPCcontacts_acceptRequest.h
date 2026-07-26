#ifndef TG_LEGACY_TL_TLRPCCONTACTS_ACCEPTREQUEST_H
#define TG_LEGACY_TL_TLRPCCONTACTS_ACCEPTREQUEST_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputUser;
@class TLcontacts_Link;

@interface TLRPCcontacts_acceptRequest : TLMetaRpc

@property (nonatomic, retain) TLInputUser *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_acceptRequest$contacts_acceptRequest : TLRPCcontacts_acceptRequest


@end

#endif
