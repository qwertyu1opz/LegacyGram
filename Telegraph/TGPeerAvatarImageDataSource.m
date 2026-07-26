#import "TGPeerAvatarImageDataSource.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "../submodules/LegacyComponents/LegacyComponents/ASQueue.h"
#import "../submodules/LegacyComponents/LegacyComponents/ActionStage.h"

#import "TGAppDelegate.h"
#import "TGWorkerPool.h"
#import "TGWorkerTask.h"
#import "TGMediaPreviewTask.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGMemoryImageCache.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGRemoteImageView.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGImageBlur.h"
#import "../submodules/LegacyComponents/LegacyComponents/UIImage+TG.h"

#import "TGMediaStoreContext.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGMediaOriginInfo.h"

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
        queue = [[ASQueue alloc] initWithName:"org.telegram.peerAvatarTaskManagementQueue"];
    });
    
    return queue;
}

static void TGPeerAvatarTrace(NSString *reason, NSDictionary *args)
{
    static CFAbsoluteTime lastLogTime = 0.0;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (now - lastLogTime < 30.0)
        return;
    lastLogTime = now;
    
    NSString *legacyUrl = args[@"legacy-cache-url"];
    NSString *thumbnailUrl = args[@"legacy-thumbnail-cache-url"];
    while (false) TGLog(@"IOS6AVATAR viewer reason=%@ hasFull=%d fullLen=%d hasThumb=%d thumbLen=%d imageId=%@",
          reason,
          [legacyUrl respondsToSelector:@selector(length)] && legacyUrl.length != 0 ? 1 : 0,
          [legacyUrl respondsToSelector:@selector(length)] ? (int)legacyUrl.length : 0,
          [thumbnailUrl respondsToSelector:@selector(length)] && thumbnailUrl.length != 0 ? 1 : 0,
          [thumbnailUrl respondsToSelector:@selector(length)] ? (int)thumbnailUrl.length : 0,
          args[@"imageId"] ?: @"");
}

static void TGPeerAvatarFetchLog(NSString *stage, NSString *url, TGMediaOriginInfo *originInfo, bool success)
{
    static NSMutableDictionary *lastLogs = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        lastLogs = [[NSMutableDictionary alloc] init];
    });
    
    NSString *key = [[NSString alloc] initWithFormat:@"%@:%@", stage ?: @"", url ?: @""];
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    NSNumber *last = lastLogs[key];
    if (last != nil && now - [last doubleValue] < 10.0)
        return;
    lastLogs[key] = @(now);
    
    NSString *kind = @"other";
    if ([url hasPrefix:@"peerphoto:"])
        kind = @"peerphoto";
    else if ([url hasPrefix:@"photo:"])
        kind = @"photo";
    
    while (false) TGLog(@"IOS6AVATAR fetch %@ kind=%@ origin=%d success=%d len=%d", stage, kind, originInfo != nil ? 1 : 0, success ? 1 : 0, [url respondsToSelector:@selector(length)] ? (int)url.length : 0);
}

static NSString *TGPeerAvatarTrimmedLegacyUrl(NSString *url)
{
    NSString *trimmedUrl = url;
    NSArray *components = [trimmedUrl componentsSeparatedByString:@"_"];
    if (components.count >= 5)
        trimmedUrl = [NSString stringWithFormat:@"%@_%@_%@_%@", components[0], components[1], components[2], components[3]];
    return trimmedUrl;
}

