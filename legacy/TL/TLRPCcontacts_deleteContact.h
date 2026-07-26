#ifndef TG_LEGACY_TL_TLRPCCONTACTS_DELETECONTACT_H
#define TG_LEGACY_TL_TLRPCCONTACTS_DELETECONTACT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputUser;
@class TLcontacts_Link;

@interface TLRPCcontacts_deleteContact : TLMetaRpc

@property (nonatomic, retain) TLInputUser *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_deleteContact$contacts_deleteContact : TLRPCcontacts_deleteContact


@end

#endif
