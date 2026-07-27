#import "MultipartFetch.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

#import "../submodules/LegacyComponents/LegacyComponents/TGMediaOriginInfo.h"

#import "TL/TLMetaScheme.h"
#import "TGTelegramNetworking.h"
#import "MediaBoxContexts.h"
#import "TelegramMediaResources.h"

#import "TGCdnFileData.h"

#import "TGNetworkWorker.h"

#import "../submodules/MtProtoKit/MTProtoKit/MTProtoKit.h"

#import "TGDownloadMessagesSignal.h"

static bool IOS6PerfLoggingEnabled()
{
    return false;
}

static NSString *IOS6PerfDeviceName(NSString *machine)
{
    if ([machine hasPrefix:@"iPad2,1"] || [machine hasPrefix:@"iPad2,2"] || [machine hasPrefix:@"iPad2,3"] || [machine hasPrefix:@"iPad2,4"])
        return @"iPad 2";
    if ([machine hasPrefix:@"iPad2,5"] || [machine hasPrefix:@"iPad2,6"] || [machine hasPrefix:@"iPad2,7"])
        return @"iPad mini";
    if ([machine hasPrefix:@"iPad3,1"] || [machine hasPrefix:@"iPad3,2"] || [machine hasPrefix:@"iPad3,3"])
        return @"iPad 3";
    if ([machine hasPrefix:@"iPad3,4"] || [machine hasPrefix:@"iPad3,5"] || [machine hasPrefix:@"iPad3,6"])
        return @"iPad 4";
    if ([machine hasPrefix:@"iPhone4,1"])
        return @"iPhone 4S";
    if ([machine hasPrefix:@"iPhone5,1"] || [machine hasPrefix:@"iPhone5,2"])
        return @"iPhone 5";
    if ([machine hasPrefix:@"iPhone5,3"] || [machine hasPrefix:@"iPhone5,4"])
        return @"iPhone 5c";
    if ([machine hasPrefix:@"iPhone6,1"] || [machine hasPrefix:@"iPhone6,2"])
        return @"iPhone 5s";
    if ([machine hasPrefix:@"iPod5,1"])
        return @"iPod touch 5";
    return machine ?: @"?";
}

static NSString *IOS6PerfBuildTag()
{
    static NSString *tag = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?";
        NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"?";
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *machine = [[NSString alloc] initWithUTF8String:systemInfo.machine] ?: @"?";
        UIDevice *device = [UIDevice currentDevice];
        tag = [[NSString alloc] initWithFormat:@"version=%@ build=%@ os=%@ %@ device=%@ (%@)", version, build, device.systemName, device.systemVersion, IOS6PerfDeviceName(machine), machine];
    });
    return tag;
}

static NSString *IOS6PerfEscape(NSString *string)
{
    if (string == nil)
        return @"";
    NSString *escaped = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
    return escaped;
}

static void IOS6PerfReportToBot(NSString *event, NSString *key, NSString *message, NSTimeInterval interval)
{
    if (!IOS6PerfLoggingEnabled())
        return;
    
    static NSMutableDictionary *lastReports = nil;
    static NSLock *reportLock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        lastReports = [[NSMutableDictionary alloc] init];
        reportLock = [[NSLock alloc] init];
    });
    
    NSString *reportKey = [NSString stringWithFormat:@"%@:%@", event ?: @"", key ?: message ?: @""];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    [reportLock lock];
    NSNumber *last = [lastReports objectForKey:reportKey];
    if (last != nil && now - [last doubleValue] < interval)
    {
        [reportLock unlock];
        return;
    }
    [lastReports setObject:@(now) forKey:reportKey];
    [reportLock unlock];
    
    NSString *bodyString = [NSString stringWithFormat:@"secret=%@&event=%@&message=%@",
        IOS6PerfEscape(@""),
        IOS6PerfEscape(event),
        IOS6PerfEscape([NSString stringWithFormat:@"%@\n%@", IOS6PerfBuildTag(), message ?: @""])];
    NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:@""];
    if (url == nil || body == nil)
        return;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:nil];
}

