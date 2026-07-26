#import "../LOTXcode46Compat.h"
//
//  LOTShapeTransform.m
//  LottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "LOTShapeTransform.h"
#import "LOTHelpers.h"

@implementation LOTShapeTransform

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary {
  self = [super init];
  if (self) {
    [self _mapFromJSON:jsonDictionary];
  }
  return self;
}

- (void)_mapFromJSON:(NSDictionary *)jsonDictionary {
  
  if ([jsonDictionary objectForKey:@2] ) {
    _keyname = [[jsonDictionary objectForKey:@2] copy];
  }
  
  NSDictionary *position = [jsonDictionary objectForKey:@2];
  if (position) {
    _position = [[LOTKeyframeGroup alloc] initWithData:position];
  }
  
  NSDictionary *anchor = [jsonDictionary objectForKey:@2];
  if (anchor) {
    _anchor = [[LOTKeyframeGroup alloc] initWithData:anchor];
  }
  
  NSDictionary *scale = [jsonDictionary objectForKey:@2];
  if (scale) {
    _scale = [[LOTKeyframeGroup alloc] initWithData:scale];
    [_scale remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return LOT_RemapValue(inValue, -100, 100, -1, 1);
    }];
  }
  
  NSDictionary *rotation = [jsonDictionary objectForKey:@2];
  if (rotation) {
    _rotation = [[LOTKeyframeGroup alloc] initWithData:rotation];
    [_rotation remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return LOT_DegreesToRadians(inValue);
    }];
  }
  
  NSDictionary *opacity = [jsonDictionary objectForKey:@2];
  if (opacity) {
    _opacity = [[LOTKeyframeGroup alloc] initWithData:opacity];
    [_opacity remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return LOT_RemapValue(inValue, 0, 100, 0, 1);
    }];
  }
  
  NSString *name = [jsonDictionary objectForKey:@2];
  
  NSDictionary *skew = [jsonDictionary objectForKey:@2];
  BOOL hasSkew = (skew && [skew[@"k"] isEqual:@0] == NO);
  NSDictionary *skewAxis = [jsonDictionary objectForKey:@2];
  BOOL hasSkewAxis = (skewAxis && [skewAxis[@"k"] isEqual:@0] == NO);
  
  if (hasSkew || hasSkewAxis) {
    NSLog(@"%s: Warning: skew is not supported: %@", __PRETTY_FUNCTION__, name);
  }
}

- (NSString *)description {
  return [NSString stringWithFormat:@"LOTShapeTransform \"Position: %@ Anchor: %@ Scale: %@ Rotation: %@ Opacity: %@\"", _position.description, _anchor.description, _scale.description, _rotation.description, _opacity.description];
}

@end
