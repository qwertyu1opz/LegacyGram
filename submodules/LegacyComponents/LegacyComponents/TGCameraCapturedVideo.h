#import <UIKit/UIKit.h>
#import "TGMediaEditingContext.h"
#import "TGMediaSelectionContext.h"

@class AVURLAsset;

@interface TGCameraCapturedVideo : NSObject <TGMediaEditableItem, TGMediaSelectableItem>

@property (nonatomic, readonly) AVURLAsset *avAsset;
@property (nonatomic, readonly) NSTimeInterval videoDuration;

- (instancetype)initWithURL:(NSURL *)url;

- (void)_cleanUp;

@end