static NSString *IOS6MediaDescribeInputLocation(id location)
{
    if (location == nil)
        return @"nil";
    NSString *className = NSStringFromClass([location class]);
    if ([location isKindOfClass:[TLInputFileLocation$inputPhotoFileLocation class]])
    {
        TLInputFileLocation$inputPhotoFileLocation *photo = (TLInputFileLocation$inputPhotoFileLocation *)location;
        return [[NSString alloc] initWithFormat:@"%@ id=%lld hash=%lld fileRef=%d thumb=%@", className, photo.n_id, photo.access_hash, (int)photo.file_reference.length, photo.thumb_size];
    }
    else if ([location isKindOfClass:[TLInputFileLocation$inputPeerPhotoFileLocation class]])
    {
        TLInputFileLocation$inputPeerPhotoFileLocation *peerPhoto = (TLInputFileLocation$inputPeerPhotoFileLocation *)location;
        return [[NSString alloc] initWithFormat:@"%@ peer=%lld type=%d hash=%lld photo=%lld big=%d", className, peerPhoto.peer_id, peerPhoto.peer_type, peerPhoto.access_hash, peerPhoto.photo_id, peerPhoto.big ? 1 : 0];
    }
    else if ([location isKindOfClass:[TLInputFileLocation$inputDocumentFileLocation class]])
    {
        TLInputFileLocation$inputDocumentFileLocation *document = (TLInputFileLocation$inputDocumentFileLocation *)location;
        return [[NSString alloc] initWithFormat:@"%@ id=%lld hash=%lld fileRef=%d thumb=%@", className, document.n_id, document.access_hash, (int)document.file_reference.length, document.thumb_size];
    }
    else if ([location isKindOfClass:[TLInputFileLocation$inputFileLocation class]])
    {
        TLInputFileLocation$inputFileLocation *file = (TLInputFileLocation$inputFileLocation *)location;
        return [[NSString alloc] initWithFormat:@"%@ volume=%lld local=%d secret=%lld fileRef=%d", className, file.volume_id, file.local_id, file.secret, (int)file.file_reference.length];
    }
    return className;
}

@interface MultipartFetchRequestData : NSObject
    
@property (nonatomic, strong, readonly) TGNetworkWorkerGuard *worker;
@property (nonatomic, strong, readonly) id data;

@end

@implementation MultipartFetchRequestData

- (instancetype)initWithWorker:(TGNetworkWorkerGuard *)worker data:(id)data {
    self = [super init];
    if (self != nil) {
        _worker = worker;
        _data = data;
    }
    return self;
}

@end

@interface MultipartPendingPart : NSObject

@property (nonatomic, readonly) int32_t size;
@property (nonatomic, strong, readonly) id<SDisposable> disposable;

@end

@implementation MultipartPendingPart

- (instancetype)initWithSize:(int32_t)size disposable:(id<SDisposable>)disposable {
    self = [super init];
    if (self != nil) {
        _size = size;
        _disposable = disposable;
    }
    return self;
}

@end

@interface MultipartFetchManager : NSObject {
    int32_t _parallelParts;
    int32_t _defaultPartSize;
    
    id<TelegramCloudMediaResource> _resource;
    TGNetworkMediaTypeTag _mediaTypeTag;
    
    SQueue *_queue;
    
    int32_t _committedOffset;
    NSRange _range;
    NSNumber *_completeSize;
    
    void (^_partReady)(NSData *);
    void (^_completed)();
    void (^_failed)();
    
    NSMutableDictionary *_fetchingParts;
    NSMutableDictionary *_fetchedParts;
    NSMutableSet *_retriedPartOffsets;
    
    SVariable *_requestData;
    bool _switchedToCdn;
    bool _reuploadedToCdn;
    bool _updatedFileReference;
    
    SMetaDisposable *_reuploadToCdnDisposable;
    SMetaDisposable *_partHashesDisposable;
    SMetaDisposable *_fileReferenceDisposable;
    
    NSDictionary *_cdnFilePartHashes;
    CFAbsoluteTime _fetchStartedAt;
    bool _reportedSlowCompletion;
    bool _terminated;
}

@end

@implementation MultipartFetchManager

