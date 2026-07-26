#ifndef TG_LEGACY_TL_TLRPCMESSAGES_GETRECENTLOCATIONS_H
#define TG_LEGACY_TL_TLRPCMESSAGES_GETRECENTLOCATIONS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPeer;
@class TLmessages_Messages;

@interface TLRPCmessages_getRecentLocations : TLMetaRpc

@property (nonatomic, retain) TLInputPeer *peer;
@property (nonatomic) int32_t limit;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_getRecentLocations$messages_getRecentLocations : TLRPCmessages_getRecentLocations


@end

#endif
