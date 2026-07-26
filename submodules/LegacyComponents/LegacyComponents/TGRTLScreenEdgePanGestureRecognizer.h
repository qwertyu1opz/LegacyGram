#import <UIKit/UIKit.h>
#import "LegacyComponentsIos6Compat.h"

#import <UIKit/UIGestureRecognizerSubclass.h>

@interface TGRTLScreenEdgePanGestureRecognizer : UIScreenEdgePanGestureRecognizer

@end

@interface TGRTLScreenEdgePanGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>

@end
