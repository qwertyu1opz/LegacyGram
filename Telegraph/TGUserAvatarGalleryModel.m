#import "TGUserAvatarGalleryModel.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGUserAvatarGalleryItem.h"

#import "../submodules/LegacyComponents/LegacyComponents/ActionStage.h"
#import "TGDatabase.h"

#import "TGImageInfo+Telegraph.h"

#import "TGGenericPeerMediaGalleryDefaultHeaderView.h"
#import "TGGenericPeerMediaGalleryActionsAccessoryView.h"
#import "TGGenericPeerMediaGalleryDefaultFooterView.h"

#import "TGGenericPeerGalleryGroupItem.h"

#import "TGCustomActionSheet.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGProgressWindow.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGMediaAssetsLibrary.h"

@interface TGUserAvatarGalleryModel () <ASWatcher>
{
    int64_t _peerId;
    
    TGGenericPeerMediaGalleryDefaultFooterView *_footerView;
    NSMutableDictionary *_groupedItems;
    NSArray *_groupItems;
    NSString *_currentAvatarLegacyThumbnailImageUri;
    bool _profilePhotosRequested;
}

@property (nonatomic, strong) ASHandle *actionHandle;

- (void)_requestProfilePhotosIfNeeded;

@end

@implementation TGUserAvatarGalleryModel

- (instancetype)initWithPeerId:(int64_t)peerId currentAvatarLegacyThumbnailImageUri:(NSString *)currentAvatarLegacyThumbnailImageUri currentAvatarLegacyImageUri:(NSString *)currentAvatarLegacyImageUri currentAvatarImageSize:(CGSize)currentAvatarImageSize
{
    self = [super init];
    if (self != nil)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self];
        
        _peerId = peerId;
        _currentAvatarLegacyThumbnailImageUri = [currentAvatarLegacyThumbnailImageUri copy];
        
        _groupedItems = [[NSMutableDictionary alloc] init];
        
        TGUserAvatarGalleryItem *firstItem = [self itemForImageId:0 accessHash:0 legacyThumbnailUrl:currentAvatarLegacyThumbnailImageUri legacyUrl:currentAvatarLegacyImageUri imageSize:currentAvatarImageSize isCurrent:true];
        [self _replaceItems:@[firstItem] focusingOnItem:firstItem];
        [self _requestProfilePhotosIfNeeded];
    }
    return self;
}

- (void)dealloc
{
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

- (void)_requestProfilePhotosIfNeeded
{
    if (_profilePhotosRequested || _peerId == 777000 || _peerId == 333000)
        return;
    _profilePhotosRequested = true;
    
    __weak TGUserAvatarGalleryModel *weakSelf = self;
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        __strong TGUserAvatarGalleryModel *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        [ActionStageInstance() watchForPath:[[NSString alloc] initWithFormat:@"/tg/profilePhotos/(%" PRId64 ")", strongSelf->_peerId] watcher:strongSelf];
        [ActionStageInstance() requestActor:[[NSString alloc] initWithFormat:@"/tg/profilePhotos/(%" PRId64 ",cached)", strongSelf->_peerId] options:@{@"peerId": @(strongSelf->_peerId)} flags:0 watcher:strongSelf];
    }];
}

- (void)_transitionCompleted
{
    [self _requestProfilePhotosIfNeeded];
}

- (TGUserAvatarGalleryItem *)itemForImageId:(int64_t)imageId accessHash:(int64_t)__unused accessHash legacyThumbnailUrl:(NSString *)legacyThumbnailUrl legacyUrl:(NSString *)legacyUrl imageSize:(CGSize)imageSize isCurrent:(bool)isCurrent
{
    TGUserAvatarGalleryItem *item = [[TGUserAvatarGalleryItem alloc] initWithLegacyThumbnailUrl:legacyThumbnailUrl legacyUrl:legacyUrl imageId:imageId imageSize:imageSize isCurrent:isCurrent];
    return item;
}

- (TGUserAvatarGalleryItem *)itemForImageId:(int64_t)imageId accessHash:(int64_t)__unused accessHash legacyThumbnailUrl:(NSString *)legacyThumbnailUrl legacyUrl:(NSString *)legacyUrl imageSize:(CGSize)imageSize isCurrent:(bool)isCurrent originInfo:(TGMediaOriginInfo *)originInfo
{
    TGUserAvatarGalleryItem *item = [[TGUserAvatarGalleryItem alloc] initWithLegacyThumbnailUrl:legacyThumbnailUrl legacyUrl:legacyUrl imageId:imageId imageSize:imageSize isCurrent:isCurrent originInfo:originInfo];
    return item;
}

- (UIView<TGModernGalleryDefaultHeaderView> *)createDefaultHeaderView
{
    __weak TGUserAvatarGalleryModel *weakSelf = self;
    return [[TGGenericPeerMediaGalleryDefaultHeaderView alloc] initWithPositionAndCountBlock:^(id<TGModernGalleryItem> item, NSUInteger *position, NSUInteger *count)
    {
        __strong TGUserAvatarGalleryModel *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            if (position != NULL)
            {
                NSUInteger index = [strongSelf.items indexOfObject:item];
                if (index != NSNotFound)
                    *position = index;
            }
            if (count != NULL)
                *count = strongSelf.items.count;
        }
    }];
}

