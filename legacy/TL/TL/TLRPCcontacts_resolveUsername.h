#ifndef TG_LEGACY_TL_TLRPCCONTACTS_RESOLVEUSERNAME_H
#define TG_LEGACY_TL_TLRPCCONTACTS_RESOLVEUSERNAME_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLcontacts_ResolvedPeer;

@interface TLRPCcontacts_resolveUsername : TLMetaRpc

@property (nonatomic, retain) NSString *username;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_resolveUsername$contacts_resolveUsername : TLRPCcontacts_resolveUsername


@end

#endif
