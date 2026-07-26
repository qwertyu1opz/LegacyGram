#import <Foundation/Foundation.h>

#import "TGInstantPageLayout.h"

@interface TGInstantPageTile : NSObject

@property (nonatomic, readonly) CGRect frame;

+ (NSArray *)tilesWithLayout:(TGInstantPageLayout *)layout boundingWidth:(CGFloat)boundingWidth;

- (void)drawInContext;

@end