- (instancetype)initWithResource:(id<TelegramCloudMediaResource>)resource mediaTypeTag:(TGNetworkMediaTypeTag)mediaTypeTag size:(NSNumber *)size range:(NSRange)range partReady:(void (^)(NSData *))partReady completed:(void (^)())completed failed:(void (^)())failed {
    self = [super init];
    if (self != nil) {
        _defaultPartSize = 128 * 1024;
        _queue = [[SQueue alloc] init];
        
        _resource = resource;
        _mediaTypeTag = mediaTypeTag;
        
        _fetchingParts = [[NSMutableDictionary alloc] init];
        _fetchedParts = [[NSMutableDictionary alloc] init];
        _retriedPartOffsets = [[NSMutableSet alloc] init];
        
        _completeSize = size;
        if (size != nil) {
            _range = NSMakeRange(range.location, MIN(range.location + range.length, (NSUInteger)[size intValue]));
            _parallelParts = 4;
        } else {
            _range = range;
            _parallelParts = 1;
        }
        _committedOffset = (int32_t)range.location;
        _partReady = [partReady copy];
        _completed = [completed copy];
        _failed = [failed copy];
        
        _reuploadToCdnDisposable = [[SMetaDisposable alloc] init];
        _partHashesDisposable = [[SMetaDisposable alloc] init];
        _fileReferenceDisposable = [[SMetaDisposable alloc] init];
        _fetchStartedAt = CFAbsoluteTimeGetCurrent();
        
        if (IOS6PerfLoggingEnabled())
            while (false) NSLog(@"IOS6PERF mediaFetchStart %@ resource=%@ dc=%d size=%@ range=%lu:%lu tag=%d", IOS6PerfBuildTag(), NSStringFromClass([resource class]), [resource datacenterId], size, (unsigned long)range.location, (unsigned long)range.length, (int)_mediaTypeTag);
        
        _requestData = [[SVariable alloc] init];
        [_requestData set:[[SSignal combineSignals:@[[[TGTelegramNetworking instance] downloadWorkerForDatacenterId:[resource datacenterId] type:_mediaTypeTag], [SSignal single:[resource apiInputLocation]]]] map:^id(NSArray *values) {
            return [[MultipartFetchRequestData alloc] initWithWorker:values[0] data:values[1]];
        }]];
    }
    return self;
}

- (void)start {
    [_queue dispatch:^{
        [self checkState];
    }];
}

- (void)cancel {
    [_queue dispatch:^{
        _terminated = true;
        for (MultipartPendingPart *part in _fetchingParts.allValues) {
            [part.disposable dispose];
        }
        [_fetchingParts removeAllObjects];
        [_reuploadToCdnDisposable dispose];
        [_partHashesDisposable dispose];
        [_fileReferenceDisposable dispose];
    }];
}

- (void)fail {
    if (_terminated)
        return;

    _terminated = true;
    NSArray *pendingParts = [_fetchingParts.allValues copy];
    [_fetchingParts removeAllObjects];
    for (MultipartPendingPart *part in pendingParts)
        [part.disposable dispose];
    _failed();
}

