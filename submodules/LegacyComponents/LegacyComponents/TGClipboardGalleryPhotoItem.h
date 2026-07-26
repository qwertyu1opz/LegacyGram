#import "TGModernGallerySelectableItem.h"
#import "TGModernGalleryEditableItem.h"

@interface TGClipboardGalleryPhotoItem : NSObject <TGModernGallerySelectableItem, TGModernGalleryEditableItem>

@property (nonatomic, strong) UIImage *image;

- (instancetype)initWithImage:(UIImage *)image;

@end
