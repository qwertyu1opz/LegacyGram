#import <UIKit/UIKit.h>

#import "../submodules/LegacyComponents/LegacyComponents/TGOverlayControllerWindow.h"

@interface TGProxyWindowController : TGOverlayWindowViewController

@end

@interface TGProxyWindow : UIWindow

- (void)dismissWithSuccess;
+ (void)setDarkStyle:(bool)dark;

@end


