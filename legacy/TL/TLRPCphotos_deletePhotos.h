#ifndef TG_LEGACY_TL_TLRPCPHOTOS_DELETEPHOTOS_H
#define TG_LEGACY_TL_TLRPCPHOTOS_DELETEPHOTOS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class NSArray_long;

@interface TLRPCphotos_deletePhotos : TLMetaRpc

@property (nonatomic, retain) NSArray *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCphotos_deletePhotos$photos_deletePhotos : TLRPCphotos_deletePhotos


@end

#endif
