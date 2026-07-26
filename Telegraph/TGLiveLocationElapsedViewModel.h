#import "TGModernViewModel.h"
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGLiveLocationElapsedViewModel : TGModernViewModel

- (instancetype)initWithColor:(UIColor *)color;
- (void)setRemaining:(int32_t)remaining period:(int32_t)period;

@end
