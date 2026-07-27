#import "TGStickerImageDataSource.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGWorkerPool.h"
#import "TGWorkerTask.h"
#import "TGMediaPreviewTask.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGMemoryImageCache.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGRemoteImageView.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGImageBlur.h"
#import "../submodules/LegacyComponents/LegacyComponents/UIImage+TG.h"

#import "TGMediaStoreContext.h"

#import "UIImage+WebP.h"

#import "TGAppDelegate.h"

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
        queue = [[ASQueue alloc] initWithName:"org.telegram.stickerImageTaskManagementQueue"];
    });
    
    return queue;
}

static NSMutableArray *TGStickerPendingLoadTasks()
{
    static NSMutableArray *tasks = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        tasks = [[NSMutableArray alloc] init];
    });
    return tasks;
}

static NSUInteger TGStickerActiveLoadTaskCount = 0;
static const NSUInteger TGStickerMaximumConcurrentLoadTaskCount = 3;

static void TGStickerScheduleLoadTask(void (^task)(void))
{
    void (^taskCopy)(void) = [task copy];
    [taskManagementQueue() dispatchOnQueue:^
    {
        if (TGStickerActiveLoadTaskCount < TGStickerMaximumConcurrentLoadTaskCount)
        {
            TGStickerActiveLoadTaskCount++;
            taskCopy();
        }
        else
        {
            [TGStickerPendingLoadTasks() addObject:taskCopy];
        }
    }];
}

static void TGStickerCompleteLoadTask()
{
    [taskManagementQueue() dispatchOnQueue:^
    {
        if (TGStickerActiveLoadTaskCount != 0)
            TGStickerActiveLoadTaskCount--;
        
        NSMutableArray *pendingTasks = TGStickerPendingLoadTasks();
        if (pendingTasks.count != 0 && TGStickerActiveLoadTaskCount < TGStickerMaximumConcurrentLoadTaskCount)
        {
            void (^nextTask)(void) = [pendingTasks[0] copy];
            [pendingTasks removeObjectAtIndex:0];
            TGStickerActiveLoadTaskCount++;
            nextTask();
        }
    }];
}

@interface TGStickerImageLoadTask : TGMediaPreviewTask
{
    bool _queueCancelled;
    bool _queueSlotStarted;
    bool _queueSlotCompleted;
}

- (bool)beginQueueSlot;
- (void)completeQueueSlot;

@end

@implementation TGStickerImageLoadTask

- (bool)beginQueueSlot
{
    bool shouldStart = false;
    @synchronized(self)
    {
        _queueSlotStarted = true;
        shouldStart = !_queueCancelled;
    }
    if (!shouldStart)
        [self completeQueueSlot];
    return shouldStart;
}

- (void)completeQueueSlot
{
    bool shouldComplete = false;
    @synchronized(self)
    {
        if (_queueSlotStarted && !_queueSlotCompleted)
        {
            _queueSlotCompleted = true;
            shouldComplete = true;
        }
    }
    if (shouldComplete)
        TGStickerCompleteLoadTask();
}

- (void)cancel
{
    bool slotStarted = false;
    @synchronized(self)
    {
        _queueCancelled = true;
        slotStarted = _queueSlotStarted;
    }
    [super cancel];
    if (slotStarted)
        [self completeQueueSlot];
}

- (void)dealloc
{
    [self completeQueueSlot];
}

@end

@implementation TGStickerImageDataSource

+ (void)load
{
    @autoreleasepool
    {
        [TGImageDataSource registerDataSource:[[self alloc] init]];
    }
}

+ (NSString *)uriPrefix
{
    return @"sticker://?";
}

- (bool)canHandleUri:(NSString *)uri
{
    return [uri hasPrefix:@"sticker://"];
}

- (bool)canHandleAttributeUri:(NSString *)uri
{
    return [uri hasPrefix:@"sticker://"];
}

