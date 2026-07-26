#import "TGWebSearchResult.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGModernMediaListItem.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGModernMediaListSelectableItem.h"

@protocol TGWebSearchListItem <TGModernMediaListItem, TGModernMediaListSelectableItem>

- (id<TGWebSearchResult>)webSearchResult;

@end
