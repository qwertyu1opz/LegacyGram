#import <Foundation/Foundation.h>

#import "MediaResource.h"
#import "TelegramCloudMediaResource.h"

@interface CloudFileMediaResource: NSObject <TelegramCloudMediaResource>

@property (nonatomic, readonly) int32_t datacenterId;
@property (nonatomic, readonly) int64_t volumeId;
@property (nonatomic, readonly) int32_t localId;
@property (nonatomic, readonly) int64_t secret;
@property (nonatomic, strong, readonly) NSNumber *size;

@property (nonatomic, strong, readonly) NSString *legacyCacheUrl;
@property (nonatomic, strong, readonly) NSString *legacyCachePath;

@property (nonatomic, strong, readonly) id mediaType;

@property (nonatomic, strong, readonly) TGMediaOriginInfo *originInfo;
@property (nonatomic, readonly) int64_t identifier;

- (instancetype)initWithDatacenterId:(int32_t)datacenterId volumeId:(int64_t)volumeId localId:(int32_t)localId secret:(int64_t)secret size:(NSNumber *)size legacyCacheUrl:(NSString *)legacyCacheUrl legacyCachePath:(NSString *)legacyCachePath mediaType:(id)mediaType originInfo:(TGMediaOriginInfo *)originInfo identifier:(int64_t)identifier;

@end

@interface CloudSecureMediaResource: NSObject <TelegramCloudMediaResource>

@property (nonatomic, readonly) int32_t datacenterId;
@property (nonatomic, readonly) int64_t fileId;
@property (nonatomic, readonly) int64_t accessHash;
@property (nonatomic, strong, readonly) NSNumber *size;
@property (nonatomic, strong, readonly) NSData *fileHash;
@property (nonatomic, readonly) bool thumbnail;

@property (nonatomic, strong, readonly) id mediaType;

- (instancetype)initWithDatacenterId:(int32_t)datacenterId fileId:(int64_t)fileId accessHash:(int64_t)accessHash size:(NSNumber *)size fileHash:(NSData *)fileHash thumbnail:(bool)thumbnail mediaType:(id)mediaType;

@end

@interface CloudDocumentMediaResource: NSObject <TelegramCloudMediaResource>

@property (nonatomic, readonly) int32_t datacenterId;
@property (nonatomic, readonly) int64_t fileId;
@property (nonatomic, readonly) int64_t accessHash;
@property (nonatomic, strong, readonly) NSData *fileReference;
@property (nonatomic, strong, readonly) NSString *thumbSize;
@property (nonatomic, strong, readonly) NSNumber *size;

@property (nonatomic, strong, readonly) id mediaType;

@property (nonatomic, strong, readonly) TGMediaOriginInfo *originInfo;
@property (nonatomic, readonly) int64_t identifier;

- (instancetype)initWithDatacenterId:(int32_t)datacenterId fileId:(int64_t)fileId accessHash:(int64_t)accessHash fileReference:(NSData *)fileReference thumbSize:(NSString *)thumbSize size:(NSNumber *)size mediaType:(id)mediaType originInfo:(TGMediaOriginInfo *)originInfo identifier:(int64_t)identifier;

@end

@interface CloudPhotoMediaResource: NSObject <TelegramCloudMediaResource>

@property (nonatomic, readonly) int32_t datacenterId;
@property (nonatomic, readonly) int64_t fileId;
@property (nonatomic, readonly) int64_t accessHash;
@property (nonatomic, strong, readonly) NSData *fileReference;
@property (nonatomic, strong, readonly) NSString *thumbSize;
@property (nonatomic, strong, readonly) NSNumber *size;
@property (nonatomic, strong, readonly) id mediaType;
@property (nonatomic, strong, readonly) TGMediaOriginInfo *originInfo;
@property (nonatomic, readonly) int64_t identifier;

- (instancetype)initWithDatacenterId:(int32_t)datacenterId fileId:(int64_t)fileId accessHash:(int64_t)accessHash fileReference:(NSData *)fileReference thumbSize:(NSString *)thumbSize size:(NSNumber *)size mediaType:(id)mediaType originInfo:(TGMediaOriginInfo *)originInfo identifier:(int64_t)identifier;

@end

@interface CloudPeerPhotoMediaResource: NSObject <TelegramCloudMediaResource>

@property (nonatomic, readonly) int32_t datacenterId;
@property (nonatomic, readonly) int64_t peerId;
@property (nonatomic, readonly) int64_t accessHash;
@property (nonatomic, readonly) int64_t photoId;
@property (nonatomic, readonly) int32_t peerType;
@property (nonatomic, readonly) bool big;
@property (nonatomic, strong, readonly) id mediaType;
@property (nonatomic, readonly) int64_t identifier;

- (instancetype)initWithDatacenterId:(int32_t)datacenterId peerId:(int64_t)peerId accessHash:(int64_t)accessHash photoId:(int64_t)photoId peerType:(int32_t)peerType big:(bool)big mediaType:(id)mediaType identifier:(int64_t)identifier;

@end
