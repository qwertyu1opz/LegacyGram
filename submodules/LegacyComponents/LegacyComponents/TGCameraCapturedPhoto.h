#import <UIKit/UIKit.h>
#import "TGMediaEditingContext.h"
#import "TGMediaSelectionContext.h"

@class PGCameraShotMetadata;

@interface TGCameraCapturedPhoto : NSObject <TGMediaEditableItem, TGMediaSelectableItem>

@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) PGCameraShotMetadata *metadata;

- (instancetype)initWithImage:(UIImage *)image metadata:(PGCameraShotMetadata *)metadata;
- (instancetype)initWithExistingImage:(UIImage *)image;

- (void)_cleanUp;

@end
