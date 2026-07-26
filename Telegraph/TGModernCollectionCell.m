#import "TGModernCollectionCell.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGMessageModernConversationItem.h"
#import "TGModernFlatteningViewModel.h"

@interface TGModernCollectionCellLayer : CALayer

@end

@implementation TGModernCollectionCellLayer

- (void)setShouldRasterize:(BOOL)shouldRasterize
{
    if (shouldRasterize)
        [super setShouldRasterize:false];
}

- (void)setHidden:(BOOL)hidden
{
    if (hidden && [[[UIDevice currentDevice] systemVersion] intValue] <= 6 && self.bounds.size.height > TGModernFlatteningViewModelTilingLimit)
    {
        [super setHidden:NO];
        return;
    }

    [super setHidden:hidden];
}

@end

@interface TGModernCollectionCell ()
{
    bool _editing;
    UIView *_contentViewForBinding;
}

@end

@implementation TGModernCollectionCell

static bool IOS6KeepTallMessageCellVisible(CGRect frame)
{
    return [[[UIDevice currentDevice] systemVersion] intValue] <= 6 && frame.size.height > TGModernFlatteningViewModelTilingLimit;
}

+ (Class)layerClass
{
    return [TGModernCollectionCellLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        [self contentViewForBinding].transform = CGAffineTransformMakeRotation((float)M_PI);
        self.clipsToBounds = true;
        
        _contentViewForBinding = [[UIView alloc] initWithFrame:(CGRect){CGPointZero, frame.size}];
        _contentViewForBinding.transform = CGAffineTransformMakeRotation((float)M_PI);
        [self addSubview:_contentViewForBinding];
    }
    return self;
}

- (void)relativeBoundsUpdated:(CGRect)bounds
{
    id item = _boundItem;
    if (item != nil && [item conformsToProtocol:@protocol(TGModernCollectionRelativeBoundsObserver)])
    {
        CGRect convertedBounds = [[self contentViewForBinding] convertRect:bounds fromView:self];
        [item relativeBoundsUpdated:self bounds:convertedBounds];
    }
}

- (void)setEditing:(bool)editing animated:(bool)__unused animated viewStorage:(TGModernViewStorage *)__unused viewStorage
{
    if (_editing != editing)
    {
        _editing = editing;
        [self contentViewForBinding].userInteractionEnabled = !_editing;
    }
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];

    if (IOS6KeepTallMessageCellVisible(layoutAttributes.frame))
    {
        // UICollectionView on iOS 6 sometimes reuses the layout attributes
        // of a tall off-screen cell during a fast inertial jump.  The frame
        // is corrected, but alpha/opacity (or the binding container's hidden
        // flag) remains in the off-screen state.  The text tiles are present
        // and have contents, yet Core Animation composites a blank cell.
        // Restore the complete visibility chain for tall cells only.
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [super setHidden:NO];
        self.alpha = 1.0f;
        self.layer.hidden = false;
        self.layer.opacity = 1.0f;
        self.contentView.hidden = false;
        self.contentView.alpha = 1.0f;
        _contentViewForBinding.hidden = false;
        _contentViewForBinding.alpha = 1.0f;
        [CATransaction commit];
    }
}

- (void)setHidden:(BOOL)hidden
{
    if (hidden && IOS6KeepTallMessageCellVisible(self.frame))
        hidden = NO;

    [super setHidden:hidden];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];

    if (IOS6KeepTallMessageCellVisible(frame) && self.hidden)
        [super setHidden:NO];

    if (IOS6KeepTallMessageCellVisible(frame))
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.alpha = 1.0f;
        self.layer.hidden = false;
        self.layer.opacity = 1.0f;
        self.contentView.hidden = false;
        self.contentView.alpha = 1.0f;
        _contentViewForBinding.hidden = false;
        _contentViewForBinding.alpha = 1.0f;
        [CATransaction commit];
    }
    
    _contentViewForBinding.frame = (CGRect){CGPointZero, frame.size};
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    _contentViewForBinding.frame = (CGRect){CGPointZero, bounds.size};
}

- (UIView *)contentViewForBinding
{
    return _contentViewForBinding;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    bool initial = [super pointInside:point withEvent:event];
    
    id item = _boundItem;
    if (initial && item != nil && [item conformsToProtocol:@protocol(TGModernCollectionPointInsideSolver)])
    {
        if ([item pointInside] != nil)
        {
            CGPoint convertedPoint = [[self contentViewForBinding] convertPoint:point fromView:self];
            return [item pointInside](convertedPoint);
        }
    }
    
    return initial;
}

@end
