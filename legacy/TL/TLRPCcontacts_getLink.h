#ifndef TG_LEGACY_TL_TLRPCCONTACTS_GETLINK_H
#define TG_LEGACY_TL_TLRPCCONTACTS_GETLINK_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputUser;
@class TLcontacts_Link;

@interface TLRPCcontacts_getLink : TLMetaRpc

@property (nonatomic, retain) TLInputUser *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_getLink$contacts_getLink : TLRPCcontacts_getLink


@end

#endif
