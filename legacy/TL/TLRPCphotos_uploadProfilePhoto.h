#ifndef TG_LEGACY_TL_TLRPCPHOTOS_UPLOADPROFILEPHOTO_H
#define TG_LEGACY_TL_TLRPCPHOTOS_UPLOADPROFILEPHOTO_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputFile;
@class TLInputGeoPoint;
@class TLInputPhotoCrop;
@class TLphotos_Photo;

@interface TLRPCphotos_uploadProfilePhoto : TLMetaRpc

@property (nonatomic, retain) TLInputFile *file;
@property (nonatomic, retain) NSString *caption;
@property (nonatomic, retain) TLInputGeoPoint *geo_point;
@property (nonatomic, retain) TLInputPhotoCrop *crop;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCphotos_uploadProfilePhoto$photos_uploadProfilePhoto : TLRPCphotos_uploadProfilePhoto


@end

#endif
