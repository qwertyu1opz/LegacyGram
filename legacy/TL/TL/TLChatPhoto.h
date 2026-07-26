#ifndef TG_LEGACY_TL_TLCHATPHOTO_H
#define TG_LEGACY_TL_TLCHATPHOTO_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLFileLocation;

@interface TLChatPhoto : NSObject <TLObject>


@end

@interface TLChatPhoto$chatPhotoEmpty : TLChatPhoto


@end

@interface TLChatPhoto$chatPhoto : TLChatPhoto

@property (nonatomic) int64_t photo_id;
@property (nonatomic) int32_t dc_id;
@property (nonatomic, retain) TLFileLocation *photo_small;
@property (nonatomic, retain) TLFileLocation *photo_big;

@end

#endif
