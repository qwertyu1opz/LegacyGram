#import "TGProfilePhotoListActor.h"

#import "../submodules/LegacyComponents/LegacyComponents/ActionStage.h"

#import "TGDatabase.h"
#import "TGTelegraph.h"

#import "TGUserDataRequestBuilder.h"

#import "TGUpdateStateRequestBuilder.h"

#import "TGImageMediaAttachment+Telegraph.h"

#import <map>

@interface TGProfilePhotoListActor ()

@property (nonatomic) int64_t peerId;

@end

@implementation TGProfilePhotoListActor

+ (NSString *)genericPath
{
    return @"/tg/profilePhotos/@";
}

- (void)execute:(NSDictionary *)__unused options
{
    _peerId = [options[@"peerId"] longLongValue];
    
    if (_peerId == 0)
        [ActionStageInstance() actionFailed:self.path reason:-1];
    else
    {
        if ([self.path hasSuffix:@"force)"])
        {
            self.cancelToken = [TGTelegraphInstance doRequestPeerProfilePhotoList:_peerId actor:self];
        }
        else
        {
            [TGDatabaseInstance() loadPeerProfilePhotos:_peerId completion:^(NSArray *photosArray)
            {
                [ActionStageInstance() dispatchOnStageQueue:^
                {
                    [ActionStageInstance() requestActor:[[NSString alloc] initWithFormat:@"/tg/profilePhotos/(%lld,force)", _peerId] options:@{@"peerId": @(_peerId)} flags:0 watcher:TGTelegraphInstance];
                    
                    [ActionStageInstance() actionCompleted:self.path result:photosArray];
                }];
            }];
        }
    }
}

- (void)photoListRequestSuccess:(TLphotos_Photos *)result
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    while (false) TGLog(@"IOS6PROFILE photos.result peer=%lld photos=%d users=%d class=%@",
          _peerId,
          (int)result.photos.count,
          (int)result.users.count,
          NSStringFromClass([result class]));
    
    [TGUserDataRequestBuilder executeUserDataUpdate:result.users];
    
    for (TLPhoto *photoDesc in result.photos)
    {
        TGImageMediaAttachment *imageAttachment = [[TGImageMediaAttachment alloc] initWithTelegraphDesc:photoDesc];
        if (imageAttachment != nil) {
            TGMediaOriginInfo *origin = nil;
            if ([photoDesc isKindOfClass:[TLPhoto$photo class]])
            {
                TLPhoto$photo *photo = (TLPhoto$photo *)photoDesc;
                
                NSMutableDictionary *fileReferences = [[NSMutableDictionary alloc] init];
                for (TLPhotoSize$photoSize *size in photo.sizes)
                {
                    if (![size isKindOfClass:[TLPhotoSize$photoSize class]])
                        continue;
                    
                    if ([size.location isKindOfClass:[TLFileLocation$fileLocation class]])
                    {
                        TLFileLocation$fileLocation *fileLocation = (TLFileLocation$fileLocation *)size.location;
                        fileReferences[[NSString stringWithFormat:@"%lld_%d", fileLocation.volume_id, fileLocation.local_id]] = fileLocation.file_reference;
                    }
                }
                
                origin = [TGMediaOriginInfo mediaOriginInfoWithFileReference:photo.file_reference fileReferences:fileReferences userId:(int32_t)self.peerId offset:0];
                imageAttachment.originInfo = origin;
            }
            NSString *thumbUrl = [imageAttachment.imageInfo closestImageUrlWithSize:CGSizeMake(160.0f, 160.0f) resultingSize:NULL];
            NSString *fullUrl = [imageAttachment.imageInfo closestImageUrlWithSize:CGSizeMake(640.0f, 640.0f) resultingSize:NULL];
            while (false) TGLog(@"IOS6PROFILE photos.item peer=%lld photoClass=%@ imageId=%lld access=%lld thumb=%@ full=%@ origin=%d",
                  _peerId,
                  NSStringFromClass([photoDesc class]),
                  imageAttachment.imageId,
                  imageAttachment.accessHash,
                  thumbUrl,
                  fullUrl,
                  imageAttachment.originInfo != nil ? 1 : 0);
            [array addObject:imageAttachment];
        }
        else
        {
            while (false) TGLog(@"IOS6PROFILE photos.item.skip peer=%lld photoClass=%@", _peerId, NSStringFromClass([photoDesc class]));
        }
    }
    
    [TGDatabaseInstance() storePeerProfilePhotos:_peerId photosArray:array append:false];
    
    if ([self.path hasSuffix:@"force)"])
        [ActionStageInstance() dispatchResource:[[NSString alloc] initWithFormat:@"/tg/profilePhotos/(%lld)", _peerId] resource:array];
    
    [ActionStageInstance() actionCompleted:self.path result:array];
}

- (void)photoListRequestFailed
{
    [ActionStageInstance() actionFailed:self.path reason:-1];
}

@end
