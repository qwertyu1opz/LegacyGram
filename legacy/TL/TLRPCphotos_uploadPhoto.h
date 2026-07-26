#ifndef TG_LEGACY_TL_TLRPCPHOTOS_UPLOADPHOTO_H
#define TG_LEGACY_TL_TLRPCPHOTOS_UPLOADPHOTO_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputFile;
@class TLInputGeoPoint;
@class TLphotos_Photo;

@interface TLRPCphotos_uploadPhoto : TLMetaRpc

@property (nonatomic, retain) TLInputFile *file;
@property (nonatomic, retain) NSString *caption;
@property (nonatomic, retain) TLInputGeoPoint *geo_point;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCphotos_uploadPhoto$photos_uploadPhoto : TLRPCphotos_uploadPhoto


@end

#endif
