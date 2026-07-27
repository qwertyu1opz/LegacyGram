#import <WatchKit/WatchKit.h>
#import "../../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface WKInterfaceGroup (Signals)

- (void)setBackgroundImageSignal:(SSignal *)signal isVisible:(bool (^)(void))isVisible;
- (void)updateIfNeeded;

@end