static NSString *TGPeerAvatarModernImagePath(NSString *photoDirectoryPath, CGSize size)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *imagePath = [photoDirectoryPath stringByAppendingPathComponent:@"image.jpg"];
    if ([fileManager fileExistsAtPath:imagePath isDirectory:NULL])
        return imagePath;
    
    NSString *thumbnailPath = [photoDirectoryPath stringByAppendingPathComponent:@"image-thumb.jpg"];
    if ([fileManager fileExistsAtPath:thumbnailPath isDirectory:NULL])
        return thumbnailPath;
    
    NSArray *items = [fileManager contentsOfDirectoryAtPath:photoDirectoryPath error:nil];
    NSString *bestPath = nil;
    int bestScore = INT_MAX;
    for (NSString *item in items)
    {
        if (![item hasPrefix:@"thumbnail-"] || ![item hasSuffix:@".jpg"])
            continue;
        
        NSString *path = [photoDirectoryPath stringByAppendingPathComponent:item];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
        if (image == nil || image.size.width < FLT_EPSILON || image.size.height < FLT_EPSILON)
            continue;
        
        int score = (int)ABS((int)image.size.width - (int)size.width) + (int)ABS((int)image.size.height - (int)size.height);
        if (bestPath == nil || score < bestScore)
        {
            bestPath = path;
            bestScore = score;
        }
    }
    
    return bestPath;
}

@interface TGPeerAvatarImageDataSource ()

@end

@implementation TGPeerAvatarImageDataSource

+ (NSString *)uriPrefix
{
    return @"peer-avatar";
}

+ (void)load
{
    @autoreleasepool
    {
        [TGImageDataSource registerDataSource:[[self alloc] init]];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
    }
    return self;
}

- (bool)canHandleUri:(NSString *)uri
{
    return [uri hasPrefix:[[NSString alloc] initWithFormat:@"%@://", [TGPeerAvatarImageDataSource uriPrefix]]];
}

- (bool)canHandleAttributeUri:(NSString *)uri
{
    return [uri hasPrefix:[[NSString alloc] initWithFormat:@"%@://", [TGPeerAvatarImageDataSource uriPrefix]]];
}

