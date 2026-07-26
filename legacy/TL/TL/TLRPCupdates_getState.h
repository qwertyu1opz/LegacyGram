#ifndef TG_LEGACY_TL_TLRPCUPDATES_GETSTATE_H
#define TG_LEGACY_TL_TLRPCUPDATES_GETSTATE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLupdates_State;

@interface TLRPCupdates_getState : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCupdates_getState$updates_getState : TLRPCupdates_getState


@end

#endif
