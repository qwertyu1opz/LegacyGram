#import "../LOTXcode46Compat.h"
//
//  LOTShapePath.m
//  LottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "LOTShapePath.h"

@implementation LOTShapePath

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
  
  _index = [jsonDictionary objectForKey:@2];
  _closed = [[jsonDictionary objectForKey:@2] boolValue];
  NSDictionary *shape = [jsonDictionary objectForKey:@2];
  if (shape) {
    _shapePath = [[LOTKeyframeGroup alloc] initWithData:shape];
  }
}

@end
