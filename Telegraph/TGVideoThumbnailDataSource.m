#import "TGVideoThumbnailDataSource.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGWorkerPool.h"
#import "TGWorkerTask.h"
#import "TGMediaPreviewTask.h"

#import "TGPhotoThumbnailDataSource.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGMemoryImageCache.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGRemoteImageView.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGImageBlur.h"
#import "../submodules/LegacyComponents/LegacyComponents/UIImage+TG.h"

#import "TGMediaStoreContext.h"

#import <AVFoundation/AVFoundation.h>

#import "TGAppDelegate.h"

#include <string.h>

static TGWorkerPool *workerPool()
{
    static TGWorkerPool *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        instance = [[TGWorkerPool alloc] init];
    });
    
    return instance;
}

static ASQueue *taskManagementQueue()
{
    static ASQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        queue = [[ASQueue alloc] initWithName:"org.telegram.videoThumbnailTaskManagementQueue"];
    });
    
    return queue;
}

static bool TGIOS6ImageLooksBlack(UIImage *image)
{
    CGImageRef imageRef = image.CGImage;
    if (imageRef == NULL)
        return false;
    
    NSUInteger width = 8;
    NSUInteger height = 8;
    unsigned char pixels[8 * 8 * 4];
    memset(pixels, 0, sizeof(pixels));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    if (context == NULL)
        return false;
    
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), imageRef);
    CGContextRelease(context);
    
    NSUInteger darkCount = 0;
    NSUInteger alphaCount = 0;
    for (NSUInteger i = 0; i < width * height; i++)
    {
        unsigned char r = pixels[i * 4];
        unsigned char g = pixels[i * 4 + 1];
        unsigned char b = pixels[i * 4 + 2];
        unsigned char a = pixels[i * 4 + 3];
        if (a > 16)
        {
            alphaCount++;
            if (r < 14 && g < 14 && b < 14)
                darkCount++;
        }
    }
    
    return alphaCount != 0 && darkCount * 100 / alphaCount > 92;
}

static UIImage *TGIOS6VideoFrameImage(AVAsset *asset, CGSize maximumSize)
{
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.maximumSize = maximumSize;
    imageGenerator.appliesPreferredTrackTransform = true;
    
    Float64 duration = CMTimeGetSeconds(asset.duration);
    Float64 candidates[] = {0.0, 0.15, 0.5, 1.0};
    UIImage *fallbackImage = nil;
    
    for (NSUInteger i = 0; i < sizeof(candidates) / sizeof(candidates[0]); i++)
    {
        Float64 seconds = candidates[i];
        if (duration > 0.01)
            seconds = MIN(seconds, MAX(0.0, duration - 0.01));
        
        NSError *imageError = nil;
        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:CMTimeMakeWithSeconds(seconds, MAX(1, asset.duration.timescale)) actualTime:NULL error:&imageError];
        UIImage *image = imageRef == NULL ? nil : [[UIImage alloc] initWithCGImage:imageRef];
        if (imageRef != NULL)
            CGImageRelease(imageRef);
        
        if (image == nil)
            continue;
        
        if (fallbackImage == nil)
            fallbackImage = image;
        
        if (!TGIOS6ImageLooksBlack(image))
            return image;
    }
    
    return fallbackImage;
}

@implementation TGVideoThumbnailDataSource

+ (void)load
{
    @autoreleasepool
    {
        [TGImageDataSource registerDataSource:[[self alloc] init]];
    }
}

- (bool)canHandleUri:(NSString *)uri
{
    return [uri hasPrefix:@"video-thumbnail://"];
}

- (bool)canHandleAttributeUri:(NSString *)uri
{
    return [uri hasPrefix:@"video-thumbnail://"];
}

