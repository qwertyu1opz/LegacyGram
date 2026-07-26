#import "TGStickerPreviewImageDataSource.h"

#ifndef IOS6_NOOP_LOG
#define IOS6_NOOP_LOG(...) do { } while (0)
#endif

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGWorkerPool.h"
#import "TGWorkerTask.h"
#import "TGMediaPreviewTask.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGRemoteImageView.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGImageBlur.h"
#import "../submodules/LegacyComponents/LegacyComponents/UIImage+TG.h"

#import "TGMediaStoreContext.h"

#import "UIImage+WebP.h"

#import "TGSharedMediaUtils.h"

#import "TGAppDelegate.h"

static ASQueue *taskManagementQueue()
{
    static ASQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        queue = [[ASQueue alloc] initWithName:"org.telegram.stickerPreviewImageTaskManagementQueue"];
    });
    
    return queue;
}

@implementation TGStickerPreviewImageDataSource

+ (void)load
{
    @autoreleasepool
    {
        [TGImageDataSource registerDataSource:[[self alloc] init]];
    }
}

+ (NSString *)uriPrefix
{
    return @"sticker-preview://?";
}

- (bool)canHandleUri:(NSString *)uri
{
    return [uri hasPrefix:@"sticker-preview://"];
}

- (bool)canHandleAttributeUri:(NSString *)uri
{
    return [uri hasPrefix:@"sticker-preview://"];
}

