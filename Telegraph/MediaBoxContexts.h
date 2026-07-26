#import <Foundation/Foundation.h>

#import "MediaResource.h"
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

typedef enum {
    MediaResourceStatusRemote,
    MediaResourceStatusLocal,
    MediaResourceStatusFetching
} MediaResourceStatusType;

@interface MediaResourceStatus : NSObject

@property (nonatomic, readonly) MediaResourceStatusType status;
@property (nonatomic, readonly) float progress;

- ( instancetype)initWithStatus:(MediaResourceStatusType)status progress:(float)progress;

@end

@interface ResourceStatusContext : NSObject

@property (nonatomic, strong)  MediaResourceStatus * status;
@property (nonatomic, strong)  SBag * subscribers;

@end

@interface ResourceData : NSObject

@property (nonatomic, strong, readonly)  NSString * path;
@property (nonatomic, readonly) int32_t size;
@property (nonatomic, readonly) bool complete;

- ( instancetype)initWithPath:(NSString * )path size:(int32_t)size complete:(bool)complete;

@end

@interface ResourceDataContext : NSObject

@property (nonatomic, strong) ResourceData * data;
@property (nonatomic, strong) SBag * completeDataSubscribers;
@property (nonatomic, strong) SBag * fetchSubscribers;
@property (nonatomic, strong) id<SDisposable>  fetchDisposable;

- ( instancetype)initWithData:(ResourceData * )data;

@end

@interface ResourceStorePaths : NSObject

@property (nonatomic, strong, readonly) NSString * partial;
@property (nonatomic, strong, readonly) NSString * complete;

- ( instancetype)initWithPartial:(NSString * )partial complete:(NSString * )complete;

@end

@interface MediaResourceDataFetchResult : NSObject

@property (nonatomic, strong, readonly) NSData * data;
@property (nonatomic, readonly) bool complete;

- ( instancetype)initWithData:(NSData * )data complete:(bool)complete;

@end


