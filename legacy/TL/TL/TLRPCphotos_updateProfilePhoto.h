#ifndef TG_LEGACY_TL_TLRPCPHOTOS_UPDATEPROFILEPHOTO_H
#define TG_LEGACY_TL_TLRPCPHOTOS_UPDATEPROFILEPHOTO_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPhoto;
@class TLInputPhotoCrop;
@class TLUserProfilePhoto;

@interface TLRPCphotos_updateProfilePhoto : TLMetaRpc

@property (nonatomic, retain) TLInputPhoto *n_id;
@property (nonatomic, retain) TLInputPhotoCrop *crop;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCphotos_updateProfilePhoto$photos_updateProfilePhoto : TLRPCphotos_updateProfilePhoto


@end

#endif
