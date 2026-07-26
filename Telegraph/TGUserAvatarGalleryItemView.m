#import "TGUserAvatarGalleryItemView.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGModernGalleryImageItem.h"

@implementation TGUserAvatarGalleryItemView

- (void)setItem:(TGModernGalleryImageItem *)item synchronously:(bool)__unused synchronously
{
    [super setItem:item synchronously:false];
}

@end
