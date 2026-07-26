#import "TGNotificationOverlayView.h"

@interface TGNotificationOverlayView ()
{
    UIView *_effectView;
    UIView *_backgroundView;
}
@end

@implementation TGNotificationOverlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _effectView = [[UIView alloc] initWithFrame:self.bounds];
        _effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _effectView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.67f];
        _effectView.userInteractionEnabled = false;
        [self addSubview:_effectView];
    }
    return self;
}

- (void)setIsTransparent:(bool)isTransparent
{
    _isTransparent = isTransparent;
    _effectView.hidden = isTransparent;
    _backgroundView.hidden = isTransparent;
}

@end