- (id)loadDataAsyncWithUri:(NSString *)uri progress:(void (^)(float))progress partialCompletion:(void (^)(TGDataResource *resource))__unused partialCompletion completion:(void (^)(TGDataResource *))completion
{
    TGMediaPreviewTask *previewTask = [[TGMediaPreviewTask alloc] init];
    
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:@"video-thumbnail://?".length]];
    bool isFlat = [args[@"flat"] boolValue];
    int cornerRadius = [args[@"cornerRadius"] intValue];
    int position = [args[@"position"] intValue];
    
    [taskManagementQueue() dispatchOnQueue:^
    {
        TGWorkerTask *workerTask = [[TGWorkerTask alloc] initWithBlock:^(bool (^isCancelled)())
        {
            TGDataResource *result = [TGVideoThumbnailDataSource _performLoad:uri isCancelled:isCancelled];
            
            if (result != nil && progress != nil)
                progress(1.0f);
            
            if (isCancelled != nil && isCancelled())
                return;
            
            if (completion != nil)
                completion(result != nil ? result : [TGVideoThumbnailDataSource resultForUnavailableImage:isFlat cornerRadius:cornerRadius position:position]);
        }];
        
        if ([TGVideoThumbnailDataSource _isDataLocallyAvailableForUri:uri])
        {
            [previewTask executeWithWorkerTask:workerTask workerPool:workerPool()];
        }
        else
        {
            NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:@"video-thumbnail://?".length]];
            
            if ([args[@"legacy-thumbnail-cache-url"] respondsToSelector:@selector(characterAtIndex:)])
            {
                static NSString *filesDirectory = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^
                {
                    filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
                });
                
                NSString *videoDirectoryName = nil;
                if (args[@"id"] != nil)
                {
                    videoDirectoryName = [[NSString alloc] initWithFormat:@"video-remote-%" PRIx64 "", (int64_t)[args[@"id"] longLongValue]];
                }
                else
                {
                    videoDirectoryName = [[NSString alloc] initWithFormat:@"video-local-%" PRIx64 "", (int64_t)[args[@"local-id"] longLongValue]];                    
                }
                NSString *videoDirectory = [filesDirectory stringByAppendingPathComponent:videoDirectoryName];
                
                [[NSFileManager defaultManager] createDirectoryAtPath:videoDirectory withIntermediateDirectories:true attributes:nil error:nil];
                
                NSString *temporaryThumbnailImagePath = [videoDirectory stringByAppendingPathComponent:@"video-thumb.jpg"];
                
                NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
                TGMediaOriginInfo *originInfo = nil;
                if (args[@"origin_info"] != nil)
                {
                    originInfo = [TGMediaOriginInfo mediaOriginInfoWithStringRepresentation:args[@"origin_info"]];
                }
                else if (args[@"cid"] != nil)
                {
                    int64_t cid = [args[@"cid"] longLongValue];
                    int32_t mid = [args[@"mid"] intValue];
                    originInfo = [TGMediaOriginInfo mediaOriginInfoWithFileReference:nil fileReferences:nil cid:cid mid:mid];
                }
                
                if (originInfo != nil)
                    options[@"originInfo"] = originInfo;
                
                [previewTask executeWithTargetFilePath:temporaryThumbnailImagePath uri:args[@"legacy-thumbnail-cache-url"] options:options completion:^(bool success)
                {
                    if (success)
                    {
                        dispatch_async([TGCache diskCacheQueue], ^
                        {
                            [previewTask executeWithWorkerTask:workerTask workerPool:workerPool()];
                        });
                    }
                    else
                    {
                        if (completion != nil)
                            completion([TGVideoThumbnailDataSource resultForUnavailableImage:isFlat cornerRadius:cornerRadius position:position]);
                    }
                } workerTask:workerTask];
            }
            else
            {
                if (completion != nil)
                    completion([TGVideoThumbnailDataSource resultForUnavailableImage:isFlat cornerRadius:cornerRadius position:position]);
            }
        }
    }];
    
    return previewTask;
}