- (void)checkState {
    if (_terminated)
        return;

    for (NSNumber *nOffset in [_fetchedParts.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
        if ([nOffset intValue] == _committedOffset) {
            NSData *data = _fetchedParts[nOffset];
            _committedOffset += (int32_t)data.length;
            [_fetchedParts removeObjectForKey:nOffset];
            
            if (_cdnFilePartHashes != nil) {
                NSData *dataToWrite = data;
                int32_t basePartOffset = [nOffset intValue];
                for (int32_t localOffset = 0; localOffset < (int32_t)dataToWrite.length; localOffset += 128 * 1024) {
                    int32_t partOffset = basePartOffset + localOffset;
                    NSData *hashData = _cdnFilePartHashes[@(partOffset)];
                    if (hashData == nil) {
                        TGLog(@"File CDN part hash missing at %d", partOffset);
                        [self fail];
                        return;
                    }
                    NSData *localHash = nil;
                    if (partOffset + 128 * 1024 > (int32_t)dataToWrite.length) {
                        localHash = MTSha256([[NSData alloc] initWithBytesNoCopy:(void *)dataToWrite.bytes + localOffset length:(int32_t)dataToWrite.length - localOffset freeWhenDone:false]);
                    } else {
                        localHash = MTSha256([[NSData alloc] initWithBytesNoCopy:(void *)dataToWrite.bytes + localOffset length:128 * 1024 freeWhenDone:false]);
                    }
                    if (![localHash isEqual:hashData]) {
                        TGLog(@"File CDN part hash mismatch at %d", partOffset);
                        [self fail];
                        return;
                    }
                }
            }
            
            _partReady(data);
        }
    }
    
    if (_completeSize != nil && _committedOffset >= [_completeSize intValue]) {
        [self maybeLogSlowCompletion];
        _terminated = true;
        _completed();
    } else if ((NSUInteger)_committedOffset >= _range.location + _range.length) {
        [self maybeLogSlowCompletion];
        _terminated = true;
        _completed();
    } else {
        while ((int32_t)(_fetchingParts.count) < _parallelParts) {
            __block int32_t nextOffset = _committedOffset;
            [_fetchingParts enumerateKeysAndObjectsUsingBlock:^(NSNumber *nOffset, MultipartPendingPart *part, __unused BOOL *stop) {
                nextOffset = MAX(nextOffset, [nOffset intValue] + part.size);
            }];
            
            [_fetchedParts enumerateKeysAndObjectsUsingBlock:^(NSNumber *nOffset, NSData *data, __unused BOOL *stop) {
                nextOffset = MAX(nextOffset, [nOffset intValue] + ((int32_t)data.length));
            }];
            
            NSUInteger upperBound = _range.location + _range.length;
            if (_completeSize != nil) {
                upperBound = MIN(upperBound, (NSUInteger)[_completeSize intValue]);
            }
            
            __weak MultipartFetchManager *weakSelf = self;
            if ((NSUInteger)nextOffset < upperBound) {
                
                int32_t partSize = (int32_t)(MIN(upperBound - (NSUInteger)nextOffset, (NSUInteger)_defaultPartSize));
                
                int32_t updatedLimit = partSize;
                while (updatedLimit % 4096 != 0 || 1048576 % updatedLimit != 0) {
                    updatedLimit++;
                }
                
                SSignal *part = [[[[self fetchPart:nextOffset limit:updatedLimit] timeout:30.0 onQueue:_queue orSignal:[SSignal fail:@"media-timeout"]] deliverOn:_queue] take:1];
                
                int32_t partOffset = nextOffset;
                _fetchingParts[@(nextOffset)] = [[MultipartPendingPart alloc] initWithSize:partSize disposable:[part startWithNext:^(NSData *data) {
                    __strong MultipartFetchManager *strongSelf = weakSelf;
                    if (strongSelf != nil) {
                        NSData *clippedData = data;
                        if ((int32_t)data.length > partSize) {
                            clippedData = [data subdataWithRange:NSMakeRange(0, partSize)];
                        }
                        if (strongSelf->_completeSize != nil) {
                            assert((int32_t)data.length == partSize);
                        } else if ((int32_t)data.length < partSize) {
                            strongSelf->_completeSize = @(partOffset + (int32_t)data.length);
                        }
                        [strongSelf->_fetchingParts removeObjectForKey:@(partOffset)];
                        strongSelf->_fetchedParts[@(partOffset)] = data;
                        [strongSelf checkState];
                    }
                } error:^(__unused id error) {
                    __strong MultipartFetchManager *strongSelf = weakSelf;
                    if (strongSelf != nil)
                    {
                        [strongSelf->_fetchingParts removeObjectForKey:@(partOffset)];
                        NSNumber *offsetKey = @(partOffset);
                        if (![strongSelf->_retriedPartOffsets containsObject:offsetKey])
                        {
                            [strongSelf->_retriedPartOffsets addObject:offsetKey];
                            [strongSelf checkState];
                        }
                        else
                        {
                            [strongSelf fail];
                        }
                    }
                } completed:nil]];
            } else {
                break;
            }
        }
    }
}

- (void)maybeLogSlowCompletion
{
    if (!IOS6PerfLoggingEnabled())
        return;
    
    if (_reportedSlowCompletion)
        return;
    
    CFAbsoluteTime elapsedMs = (CFAbsoluteTimeGetCurrent() - _fetchStartedAt) * 1000.0;
    if (elapsedMs < 1000.0)
        return;
    
    _reportedSlowCompletion = true;
    while (false) NSLog(@"IOS6PERF mediaFetchCompleteSlow %@ resource=%@ dc=%d committed=%d size=%@ range=%lu:%lu ms=%.1f", IOS6PerfBuildTag(), NSStringFromClass([_resource class]), [_resource datacenterId], _committedOffset, _completeSize, (unsigned long)_range.location, (unsigned long)_range.length, elapsedMs);
    if (elapsedMs >= 5000.0)
        IOS6PerfReportToBot(@"perf_media_fetch_slow", [NSString stringWithFormat:@"%@:%d", NSStringFromClass([_resource class]), [_resource datacenterId]], [NSString stringWithFormat:@"resource=%@ dc=%d committed=%d size=%@ range=%lu:%lu ms=%.1f", NSStringFromClass([_resource class]), [_resource datacenterId], _committedOffset, _completeSize, (unsigned long)_range.location, (unsigned long)_range.length, elapsedMs], 300.0);
}
    
- (SSignal *)fetchPart:(int32_t)offset limit:(int32_t)limit {
    __weak MultipartFetchManager *weakSelf = self;
    SQueue *queue = _queue;
    return [[[_requestData signal] mapToSignal:^SSignal *(MultipartFetchRequestData *requestData) {
        CFAbsoluteTime partStart = CFAbsoluteTimeGetCurrent();
        id requestRpc = nil;
        if ([requestData.data isKindOfClass:[TLInputFileLocation class]]) {
            TLRPCupload_getFile$upload_getFile *getFile = [[TLRPCupload_getFile$upload_getFile alloc] init];
            getFile.location = requestData.data;
            getFile.offset = offset;
            getFile.limit = limit;
            requestRpc = getFile;
        } else if ([requestData.data isKindOfClass:[TGCdnFileData class]]) {
            TGCdnFileData *fileData = requestData.data;
            TLRPCupload_getCdnFile$upload_getCdnFile *getFile = [[TLRPCupload_getCdnFile$upload_getCdnFile alloc] init];
            getFile.file_token = fileData.token;
            getFile.offset = offset;
            getFile.limit = limit;
            requestRpc = getFile;
        } else {
            return [SSignal never];
        }
        
        return [[[[[TGTelegramNetworking instance] requestSignal:requestRpc worker:requestData.worker] deliverOn:queue] mapToSignal:^SSignal *(id next) {
            __strong MultipartFetchManager *strongSelf = weakSelf;
            if (strongSelf != nil) {
                if ([next isKindOfClass:[TLupload_File$upload_file class]]) {
                    TLupload_File$upload_file *part = next;
                    CFAbsoluteTime elapsedMs = (CFAbsoluteTimeGetCurrent() - partStart) * 1000.0;
                    if (IOS6PerfLoggingEnabled() && elapsedMs >= 500.0)
                        while (false) NSLog(@"IOS6PERF mediaPartSlow %@ offset=%d limit=%d bytes=%d ms=%.1f %@", IOS6PerfBuildTag(), offset, limit, (int)part.bytes.length, elapsedMs, IOS6MediaDescribeInputLocation(requestData.data));
                    if (IOS6PerfLoggingEnabled() && elapsedMs >= 2000.0)
                        IOS6PerfReportToBot(@"perf_media_part_slow", [NSString stringWithFormat:@"%@:%d:%d", NSStringFromClass([requestData.data class]), [strongSelf->_resource datacenterId], limit], [NSString stringWithFormat:@"offset=%d limit=%d bytes=%d dc=%d ms=%.1f location=%@", offset, limit, (int)part.bytes.length, [strongSelf->_resource datacenterId], elapsedMs, IOS6MediaDescribeInputLocation(requestData.data)], 300.0);
                    return [SSignal single:part.bytes];
                } else if ([next isKindOfClass:[TLupload_File$upload_fileCdnRedirect class]]) {
                    TLupload_File$upload_fileCdnRedirect *redirect = (TLupload_File$upload_fileCdnRedirect *)next;
                    if (IOS6PerfLoggingEnabled())
                        while (false) NSLog(@"IOS6PERF mediaCdnRedirect %@ offset=%d dc=%d", IOS6PerfBuildTag(), offset, redirect.dc_id);
                    [strongSelf switchToCdn:[[TGCdnFileData alloc] initWithCdnId:redirect.dc_id token:redirect.file_token encryptionKey:redirect.encryption_key encryptionIv:redirect.encryption_iv]];
                    return [SSignal never];
                } else if ([next isKindOfClass:[TLupload_CdnFile$upload_cdnFile class]]) {
                    TGCdnFileData *fileData = (TGCdnFileData *)requestData.data;
                    NSData *bytes = ((TLupload_CdnFile$upload_cdnFile *)next).bytes;
                    NSMutableData *encryptionIv = [[NSMutableData alloc] initWithData:fileData.encryptionIv];
                    int32_t ivOffset = offset / 16;
                    ivOffset = NSSwapInt(ivOffset);
                    memcpy(encryptionIv.mutableBytes + encryptionIv.length - 4, &ivOffset, 4);
                    NSData *data = MTAesCtrDecrypt(bytes, fileData.encryptionKey, encryptionIv);
                    CFAbsoluteTime elapsedMs = (CFAbsoluteTimeGetCurrent() - partStart) * 1000.0;
                    if (IOS6PerfLoggingEnabled() && elapsedMs >= 500.0)
                        while (false) NSLog(@"IOS6PERF mediaPartSlow %@ offset=%d limit=%d bytes=%d cdn=1 ms=%.1f", IOS6PerfBuildTag(), offset, limit, (int)data.length, elapsedMs);
                    if (IOS6PerfLoggingEnabled() && elapsedMs >= 2000.0)
                        IOS6PerfReportToBot(@"perf_media_part_slow", [NSString stringWithFormat:@"cdn:%d:%d", [strongSelf->_resource datacenterId], limit], [NSString stringWithFormat:@"offset=%d limit=%d bytes=%d dc=%d cdn=1 ms=%.1f", offset, limit, (int)data.length, [strongSelf->_resource datacenterId], elapsedMs], 300.0);
                    return [SSignal single:data];
                } else if ([next isKindOfClass:[TLupload_CdnFile$upload_cdnFileReuploadNeeded class]]) {
                    TLupload_CdnFile$upload_cdnFileReuploadNeeded *reupload = (TLupload_CdnFile$upload_cdnFileReuploadNeeded *)next;
                    TGCdnFileData *fileData = (TGCdnFileData *)requestData.data;
                    [strongSelf reuploadToCdn:fileData requestToken:reupload.request_token];
                    return [SSignal never];
                } else {
                    return [SSignal complete];
                }
            } else {
                return [SSignal complete];
            }
        }] catch:^SSignal *(id error) {
            int32_t errorCode = [[TGTelegramNetworking instance] extractNetworkErrorCode:error];
            NSString *errorText = [[TGTelegramNetworking instance] extractNetworkErrorType:error];
            if (IOS6PerfLoggingEnabled())
                while (false) NSLog(@"IOS6PERF mediaPartError %@ offset=%d limit=%d code=%d text=%@ location=%@", IOS6PerfBuildTag(), offset, limit, errorCode, errorText, IOS6MediaDescribeInputLocation(requestData.data));
            
            if ([errorText hasPrefix:@"FILE_REFERENCE_"] && errorCode == 400 && [requestData.data isKindOfClass:[TLInputFileLocation class]]) {
                __strong MultipartFetchManager *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    [strongSelf updateFileReferenceWithFileLocation:(TLInputFileLocation *)requestData.data originInfo:strongSelf->_resource.originInfo];
                }
                return [SSignal never];
            } else {
                return [SSignal fail:error];
            }
        }];
    }] take:1];
}

