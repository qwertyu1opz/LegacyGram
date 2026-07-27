#import "../LOTXcode46Compat.h"
//
//  LOTShapeFill.m
//  LottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "LOTShapeFill.h"
#import "CGGeometry+LOTAdditions.h"

@implementation LOTShapeFill

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
  
  NSDictionary *color = [jsonDictionary objectForKey:@2];
  if (color) {
    _color = [[LOTKeyframeGroup alloc] initWithData:color];
  }
  
  NSDictionary *opacity = [jsonDictionary objectForKey:@2];
  if (opacity) {
    _opacity = [[LOTKeyframeGroup alloc] initWithData:opacity];
    [_opacity remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return LOT_RemapValue(inValue, 0, 100, 0, 1);
    }];
  }
  
  NSNumber *evenOdd = [jsonDictionary objectForKey:@2];
  if (evenOdd.integerValue == 2) {
    _evenOddFillRule = YES;
  } else {
    _evenOddFillRule = NO;
  }
  
  NSNumber *fillEnabled = [jsonDictionary objectForKey:@2];
  _fillEnabled = fillEnabled.boolValue;
}

@end
