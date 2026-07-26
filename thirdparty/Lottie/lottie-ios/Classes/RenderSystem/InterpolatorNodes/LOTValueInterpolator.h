#import "../../LOTXcode46Compat.h"
//
//  LOTValueInterpolator.h
//  Pods
//
//  Created by brandon_withrow on 7/10/17.
//
//

#import <Foundation/Foundation.h>
#import "LOTKeyframe.h"
#import "LOTValueDelegate.h"



@interface LOTValueInterpolator : NSObject

- (instancetype)initWithKeyframes:(NSArray *)keyframes;

@property (nonatomic, weak) LOTKeyframe *leadingKeyframe;
@property (nonatomic, weak) LOTKeyframe *trailingKeyframe;
@property (nonatomic, readonly) BOOL hasDelegateOverride;

- (void)setValueDelegate:(id<LOTValueDelegate> )delegate;

- (BOOL)hasUpdateForFrame:(NSNumber *)frame;
- (CGFloat)progressForFrame:(NSNumber *)frame;

@end


