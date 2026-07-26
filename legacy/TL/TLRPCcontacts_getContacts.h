#ifndef TG_LEGACY_TL_TLRPCCONTACTS_GETCONTACTS_H
#define TG_LEGACY_TL_TLRPCCONTACTS_GETCONTACTS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLcontacts_Contacts;

@interface TLRPCcontacts_getContacts : TLMetaRpc

@property (nonatomic) int32_t n_hash;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_getContacts$contacts_getContacts : TLRPCcontacts_getContacts


@end

#endif
