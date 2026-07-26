#import "../LOTXcode46Compat.h"
//
//  LOTShapeTrimPath.m
//  LottieAnimator
//
//  Created by brandon_withrow on 7/26/16.
//  Copyright © 2016 Brandon Withrow. All rights reserved.
//

#import "LOTShapeTrimPath.h"

@implementation LOTShapeTrimPath

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
  
  NSDictionary *start = [jsonDictionary objectForKey:@2];
  if (start) {
    _start = [[LOTKeyframeGroup alloc] initWithData:start];
  }
  
  NSDictionary *end = [jsonDictionary objectForKey:@2];
  if (end) {
    _end = [[LOTKeyframeGroup alloc] initWithData:end];
  }
  
  NSDictionary *offset = [jsonDictionary objectForKey:@2];
  if (offset) {
    _offset = [[LOTKeyframeGroup alloc] initWithData:offset];
  }
}

@end
