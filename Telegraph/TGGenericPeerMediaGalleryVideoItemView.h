#import "TGModernGalleryNewVideoItemView.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGPIPAblePlayerView.h"

@interface TGGenericPeerMediaGalleryVideoItemView : TGModernGalleryNewVideoItemView <TGPIPAblePlayerContainerView>

- (void)cancelPIP;

@end
