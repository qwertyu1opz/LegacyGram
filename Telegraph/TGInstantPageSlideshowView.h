 #import <UIKit/UIKit.h>

#import "TGInstantPageDisplayView.h"
#import "TGInstantPageLayout.h"

@class TGInstantPageMedia;

@interface TGInstantPageSlideshowView : UIView <TGInstantPageDisplayView>

@property (nonatomic, strong, readonly) NSArray *medias;

- (instancetype)initWithFrame:(CGRect)frame medias:(NSArray *)medias;

@end
