#import "TGModernUnreadHeaderView.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGPresentation.h"

static UIImage *TGClassicIOS6UnreadHeaderBackgroundImage(void)
{
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        CGSize size = CGSizeMake(2.0f, 25.0f);
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0f);
        CGContextRef context = UIGraphicsGetCurrentContext();

        NSArray *colors = @[(id)UIColorRGB(0xf8fafc).CGColor, (id)UIColorRGB(0xdce2e8).CGColor, (id)UIColorRGB(0xaeb8c2).CGColor];
        CGFloat locations[] = {0.0f, 0.48f, 1.0f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
        CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(0.0f, size.height), 0);
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);

        CGContextSetFillColorWithColor(context, UIColorRGBA(0xffffff, 0.9f).CGColor);
        CGContextFillRect(context, CGRectMake(0.0f, 0.0f, size.width, 1.0f));
        CGContextSetFillColorWithColor(context, UIColorRGB(0x7d8995).CGColor);
        CGContextFillRect(context, CGRectMake(0.0f, size.height - 1.0f, size.width, 1.0f));
        CGContextSetFillColorWithColor(context, UIColorRGBA(0xffffff, 0.35f).CGColor);
        CGContextFillRect(context, CGRectMake(0.0f, size.height - 2.0f, size.width, 1.0f));

        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return image;
}

static UIColor *TGClassicIOS6UnreadHeaderTextColor(void)
{
    return UIColorRGB(0x43576b);
}

@interface TGModernUnreadHeaderView ()
{
    UIImageView *_backgroundView;
    UILabel *_labelView;
}

@property (nonatomic, strong) NSString *viewIdentifier;
@property (nonatomic, strong) NSString *viewStateIdentifier;

@end

@implementation TGModernUnreadHeaderView

+ (void)drawHeaderForContainerWidth:(CGFloat)containerWidth inContext:(CGContextRef)context andBindBackgroundToContainer:(UIView *)backgroundContainer atPosition:(CGPoint)position presentation:(TGPresentation *)presentation
{
    bool classicIOS6Style = [TGPresentation classicIOS6Style];
    UIImage *backgroundImage = classicIOS6Style ? TGClassicIOS6UnreadHeaderBackgroundImage() : presentation.images.chatUnreadBackground;
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    CGRect backgroundFrame = CGRectMake(0.0f, 3.0f, containerWidth, 25.0f);
    backgroundImageView.frame = CGRectOffset(backgroundFrame, position.x, position.y);
    [backgroundContainer addSubview:backgroundImageView];
    
    static UIFont *font = nil;
    static UIFont *classicFont = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        font = TGSystemFontOfSize(13.0f);
        classicFont = TGBoldSystemFontOfSize(13.0f);
    });
    
    NSString *text = TGLocalized(@"Conversation.UnreadMessages");
    UIFont *effectiveFont = classicIOS6Style ? classicFont : font;
    CGSize textSize = [text sizeWithFont:effectiveFont];
    
    CGContextSaveGState(context);
    if (classicIOS6Style)
        CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 0.0f, UIColorRGBA(0xffffff, 0.9f).CGColor);
    CGContextSetFillColorWithColor(context, (classicIOS6Style ? TGClassicIOS6UnreadHeaderTextColor() : presentation.pallete.chatUnreadTextColor).CGColor);
    CGPoint textOrigin = CGPointMake(CGFloor((containerWidth - textSize.width) / 2) + 1, 7.0f + TGRetinaPixel);
    [text drawAtPoint:textOrigin withFont:effectiveFont];
    CGContextRestoreGState(context);
}

- (id)initWithFrame:(CGRect)frame presentation:(TGPresentation *)presentation
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.viewIdentifier = @"_unread";
        
        bool classicIOS6Style = [TGPresentation classicIOS6Style];
        _backgroundView = [[UIImageView alloc] initWithImage:classicIOS6Style ? TGClassicIOS6UnreadHeaderBackgroundImage() : presentation.images.chatUnreadBackground];
        [self addSubview:_backgroundView];
        
        _labelView = [[UILabel alloc] init];
        _labelView.backgroundColor = [UIColor clearColor];
        _labelView.textColor = classicIOS6Style ? TGClassicIOS6UnreadHeaderTextColor() : presentation.pallete.chatUnreadTextColor;
        _labelView.font = classicIOS6Style ? TGBoldSystemFontOfSize(13.0f) : TGSystemFontOfSize(13.0f);
        _labelView.shadowColor = classicIOS6Style ? UIColorRGBA(0xffffff, 0.9f) : [UIColor clearColor];
        _labelView.shadowOffset = classicIOS6Style ? CGSizeMake(0.0f, 1.0f) : CGSizeZero;
        _labelView.text = TGLocalized(@"Conversation.UnreadMessages");
        _labelView.transform = CGAffineTransformMakeRotation((CGFloat)M_PI);
        [_labelView sizeToFit];
        [self addSubview:_labelView];
    }
    return self;
}
- (void)setPresentation:(TGPresentation *)presentation
{
    bool classicIOS6Style = [TGPresentation classicIOS6Style];
    _backgroundView.image = classicIOS6Style ? TGClassicIOS6UnreadHeaderBackgroundImage() : presentation.images.chatUnreadBackground;
    _labelView.textColor = classicIOS6Style ? TGClassicIOS6UnreadHeaderTextColor() : presentation.pallete.chatUnreadTextColor;
    _labelView.font = classicIOS6Style ? TGBoldSystemFontOfSize(13.0f) : TGSystemFontOfSize(13.0f);
    _labelView.shadowColor = classicIOS6Style ? UIColorRGBA(0xffffff, 0.9f) : [UIColor clearColor];
    _labelView.shadowOffset = classicIOS6Style ? CGSizeMake(0.0f, 1.0f) : CGSizeZero;
    [_labelView sizeToFit];
}

- (void)willBecomeRecycled
{
}

- (void)updateAssets
{
}

- (void)layoutSubviews
{
    _backgroundView.frame = CGRectMake(0.0f, 3.0f, self.frame.size.width, 25.0f);
    CGRect labelFrame = _labelView.frame;
    labelFrame.origin = CGPointMake(CGFloor((self.frame.size.width - labelFrame.size.width) / 2.0f), 7.0f + TGRetinaPixel);
    _labelView.frame = labelFrame;
}

@end
