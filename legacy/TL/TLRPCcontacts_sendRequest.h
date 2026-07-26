#ifndef TG_LEGACY_TL_TLRPCCONTACTS_SENDREQUEST_H
#define TG_LEGACY_TL_TLRPCCONTACTS_SENDREQUEST_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputUser;
@class TLcontacts_SentLink;

@interface TLRPCcontacts_sendRequest : TLMetaRpc

@property (nonatomic, retain) TLInputUser *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_sendRequest$contacts_sendRequest : TLRPCcontacts_sendRequest


@end

#endif
