#import <UIKit/UIKit.h>

@interface TGNotificationBackgroundView : UIView

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
@property (nonatomic, readonly) UIView *blurEffectView;
@property (nonatomic, readonly) UIView *vibrantEffectView;
#endif

@end