- (UIView<TGModernGalleryDefaultFooterView> *)createDefaultFooterView
{
    _footerView = [[TGGenericPeerMediaGalleryDefaultFooterView alloc] init];
    __weak TGUserAvatarGalleryModel *weakSelf = self;
    _footerView.groupItemChanged = ^(TGGenericPeerGalleryGroupItem *item, bool synchronously)
    {
        __strong TGUserAvatarGalleryModel *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        id<TGModernGalleryItem> galleryItem = strongSelf->_groupedItems[@(item.keyId)];
        [strongSelf _focusOnItem:(id<TGModernGalleryItem>)galleryItem synchronously:synchronously];
    };
    return _footerView;
}

- (void)_replaceItemsFromImageMediaList:(NSArray *)imageMediaList focusOnFirst:(bool)focusOnFirst
{
    NSArray *sortedResult = [(NSArray *)imageMediaList sortedArrayUsingComparator:^NSComparisonResult(TGImageMediaAttachment *imageMedia1, TGImageMediaAttachment *imageMedia2)
    {
        if (imageMedia1.date > imageMedia2.date)
            return NSOrderedAscending;
        return NSOrderedDescending;
    }];
    
    NSMutableArray *updatedItems = [[NSMutableArray alloc] init];
    NSInteger index = -1;
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (TGImageMediaAttachment *imageMedia in sortedResult)
    {
        index++;
        
        NSString *legacyThumbnailUrl = [imageMedia.imageInfo closestImageUrlWithSize:CGSizeMake(160.0f, 160.0f) resultingSize:NULL];
        {
            int datacenterId = 0;
            int64_t volumeId = 0;
            int localId = 0;
            int64_t secret = 0;
            if (extractFileUrlComponents(legacyThumbnailUrl, &datacenterId, &volumeId, &localId, &secret)) {
                NSData *fileReference = [imageMedia.originInfo fileReferenceForVolumeId:volumeId localId:localId];
                if (fileReference != nil)
                    legacyThumbnailUrl = [legacyThumbnailUrl stringByAppendingFormat:@"_%@", [fileReference stringByEncodingInHex]];
            }
        }
        NSString *legacyUrl = [imageMedia.imageInfo closestImageUrlWithSize:CGSizeMake(640.0f, 640.0f) resultingSize:NULL];
        {
            int datacenterId = 0;
            int64_t volumeId = 0;
            int localId = 0;
            int64_t secret = 0;
            if (extractFileUrlComponents(legacyUrl, &datacenterId, &volumeId, &localId, &secret)) {
                NSData *fileReference = [imageMedia.originInfo fileReferenceForVolumeId:volumeId localId:localId];
                if (fileReference != nil)
                    legacyUrl = [legacyUrl stringByAppendingFormat:@"_%@", [fileReference stringByEncodingInHex]];
            }
        }
        if (legacyUrl.length == 0)
            legacyUrl = legacyThumbnailUrl;
        if (legacyThumbnailUrl.length == 0)
            legacyThumbnailUrl = legacyUrl;
        if (legacyUrl.length == 0)
        {
            while (false) TGLog(@"IOS6PROFILE avatar.gallery.skip imageId=%lld noUrl", imageMedia.imageId);
            continue;
        }
        while (false) TGLog(@"IOS6PROFILE avatar.gallery.item imageId=%lld thumb=%@ url=%@ origin=%d",
              imageMedia.imageId,
              legacyThumbnailUrl,
              legacyUrl,
              imageMedia.originInfo != nil ? 1 : 0);
        bool isCurrent = false;
        
        if (index == 0)
        {
            isCurrent = true;
            if (_currentAvatarLegacyThumbnailImageUri.length != 0)
                legacyThumbnailUrl = _currentAvatarLegacyThumbnailImageUri;
        }
        
        TGUserAvatarGalleryItem *item = [self itemForImageId:imageMedia.imageId accessHash:imageMedia.accessHash legacyThumbnailUrl:legacyThumbnailUrl legacyUrl:legacyUrl imageSize:CGSizeMake(640.0f, 640.0f) isCurrent:isCurrent originInfo:imageMedia.originInfo];
        [updatedItems addObject:item];
     
        [items addObject:[[TGGenericPeerGalleryGroupItem alloc] initWithImageAttachment:imageMedia]];
        _groupedItems[@(imageMedia.imageId)] = item;
    }
    
    _groupItems = items;
    if (items.count > 1)
        [_footerView setGroupItems:items];
    
    if (updatedItems.count != 0)
        [self _replaceItems:updatedItems focusingOnItem:focusOnFirst ? updatedItems.firstObject : nil];
    else
        while (false) TGLog(@"IOS6PROFILE avatar.gallery.keepCurrent emptyLoadedList peer=%lld", _peerId);
}

