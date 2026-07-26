#import "TGExternalGifSearchResult+TGMediaItem.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@implementation TGExternalGifSearchResult (TGMediaItem)

- (bool)isVideo
{
    return false;
}

- (NSString *)uniqueIdentifier
{
    return [TGStringUtils stringByEscapingForURL:self.url];
}

@end
