#ifndef TG_LEGACY_TL_TLRPCCONTACTS_CLEARCONTACT_H
#define TG_LEGACY_TL_TLRPCCONTACTS_CLEARCONTACT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputUser;
@class TLcontacts_Link;

@interface TLRPCcontacts_clearContact : TLMetaRpc

@property (nonatomic, retain) TLInputUser *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_clearContact$contacts_clearContact : TLRPCcontacts_clearContact


@end

#endif