- (void)updateFileReferenceWithFileLocation:(TLInputFileLocation *)location originInfo:(TGMediaOriginInfo *)originInfo {
    if (_updatedFileReference) {
        return;
    }
    if (originInfo == nil) {
        while (false) TGLog(@"IOS6MEDIA fileRef refresh skipped: missing origin for %@", IOS6MediaDescribeInputLocation(location));
        [self fail];
        return;
    }
    
    _updatedFileReference = true;
    
    __weak MultipartFetchManager *weakSelf = self;
    [_fileReferenceDisposable setDisposable:[[[TGDownloadMessagesSignal updatedOriginInfo:originInfo identifier:_resource.identifier] deliverOn:_queue] startWithNext:^(TGMediaOriginInfo *next)
    {
        __strong MultipartFetchManager *strongSelf = weakSelf;
        if (strongSelf != nil) {
            strongSelf->_updatedFileReference = false;
            
            TLInputFileLocation *updatedLocation = nil;
            if ([location isKindOfClass:[TLInputFileLocation$inputDocumentFileLocation class]]) {
                TLInputFileLocation$inputDocumentFileLocation *documentFileLocation = (TLInputFileLocation$inputDocumentFileLocation *)location;
                NSData *documentFileReference = [next fileReferenceForDocumentId:documentFileLocation.n_id accessHash:documentFileLocation.access_hash];
                documentFileLocation.file_reference = documentFileReference.length != 0 ? documentFileReference : [next fileReference];
                updatedLocation = documentFileLocation;
            } else if ([location isKindOfClass:[TLInputFileLocation$inputPhotoFileLocation class]]) {
                TLInputFileLocation$inputPhotoFileLocation *photoFileLocation = (TLInputFileLocation$inputPhotoFileLocation *)location;
                photoFileLocation.file_reference = [next fileReference];
                updatedLocation = photoFileLocation;
            } else if ([location isKindOfClass:[TLInputFileLocation$inputFileLocation class]]) {
                TLInputFileLocation$inputFileLocation *fileLocation = (TLInputFileLocation$inputFileLocation *)location;
                fileLocation.file_reference = [next fileReferenceForVolumeId:fileLocation.volume_id localId:fileLocation.local_id];
                updatedLocation = fileLocation;
            }
            if (updatedLocation == nil || ([updatedLocation respondsToSelector:@selector(file_reference)] && ((NSData *)[updatedLocation performSelector:@selector(file_reference)]).length == 0)) {
                while (false) TGLog(@"IOS6MEDIA fileRef refresh produced empty reference for %@", IOS6MediaDescribeInputLocation(location));
                [strongSelf fail];
                return;
            }
            while (false) TGLog(@"IOS6MEDIA fileRef refreshed %@", IOS6MediaDescribeInputLocation(updatedLocation));
            
            [strongSelf->_requestData set:[[SSignal combineSignals:@[[[TGTelegramNetworking instance] downloadWorkerForDatacenterId:[strongSelf->_resource datacenterId] type:strongSelf->_mediaTypeTag isCdn:false], [SSignal single:updatedLocation]]] map:^id(NSArray *values) {
                return [[MultipartFetchRequestData alloc] initWithWorker:values[0] data:values[1]];
            }]];
            [strongSelf checkState];
        }
    } error:^(__unused id error) {
        __strong MultipartFetchManager *strongSelf = weakSelf;
        if (strongSelf != nil) {
            strongSelf->_updatedFileReference = false;
            while (false) TGLog(@"IOS6MEDIA fileRef refresh failed for %@", IOS6MediaDescribeInputLocation(location));
            [strongSelf fail];
        }
    } completed:nil]];
}

