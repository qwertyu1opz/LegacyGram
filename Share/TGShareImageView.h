#import <UIKit/UIKit.h>

#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGShareImageView : UIImageView

- (void)setSignal:(SSignal *)signal;

@end
