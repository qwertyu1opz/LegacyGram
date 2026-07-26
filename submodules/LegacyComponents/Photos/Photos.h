#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>

typedef NSInteger PHAssetMediaType;
typedef NSUInteger PHAssetMediaSubtype;
typedef NSUInteger PHAssetMediaSubtypes;
typedef NSInteger PHImageRequestID;
typedef NSInteger PHContentEditingInputRequestID;
typedef NSInteger PHImageContentMode;
typedef NSInteger PHImageRequestOptionsDeliveryMode;
typedef NSInteger PHImageRequestOptionsResizeMode;
typedef NSInteger PHVideoRequestOptionsDeliveryMode;
typedef NSInteger PHAuthorizationStatus;
typedef NSInteger PHAssetCollectionSubtype;
typedef NSInteger PHAssetCollectionType;
typedef NSInteger PHAssetResourceType;

#define PHAssetMediaTypeUnknown 0
#define PHAssetMediaTypeImage 1
#define PHAssetMediaTypeVideo 2

#define PHAssetMediaSubtypePhotoPanorama (1UL << 0)
#define PHAssetMediaSubtypePhotoHDR (1UL << 1)
#define PHAssetMediaSubtypePhotoScreenshot (1UL << 2)
#define PHAssetMediaSubtypePhotoLive (1UL << 3)
#define PHAssetMediaSubtypeVideoStreamed (1UL << 16)
#define PHAssetMediaSubtypeVideoHighFrameRate (1UL << 17)
#define PHAssetMediaSubtypeVideoTimelapse (1UL << 18)

#define PHAssetCollectionTypeAlbum 1
#define PHAssetCollectionTypeSmartAlbum 2
#define PHAssetCollectionTypeMoment 3

#define PHAssetCollectionSubtypeAny 0x7fffffff
#define PHAssetCollectionSubtypeAlbumRegular 2
#define PHAssetCollectionSubtypeAlbumMyPhotoStream 100
#define PHAssetCollectionSubtypeSmartAlbumPanoramas 201
#define PHAssetCollectionSubtypeSmartAlbumVideos 202
#define PHAssetCollectionSubtypeSmartAlbumFavorites 203
#define PHAssetCollectionSubtypeSmartAlbumTimelapses 204
#define PHAssetCollectionSubtypeSmartAlbumRecentlyAdded 206
#define PHAssetCollectionSubtypeSmartAlbumBursts 207
#define PHAssetCollectionSubtypeSmartAlbumSlomoVideos 208
#define PHAssetCollectionSubtypeSmartAlbumUserLibrary 209
#define PHAssetCollectionSubtypeSmartAlbumScreenshots 211
#define PHAssetCollectionSubtypeSmartAlbumSelfPortraits 212

#define PHImageContentModeAspectFit 0
#define PHImageContentModeAspectFill 1
#define PHImageContentModeDefault 0

#define PHImageRequestOptionsDeliveryModeOpportunistic 0
#define PHImageRequestOptionsDeliveryModeHighQualityFormat 1
#define PHImageRequestOptionsResizeModeNone 0
#define PHImageRequestOptionsResizeModeFast 1
#define PHImageRequestOptionsResizeModeExact 2
#define PHVideoRequestOptionsDeliveryModeHighQualityFormat 1

#define PHAuthorizationStatusRestricted 1
#define PHAuthorizationStatusDenied 2
#define PHAuthorizationStatusAuthorized 3

#define PHAssetResourceTypePairedVideo 9
#define PHInvalidImageRequestID 0
#define PHImageManagerMaximumSize CGSizeZero

#define PHImageResultIsDegradedKey @"PHImageResultIsDegradedKey"
#define PHImageCancelledKey @"PHImageCancelledKey"
#define PHImageResultIsInCloudKey @"PHImageResultIsInCloudKey"
#define PHImageFileURLKey @"PHImageFileURLKey"

