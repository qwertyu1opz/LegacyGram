#ifndef TG_LEGACY_TL_TLRPCUPDATES_UNSUBSCRIBE_H
#define TG_LEGACY_TL_TLRPCUPDATES_UNSUBSCRIBE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPCupdates_unsubscribe : TLMetaRpc

@property (nonatomic, retain) NSArray *users;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCupdates_unsubscribe$updates_unsubscribe : TLRPCupdates_unsubscribe


@end

#endif
