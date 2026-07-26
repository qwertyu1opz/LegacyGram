#ifndef TG_LEGACY_TL_TLRPCUPDATES_SUBSCRIBE_H
#define TG_LEGACY_TL_TLRPCUPDATES_SUBSCRIBE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPCupdates_subscribe : TLMetaRpc

@property (nonatomic, retain) NSArray *users;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCupdates_subscribe$updates_subscribe : TLRPCupdates_subscribe


@end

#endif
