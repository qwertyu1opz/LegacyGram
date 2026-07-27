#import <WatchKit/WatchKit.h>
#import "../../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface WKInterfaceImage (Signals)

- (void)setSignal:(SSignal *)signal isVisible:(bool (^)(void))isVisible;
- (void)updateIfNeeded;

@end
