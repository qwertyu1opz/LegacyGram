#ifndef TG_LEGACY_TL_TLEMBEDPOSTMEDIA_H
#define TG_LEGACY_TL_TLEMBEDPOSTMEDIA_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLEmbedPostMedia : NSObject <TLObject>


@end

@interface TLEmbedPostMedia$embedPostPhoto : TLEmbedPostMedia

@property (nonatomic) int64_t photo_id;

@end

@interface TLEmbedPostMedia$embedPostVideo : TLEmbedPostMedia

@property (nonatomic) int64_t video_id;

@end

#endif
