#import <Foundation/Foundation.h>
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@class UIEvent;

@interface TGRemoteControlsManager : NSObject

+ (TGRemoteControlsManager *)instance;

- (id<SDisposable>)requestControlsWithPrevious:(void (^)())previous next:(void (^)())next play:(void (^)())play pause:(void (^)())pause position:(void (^)(NSTimeInterval position))position;

// MPRemoteCommandCenter starts at iOS 7.1.  iOS 6 delivers the same buttons
// as legacy UIResponder remote-control events, forwarded by TGAppDelegate.
- (void)handleLegacyRemoteControlEvent:(UIEvent *)event;

@end
