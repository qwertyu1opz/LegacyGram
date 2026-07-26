#ifndef TG_LEGACY_TL_TLRPCCONTACTS_RESETTOPPEERRATING_H
#define TG_LEGACY_TL_TLRPCCONTACTS_RESETTOPPEERRATING_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLTopPeerCategory;
@class TLInputPeer;

@interface TLRPCcontacts_resetTopPeerRating : TLMetaRpc

@property (nonatomic, retain) TLTopPeerCategory *category;
@property (nonatomic, retain) TLInputPeer *peer;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_resetTopPeerRating$contacts_resetTopPeerRating : TLRPCcontacts_resetTopPeerRating


@end

#endif