- (void)switchToCdnWithFileData:(TGCdnFileData *)fileData partHashes:(NSDictionary *)partHashes {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (partHashes != nil) {
        [dict addEntriesFromDictionary:partHashes];
    }
    int32_t maxOffset = 0;
    for (NSNumber *nOffset in dict.keyEnumerator) {
        maxOffset = MAX(maxOffset, [nOffset intValue] + 128 * 1024);
    }
    if (_completeSize != nil && maxOffset < [_completeSize intValue]) {
        if (_partHashesDisposable == nil) {
            _partHashesDisposable = [[SMetaDisposable alloc] init];
        }
        __weak MultipartFetchManager *weakSelf = self;
        
        SQueue *queue = _queue;
        [_partHashesDisposable setDisposable:[[[[TGTelegramNetworking instance] downloadWorkerForDatacenterId:[_resource datacenterId] type:TGNetworkMediaTypeTagGeneric] mapToSignal:^SSignal *(TGNetworkWorkerGuard *worker) {
            TLRPCupload_getCdnFileHashes$upload_getCdnFileHashes *getCdnFileHashes = [[TLRPCupload_getCdnFileHashes$upload_getCdnFileHashes alloc] init];
            getCdnFileHashes.file_token = fileData.token;
            getCdnFileHashes.offset = maxOffset;
            return [[TGTelegramNetworking instance] requestSignal:getCdnFileHashes worker:worker];
        }] startWithNext:^(NSArray *hashes) {
            [queue dispatch:^{
                __strong MultipartFetchManager *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    for (TLFileHash$fileHash *nHash in hashes) {
                        dict[@(nHash.offset)] = nHash.n_hash;
                    }
                    
                    int32_t maxOffset = 0;
                    for (NSNumber *nOffset in dict.keyEnumerator) {
                        maxOffset = MAX(maxOffset, [nOffset intValue] + 128 * 1024);
                    }
                    
                    if (strongSelf->_completeSize != nil && maxOffset < [strongSelf->_completeSize intValue]) {
                        [strongSelf switchToCdnWithFileData:fileData partHashes:dict];
                    } else {
                        strongSelf->_cdnFilePartHashes = dict;
                        [strongSelf switchToCdn:fileData];
                    }
                }
            }];
        } error:nil completed:nil]];
    } else {
        _cdnFilePartHashes = dict;
        [self switchToCdn:fileData];
    }
}
    
