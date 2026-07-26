#import <Foundation/Foundation.h>
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

#import "MediaResource.h"
#import "MediaBoxContexts.h"

@interface MediaBox : NSObject

- ( instancetype)initWithBasePath:(NSString * )basePath;
- (void)setFetchResource:(SSignal * (^ )(id<MediaResource> , NSRange))fetchResource;
- (SSignal * )resourceStatus:(id<MediaResource> )resource;
- (SSignal * )resourceData:(id<MediaResource> )resource pathExtension:(NSString * )pathExtension;
- (SSignal * )fetchedResource:(id<MediaResource> )resource;
- (void)cancelInteractiveResourceFetch:(id<MediaResource> )resource;

- (ResourceStorePaths * )storePathsForId:(id<MediaResourceId> )resourceId;

@end