- (id)loadDataAsyncWithUri:(NSString *)uri progress:(void (^)(float))progress partialCompletion:(void (^)(TGDataResource *resource))__unused partialCompletion completion:(void (^)(TGDataResource *))completion
{
    TGMediaPreviewTask *previewTask = [[TGMediaPreviewTask alloc] init];
    
    [taskManagementQueue() dispatchOnQueue:^
    {
        TGWorkerTask *workerTask = [[TGWorkerTask alloc] initWithBlock:^(bool (^isCancelled)())
        {
            TGDataResource *result = [TGPeerAvatarImageDataSource _performLoad:uri isCancelled:isCancelled];
            
            if (result != nil && progress != nil)
                progress(1.0f);
            
            if (isCancelled != nil && isCancelled())
                return;
            
            if (completion != nil)
                completion(result != nil ? result : [TGPeerAvatarImageDataSource resultForUnavailableImage]);
        }];
        
        bool isThumbnail = false;
        bool completed = false;
        if ([TGPeerAvatarImageDataSource _isDataLocallyAvailableForUri:uri outIsThumbnail:&isThumbnail])
        {
            TGDataResource *result = [TGPeerAvatarImageDataSource _performLoad:uri isCancelled:nil];
            if (isThumbnail)
            {
                if (partialCompletion)
                    partialCompletion(result);
            }
            else
            {
                if (completion)
                    completion(result);
            }
            
            completed = !isThumbnail;
        }
        
        if (!completed)
        {
            NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:[[NSString alloc] initWithFormat:@"%@://?", [TGPeerAvatarImageDataSource uriPrefix]].length]];
            NSString *legacyUrl = args[@"legacy-cache-url"];
            NSString *thumbnailUrl = args[@"legacy-thumbnail-cache-url"];
            TGMediaOriginInfo *originInfo = [TGMediaOriginInfo mediaOriginInfoWithStringRepresentation:args[@"origin_info"]];
            
            void (^completeWithUnavailable)(void) = ^
            {
                TGDataResource *thumbnailResult = [TGPeerAvatarImageDataSource _performLoad:uri isCancelled:nil];
                if (completion != nil)
                    completion(thumbnailResult != nil ? thumbnailResult : [TGPeerAvatarImageDataSource resultForUnavailableImage]);
            };
            
            void (^completeFromSettledCacheOrFallback)(NSString *, void (^)(void)) = ^(NSString *stage, void (^fallback)(void))
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), [TGCache diskCacheQueue], ^
                {
                    TGDataResource *settledResult = [TGPeerAvatarImageDataSource _performLoad:uri isCancelled:nil];
                    if (settledResult != nil)
                    {
                        TGPeerAvatarTrace(stage, args);
                        [previewTask executeWithWorkerTask:workerTask workerPool:workerPool()];
                    }
                    else if (fallback != nil)
                    {
                        fallback();
                    }
                });
            };
            
            void (^fetchThumbnail)(void) = ^
            {
                if ([thumbnailUrl respondsToSelector:@selector(characterAtIndex:)] && thumbnailUrl.length != 0)
                {
                    NSDictionary *thumbnailOptions = originInfo == nil ? nil : @{@"originInfo": originInfo};
                    TGPeerAvatarFetchLog(@"thumb_start", thumbnailUrl, originInfo, false);
                    [previewTask executeWithTargetFilePath:nil uri:thumbnailUrl options:thumbnailOptions progress:nil completion:^(bool thumbnailSuccess)
                    {
                        TGPeerAvatarFetchLog(@"thumb_done", thumbnailUrl, originInfo, thumbnailSuccess);
                        TGDataResource *thumbnailResult = [TGPeerAvatarImageDataSource _performLoad:uri isCancelled:nil];
                        if (thumbnailResult != nil)
                        {
                            dispatch_async([TGCache diskCacheQueue], ^
                            {
                                [previewTask executeWithWorkerTask:workerTask workerPool:workerPool()];
                            });
                        }
                        else
                        {
                            completeFromSettledCacheOrFallback(@"thumb_late_cache", ^
                            {
                                TGPeerAvatarTrace(@"fetch_failed", args);
                                completeWithUnavailable();
                            });
                        }
                    } workerTask:workerTask];
                }
                else
                {
                    TGPeerAvatarTrace(@"missing_thumb", args);
                    completeWithUnavailable();
                }
            };
            
            if ([legacyUrl respondsToSelector:@selector(characterAtIndex:)] && legacyUrl.length != 0)
            {
                if (progress)
                    progress(0.0);
                NSDictionary *fullOptions = originInfo == nil ? nil : @{@"originInfo": originInfo};
                TGPeerAvatarFetchLog(@"full_start", legacyUrl, originInfo, false);
                [previewTask executeWithTargetFilePath:nil uri:legacyUrl options:fullOptions progress:^(float value)
                {
                    if (progress)
                        progress(value);
                } completion:^(bool success)
                {
                    TGPeerAvatarFetchLog(@"full_done", legacyUrl, originInfo, success);
                    TGDataResource *fullResult = [TGPeerAvatarImageDataSource _performLoad:uri isCancelled:nil];
                    if (fullResult != nil)
                    {
                        dispatch_async([TGCache diskCacheQueue], ^
                        {
                            [previewTask executeWithWorkerTask:workerTask workerPool:workerPool()];
                        });
                    }
                    else
                    {
                        completeFromSettledCacheOrFallback(@"full_late_cache", ^
                        {
                            fetchThumbnail();
                        });
                    }
                } workerTask:workerTask];
            }
            else
            {
                fetchThumbnail();
            }
        }
    }];
    
    return previewTask;
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

+ (TGDataResource *)resultForUnavailableImage
{
    static TGDataResource *imageData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        imageData = [[TGDataResource alloc] initWithImage:TGAverageColorImage([UIColor blackColor]) decoded:true];
    });
    
    return imageData;
}

- (id)loadAttributeSyncForUri:(NSString *)uri attribute:(NSString *)attribute
{
    if ([attribute isEqualToString:@"placeholder"])
    {
        NSNumber *averageColor = [[TGMediaStoreContext instance] mediaImageAverageColor:uri];
        if (averageColor != nil)
        {
            UIImage *image = TGAverageColorImage(UIColorRGB([averageColor intValue]));
            return image;
        }
        
        static UIImage *placeholder = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            placeholder = TGAverageColorImage([UIColor blackColor]);
        });
        
        return placeholder;
    }
    
    return nil;
}

