#import "TGNeoViewModel.h"
#import "../../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGNeoRenderableViewModel : TGNeoViewModel

@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, strong) UIImage *cachedImage;

- (CGSize)layoutWithContainerSize:(CGSize)containerSize;
+ (SSignal *)renderSignalForViewModel:(TGNeoRenderableViewModel *)viewModel;

@end
