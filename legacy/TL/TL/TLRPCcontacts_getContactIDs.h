#ifndef TG_LEGACY_TL_TLRPCCONTACTS_GETCONTACTIDS_H
#define TG_LEGACY_TL_TLRPCCONTACTS_GETCONTACTIDS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class NSArray_int;

@interface TLRPCcontacts_getContactIDs : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_getContactIDs$contacts_getContactIDs : TLRPCcontacts_getContactIDs


@end

#endif
