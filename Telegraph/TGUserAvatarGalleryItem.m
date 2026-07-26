#import "TGUserAvatarGalleryItem.h"

#import "TGUserAvatarGalleryItemView.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGRemoteImageView.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGStringUtils.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGMediaOriginInfo.h"

@implementation TGUserAvatarGalleryItem

- (instancetype)initWithLegacyThumbnailUrl:(NSString *)legacyThumbnailUrl legacyUrl:(NSString *)legacyUrl imageId:(int64_t)imageId imageSize:(CGSize)imageSize isCurrent:(bool)isCurrent
{
    return [self initWithLegacyThumbnailUrl:legacyThumbnailUrl legacyUrl:legacyUrl imageId:imageId imageSize:imageSize isCurrent:isCurrent originInfo:nil];
}

- (instancetype)initWithLegacyThumbnailUrl:(NSString *)legacyThumbnailUrl legacyUrl:(NSString *)legacyUrl imageId:(int64_t)imageId imageSize:(CGSize)imageSize isCurrent:(bool)isCurrent originInfo:(TGMediaOriginInfo *)originInfo
{
    if (legacyUrl.length == 0)
        legacyUrl = legacyThumbnailUrl;
    if (legacyThumbnailUrl.length == 0)
        legacyThumbnailUrl = legacyUrl;
    if (legacyUrl == nil)
        legacyUrl = @"";
    if (legacyThumbnailUrl == nil)
        legacyThumbnailUrl = @"";
    
    NSMutableString *imageUri = nil;
    if (imageId != 0)
    {
        NSString *legacyFilePath = [[TGRemoteImageView sharedCache] pathForCachedData:legacyUrl];
        imageUri = [[NSMutableString alloc] initWithString:@"media-gallery-image://?"];
        [imageUri appendFormat:@"&id=%lld", imageId];
        [imageUri appendFormat:@"&legacy-file-path=%@", [TGStringUtils stringByEscapingForURL:legacyFilePath ?: @""]];
        [imageUri appendFormat:@"&legacy-thumbnail-cache-url=%@", [TGStringUtils stringByEscapingForURL:legacyThumbnailUrl]];
        [imageUri appendFormat:@"&width=%d&height=%d&renderWidth=%d&renderHeight=%d", (int)imageSize.width, (int)imageSize.height, (int)imageSize.width, (int)imageSize.height];
        [imageUri appendString:@"&messageId=0&conversationId=0"];
        if (originInfo != nil)
            [imageUri appendFormat:@"&origin_info=%@", [TGStringUtils stringByEscapingForURL:[originInfo stringRepresentation]]];
        [imageUri appendFormat:@"&legacy-cache-url=%@", [TGStringUtils stringByEscapingForURL:legacyUrl]];
    }
    else
    {
        imageUri = [[NSMutableString alloc] initWithString:@"peer-avatar://?"];
        [imageUri appendFormat:@"legacy-cache-url=%@", [TGStringUtils stringByEscapingForURL:legacyUrl]];
        [imageUri appendFormat:@"&legacy-thumbnail-cache-url=%@", [TGStringUtils stringByEscapingForURL:legacyThumbnailUrl]];
        if (originInfo != nil)
            [imageUri appendFormat:@"&origin_info=%@", [TGStringUtils stringByEscapingForURL:[originInfo stringRepresentation]]];
        [imageUri appendFormat:@"&width=%d&height=%d", (int)imageSize.width, (int)imageSize.height];
    }
    
    self = [super initWithUri:imageUri imageSize:imageSize];
    if (self != nil)
    {
        self.imageId = imageId;
        _legacyThumbnailUrl = legacyThumbnailUrl;
        _legacyUrl = legacyUrl;
        _isCurrent = isCurrent;
    }
    return self;
}

- (Class)viewClass
{
    return [TGUserAvatarGalleryItemView class];
}

- (NSString *)filePath
{
    return [[TGRemoteImageView sharedCache] pathForCachedData:_legacyUrl];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[TGUserAvatarGalleryItem class]])
        return false;
    
    TGUserAvatarGalleryItem *item = (TGUserAvatarGalleryItem *)object;
    if (self.imageId != 0 || item.imageId != 0)
        return self.imageId == item.imageId;
    
    return (_isCurrent && item->_isCurrent) || [super isEqual:object];
}

@end