+ (bool)_isDataLocallyAvailableForUri:(NSString *)uri
{
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:@"video-thumbnail://?".length]];
    
    if ((![args[@"id"] respondsToSelector:@selector(longLongValue)] && ![args[@"local-id"] respondsToSelector:@selector(longLongValue)]) || ![args[@"width"] respondsToSelector:@selector(intValue)] || ![args[@"height"] respondsToSelector:@selector(intValue)] || ![args[@"renderWidth"] respondsToSelector:@selector(intValue)] || ![args[@"renderHeight"] respondsToSelector:@selector(intValue)])
    {
        return false;
    }
    
    static NSString *filesDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
    });
    
    NSString *videoDirectoryName = nil;
    if (args[@"id"] != nil)
    {
        videoDirectoryName = [[NSString alloc] initWithFormat:@"video-remote-%" PRIx64 "", (int64_t)[args[@"id"] longLongValue]];
    }
    else
    {
        videoDirectoryName = [[NSString alloc] initWithFormat:@"video-local-%" PRIx64 "", (int64_t)[args[@"local-id"] longLongValue]];
    }
    NSString *videoDirectory = [filesDirectory stringByAppendingPathComponent:videoDirectoryName];
    
    CGSize size = CGSizeMake([args[@"width"] intValue], [args[@"height"] intValue]);
    CGSize renderSize = CGSizeMake([args[@"renderWidth"] intValue], [args[@"renderHeight"] intValue]);
    
    NSString *thumbnailPath = [videoDirectory stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"thumbnail-%dx%d-%dx%d.jpg", (int)size.width, (int)size.height, (int)renderSize.width, (int)renderSize.height]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath isDirectory:NULL])
        return true;
    
    NSString *temporaryThumbnailImagePath = [videoDirectory stringByAppendingPathComponent:@"video-thumb.jpg"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryThumbnailImagePath])
        return true;
    
    NSString *videoPath = [videoDirectory stringByAppendingPathComponent:@"video.mov"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath isDirectory:NULL])
        return true;
    
    if ([args[@"legacy-video-file-path"] respondsToSelector:@selector(characterAtIndex:)])
    {
        NSString *legacyVideoFilePath = args[@"legacy-video-file-path"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:legacyVideoFilePath isDirectory:NULL])
            return true;
    }
    
    if ([args[@"legacy-thumbnail-cache-url"] respondsToSelector:@selector(characterAtIndex:)])
    {
        NSString *legacyThumbnailImagePath = nil;
        NSString *legacyThumbnailUrl = args[@"legacy-thumbnail-cache-url"];
        
        if ([legacyThumbnailUrl hasPrefix:@"file://"])
            legacyThumbnailImagePath = [legacyThumbnailUrl substringFromIndex:@"file://".length];
        else
            legacyThumbnailImagePath = [[TGRemoteImageView sharedCache] pathForCachedData:args[@"legacy-thumbnail-cache-url"]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:legacyThumbnailImagePath isDirectory:NULL])
            return true;
    }
    
    return false;
}

- (void)cancelTaskById:(id)taskId
{
    [taskManagementQueue() dispatchOnQueue:^
    {
        if ([taskId isKindOfClass:[TGMediaPreviewTask class]])
        {
            TGMediaPreviewTask *previewTask = taskId;
            [previewTask cancel];
        }
    }];
}

+ (TGDataResource *)resultForUnavailableImage:(bool)isFlat cornerRadius:(int)cornerRadius position:(int)position
{
    return [TGPhotoThumbnailDataSource resultForUnavailableImage:isFlat cornerRadius:cornerRadius position:position];
}

