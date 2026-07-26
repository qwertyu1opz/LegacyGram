#import "../LOTXcode46Compat.h"
//
//  LOTShapeStar.m
//  Lottie
//
//  Created by brandon_withrow on 7/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTShapeStar.h"

@implementation LOTShapeStar

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
  
  NSDictionary *outerRadius = [jsonDictionary objectForKey:@2];
  if (outerRadius) {
    _outerRadius = [[LOTKeyframeGroup alloc] initWithData:outerRadius];
  }
  
  NSDictionary *outerRoundness = [jsonDictionary objectForKey:@2];
  if (outerRoundness) {
    _outerRoundness = [[LOTKeyframeGroup alloc] initWithData:outerRoundness];
  }
  
  NSDictionary *innerRadius = [jsonDictionary objectForKey:@2];
  if (innerRadius) {
    _innerRadius = [[LOTKeyframeGroup alloc] initWithData:innerRadius];
  }
  
  NSDictionary *innerRoundness = [jsonDictionary objectForKey:@2];
  if (innerRoundness) {
    _innerRoundness = [[LOTKeyframeGroup alloc] initWithData:innerRoundness];
  }
  
  NSDictionary *position = [jsonDictionary objectForKey:@2];
  if (position) {
    _position = [[LOTKeyframeGroup alloc] initWithData:position];
  }
  
  NSDictionary *numberOfPoints = [jsonDictionary objectForKey:@2];
  if (numberOfPoints) {
    _numberOfPoints = [[LOTKeyframeGroup alloc] initWithData:numberOfPoints];
  }
  
  NSDictionary *rotation = [jsonDictionary objectForKey:@2];
  if (rotation) {
    _rotation = [[LOTKeyframeGroup alloc] initWithData:rotation];
  }
  
  NSNumber *type = [jsonDictionary objectForKey:@2];
  _type = type.integerValue;
}

@end