@class PHAssetCollection;
@class PHFetchResult;
@class PHImageRequestOptions;
@class PHLivePhotoRequestOptions;
@class PHVideoRequestOptions;
@class PHCachingImageManager;
@class PHAsset;
@class PHChange;
@class PHFetchResultChangeDetails;
@class PHAssetResource;
@class PHLivePhoto;

@protocol PHPhotoLibraryChangeObserver <NSObject>
- (void)photoLibraryDidChange:(PHChange *)change;
@end

@interface PHObject : NSObject
@property (nonatomic, readonly) NSString *localIdentifier;
@end

@interface PHFetchOptions : NSObject
@property (nonatomic, copy) NSArray *sortDescriptors;
@property (nonatomic, retain) NSPredicate *predicate;
@end

@interface PHAsset : PHObject
@property (nonatomic, readonly) PHAssetMediaType mediaType;
@property (nonatomic, readonly) PHAssetMediaSubtypes mediaSubtypes;
@property (nonatomic, readonly) CGSize pixelSize;
@property (nonatomic, readonly) NSUInteger pixelWidth;
@property (nonatomic, readonly) NSUInteger pixelHeight;
@property (nonatomic, readonly) NSDate *creationDate;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) BOOL representsBurst;
- (void)requestContentEditingInputWithOptions:(id)options completionHandler:(void (^)(id contentEditingInput, NSDictionary *info))completionHandler;
- (void)cancelContentEditingInputRequest:(PHContentEditingInputRequestID)requestID;
+ (PHFetchResult *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection options:(PHFetchOptions *)options;
+ (PHFetchResult *)fetchAssetsWithOptions:(PHFetchOptions *)options;
+ (PHFetchResult *)fetchAssetsWithMediaType:(PHAssetMediaType)mediaType options:(PHFetchOptions *)options;
+ (PHFetchResult *)fetchAssetsWithLocalIdentifiers:(NSArray *)identifiers options:(PHFetchOptions *)options;
@end

@interface PHAssetCollection : PHObject
@property (nonatomic, readonly) PHAssetCollectionType assetCollectionType;
@property (nonatomic, readonly) PHAssetCollectionSubtype assetCollectionSubtype;
@property (nonatomic, readonly) NSUInteger estimatedAssetCount;
@property (nonatomic, readonly) NSString *localizedTitle;
@property (nonatomic, readonly) NSDate *startDate;
@property (nonatomic, readonly) NSDate *endDate;
@property (nonatomic, readonly) CLLocation *approximateLocation;
@property (nonatomic, readonly) NSArray *localizedLocationNames;
+ (PHFetchResult *)fetchAssetCollectionsWithType:(PHAssetCollectionType)type subtype:(PHAssetCollectionSubtype)subtype options:(PHFetchOptions *)options;
@end

@interface PHFetchResult : NSObject <NSFastEnumeration>
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) id firstObject;
- (id)objectAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfObject:(id)object;
- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;
@end

@interface PHFetchResultChangeDetails : NSObject
@property (nonatomic, readonly) PHFetchResult *fetchResultBeforeChanges;
@property (nonatomic, readonly) PHFetchResult *fetchResultAfterChanges;
@property (nonatomic, readonly) BOOL hasIncrementalChanges;
@property (nonatomic, readonly) NSIndexSet *removedIndexes;
@property (nonatomic, readonly) NSIndexSet *insertedIndexes;
@property (nonatomic, readonly) NSIndexSet *changedIndexes;
@property (nonatomic, readonly) BOOL hasMoves;
- (void)enumerateMovesWithBlock:(void (^)(NSUInteger fromIndex, NSUInteger toIndex))block;
@end

@interface PHChange : NSObject
- (PHFetchResultChangeDetails *)changeDetailsForFetchResult:(PHFetchResult *)fetchResult;
@end

@interface PHImageRequestOptions : NSObject <NSCopying>
@property (nonatomic) BOOL networkAccessAllowed;
@property (nonatomic) PHImageRequestOptionsDeliveryMode deliveryMode;
@property (nonatomic) PHImageRequestOptionsResizeMode resizeMode;
@property (nonatomic, copy) void (^progressHandler)(double progress, NSError *error, BOOL *stop, NSDictionary *info);
@end