- (void)switchToCdn:(TGCdnFileData *)fileData {
    if (_switchedToCdn) {
        return;
    }
    
    _switchedToCdn = true;
    [_requestData set:[[SSignal combineSignals:@[[[TGTelegramNetworking instance] downloadWorkerForDatacenterId:fileData.cdnId type:_mediaTypeTag isCdn:true], [SSignal single:fileData]]] map:^id(NSArray *values) {
        return [[MultipartFetchRequestData alloc] initWithWorker:values[0] data:values[1]];
    }]];
}
    
- (void)reuploadToCdn:(TGCdnFileData *)fileData requestToken:(NSData *)requestToken {
    if (_reuploadedToCdn) {
        return;
    }
    
    _reuploadedToCdn = true;
    
    __weak MultipartFetchManager *weakSelf = self;
    [_reuploadToCdnDisposable setDisposable:[[[[[TGTelegramNetworking instance] downloadWorkerForDatacenterId:[_resource datacenterId] type:TGNetworkMediaTypeTagGeneric] deliverOn:_queue] mapToSignal:^SSignal *(TGNetworkWorkerGuard *worker) {
        TLRPCupload_reuploadCdnFile$upload_reuploadCdnFile *reupload = [[TLRPCupload_reuploadCdnFile$upload_reuploadCdnFile alloc] init];
        reupload.file_token = fileData.token;
        reupload.request_token = requestToken;
        return [[TGTelegramNetworking instance] requestSignal:reupload worker:worker];
    }] startWithNext:^(__unused id next) {
        __strong MultipartFetchManager *strongSelf = weakSelf;
        if (strongSelf != nil) {
            strongSelf->_reuploadedToCdn = false;
            [strongSelf->_requestData set:[[SSignal combineSignals:@[[[TGTelegramNetworking instance] downloadWorkerForDatacenterId:fileData.cdnId type:strongSelf->_mediaTypeTag isCdn:true], [SSignal single:fileData]]] map:^id(NSArray *values) {
                return [[MultipartFetchRequestData alloc] initWithWorker:values[0] data:values[1]];
            }]];
        }
    } error:^(__unused id error) {
        __strong MultipartFetchManager *strongSelf = weakSelf;
        if (strongSelf != nil) {
        }
    } completed:nil]];
}

