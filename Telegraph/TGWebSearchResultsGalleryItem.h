#import "TGWebSearchResult.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGModernGalleryItem.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGModernGallerySelectableItem.h"

@protocol TGWebSearchResultsGalleryItem <TGModernGalleryItem, TGModernGallerySelectableItem>

- (id<TGWebSearchResult>)webSearchResult;

@end
