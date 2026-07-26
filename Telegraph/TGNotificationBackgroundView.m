#import "TGNotificationBackgroundView.h"

@interface TGNotificationBackgroundView ()
{
    UIView *_backgroundView;
}
@end

@implementation TGNotificationBackgroundView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        CGFloat backgroundAlpha = 0.8f;
        
        #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if (iosMajorVersion() >= 8)
        {
            id blurEffect = nil;
            
            _blurEffectView = [[UIView alloc] initWithFrame:CGRectZero];
            _blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _blurEffectView.frame = self.bounds;
            [self addSubview:_blurEffectView];
            
            _vibrantEffectView = [[UIView alloc] initWithFrame:CGRectZero];
            _vibrantEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _vibrantEffectView.frame = self.bounds;
            [_blurEffectView addSubview:_vibrantEffectView];
            
            backgroundAlpha = 0.4f;
        }
        #endif

        _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _backgroundView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:backgroundAlpha];
        [self addSubview:_backgroundView];
    }
    return self;
}

@end
