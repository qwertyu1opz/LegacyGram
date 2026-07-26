#import "TGGroupAvatarGalleryItem.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGGroupAvatarGalleryItemView.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGRemoteImageView.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGMediaOriginInfo.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGStringUtils.h"

@interface TGGroupAvatarGalleryItem ()
{
    NSString *_legacyUrl;
}

@end

@implementation TGGroupAvatarGalleryItem

- (Class)viewClass
{
    return [TGGroupAvatarGalleryItemView class];
}

- (instancetype)initWithMessageId:(int32_t)messageId legacyThumbnailUrl:(NSString *)legacyThumbnailUrl legacyUrl:(NSString *)legacyUrl imageId:(int64_t)imageId imageSize:(CGSize)imageSize
{
    return [self initWithMessageId:messageId legacyThumbnailUrl:legacyThumbnailUrl legacyUrl:legacyUrl imageId:imageId imageSize:imageSize originInfo:nil];
}

- (instancetype)initWithMessageId:(int32_t)messageId legacyThumbnailUrl:(NSString *)legacyThumbnailUrl legacyUrl:(NSString *)legacyUrl imageId:(int64_t)imageId imageSize:(CGSize)imageSize originInfo:(TGMediaOriginInfo *)originInfo
{
    if (legacyUrl.length == 0)
        legacyUrl = legacyThumbnailUrl;
    if (legacyThumbnailUrl.length == 0)
        legacyThumbnailUrl = legacyUrl;
    if (legacyUrl == nil)
        legacyUrl = @"";
    if (legacyThumbnailUrl == nil)
        legacyThumbnailUrl = @"";
    
    NSMutableString *imageUri = [[NSMutableString alloc] initWithString:@"peer-avatar://?"];
    [imageUri appendFormat:@"legacy-cache-url=%@", [TGStringUtils stringByEscapingForURL:legacyUrl ?: @""]];
    [imageUri appendFormat:@"&legacy-thumbnail-cache-url=%@", [TGStringUtils stringByEscapingForURL:legacyThumbnailUrl ?: @""]];
    if (originInfo != nil)
        [imageUri appendFormat:@"&origin_info=%@", [TGStringUtils stringByEscapingForURL:[originInfo stringRepresentation]]];
    [imageUri appendFormat:@"&width=%d&height=%d", (int)imageSize.width, (int)imageSize.height];
    if (imageId != 0)
        [imageUri appendFormat:@"&imageId=%lld", imageId];
    
    self = [super initWithUri:imageUri imageSize:imageSize];
    if (self != nil)
    {
        self.imageId = imageId;
        _messageId = messageId;
        _legacyUrl = legacyUrl;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (![super isEqual:object])
        return false;
    
    if ([object isKindOfClass:[TGGroupAvatarGalleryItem class]] && _messageId == ((TGGroupAvatarGalleryItem *)object).messageId)
    {
        return true;
    }
    
    return false;
}

- (NSString *)filePath
{
    return [[TGRemoteImageView sharedCache] pathForCachedData:_legacyUrl];
}

@end
