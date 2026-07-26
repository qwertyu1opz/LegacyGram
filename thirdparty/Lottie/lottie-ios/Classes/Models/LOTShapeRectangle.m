#import "../LOTXcode46Compat.h"
//
//  LOTShapeRectangle.m
//  LottieAnimator
//
//  Created by Brandon Withrow on 12/15/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "LOTShapeRectangle.h"

@implementation LOTShapeRectangle

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
  
  NSDictionary *cornerRadius = [jsonDictionary objectForKey:@2];
  if (cornerRadius) {
    _cornerRadius = [[LOTKeyframeGroup alloc] initWithData:cornerRadius];
  }
  
  NSDictionary *size = [jsonDictionary objectForKey:@2];
  if (size) {
    _size = [[LOTKeyframeGroup alloc] initWithData:size];
  }
  NSNumber *reversed = [jsonDictionary objectForKey:@2];
  _reversed = (reversed.integerValue == 3);
}

@end
