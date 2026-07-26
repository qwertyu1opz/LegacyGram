#import "TGPinnedMessageTitlePanel.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGMenuSheetController.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGModernButton.h"

#import <QuartzCore/QuartzCore.h>

#import "TGModenConcersationReplyAssociatedPanel.h"

#import "TGPresentation.h"

static UIImage *TGClassicIOS6PinnedPanelBackgroundImage(void)
{
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        CGSize size = CGSizeMake(2.0f, 29.0f);
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
        CGContextSetFillColorWithColor(context, UIColorRGB(0x6d7884).CGColor);
        CGContextFillRect(context, CGRectMake(0.0f, size.height - 1.0f, size.width, 1.0f));
        CGContextSetFillColorWithColor(context, UIColorRGBA(0xffffff, 0.35f).CGColor);
        CGContextFillRect(context, CGRectMake(0.0f, size.height - 2.0f, size.width, 1.0f));

        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return image;
}

@interface TGPinnedMessageChevronView : UIView
{
    UIColor *_color;
}

@property (nonatomic, strong) UIColor *color;

@end


@implementation TGPinnedMessageChevronView

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    if (self != nil)
    {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = false;
        _color = UIColorRGB(0xb5b5b5);
    }
    return self;
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self setNeedsDisplay];
}

- (UIColor *)color
{
    return _color;
}

- (void)drawRect:(CGRect)__unused rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, _color.CGColor);
    CGContextSetLineWidth(context, 1.5f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextMoveToPoint(context, 1.0f, 1.0f);
    CGContextAddLineToPoint(context, 6.0f, 7.0f);
    CGContextAddLineToPoint(context, 1.0f, 13.0f);
    CGContextStrokePath(context);
}

@end


@interface TGPinnedMessagesMenuHeaderItemView ()
{
    UILabel *_titleLabel;
    UIView *_countBackgroundView;
    UILabel *_countLabel;
    UIView *_separatorView;
}

@end


@implementation TGPinnedMessagesMenuHeaderItemView

- (instancetype)initWithMessageCount:(NSUInteger)messageCount
{
    self = [super initWithType:TGMenuSheetItemTypeDefault];
    if (self != nil)
    {
        NSString *title = TGLocalized(@"Channel.AdminLogFilter.EventsPinned");
        if ([title isEqualToString:@"Channel.AdminLogFilter.EventsPinned"])
            title = TGLocalized(@"Conversation.PinnedMessage");

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = TGMediumSystemFontOfSize(17.0f);
        _titleLabel.textColor = UIColorRGB(0x222222);
        _titleLabel.text = title;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_titleLabel];

        _countBackgroundView = [[UIView alloc] init];
        _countBackgroundView.userInteractionEnabled = false;
        _countBackgroundView.backgroundColor = TGAccentColor();
        _countBackgroundView.layer.cornerRadius = 12.0f;
        [self addSubview:_countBackgroundView];

        _countLabel = [[UILabel alloc] init];
        _countLabel.backgroundColor = [UIColor clearColor];
        _countLabel.font = TGMediumSystemFontOfSize(12.0f);
        _countLabel.textColor = [UIColor whiteColor];
        _countLabel.textAlignment = NSTextAlignmentCenter;
        _countLabel.text = [NSString stringWithFormat:@"%d", (int)messageCount];
        _countLabel.adjustsFontSizeToFitWidth = true;
        _countLabel.minimumScaleFactor = 0.7f;
        [_countBackgroundView addSubview:_countLabel];

        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = UIColorRGB(0xd9d9d9);
        [self addSubview:_separatorView];
    }
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)__unused width screenHeight:(CGFloat)__unused screenHeight
{
    return 52.0f;
}

- (bool)requiresDivider
{
    return false;
}

- (void)setDark
{
    _titleLabel.textColor = [UIColor whiteColor];
    _separatorView.backgroundColor = UIColorRGB(0x383838);
}