- (TGDataResource *)loadDataSyncWithUri:(NSString *)uri canWait:(bool)canWait acceptPartialData:(bool)__unused acceptPartialData asyncTaskId:(__autoreleasing id *)__unused asyncTaskId progress:(void (^)(float))__unused progress partialCompletion:(void (^)(TGDataResource *))__unused partialCompletion completion:(void (^)(TGDataResource *))__unused completion
{
    if (uri == nil)
        return nil;
    
    if (!canWait)
        return nil;
    
    bool isThumbnail = false;
    if ([TGPeerAvatarImageDataSource _isDataLocallyAvailableForUri:uri outIsThumbnail:&isThumbnail])
    {
        TGDataResource *partialData = [TGPeerAvatarImageDataSource _performLoad:uri isCancelled:nil];
        
        if (isThumbnail && acceptPartialData && asyncTaskId != NULL)
        {
            *asyncTaskId = [self loadDataAsyncWithUri:uri progress:progress partialCompletion:partialCompletion completion:completion];
        }
        
        return partialData;
    }
    
    return [TGPeerAvatarImageDataSource _performLoad:uri isCancelled:nil];
}

+ (bool)_isDataLocallyAvailableForUri:(NSString *)uri outIsThumbnail:(bool *)outIsThumbnail
{
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:[[NSString alloc] initWithFormat:@"%@://?", [TGPeerAvatarImageDataSource uriPrefix]].length]];
    
    if (![args[@"width"] respondsToSelector:@selector(intValue)] || ![args[@"height"] respondsToSelector:@selector(intValue)])
    {
        return false;
    }
    
    if ([args[@"legacy-cache-url"] respondsToSelector:@selector(characterAtIndex:)])
    {
        NSString *trimmedUrl = TGPeerAvatarTrimmedLegacyUrl(args[@"legacy-cache-url"]);
        NSString *legacyCacheFilePath = [[TGRemoteImageView sharedCache] pathForCachedData:trimmedUrl];
        if ([[NSFileManager defaultManager] fileExistsAtPath:legacyCacheFilePath isDirectory:NULL])
            return true;
    }
    
    if ([args[@"legacy-thumbnail-cache-url"] respondsToSelector:@selector(characterAtIndex:)])
    {
        NSString *trimmedUrl = TGPeerAvatarTrimmedLegacyUrl(args[@"legacy-thumbnail-cache-url"]);
        NSString *legacyThumbnailFilePath = [[TGRemoteImageView sharedCache] pathForCachedData:trimmedUrl];
        if ([[NSFileManager defaultManager] fileExistsAtPath:legacyThumbnailFilePath isDirectory:NULL])
        {
            if (outIsThumbnail)
                *outIsThumbnail = true;
            return true;
        }
    }
    
    if ([args[@"imageId"] respondsToSelector:@selector(longLongValue)])
    {
        int64_t imageId = [args[@"imageId"] longLongValue];
        CGSize size = CGSizeMake([args[@"width"] intValue], [args[@"height"] intValue]);
        NSString *photoDirectoryPath = [self pathForModernPhotoDirectory:imageId];
        NSString *modernPath = TGPeerAvatarModernImagePath(photoDirectoryPath, size);
        if (modernPath != nil)
        {
            if (outIsThumbnail)
                *outIsThumbnail = [[modernPath lastPathComponent] hasPrefix:@"thumbnail-"] || [[modernPath lastPathComponent] isEqualToString:@"image-thumb.jpg"];
            return true;
        }
    }
    
    return false;
}

