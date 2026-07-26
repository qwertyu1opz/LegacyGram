#ifndef TG_LEGACY_TL_TLRPCPHOTOS_RESTOREPHOTOS_H
#define TG_LEGACY_TL_TLRPCPHOTOS_RESTOREPHOTOS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class NSArray_long;

@interface TLRPCphotos_restorePhotos : TLMetaRpc

@property (nonatomic, retain) NSArray *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCphotos_restorePhotos$photos_restorePhotos : TLRPCphotos_restorePhotos


@end

#endif