- (id)loadDataAsyncWithUri:(NSString *)uri progress:(void (^)(float))progress partialCompletion:(void (^)(TGDataResource *resource))__unused partialCompletion completion:(void (^)(TGDataResource *))completion
{
    TGStickerImageLoadTask *previewTask = [[TGStickerImageLoadTask alloc] init];
    
    TGStickerScheduleLoadTask(^
    {
        if (![previewTask beginQueueSlot])
            return;
        __weak TGStickerImageLoadTask *weakPreviewTask = previewTask;
        TGWorkerTask *workerTask = [[TGWorkerTask alloc] initWithBlock:^(bool (^isCancelled)())
        {
            TGDataResource *result = [TGStickerImageDataSource _performLoad:uri isCancelled:isCancelled];
            
            if (result != nil && progress != nil)
                progress(1.0f);
            
            if (isCancelled != nil && isCancelled())
            {
                [weakPreviewTask completeQueueSlot];
                return;
            }
            
            if (completion != nil)
                completion(result != nil ? result : [TGStickerImageDataSource resultForUnavailableImage]);
            
            [weakPreviewTask completeQueueSlot];
        }];
        
        if ([TGStickerImageDataSource _isDataLocallyAvailableForUri:uri])
        {
            [previewTask executeWithWorkerTask:workerTask workerPool:workerPool()];
        }
        else
        {
            NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:[TGStickerImageDataSource uriPrefix].length]];
            
            if ((![args[@"documentId"] respondsToSelector:@selector(longLongValue)] && ![args[@"localDocumentId"] respondsToSelector:@selector(longLongValue)]) || (![args[@"fileName"] respondsToSelector:@selector(characterAtIndex:)]) || (![args[@"datacenterId"] respondsToSelector:@selector(intValue)]))
            {
                if (completion != nil)
                    completion([TGStickerImageDataSource resultForUnavailableImage]);
                [previewTask completeQueueSlot];
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
                else if (args[@"localDocumentId"] != nil)
                {
                    fileDirectoryName = [[NSString alloc] initWithFormat:@"local%" PRIx64 "", (int64_t)[args[@"localDocumentId"] longLongValue]];
                }
                    
                NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
                
                [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:true attributes:nil error:nil];
                
                NSString *filePath = [fileDirectory stringByAppendingPathComponent:args[@"fileName"]];
                
                NSString *thumbnailPath = [fileDirectory stringByAppendingPathComponent:@"thumbnail"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath])
                {
                    TGDataResource *partialResult = [TGStickerImageDataSource _performLoad:uri isCancelled:nil];
                    if (partialResult != nil)
                    {
                        if (partialCompletion)
                            partialCompletion(partialResult);
                    }
                }
                
                NSString *thumbnailHighPath = [fileDirectory stringByAppendingPathComponent:@"thumbnail-high"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailHighPath])
                {
                    TGDataResource *partialResult = [TGStickerImageDataSource _performLoad:uri isCancelled:nil];
                    if (partialResult != nil)
                    {
                        if (partialCompletion)
                            partialCompletion(partialResult);
                    }
                }
                
                NSMutableArray *attributes = [[NSMutableArray alloc] init];
                [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:args[@"fileName"]]];
                
                TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] init];
                documentAttachment.documentId = [args[@"documentId"] longLongValue];
                documentAttachment.localDocumentId = [args[@"localDocumentId"] longLongValue];
                documentAttachment.accessHash = [args[@"accessHash"] longLongValue];
                documentAttachment.datacenterId = [args[@"datacenterId"] intValue];
                documentAttachment.attributes = attributes;
                documentAttachment.size = [args[@"size"] intValue];
                documentAttachment.documentUri = args[@"documentUri"];
                documentAttachment.originInfo = [TGMediaOriginInfo mediaOriginInfoWithStringRepresentation:args[@"origin_info"]];
                
                [previewTask executeWithTargetFilePath:filePath document:documentAttachment progress:^(float value)
                {
                    if (progress)
                        progress(value);
                } completion:^(bool success)
                {
                    if (success)
                    {
                        [ActionStageInstance() dispatchOnStageQueue:^
                        {
                            [previewTask executeWithWorkerTask:workerTask workerPool:workerPool()];
                        }];
                    }
                    else
                    {
                        if (completion != nil)
                            completion([TGStickerImageDataSource resultForUnavailableImage]);
                        [weakPreviewTask completeQueueSlot];
                    }
                } workerTask:nil];
            }
        }
    });
    
    return previewTask;
}