+ (NSString *)pathForModernPhotoDirectory:(int64_t)imageId
{
    static NSString *filesDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
    });
    
    NSString *photoDirectoryName = [[NSString alloc] initWithFormat:@"image-remote-%" PRIx64 "", imageId];
    return [filesDirectory stringByAppendingPathComponent:photoDirectoryName];
}

+ (TGDataResource *)_performLoad:(NSString *)uri isCancelled:(bool (^)())isCancelled
{
    if (isCancelled && isCancelled())
        return nil;
    
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:[[NSString alloc] initWithFormat:@"%@://?", [TGPeerAvatarImageDataSource uriPrefix]].length]];
    
    if (![args[@"width"] respondsToSelector:@selector(intValue)] || ![args[@"height"] respondsToSelector:@selector(intValue)])
    {
        TGPeerAvatarTrace(@"bad_size", args);
        return nil;
    }
    
    CGSize size = CGSizeMake([args[@"width"] intValue], [args[@"height"] intValue]);
    if (size.width < FLT_EPSILON || size.height < FLT_EPSILON)
    {
        TGPeerAvatarTrace(@"zero_size", args);
        return nil;
    }
    
    UIImage *image = nil;
    bool lowQualityThumbnail = false;
    bool decoded = false;
    
    if ([args[@"legacy-cache-url"] respondsToSelector:@selector(characterAtIndex:)])
    {
        NSString *trimmedUrl = TGPeerAvatarTrimmedLegacyUrl(args[@"legacy-cache-url"]);
        image = [[TGRemoteImageView sharedCache] cachedImage:trimmedUrl availability:TGCacheDisk];
        if (image != nil && (image.size.width < FLT_EPSILON || image.size.height < FLT_EPSILON))
            image = nil;
    }
    if (image == nil && [args[@"legacy-thumbnail-cache-url"] respondsToSelector:@selector(characterAtIndex:)])
    {
        NSString *trimmedUrl = TGPeerAvatarTrimmedLegacyUrl(args[@"legacy-thumbnail-cache-url"]);
        image = [[TGRemoteImageView sharedCache] cachedImage:trimmedUrl availability:TGCacheDisk];
        if (image != nil && (image.size.width < FLT_EPSILON || image.size.height < FLT_EPSILON))
            image = nil;
        lowQualityThumbnail = true;
    }
    
    if (image == nil && [args[@"imageId"] respondsToSelector:@selector(longLongValue)])
    {
        int64_t imageId = [args[@"imageId"] longLongValue];
        NSString *photoDirectoryPath = [self pathForModernPhotoDirectory:imageId];
        NSString *modernPath = TGPeerAvatarModernImagePath(photoDirectoryPath, size);
        
        image = modernPath == nil ? nil : [[UIImage alloc] initWithContentsOfFile:modernPath];
        if (image != nil && (image.size.width < FLT_EPSILON || image.size.height < FLT_EPSILON))
            image = nil;
        lowQualityThumbnail = modernPath != nil && ([[modernPath lastPathComponent] hasPrefix:@"thumbnail-"] || [[modernPath lastPathComponent] isEqualToString:@"image-thumb.jpg"]);
    }
    
    if (image != nil)
    {
        NSNumber *averageColor = [[TGMediaStoreContext instance] mediaImageAverageColor:uri];
        bool needsAverageColor = averageColor == nil;
        uint32_t averageColorValue = [averageColor intValue];
        
        if (lowQualityThumbnail)
        {
            UIImage *blurredImage = TGBlurredFileImage(image, size, needsAverageColor ? &averageColorValue : NULL, 0);
            if (blurredImage != nil)
            {
                image = blurredImage;
                decoded = true;
            }
        }
        
        if (image != nil)
        {
            if (needsAverageColor)
                [[TGMediaStoreContext instance] setMediaImageAverageColorForKey:uri averageColor:@(averageColorValue)];
            
            return [[TGDataResource alloc] initWithImage:image decoded:decoded];
        }
    }
    
    TGPeerAvatarTrace(@"cache_miss", args);
    return nil;
}

@end