- (void)setPallete:(TGMenuSheetPallete *)pallete
{
    _titleLabel.textColor = pallete.textColor;
    _countBackgroundView.backgroundColor = pallete.accentColor;
    _separatorView.backgroundColor = pallete.separatorColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat countSize = 24.0f;
    _countBackgroundView.frame = CGRectMake(self.bounds.size.width - 16.0f - countSize, 14.0f, countSize, countSize);
    _countBackgroundView.layer.cornerRadius = countSize / 2.0f;
    _countLabel.frame = _countBackgroundView.bounds;
    _titleLabel.frame = CGRectMake(16.0f, 0.0f, self.bounds.size.width - 16.0f - countSize - 26.0f, self.bounds.size.height);
    _separatorView.frame = CGRectMake(16.0f, self.bounds.size.height - TGScreenPixel, self.bounds.size.width - 16.0f, TGScreenPixel);
}

@end


@interface TGPinnedMessageMenuItemView ()
{
    UIView *_indexBackgroundView;
    UILabel *_indexLabel;
    UILabel *_messageLabel;
    TGPinnedMessageChevronView *_chevronView;
    UIView *_separatorView;
}

@end


@implementation TGPinnedMessageMenuItemView

- (instancetype)initWithTitle:(NSString *)title index:(NSUInteger)index action:(void (^)(void))action
{
    self = [super initWithTitle:@"" type:TGMenuSheetButtonTypeDefault action:action];
    if (self != nil)
    {
        _button.accessibilityLabel = title;
        _button.titleLabel.adjustsFontSizeToFitWidth = false;

        _indexBackgroundView = [[UIView alloc] init];
        _indexBackgroundView.userInteractionEnabled = false;
        _indexBackgroundView.backgroundColor = TGAccentColor();
        _indexBackgroundView.layer.cornerRadius = 14.0f;
        [self addSubview:_indexBackgroundView];

        _indexLabel = [[UILabel alloc] init];
        _indexLabel.backgroundColor = [UIColor clearColor];
        _indexLabel.font = TGMediumSystemFontOfSize(12.0f);
        _indexLabel.textColor = [UIColor whiteColor];
        _indexLabel.textAlignment = NSTextAlignmentCenter;
        _indexLabel.text = [NSString stringWithFormat:@"%d", (int)index + 1];
        _indexLabel.adjustsFontSizeToFitWidth = true;
        _indexLabel.minimumScaleFactor = 0.65f;
        [_indexBackgroundView addSubview:_indexLabel];

        _messageLabel = [[UILabel alloc] init];
        _messageLabel.userInteractionEnabled = false;
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.font = TGSystemFontOfSize(15.5f);
        _messageLabel.textColor = UIColorRGB(0x222222);
        _messageLabel.numberOfLines = 2;
        _messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _messageLabel.text = title;
        [self addSubview:_messageLabel];

        _chevronView = [[TGPinnedMessageChevronView alloc] init];
        [self addSubview:_chevronView];

        _separatorView = [[UIView alloc] init];
        _separatorView.userInteractionEnabled = false;
        _separatorView.backgroundColor = UIColorRGB(0xd9d9d9);
        [self addSubview:_separatorView];
    }
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)__unused width screenHeight:(CGFloat)__unused screenHeight
{
    return 64.0f;
}

- (bool)requiresDivider
{
    return false;
}

- (void)setDark
{
    [super setDark];
    _messageLabel.textColor = [UIColor whiteColor];
    _separatorView.backgroundColor = UIColorRGB(0x383838);
    _chevronView.color = UIColorRGB(0x666666);
}

- (void)setPallete:(TGMenuSheetPallete *)pallete
{
    [super setPallete:pallete];
    _messageLabel.textColor = pallete.textColor;
    _indexBackgroundView.backgroundColor = pallete.accentColor;
    _separatorView.backgroundColor = pallete.separatorColor;
    _chevronView.color = pallete.secondaryTextColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat indexSize = 28.0f;
    _indexBackgroundView.frame = CGRectMake(14.0f, floor((self.bounds.size.height - indexSize) / 2.0f), indexSize, indexSize);
    _indexBackgroundView.layer.cornerRadius = indexSize / 2.0f;
    _indexLabel.frame = _indexBackgroundView.bounds;
    _messageLabel.frame = CGRectMake(54.0f, 8.0f, self.bounds.size.width - 54.0f - 34.0f, self.bounds.size.height - 16.0f);
    _chevronView.frame = CGRectMake(self.bounds.size.width - 21.0f, floor((self.bounds.size.height - 14.0f) / 2.0f), 8.0f, 14.0f);
    _separatorView.frame = CGRectMake(54.0f, self.bounds.size.height - TGScreenPixel, self.bounds.size.width - 54.0f, TGScreenPixel);
}

