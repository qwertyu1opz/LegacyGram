#import <Foundation/Foundation.h>

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGInstantPageDisplayView.h"
#import "TGInstantPageLinkSelectionView.h"
#import "TGInstantPageMedia.h"

@class TGPIPSourceLocation;

typedef enum {
    TGInstantPagePresentationThemeDefault,
    TGInstantPagePresentationThemeBrown,
    TGInstantPagePresentationThemeGray,
    TGInstantPagePresentationThemeBlack
} TGInstantPagePresentationTheme;

@protocol TGInstantPageLayoutItem <NSObject>

@property (nonatomic) CGRect frame;

- (bool)hasLinks;
- (NSArray *)medias;

@optional

- (bool)hasText;
- (bool)matchesAnchor:(NSString *)anchor;
- (void)drawInTile;
- (UIView<TGInstantPageDisplayView> *)view;
- (bool)matchesView:(UIView<TGInstantPageDisplayView> *)view;
- (bool)matchesEmbedIndex:(int32_t)embedIndex;
- (TGInstantPageTextSelectionView *)textSelectionView;
- (NSArray *)linkSelectionViews;

- (int32_t)distanceThresholdGroup;
- (CGFloat)distanceThresholdWithGroupCount:(NSDictionary *)groupCount;

- (NSArray *)audios;

@end

@interface TGInstantPagePresentation : NSObject

@property (nonatomic, readonly) CGFloat fontSizeMultiplier;
@property (nonatomic, readonly) bool fontSerif;
@property (nonatomic, readonly) TGInstantPagePresentationTheme theme;
@property (nonatomic, readonly) TGInstantPagePresentationTheme initialTheme;
@property (nonatomic, readonly) bool forceAutoNight;

@property (nonatomic, readonly) UIColor *backgroundColor;

@property (nonatomic, readonly) UIColor *textColor;
@property (nonatomic, readonly) UIColor *titleColor;
@property (nonatomic, readonly) UIColor *subtextColor;

@property (nonatomic, readonly) UIColor *linkColor;
@property (nonatomic, readonly) UIColor *actionColor;
@property (nonatomic, readonly) UIColor *textSelectionColor;

@property (nonatomic, readonly) UIColor *panelColor;
@property (nonatomic, readonly) UIColor *panelHighlightColor;
@property (nonatomic, readonly) UIColor *panelTextColor;
@property (nonatomic, readonly) UIColor *panelSubtextColor;

+ (instancetype)presentationWithFontSizeMultiplier:(CGFloat)fontSizeMultiplier fontSerif:(bool)fontSerif theme:(TGInstantPagePresentationTheme)theme forceAutoNight:(bool)forceAutoNight;

@end

@interface TGInstantPageLayout : NSObject

@property (nonatomic, readonly) CGPoint origin;
@property (nonatomic, readonly) CGSize contentSize;
@property (nonatomic, strong, readonly) NSArray *items;

- (instancetype)initWithOrigin:(CGPoint)origin contentSize:(CGSize)contentSize items:(NSArray *)items;

+ (TGInstantPageLayout *)makeLayoutForWebPage:(TGWebPageMediaAttachment *)webPage peerId:(int64_t)peerId messageId:(int32_t)messageId boundingWidth:(CGFloat)boundingWidth safeAreaInset:(UIEdgeInsets)safeAreaInset presentation:(TGInstantPagePresentation *)presentation showFeedbackButton:(bool)showFeedbackButto;

@end