- (id)loadAttributeSyncForUri:(NSString *)uri attribute:(NSString *)attribute
{
    if ([attribute isEqualToString:@"placeholder"])
    {
        NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:@"video-thumbnail://?".length]];
        bool isFlat = [args[@"flat"] boolValue];
        int cornerRadius = [args[@"cornerRadius"] intValue];
        int position = [args[@"position"] intValue];
        
        UIImage *reducedImage = [[TGMediaStoreContext instance] mediaReducedImage:uri attributes:NULL];
        
        if (reducedImage != nil)
            return reducedImage;
        
        NSNumber *averageColor = [[TGMediaStoreContext instance] mediaImageAverageColor:uri];
        if (averageColor != nil)
        {
            UIImage *image = nil;
            if (isFlat && cornerRadius > 0)
                image = TGAverageColorAttachmentWithCornerRadiusImage(UIColorRGB([averageColor intValue]), !isFlat, cornerRadius, position);
            else
                image = TGAverageColorAttachmentImage(UIColorRGB([averageColor intValue]), !isFlat, position);
            return image;
        }
        
        static UIImage *normalPlaceholder = nil;
        static NSMutableDictionary *flatPlaceholders = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            normalPlaceholder = TGAverageColorAttachmentImage([UIColor whiteColor], true, 0);
            flatPlaceholders = [[NSMutableDictionary alloc] init];
        });
        
        if (position == 0)
        {
            if (isFlat)
            {
                UIImage *flatPlaceholder = flatPlaceholders[@(cornerRadius)];
                if (flatPlaceholder == nil)
                {
                    if (cornerRadius == 0)
                        flatPlaceholder = TGAverageColorAttachmentImage([UIColor whiteColor], false, 0);
                    else
                        flatPlaceholder = TGAverageColorAttachmentWithCornerRadiusImage([UIColor whiteColor], false, cornerRadius, 0);
                    
                    flatPlaceholders[@(cornerRadius)] = flatPlaceholder;
                }
                return flatPlaceholder;
            }
            else
            {
                return normalPlaceholder;
            }
        }
        else
        {
            if (isFlat)
            {
                if (cornerRadius == 0)
                    return TGAverageColorAttachmentImage([UIColor whiteColor], false, position);
                else
                    return TGAverageColorAttachmentWithCornerRadiusImage([UIColor whiteColor], false, cornerRadius, position);
            }
            else
            {
                return TGAverageColorAttachmentImage([UIColor whiteColor], true, position);
            }
        }
    }
    
    return nil;
}

- (TGDataResource *)loadDataSyncWithUri:(NSString *)uri canWait:(bool)canWait acceptPartialData:(bool)__unused acceptPartialData asyncTaskId:(__autoreleasing id *)__unused asyncTaskId progress:(void (^)(float))__unused progress partialCompletion:(void (^)(TGDataResource *))__unused partialCompletion completion:(void (^)(TGDataResource *))__unused completion
{
    if (uri == nil)
        return nil;
    
    UIImage *cachedImage = [[TGMediaStoreContext instance] mediaImage:uri attributes:nil];
    if (cachedImage != nil)
    {
        if (!TGIOS6ImageLooksBlack(cachedImage))
            return [[TGDataResource alloc] initWithImage:cachedImage decoded:true];
        else if (!canWait)
            return nil;
    }
    
    if (!canWait)
        return nil;
    
    return [TGVideoThumbnailDataSource _performLoad:uri isCancelled:nil];
}

