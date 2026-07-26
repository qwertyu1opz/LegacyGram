#import "../submodules/LegacyComponents/LegacyComponents/TGModernGalleryImageItem.h"

@class TGImageInfo;
@class TGMediaOriginInfo;

@interface TGGroupAvatarGalleryItem : TGModernGalleryImageItem <TGModernGalleryItem>

@property (nonatomic, readonly) int32_t messageId;

- (instancetype)initWithMessageId:(int32_t)messageId legacyThumbnailUrl:(NSString *)legacyThumbnailUrl legacyUrl:(NSString *)legacyUrl imageId:(int64_t)imageId imageSize:(CGSize)imageSize;
- (instancetype)initWithMessageId:(int32_t)messageId legacyThumbnailUrl:(NSString *)legacyThumbnailUrl legacyUrl:(NSString *)legacyUrl imageId:(int64_t)imageId imageSize:(CGSize)imageSize originInfo:(TGMediaOriginInfo *)originInfo;
- (NSString *)filePath;

@end