@end

@interface TGPinnedMessageTitlePanel () {
    TGModenConcersationReplyAssociatedPanel *_replyPanel;
    UIView *_separatorView;
    UIImageView *_classicIOS6BackgroundView;
}

@end

@implementation TGPinnedMessageTitlePanel

- (instancetype)initWithMessage:(TGMessage *)message {
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 29.0f)];
    if (self != nil) {
        _message = message;
        self.clipsToBounds = true;

        _classicIOS6BackgroundView = [[UIImageView alloc] initWithImage:TGClassicIOS6PinnedPanelBackgroundImage()];
        _classicIOS6BackgroundView.userInteractionEnabled = false;
        _classicIOS6BackgroundView.hidden = ![TGPresentation classicIOS6Style];
        [self addSubview:_classicIOS6BackgroundView];
        
        _replyPanel = [[TGModenConcersationReplyAssociatedPanel alloc] initWithMessage:message];
        _replyPanel.compactMode = true;
        [_replyPanel setSendAreaWidth:14.0f - TGRetinaPixel attachmentAreaWidth:6.0f];
        _replyPanel.largeDismissButton = true;
        __weak TGPinnedMessageTitlePanel *weakSelf = self;
        _replyPanel.pressed = ^{
            __strong TGPinnedMessageTitlePanel *strongSelf = weakSelf;
            if (strongSelf != nil && strongSelf->_tapped) {
                strongSelf->_tapped();
            }
        };
        _replyPanel.dismiss = ^{
            __strong TGPinnedMessageTitlePanel *strongSelf = weakSelf;
            if (strongSelf != nil && strongSelf.dismiss) {
                strongSelf.dismiss();
            }
        };
        [self addSubview:_replyPanel];
        self.backgroundColor = [TGPresentation classicIOS6Style] ? [UIColor clearColor] : UIColorRGB(0xf7f7f7);
        
        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = [TGPresentation classicIOS6Style] ? UIColorRGB(0x6d7884) : TGSeparatorColor();
        [self addSubview:_separatorView];
        
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)]];
    }
    return self;
}

- (void)setPresentation:(TGPresentation *)presentation
{
    [super setPresentation:presentation];
    
    bool classicIOS6Style = [TGPresentation classicIOS6Style];
    _classicIOS6BackgroundView.hidden = !classicIOS6Style;
    self.backgroundColor = classicIOS6Style ? [UIColor clearColor] : presentation.pallete.barBackgroundColor;
    _separatorView.backgroundColor = classicIOS6Style ? UIColorRGB(0x6d7884) : presentation.pallete.barSeparatorColor;
    _replyPanel.pallete = presentation.associatedInputPanelPallete;
}

- (void)updateMessage:(TGMessage *)message {
    _message = message;
    [_replyPanel updateMessage:message];
}

- (void)setMessageCount:(NSUInteger)messageCount {
    _replyPanel.compactPrefix = messageCount > 1 ? [NSString stringWithFormat:@"%d", (int)messageCount] : nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat separatorHeight = TGScreenPixel;
    _separatorView.frame = CGRectMake(0.0f, self.frame.size.height - separatorHeight, self.frame.size.width, separatorHeight);
    _classicIOS6BackgroundView.frame = self.bounds;
    
    _replyPanel.frame = CGRectMake(self.safeAreaInset.left, 0.0f, self.frame.size.width - self.safeAreaInset.left - self.safeAreaInset.right, 28.0f);
}

- (void)tapGesture:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (_tapped) {
            _tapped();
        }
    }
}

@end