- (id)loadDataAsyncWithUri:(NSString *)uri progress:(void (^)(float))progress partialCompletion:(void (^)(TGDataResource *resource))__unused partialCompletion completion:(void (^)(TGDataResource *))completion
{
    TGMediaPreviewTask *previewTask = [[TGMediaPreviewTask alloc] init];
    
    [taskManagementQueue() dispatchOnQueue:^
     {
         TGWorkerTask *workerTask = [[TGWorkerTask alloc] initWithBlock:^(bool (^isCancelled)())
         {
             TGDataResource *result = [TGStickerPreviewImageDataSource _performLoad:uri isCancelled:isCancelled];
             
             if (result != nil && progress != nil)
                 progress(1.0f);
             
             if (isCancelled != nil && isCancelled())
                 return;
             
             if (completion != nil)
                 completion(result != nil ? result : [TGStickerPreviewImageDataSource resultForUnavailableImage]);
         }];
         
         if ([TGStickerPreviewImageDataSource _isDataLocallyAvailableForUri:uri])
         {
             [previewTask executeWithWorkerTask:workerTask threadPool:[TGSharedMediaUtils sharedMediaImageProcessingThreadPool]];
         }
         else
         {
             NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:[TGStickerPreviewImageDataSource uriPrefix].length]];
             
             bool hasLegacyThumbnailUri = [args[@"legacyThumbnailUri"] respondsToSelector:@selector(characterAtIndex:)];
             bool hasFullDocumentFallback = [args[@"fileName"] respondsToSelector:@selector(characterAtIndex:)];
             
             if ((![args[@"documentId"] respondsToSelector:@selector(longLongValue)] && ![args[@"localDocumentId"] respondsToSelector:@selector(longLongValue)]) || (!hasLegacyThumbnailUri && !hasFullDocumentFallback) || (![args[@"accessHash"] respondsToSelector:@selector(longLongValue)]) || (![args[@"datacenterId"] respondsToSelector:@selector(intValue)]))
             {
                 IOS6_NOOP_LOG(@"IOS6STICKER preview.missingArgs doc=%@ local=%@ hasThumb=%d hasFile=%d access=%d dc=%d", args[@"documentId"], args[@"localDocumentId"], hasLegacyThumbnailUri ? 1 : 0, hasFullDocumentFallback ? 1 : 0, [args[@"accessHash"] respondsToSelector:@selector(longLongValue)] ? 1 : 0, [args[@"datacenterId"] respondsToSelector:@selector(intValue)] ? 1 : 0);
                 if (completion != nil)
                     completion([TGStickerPreviewImageDataSource resultForUnavailableImage]);
             }
             else
             {
                 static NSString *filesDirectory = nil;
                 static dispatch_once_t onceToken;
                 dispatch_once(&onceToken, ^
                 {
                     filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
                 });
                 
                 NSString *fileDirectoryName = nil;
                 if (args[@"documentId"] != nil)
                 {
                     fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", (int64_t)[args[@"documentId"] longLongValue]];
                 }
                 NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
                 
                 [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:true attributes:nil error:nil];
                 
                 bool highQuality = [args[@"highQuality"] boolValue];
                 
                 NSString *filePath = [fileDirectory stringByAppendingPathComponent:highQuality ? @"thumbnail-high" :  @"thumbnail"];
                 
                 int64_t identifier = [args[@"documentId"] longLongValue];
                 __weak TGMediaPreviewTask *weakPreviewTask = previewTask;
                 if (hasLegacyThumbnailUri)
                 {
                     IOS6_NOOP_LOG(@"IOS6STICKER preview.fetchThumb doc=%lld uri=%@", identifier, args[@"legacyThumbnailUri"]);
                     [previewTask executeMultipartWithImageUri:args[@"legacyThumbnailUri"] identifier:identifier originInfo:[TGMediaOriginInfo mediaOriginInfoWithStringRepresentation:args[@"origin_info"]] targetFilePath:filePath progress:^(float value)
                     {
                         if (progress)
                             progress(value);
                     } completion:^(bool success)
                     {
                         IOS6_NOOP_LOG(@"IOS6STICKER preview.fetchThumb.done doc=%lld success=%d", identifier, success ? 1 : 0);
                         if (success)
                         {
                             __strong TGMediaPreviewTask *strongPreviewTask = weakPreviewTask;
                             if (strongPreviewTask != nil) {
                                 [strongPreviewTask executeWithWorkerTask:workerTask threadPool:[TGSharedMediaUtils sharedMediaImageProcessingThreadPool]];
                             }
                         }
                         else
                         {
                             if (completion != nil)
                                 completion([TGStickerPreviewImageDataSource resultForUnavailableImage]);
                         }
                     }];
                 }
                 else
                 {
                     NSString *documentFilePath = [fileDirectory stringByAppendingPathComponent:args[@"fileName"]];
                     
                     NSMutableArray *attributes = [[NSMutableArray alloc] init];
                     [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:args[@"fileName"]]];
                     
                     TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] init];
                     documentAttachment.documentId = [args[@"documentId"] longLongValue];
                     documentAttachment.localDocumentId = [args[@"localDocumentId"] longLongValue];
                     documentAttachment.accessHash = [args[@"accessHash"] longLongValue];
                     documentAttachment.datacenterId = [args[@"datacenterId"] intValue];
                     documentAttachment.attributes = attributes;
                     documentAttachment.size = [args[@"size"] intValue];
                     documentAttachment.mimeType = args[@"mimeType"];
                     documentAttachment.originInfo = [TGMediaOriginInfo mediaOriginInfoWithStringRepresentation:args[@"origin_info"]];
                     
                     IOS6_NOOP_LOG(@"IOS6STICKER preview.fetchDocument doc=%lld dc=%d size=%d mime=%@ file=%@ target=%@", documentAttachment.documentId, documentAttachment.datacenterId, documentAttachment.size, documentAttachment.mimeType, args[@"fileName"], documentFilePath);
                     [previewTask executeWithTargetFilePath:documentFilePath document:documentAttachment progress:^(float value)
                     {
                         if (progress)
                             progress(value);
                     } completion:^(bool success)
                     {
                         IOS6_NOOP_LOG(@"IOS6STICKER preview.fetchDocument.done doc=%lld success=%d", documentAttachment.documentId, success ? 1 : 0);
                         if (success)
                         {
                             __strong TGMediaPreviewTask *strongPreviewTask = weakPreviewTask;
                             if (strongPreviewTask != nil)
                                 [strongPreviewTask executeWithWorkerTask:workerTask threadPool:[TGSharedMediaUtils sharedMediaImageProcessingThreadPool]];
                         }
                         else
                         {
                             if (completion != nil)
                                 completion([TGStickerPreviewImageDataSource resultForUnavailableImage]);
                         }
                     } workerTask:nil];
                 }
             }
         }
     }];
    
    return previewTask;
}

+ (bool)_isDataLocallyAvailableForUri:(NSString *)uri
{
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:[TGStickerPreviewImageDataSource uriPrefix].length]];
    
    if ((![args[@"documentId"] respondsToSelector:@selector(longLongValue)] && ![args[@"localDocumentId"] respondsToSelector:@selector(longLongValue)]))
    {
        return false;
    }
    
    static NSString *filesDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
    });
    
    NSString *fileDirectoryName = nil;
    if ([args[@"documentId"] longLongValue] != 0)
        fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", (int64_t)[args[@"documentId"] longLongValue]];
    else
        fileDirectoryName = [[NSString alloc] initWithFormat:@"local%" PRIx64 "", (int64_t)[args[@"localDocumentId"] longLongValue]];
    NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
    
    bool highQuality = [args[@"highQuality"] boolValue];
    
    NSString *filePath = [fileDirectory stringByAppendingPathComponent:highQuality ? @"thumbnail-high" :  @"thumbnail"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NULL])
        return true;
    
    if ([args[@"fileName"] respondsToSelector:@selector(characterAtIndex:)])
    {
        NSString *documentFilePath = [fileDirectory stringByAppendingPathComponent:args[@"fileName"]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:documentFilePath isDirectory:NULL])
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

+ (TGDataResource *)resultForUnavailableImage
{
    return nil;
}