+ (TGDataResource *)_performLoad:(NSString *)uri isCancelled:(bool (^)())isCancelled
{
    if (isCancelled && isCancelled())
    {
        TGLog(@"[TGPhotoMediaPreviewImageDataSource cancelled while loading %@]", uri);
        return nil;
    }
    
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:@"video-thumbnail://?".length]];
    
    if ((![args[@"id"] respondsToSelector:@selector(longLongValue)] && ![args[@"local-id"] respondsToSelector:@selector(longLongValue)]) || ![args[@"width"] respondsToSelector:@selector(intValue)] || ![args[@"height"] respondsToSelector:@selector(intValue)] || ![args[@"renderWidth"] respondsToSelector:@selector(intValue)] || ![args[@"renderHeight"] respondsToSelector:@selector(intValue)])
    {
        return nil;
    }
    
    static NSString *filesDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
    });
    
    NSString *videoDirectoryName = nil;
    bool isLocal = false;
    if (args[@"id"] != nil)
    {
        videoDirectoryName = [[NSString alloc] initWithFormat:@"video-remote-%" PRIx64 "", (int64_t)[args[@"id"] longLongValue]];
    }
    else
    {
        videoDirectoryName = [[NSString alloc] initWithFormat:@"video-local-%" PRIx64 "", (int64_t)[args[@"local-id"] longLongValue]];
        isLocal = true;
    }
    NSString *videoDirectory = [filesDirectory stringByAppendingPathComponent:videoDirectoryName];
    
    CGSize size = CGSizeMake([args[@"width"] intValue], [args[@"height"] intValue]);
    CGSize renderSize = CGSizeMake([args[@"renderWidth"] intValue], [args[@"renderHeight"] intValue]);
    
    NSString *thumbnailPath = [videoDirectory stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"thumbnail-%dx%d-%dx%d.jpg", (int)size.width, (int)size.height, (int)renderSize.width, (int)renderSize.height]];
    
    UIImage *thumbnailSourceImage = [[UIImage alloc] initWithContentsOfFile:thumbnailPath];
    if (thumbnailSourceImage != nil && TGIOS6ImageLooksBlack(thumbnailSourceImage))
    {
        thumbnailSourceImage = nil;
        [[NSFileManager defaultManager] removeItemAtPath:thumbnailPath error:nil];
    }
    bool lowQualityThumbnail = false;
    
    if (thumbnailSourceImage == nil)
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:videoDirectory withIntermediateDirectories:true attributes:nil error:nil];
        
        NSString *videoPath = [videoDirectory stringByAppendingPathComponent:@"video.mov"];
        NSString *temporaryThumbnailImagePath = [videoDirectory stringByAppendingPathComponent:@"video-thumb.jpg"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:videoPath isDirectory:NULL])
        {
            if ([args[@"legacy-video-file-path"] respondsToSelector:@selector(characterAtIndex:)])
            {
                NSString *legacyVideoFilePath = args[@"legacy-video-file-path"];
                videoPath = legacyVideoFilePath;
            }
        }
        
        UIImage *image = nil;
        
        if (![args[@"secret"] boolValue] && [[NSFileManager defaultManager] fileExistsAtPath:videoPath isDirectory:NULL])
        {
            AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
            
            image = TGIOS6VideoFrameImage(asset, CGSizeMake(800, 800));
        }
        else
        {
            image = [[UIImage alloc] initWithContentsOfFile:temporaryThumbnailImagePath];
            if (image == nil)
            {
                if ([args[@"legacy-thumbnail-cache-url"] respondsToSelector:@selector(characterAtIndex:)])
                {
                    NSString *legacyThumbnailImagePath = nil;
                    NSString *legacyThumbnailUrl = args[@"legacy-thumbnail-cache-url"];
                    
                    if ([legacyThumbnailUrl hasPrefix:@"file://"])
                        legacyThumbnailImagePath = [legacyThumbnailUrl substringFromIndex:@"file://".length];
                    else
                        legacyThumbnailImagePath = [[TGRemoteImageView sharedCache] pathForCachedData:args[@"legacy-thumbnail-cache-url"]];
                    
                    image = [[UIImage alloc] initWithContentsOfFile:legacyThumbnailImagePath];
                    
                    if (image != nil)
                    {
                        [[NSFileManager defaultManager] copyItemAtPath:legacyThumbnailImagePath toPath:temporaryThumbnailImagePath error:nil];
                    }
                }
            }
            
            if (!isLocal || image.size.width < 70)
                lowQualityThumbnail = true;
        }
        
        if (image != nil)
        {
            const float cacheFactor = 0.95f;
            CGSize cachedImageSize = CGSizeMake(CGCeil(size.width * cacheFactor), CGCeil(size.height * cacheFactor));
            CGSize cachedRenderSize = CGSizeMake(CGCeil(renderSize.width * cacheFactor), CGCeil(renderSize.height * cacheFactor));
            UIGraphicsBeginImageContextWithOptions(cachedImageSize, true, 0.0f);
            
            CGRect imageRect = CGRectMake((cachedImageSize.width - cachedRenderSize.width) / 2.0f, (cachedImageSize.height - cachedRenderSize.height) / 2.0f, cachedRenderSize.width, cachedRenderSize.height);
            [image drawInRect:imageRect blendMode:kCGBlendModeCopy alpha:1.0f];
            
            thumbnailSourceImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            if (thumbnailSourceImage != nil && !lowQualityThumbnail)
            {
                NSData *thumbnailSourceData = UIImageJPEGRepresentation(thumbnailSourceImage, 0.85f);
                [thumbnailSourceData writeToFile:thumbnailPath atomically:true];
            }
        }
    }
    else
    {
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0f);
        
        CGRect imageRect = CGRectMake(0.0f, 0.0f, size.width, size.height);
        [thumbnailSourceImage drawInRect:imageRect blendMode:kCGBlendModeCopy alpha:1.0f];
        
        thumbnailSourceImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    bool isFlat = [args[@"flat"] boolValue];
    int cornerRadius = [args[@"cornerRadius"] intValue];
    int inset = [args[@"inset"] intValue];
    int position = [args[@"position"] intValue];
    
    if (thumbnailSourceImage != nil)
    {
        UIImage *thumbnailImage = nil;
        
        NSNumber *averageColor = [[TGMediaStoreContext instance] mediaImageAverageColor:uri];
        bool needsAverageColor = averageColor == nil;
        uint32_t averageColorValue = [averageColor intValue];
        uint32_t *averageColorPtr = needsAverageColor ? &averageColorValue : NULL;
        
        if ([args[@"secret"] boolValue])
        {
            if (isFlat && cornerRadius > 0)
                thumbnailImage = TGSecretBlurredAttachmentWithCornerRadiusImage(thumbnailSourceImage, size, needsAverageColor ? &averageColorValue : NULL, ![args[@"flat"] boolValue], cornerRadius, position);
            else
                thumbnailImage = TGSecretBlurredAttachmentImage(thumbnailSourceImage, size, needsAverageColor ? &averageColorValue : NULL, ![args[@"flat"] boolValue], position);
        }
        else
        {
            if (lowQualityThumbnail)
            {
                if (isFlat && cornerRadius > 0)
                    thumbnailImage = TGBlurredAttachmentWithCornerRadiusImage(thumbnailSourceImage, size, averageColorPtr, !isFlat, cornerRadius, position);
                else
                    thumbnailImage = TGBlurredAttachmentImage(thumbnailSourceImage, size, averageColorPtr, !isFlat, position);
            }
            else
            {
                if (isFlat && cornerRadius > 0)
                    thumbnailImage = TGLoadedAttachmentWithCornerRadiusImage(thumbnailSourceImage, size, averageColorPtr, !isFlat, cornerRadius, inset, position);
                else
                    thumbnailImage = TGLoadedAttachmentImage(thumbnailSourceImage, size, averageColorPtr, !isFlat, position);
            }
        }
        
        if (thumbnailImage != nil)
        {
            [[TGMediaStoreContext instance] setMediaImageAverageColorForKey:uri averageColor:@(averageColorValue)];
            if (!lowQualityThumbnail)
                [[TGMediaStoreContext instance] setMediaImageForKey:uri image:thumbnailImage attributes:nil];
            
            NSDictionary *imageAttachments = [thumbnailImage attachmentsDictionary];
            
            [[TGMediaStoreContext instance] inMediaReducedImageCacheGenerationQueue:^
            {
                __autoreleasing NSDictionary *attributes = nil;
                UIImage *existingReducedImage = [[TGMediaStoreContext instance] mediaReducedImage:uri attributes:&attributes];
                bool alreadyCached = existingReducedImage != nil && !TGIOS6ImageLooksBlack(existingReducedImage);
                bool cachedLowQualityThumbnail = [attributes isKindOfClass:[NSDictionary class]] && [[attributes objectForKey:@"lowQuality"] boolValue];
                
                if (!alreadyCached || (cachedLowQualityThumbnail && !lowQualityThumbnail))
                {
                    UIImage *cachedImage = nil;
                    if (isFlat && cornerRadius > 0)
                        cachedImage = TGReducedAttachmentWithCornerRadiusImage(thumbnailImage, size, !isFlat, cornerRadius, position);
                    else
                        cachedImage = TGReducedAttachmentImage(thumbnailImage, size, !isFlat, position);
                    [cachedImage setAttachmentsFromDictionary:imageAttachments];
                    
                    if (cachedImage != nil)
                    {
                        [[TGMediaStoreContext instance] setMediaReducedImageForKey:uri reducedImage:cachedImage attributes:@{@"lowQuality": @(lowQualityThumbnail)}];
                    }
                }
            }];
            
            return [[TGDataResource alloc] initWithImage:thumbnailImage decoded:true];
        }
    }
    
    return nil;
}

@end
