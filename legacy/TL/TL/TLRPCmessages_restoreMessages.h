#ifndef TG_LEGACY_TL_TLRPCMESSAGES_RESTOREMESSAGES_H
#define TG_LEGACY_TL_TLRPCMESSAGES_RESTOREMESSAGES_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class NSArray_int;

@interface TLRPCmessages_restoreMessages : TLMetaRpc

@property (nonatomic, retain) NSArray *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_restoreMessages$messages_restoreMessages : TLRPCmessages_restoreMessages


@end

#endif
