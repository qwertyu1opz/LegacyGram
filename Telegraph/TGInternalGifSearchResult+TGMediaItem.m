#import "TGInternalGifSearchResult+TGMediaItem.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@implementation TGInternalGifSearchResult (TGMediaItem)

- (bool)isVideo
{
    return false;
}

- (NSString *)uniqueIdentifier
{
    return [TGStringUtils stringByEscapingForURL:self.url];
}

@end