- (id)loadAttributeSyncForUri:(NSString *)__unused uri attribute:(NSString *)attribute
{
    if ([attribute isEqualToString:@"placeholder"])
    {
        return nil;
    }
    
    return nil;
}

- (TGDataResource *)loadDataSyncWithUri:(NSString *)uri canWait:(bool)canWait acceptPartialData:(bool)__unused acceptPartialData asyncTaskId:(__autoreleasing id *)__unused asyncTaskId progress:(void (^)(float))__unused progress partialCompletion:(void (^)(TGDataResource *))__unused partialCompletion completion:(void (^)(TGDataResource *))__unused completion
{
    if (uri == nil)
        return nil;
    
    UIImage *cachedImage = [[TGSharedMediaUtils inMemoryImageCache] imageForKey:uri];
    if (cachedImage != nil)
        return [[TGDataResource alloc] initWithImage:cachedImage decoded:true];
    
    if (!canWait)
        return nil;
        
    return [TGStickerPreviewImageDataSource _performLoad:uri isCancelled:nil];
}

+ (TGDataResource *)_performLoad:(NSString *)uri isCancelled:(bool (^)())isCancelled
{
    if (isCancelled && isCancelled())
        return nil;
    
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:[TGStickerPreviewImageDataSource uriPrefix].length]];
    
    if ((![args[@"documentId"] respondsToSelector:@selector(longLongValue)] && ![args[@"localDocumentId"] respondsToSelector:@selector(longLongValue)]))
    {
        return false;
    }
    
    static NSString *filesDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
    });

    NSString *fileDirectoryName = nil;
    if ([args[@"documentId"] longLongValue] != 0)
        fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", (int64_t)[args[@"documentId"] longLongValue]];
    else
        fileDirectoryName = [[NSString alloc] initWithFormat:@"local%" PRIx64 "", (int64_t)[args[@"localDocumentId"] longLongValue]];
    NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
    
    CGSize size = CGSizeMake([args[@"width"] intValue], [args[@"height"] intValue]);
    
    bool highQuality = [args[@"highQuality"] boolValue];
    
    NSString *filePath = [fileDirectory stringByAppendingPathComponent:highQuality ? @"thumbnail-high" :  @"thumbnail"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NULL] && [args[@"fileName"] respondsToSelector:@selector(characterAtIndex:)])
    {
        NSString *documentFilePath = [fileDirectory stringByAppendingPathComponent:args[@"fileName"]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:documentFilePath isDirectory:NULL])
            filePath = documentFilePath;
    }
    
    UIImage *image = nil;
    
    NSString *cachedFilePath = [filePath stringByAppendingString:@".cached.bin"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachedFilePath isDirectory:NULL])
    {
        image = [UIImage convertFromGZippedData:cachedFilePath size:size];
    }
    
    
    image = [[UIImage alloc] initWithContentsOfFile:filePath];
    if (image != nil)
    {
        image = TGScaleImageToPixelSize(image, TGFitSize(image.size, size));
    }
    else
    {
        __autoreleasing NSData *compressedData = nil;
        image = [UIImage convertFromWebP:filePath compressedData:&compressedData error:nil];
            if (compressedData != nil)
                [compressedData writeToFile:cachedFilePath atomically:true];
    }
    
    IOS6_NOOP_LOG(@"IOS6STICKER preview.decode doc=%@ file=%@ image=%d path=%@ high=%d", args[@"documentId"], args[@"fileName"], image != nil ? 1 : 0, filePath, highQuality ? 1 : 0);
    
    if (image != nil)
    {
        int contextWidth = (int)image.size.width;
        int contextHeight = (int)image.size.height;
        [[TGSharedMediaUtils inMemoryImageCache] setImageDataWithSize:image.size generator:^(uint8_t *memory, NSUInteger bytesPerRow)
        {
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little;
            
            CGContextRef context = CGBitmapContextCreate(memory, contextWidth, contextHeight, 8, bytesPerRow, colorSpace, bitmapInfo);
            
            CGContextTranslateCTM(context, contextWidth / 2.0f, contextHeight / 2.0f);
            CGContextScaleCTM(context, 1.0f, -1.0f);
            CGContextTranslateCTM(context, -contextWidth / 2.0f, -contextHeight / 2.0f);
            
            UIGraphicsPushContext(context);
            
            [image drawInRect:CGRectMake(0.0f, 0.0f, contextWidth, contextHeight) blendMode:kCGBlendModeCopy alpha:1.0f];
            
            UIGraphicsPopContext();
            CGColorSpaceRelease(colorSpace);
            CGContextRelease(context);
        } forKey:uri];
        
        //[[TGMediaStoreContext instance] setMediaImageForKey:uri image:thumbnailImage attributes:nil];
        
        return [[TGDataResource alloc] initWithImage:image decoded:true];
    }
    
    return nil;
}

@end
