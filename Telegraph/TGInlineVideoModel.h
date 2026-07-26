#import "TGModernViewModel.h"

#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGInlineVideoModel : TGModernViewModel

@property (nonatomic, strong) SSignal *videoPathSignal;

@end