@end

SSignal *multipartFetch(id<TelegramCloudMediaResource> resource, NSNumber *size, NSRange range, TGNetworkMediaTypeTag mediaTypeTag) {
    if ([resource datacenterId] <= 0) {
        while (false) TGLog(@"IOS6MEDIA multipart skip invalid dc resource=%@ dc=%d size=%@ range=%lu:%lu tag=%d", NSStringFromClass([resource class]), [resource datacenterId], size, (unsigned long)range.location, (unsigned long)range.length, (int)mediaTypeTag);
        return [SSignal single:[[MediaResourceDataFetchResult alloc] initWithData:[NSData data] complete:true]];
    }
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber) {
        MultipartFetchManager *manager = [[MultipartFetchManager alloc] initWithResource:resource mediaTypeTag:mediaTypeTag size:size range:range partReady:^(NSData *data) {
            [subscriber putNext:[[MediaResourceDataFetchResult alloc] initWithData:data complete:false]];
        } completed:^{
            [subscriber putNext:[[MediaResourceDataFetchResult alloc] initWithData:[NSData data] complete:true]];
            [subscriber putCompletion];
        } failed:^{
            // Do not leave MediaBox subscribed forever after a failed MTProto
            // request.  Ending the signal releases its worker and lets a later
            // visibility/click retry start from the already cached partial file.
            [subscriber putError:[NSError errorWithDomain:@"TGMediaFetch" code:-1 userInfo:nil]];
        }];
        
        [manager start];
        
        return [[SBlockDisposable alloc] initWithBlock:^{
            [manager cancel];
        }];
    }];
}