@interface PHLivePhotoRequestOptions : NSObject
@property (nonatomic) BOOL networkAccessAllowed;
@property (nonatomic) PHImageRequestOptionsDeliveryMode deliveryMode;
@property (nonatomic, copy) void (^progressHandler)(double progress, NSError *error, BOOL *stop, NSDictionary *info);
@end

@interface PHVideoRequestOptions : NSObject
@property (nonatomic) BOOL networkAccessAllowed;
@property (nonatomic) PHVideoRequestOptionsDeliveryMode deliveryMode;
@property (nonatomic, copy) void (^progressHandler)(double progress, NSError *error, BOOL *stop, NSDictionary *info);
@end

@interface PHImageManager : NSObject
+ (PHImageManager *)defaultManager;
- (PHImageRequestID)requestImageForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(PHImageRequestOptions *)options resultHandler:(void (^)(UIImage *result, NSDictionary *info))resultHandler;
- (PHImageRequestID)requestImageDataForAsset:(PHAsset *)asset options:(PHImageRequestOptions *)options resultHandler:(void (^)(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info))resultHandler;
- (PHImageRequestID)requestAVAssetForVideo:(PHAsset *)asset options:(PHVideoRequestOptions *)options resultHandler:(void (^)(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info))resultHandler;
- (PHImageRequestID)requestLivePhotoForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(PHLivePhotoRequestOptions *)options resultHandler:(void (^)(PHLivePhoto *livePhoto, NSDictionary *info))resultHandler;
- (PHImageRequestID)requestExportSessionForVideo:(PHAsset *)asset options:(PHVideoRequestOptions *)options exportPreset:(NSString *)exportPreset resultHandler:(void (^)(AVAssetExportSession *exportSession, NSDictionary *info))resultHandler;
- (PHImageRequestID)requestPlayerItemForVideo:(PHAsset *)asset options:(PHVideoRequestOptions *)options resultHandler:(void (^)(AVPlayerItem *playerItem, NSDictionary *info))resultHandler;
- (void)cancelImageRequest:(PHImageRequestID)requestID;
@end

@interface PHCachingImageManager : PHImageManager
- (void)startCachingImagesForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(PHImageRequestOptions *)options;
- (void)stopCachingImagesForAssets:(NSArray *)assets targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(PHImageRequestOptions *)options;
- (void)stopCachingImagesForAllAssets;
@end

@interface PHPhotoLibrary : NSObject
+ (PHPhotoLibrary *)sharedPhotoLibrary;
+ (PHAuthorizationStatus)authorizationStatus;
+ (void)requestAuthorization:(void (^)(PHAuthorizationStatus status))handler;
- (void)registerChangeObserver:(id<PHPhotoLibraryChangeObserver>)observer;
- (void)unregisterChangeObserver:(id<PHPhotoLibraryChangeObserver>)observer;
- (void)performChanges:(void (^)(void))changeBlock completionHandler:(void (^)(BOOL success, NSError *error))completionHandler;
@end

@interface PHAssetChangeRequest : NSObject
+ (instancetype)creationRequestForAssetFromImage:(UIImage *)image;
+ (instancetype)creationRequestForAssetFromImageAtFileURL:(NSURL *)fileURL;
+ (instancetype)creationRequestForAssetFromVideoAtFileURL:(NSURL *)fileURL;
@end

@interface PHLivePhoto : NSObject
@end

@interface PHAssetResource : NSObject
@property (nonatomic, readonly) PHAssetResourceType type;
+ (NSArray *)assetResourcesForLivePhoto:(PHLivePhoto *)livePhoto;
@end

@interface PHAssetResourceManager : NSObject
+ (PHAssetResourceManager *)defaultManager;
- (void)writeDataForAssetResource:(PHAssetResource *)resource toFile:(NSURL *)fileURL options:(id)options completionHandler:(void (^)(NSError *error))completionHandler;
@end