- (void)_commitDeletedGroupItem:(TGUserAvatarGalleryItem *)item
{
    NSMutableArray *updatedGroupItems = [_groupItems mutableCopy];
    for (TGGenericPeerGalleryGroupItem *groupItem in updatedGroupItems)
    {
        if (groupItem.keyId == item.imageId)
        {
            [updatedGroupItems removeObject:groupItem];
            break;
        }
    }
    
    _groupItems = updatedGroupItems;
    [_footerView setGroupItems:updatedGroupItems];
}

- (void)actionStageResourceDispatched:(NSString *)path resource:(id)resource arguments:(id)__unused arguments
{
    if ([path hasPrefix:@"/tg/profilePhotos/"])
    {
        [self actorCompleted:ASStatusSuccess path:path result:resource];
    }
}

- (void)actorCompleted:(int)status path:(NSString *)path result:(id)result
{
    if ([path hasPrefix:@"/tg/profilePhotos/"])
    {
        TGDispatchOnMainThread(^
        {
            if (status == ASStatusSuccess && ((NSArray *)result).count != 0)
            {   
                while (false) TGLog(@"IOS6PROFILE avatar.gallery.loaded peer=%lld count=%d", _peerId, (int)((NSArray *)result).count);
                [self _replaceItemsFromImageMediaList:result focusOnFirst:true];
            }
            else
            {
                while (false) TGLog(@"IOS6PROFILE avatar.gallery.loaded.empty peer=%lld status=%d", _peerId, status);
            }
        });
    }
}

- (void)_interItemTransitionProgressChanged:(CGFloat)progress
{
    [_footerView setInterItemTransitionProgress:progress];
}

- (UIView<TGModernGalleryDefaultFooterAccessoryView> *)createDefaultLeftAccessoryView
{
    TGGenericPeerMediaGalleryActionsAccessoryView *accessoryView = [[TGGenericPeerMediaGalleryActionsAccessoryView alloc] init];
    __weak TGUserAvatarGalleryModel *weakSelf = self;
    __weak TGGenericPeerMediaGalleryActionsAccessoryView *weakAccessoryView = accessoryView;
    accessoryView.action = ^(id<TGModernGalleryItem> item)
    {
        if ([item isKindOfClass:[TGUserAvatarGalleryItem class]])
        {
            __strong TGUserAvatarGalleryModel *strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                UIView *actionSheetView = nil;
                if (strongSelf.actionSheetView)
                    actionSheetView = strongSelf.actionSheetView();
                
                if (actionSheetView != nil)
                {
                    NSMutableArray *actions = [[NSMutableArray alloc] init];
                    
                    if ([strongSelf _isDataAvailableForSavingItemToCameraRoll:item])
                    {
                        [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Preview.SaveToCameraRoll") action:@"save" type:TGActionSheetActionTypeGeneric]];
                    }
                    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]];
                    
                    [[[TGCustomActionSheet alloc] initWithTitle:nil actions:actions actionBlock:^(__unused id target, NSString *action)
                    {
                        __strong TGUserAvatarGalleryModel *strongSelf = weakSelf;
                        if ([action isEqualToString:@"save"])
                            [strongSelf _commitSaveItemToCameraRoll:item];
                    } target:strongSelf] showFromRect:[weakAccessoryView convertRect:weakAccessoryView.bounds toView:actionSheetView] inView:actionSheetView animated:true];
                }
            }
        }
    };
    return accessoryView;
}

- (bool)_isDataAvailableForSavingItemToCameraRoll:(id<TGModernGalleryItem>)item
{
    if ([item isKindOfClass:[TGUserAvatarGalleryItem class]])
    {
        TGUserAvatarGalleryItem *avatarItem = (TGUserAvatarGalleryItem *)item;
        return [[NSFileManager defaultManager] fileExistsAtPath:[avatarItem filePath]];
    }
    
    return false;
}

- (void)_commitSaveItemToCameraRoll:(id<TGModernGalleryItem>)item
{
    if ([item isKindOfClass:[TGUserAvatarGalleryItem class]])
    {
        TGUserAvatarGalleryItem *avatarItem = (TGUserAvatarGalleryItem *)item;
        NSData *data = [[NSData alloc] initWithContentsOfFile:[avatarItem filePath]];
        [self _saveImageDataToCameraRoll:data];
    }
}

- (void)_saveImageDataToCameraRoll:(NSData *)data
{
    if (data == nil)
        return;

    if (![[[LegacyComponentsGlobals provider] accessChecker] checkPhotoAuthorizationStatusForIntent:TGPhotoAccessIntentSave alertDismissCompletion:nil])
        return;
    
    TGProgressWindow *progressWindow = [[TGProgressWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [progressWindow show:true];
    
    [[[[TGMediaAssetsLibrary sharedLibrary] saveAssetWithImageData:data] deliverOn:[SQueue mainQueue]] startWithNext:nil error:^(__unused id error)
    {
        [[[LegacyComponentsGlobals provider] accessChecker] checkPhotoAuthorizationStatusForIntent:TGPhotoAccessIntentSave alertDismissCompletion:nil];
        [progressWindow dismiss:true];
    } completed:^
    {
        [progressWindow dismissWithSuccess];
    }];
}

@end
