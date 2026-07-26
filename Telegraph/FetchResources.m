#import "FetchResources.h"

#import "TelegramMediaResources.h"
#import "MultipartFetch.h"
#import "TGCommon.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGRemoteImageView.h"

SSignal *fetchResource(id<MediaResource> resource, NSRange range, TGNetworkMediaTypeTag mediaTypeTag) {
    if ([resource conformsToProtocol:@protocol(TelegramCloudMediaResource)]) {
        id<TelegramCloudMediaResource> cloudResource = (id<TelegramCloudMediaResource>)resource;
        if ([cloudResource datacenterId] <= 0) {
            while (false) TGLog(@"IOS6MEDIA fetch skip invalid dc resource=%@ dc=%d", NSStringFromClass([resource class]), [cloudResource datacenterId]);
            return [SSignal single:[[MediaResourceDataFetchResult alloc] initWithData:[NSData data] complete:true]];
        }
        if ([resource isKindOfClass:[CloudFileMediaResource class]]) {
            CloudFileMediaResource *cloudFile = (CloudFileMediaResource *)cloudResource;
            if (cloudFile.legacyCacheUrl != nil) {
                NSString *legacyPath = [[TGRemoteImageView sharedCache] pathForCachedData:cloudFile.legacyCacheUrl];
                NSData *data = [[NSData alloc] initWithContentsOfFile:legacyPath];
                if (data != nil) {
                    return [SSignal single:[[MediaResourceDataFetchResult alloc] initWithData:data complete:true]];
                }
            }
            if (cloudFile.legacyCachePath != nil) {
                NSData *data = [[NSData alloc] initWithContentsOfFile:cloudFile.legacyCachePath];
                if (data != nil) {
                    return [SSignal single:[[MediaResourceDataFetchResult alloc] initWithData:data complete:true]];
                }
            }
        }
        return multipartFetch(cloudResource, [cloudResource size], range, mediaTypeTag);
    } else {
        return [SSignal never];
    }
}
