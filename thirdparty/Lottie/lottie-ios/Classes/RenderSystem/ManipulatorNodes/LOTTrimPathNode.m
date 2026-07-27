#import "../../LOTXcode46Compat.h"
//
//  LOTTrimPathNode.m
//  Lottie
//
//  Created by brandon_withrow on 7/21/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTTrimPathNode.h"
#import "LOTNumberInterpolator.h"
#import "LOTPathAnimator.h"
#import "LOTCircleAnimator.h"
#import "LOTRoundedRectAnimator.h"
#import "LOTRenderGroup.h"

@implementation LOTTrimPathNode {
  LOTNumberInterpolator *_startInterpolator;
  LOTNumberInterpolator *_endInterpolator;
  LOTNumberInterpolator *_offsetInterpolator;
  
  CGFloat _startT;
  CGFloat _endT;
  CGFloat _offsetT;
}

- (instancetype )initWithInputNode:(LOTAnimatorNode *)inputNode
                                   trimPath:(LOTShapeTrimPath *)trimPath {
  self = [super initWithInputNode:inputNode keyName:trimPath.keyname];
  if (self) {
    inputNode.pathShouldCacheLengths = YES;
    _startInterpolator = [[LOTNumberInterpolator alloc] initWithKeyframes:trimPath.start.keyframes];
    _endInterpolator = [[LOTNumberInterpolator alloc] initWithKeyframes:trimPath.end.keyframes];
    _offsetInterpolator = [[LOTNumberInterpolator alloc] initWithKeyframes:trimPath.offset.keyframes];
  }
  return self;
}

- (NSDictionary *)valueInterpolators {
  return @{@"Start" : _startInterpolator,
           @"End" : _endInterpolator,
           @"Offset" : _offsetInterpolator};
}

- (BOOL)needsUpdateForFrame:(NSNumber *)frame {
  return ([_startInterpolator hasUpdateForFrame:frame] ||
          [_endInterpolator hasUpdateForFrame:frame] ||
          [_offsetInterpolator hasUpdateForFrame:frame]);
}

- (BOOL)updateWithFrame:(NSNumber *)frame
      withModifierBlock:(void (^ )(LOTAnimatorNode * ))modifier
       forceLocalUpdate:(BOOL)forceUpdate {
  BOOL localUpdate = [self needsUpdateForFrame:frame];
  [self forceSetCurrentFrame:frame];
  if (localUpdate) {
    [self performLocalUpdate];
  }
  if (self.inputNode == nil) {
    return localUpdate;
  }
  
  BOOL inputUpdated = [self.inputNode updateWithFrame:frame withModifierBlock:^(LOTAnimatorNode *  inputNode) {
    if ([inputNode isKindOfClass:[LOTPathAnimator class]] ||
        [inputNode isKindOfClass:[LOTCircleAnimator class]] ||
        [inputNode isKindOfClass:[LOTRoundedRectAnimator class]]) {
      [inputNode.localPath trimPathFromT:_startT toT:_endT offset:_offsetT];
    }
    if (modifier) {
      modifier(inputNode);
    }
    
  } forceLocalUpdate:(localUpdate || forceUpdate)];
  
  return inputUpdated;
}

- (void)performLocalUpdate {
  _startT = [_startInterpolator floatValueForFrame:self.currentFrame] / 100;
  _endT = [_endInterpolator floatValueForFrame:self.currentFrame] / 100;
  _offsetT = [_offsetInterpolator floatValueForFrame:self.currentFrame] / 360;
}

- (void)rebuildOutputs {
  // Skip this step.
}

- (LOTBezierPath *)localPath {
  return self.inputNode.localPath;
}

/// Forwards its input node's output path forwards downstream
- (LOTBezierPath *)outputPath {
  return self.inputNode.outputPath;
}

@end
