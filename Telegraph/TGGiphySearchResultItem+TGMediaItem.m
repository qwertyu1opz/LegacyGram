#import "TGGiphySearchResultItem+TGMediaItem.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@implementation TGGiphySearchResultItem (TGMediaItem)

- (bool)isVideo
{
    return false;
}

- (NSString *)uniqueIdentifier
{
    return self.gifId;
}

@end
