#import "TGBingSearchResultItem.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGMediaSelectionContext.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGMediaEditingContext.h"

@interface TGBingSearchResultItem (TGMediaItem) <TGMediaSelectableItem, TGMediaEditableItem>

@property (nonatomic, copy) void (^fetchOriginalImage)(id<TGMediaEditableItem>, void (^)(UIImage *));
@property (nonatomic, copy) void (^fetchOriginalThumbnailImage)(id<TGMediaEditableItem>, void (^)(UIImage *));

@end
