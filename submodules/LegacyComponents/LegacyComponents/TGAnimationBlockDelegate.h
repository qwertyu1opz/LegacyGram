#import "LegacyComponentsIos6Compat.h"
#import <QuartzCore/QuartzCore.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
@interface TGAnimationBlockDelegate : NSObject <CAAnimationDelegate>
#else
@interface TGAnimationBlockDelegate : NSObject
#endif

@property (nonatomic) bool removeLayerOnCompletion;
@property (nonatomic) NSNumber *opacityOnCompletion;
@property (nonatomic, weak) CALayer *layer;
@property (nonatomic, copy) void (^completion)(BOOL finished);

- (instancetype)initWithLayer:(CALayer *)layer;

@end