+ (bool)_isDataLocallyAvailableForUri:(NSString *)uri
{
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:[TGStickerImageDataSource uriPrefix].length]];
    
    if ((![args[@"documentId"] respondsToSelector:@selector(longLongValue)] && ![args[@"localDocumentId"] respondsToSelector:@selector(longLongValue)]) || (![args[@"fileName"] respondsToSelector:@selector(characterAtIndex:)]))
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
    
    NSString *filePath = [fileDirectory stringByAppendingPathComponent:args[@"fileName"]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NULL])
        return true;

    if ([[NSFileManager defaultManager] fileExistsAtPath:[fileDirectory stringByAppendingPathComponent:@"cached.bin"] isDirectory:NULL])
        return true;

    if ([[NSFileManager defaultManager] fileExistsAtPath:[fileDirectory stringByAppendingPathComponent:@"thumbnail.cached.bin"] isDirectory:NULL])
        return true;

    if ([[NSFileManager defaultManager] fileExistsAtPath:[fileDirectory stringByAppendingPathComponent:@"thumbnail"] isDirectory:NULL])
        return true;

    if ([[NSFileManager defaultManager] fileExistsAtPath:[fileDirectory stringByAppendingPathComponent:@"thumbnail-high"] isDirectory:NULL])
        return true;
    
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
    
    UIImage *cachedImage = [[TGMediaStoreContext instance] mediaImage:uri attributes:nil];
    if (cachedImage != nil)
        return [[TGDataResource alloc] initWithImage:cachedImage decoded:true];
    
    if (!canWait)
        return nil;
    
    return [TGStickerImageDataSource _performLoad:uri isCancelled:nil];
}

+ (TGDataResource *)_performLoad:(NSString *)uri isCancelled:(bool (^)())isCancelled
{
    if (isCancelled && isCancelled())
    {
        TGLog(@"[TGPhotoMediaPreviewImageDataSource cancelled while loading %@]", uri);
        return nil;
    }
    
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:[TGStickerImageDataSource uriPrefix].length]];
    
    if ((![args[@"documentId"] respondsToSelector:@selector(longLongValue)] && ![args[@"localDocumentId"] respondsToSelector:@selector(longLongValue)]) || (![args[@"fileName"] respondsToSelector:@selector(characterAtIndex:)]))
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
    
    UIImage *thumbnailSourceImage = nil;
    bool lowQualityThumbnail = false;
    
    NSString *filePath = [fileDirectory stringByAppendingPathComponent:args[@"fileName"]];
    NSString *thumbnailPath = [fileDirectory stringByAppendingPathComponent:@"thumbnail"];
    NSString *thumbnailHighPath = [fileDirectory stringByAppendingPathComponent:@"thumbnail-high"];
    
    UIImage *image = nil;
    
    {
        NSString *cachedFilePath = [fileDirectory stringByAppendingPathComponent:@"cached.bin"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachedFilePath isDirectory:NULL])
        {
            image = [UIImage convertFromGZippedData:cachedFilePath size:size];
        }
        
        if (image != nil)
        {
        }
        else
        {
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NULL])
            {
                __autoreleasing NSData *compressedData = nil;
                image = [UIImage convertFromWebP:filePath compressedData:&compressedData error:nil];
                
                if (compressedData != nil)
                    [compressedData writeToFile:cachedFilePath atomically:true];
            }
        }
    }
    
    if (image == nil)
    {
        image = [[UIImage alloc] initWithContentsOfFile:filePath];
        if (image != nil)
            image = TGScaleImageToPixelSize(image, size);
    }
    
    if (image == nil)
    {
        lowQualityThumbnail = true;
        
        NSString *cachedFilePath = [fileDirectory stringByAppendingPathComponent:@"thumbnail.cached.bin"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachedFilePath isDirectory:NULL])
        {
            image = [UIImage convertFromGZippedData:cachedFilePath size:size];
        }

        if (image == nil)
        {
            image = [[UIImage alloc] initWithContentsOfFile:thumbnailPath];
            if (image != nil)
            {
                image = TGScaleImageToPixelSize(image, TGFitSize(image.size, size));
            }
            else
            {
                __autoreleasing NSData *compressedData = nil;
                image = [UIImage convertFromWebP:thumbnailPath compressedData:&compressedData error:nil];
                if (compressedData != nil)
                    [compressedData writeToFile:cachedFilePath atomically:true];

                if (image == nil)
                {
                    image = [UIImage convertFromWebP:thumbnailHighPath compressedData:&compressedData error:nil];
                    if (compressedData != nil)
                        [compressedData writeToFile:cachedFilePath atomically:true];
                }
            }
        }
        
        if (![args[@"inhibitBlur"] boolValue])
            image = TGBlurredAlphaImage(image, CGSizeMake(size.width / 2.0f, size.height / 2.0f));
    }
    
    thumbnailSourceImage = image;
    
    if (thumbnailSourceImage != nil)
    {
        UIImage *thumbnailImage = nil;
        
        thumbnailImage = thumbnailSourceImage;
        
        if (thumbnailImage != nil)
        {
            if (!lowQualityThumbnail)
                [[TGMediaStoreContext instance] setMediaImageForKey:uri image:thumbnailImage attributes:nil];
            
            return [[TGDataResource alloc] initWithImage:thumbnailImage decoded:true];
        }
    }
    
    return nil;
}

@end
