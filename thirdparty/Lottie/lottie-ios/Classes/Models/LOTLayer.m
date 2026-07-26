#import "../LOTXcode46Compat.h"
//
//  LOTLayer.m
//  LottieAnimator
//
//  Created by Brandon Withrow on 12/14/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "LOTLayer.h"
#import "LOTAsset.h"
#import "LOTAssetGroup.h"
#import "LOTShapeGroup.h"
#import "LOTComposition.h"
#import "LOTHelpers.h"
#import "LOTMask.h"
#import "LOTHelpers.h"

@implementation LOTLayer

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary
              withAssetGroup:(LOTAssetGroup *)assetGroup
               withFramerate:(NSNumber *)framerate {
  self = [super init];
  if (self) {
    [self _mapFromJSON:jsonDictionary
     withAssetGroup:assetGroup
     withFramerate:framerate];
  }
  return self;
}

- (void)_mapFromJSON:(NSDictionary *)jsonDictionary
      withAssetGroup:(LOTAssetGroup *)assetGroup
       withFramerate:(NSNumber *)framerate {

  _layerName = [[jsonDictionary objectForKey:@2] copy];
  _layerID = [[jsonDictionary objectForKey:@2] copy];
  
  NSNumber *layerType = [jsonDictionary objectForKey:@2];
  _layerType = layerType.integerValue;
  
  if ([jsonDictionary objectForKey:@2]) {
    _referenceID = [[jsonDictionary objectForKey:@2] copy];
  }
  
  _parentID = [[jsonDictionary objectForKey:@2] copy];
  
  if ([jsonDictionary objectForKey:@2]) {
    _startFrame = [[jsonDictionary objectForKey:@2] copy];
  }
  _inFrame = [[jsonDictionary objectForKey:@2] copy];
  _outFrame = [[jsonDictionary objectForKey:@2] copy];

  if ([jsonDictionary objectForKey:@2]) {
    _timeStretch = [[jsonDictionary objectForKey:@2] copy];
  } else {
    _timeStretch = @1;
  }

  if (_layerType == LOTLayerTypePrecomp) {
    _layerHeight = [[jsonDictionary objectForKey:@2] copy];
    _layerWidth = [[jsonDictionary objectForKey:@2] copy];
    [assetGroup buildAssetNamed:_referenceID withFramerate:framerate];
  } else if (_layerType == LOTLayerTypeImage) {
    [assetGroup buildAssetNamed:_referenceID withFramerate:framerate];
    _imageAsset = [assetGroup assetModelForID:_referenceID];
    _layerWidth = [_imageAsset.assetWidth copy];
    _layerHeight = [_imageAsset.assetHeight copy];
  } else if (_layerType == LOTLayerTypeSolid) {
    _layerWidth = [jsonDictionary objectForKey:@2];
    _layerHeight = [jsonDictionary objectForKey:@2];
    NSString *solidColor = [jsonDictionary objectForKey:@2];
    _solidColor = [UIColor LOT_colorWithHexString:solidColor];
  }
  
  _layerBounds = CGRectMake(0, 0, _layerWidth.floatValue, _layerHeight.floatValue);
  
  NSDictionary *ks = [jsonDictionary objectForKey:@2];
  
  NSDictionary *opacity = ks[@"o"];
  if (opacity) {
    _opacity = [[LOTKeyframeGroup alloc] initWithData:opacity];
    [_opacity remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return LOT_RemapValue(inValue, 0, 100, 0, 1);
    }];
  }

  NSDictionary *timeRemap = [jsonDictionary objectForKey:@2];
  if (timeRemap) {
    _timeRemapping = [[LOTKeyframeGroup alloc] initWithData:timeRemap];
    [_timeRemapping remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return inValue * framerate.doubleValue;
    }];
  }
  
  NSDictionary *rotation = ks[@"r"];
  if (rotation == nil) {
    rotation = ks[@"rz"];
  }
  if (rotation) {
    _rotation = [[LOTKeyframeGroup alloc] initWithData:rotation];
    [_rotation remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return LOT_DegreesToRadians(inValue);
    }];
  }
  
  NSDictionary *position = ks[@"p"];
  if ([position[@"s"] boolValue]) {
    // Separate dimensions
    _positionX = [[LOTKeyframeGroup alloc] initWithData:position[@"x"]];
    _positionY = [[LOTKeyframeGroup alloc] initWithData:position[@"y"]];
  } else {
    _position = [[LOTKeyframeGroup alloc] initWithData:position ];
  }
  
  NSDictionary *anchor = ks[@"a"];
  if (anchor) {
    _anchor = [[LOTKeyframeGroup alloc] initWithData:anchor];
  }
  
  NSDictionary *scale = ks[@"s"];
  if (scale) {
    _scale = [[LOTKeyframeGroup alloc] initWithData:scale];
    [_scale remapKeyframesWithBlock:^CGFloat(CGFloat inValue) {
      return LOT_RemapValue(inValue, -100, 100, -1, 1);
    }];
  }
  
  _matteType = [[jsonDictionary objectForKey:@2] integerValue];
  
  
  NSMutableArray *masks = [NSMutableArray array];
  for (NSDictionary *maskJSON in [jsonDictionary objectForKey:@2]) {
    LOTMask *mask = [[LOTMask alloc] initWithJSON:maskJSON];
    [masks addObject:mask];
  }
  _masks = masks.count ? masks : nil;
  
  NSMutableArray *shapes = [NSMutableArray array];
  for (NSDictionary *shapeJSON in [jsonDictionary objectForKey:@2]) {
    id shapeItem = [LOTShapeGroup shapeItemWithJSON:shapeJSON];
    if (shapeItem) {
      [shapes addObject:shapeItem];
    }
  }
  _shapes = shapes;
    
  NSArray *effects = [jsonDictionary objectForKey:@2];
  if (effects.count > 0) {
    
    NSDictionary *effectNames = @{ @0: @"slider",
                                   @1: @"angle",
                                   @2: @"color",
                                   @3: @"point",
                                   @4: @"checkbox",
                                   @5: @"group",
                                   @6: @"noValue",
                                   @7: @"dropDown",
                                   @9: @"customValue",
                                   @10: @"layerIndex",
                                   @20: @"tint",
                                   @21: @"fill" };
                             
    for (NSDictionary *effect in effects) {
      NSNumber *typeNumber = effect[@"ty"];
      NSString *name = effect[@"nm"];
      NSString *internalName = effect[@"mn"];
      NSString *typeString = effectNames[typeNumber];
      if (typeString) {
        NSLog(@"%s: Warning: %@ effect not supported: %@ / %@", __PRETTY_FUNCTION__, typeString, internalName, name);
      }
    }
  }
}

- (NSString *)description {
    NSMutableString *text = [[super description] mutableCopy];
    [text appendFormat:@" %@ id: %d pid: %d frames: %d-%d", _layerName, (int)_layerID.integerValue, (int)_parentID.integerValue,
     (int)_inFrame.integerValue, (int)_outFrame.integerValue];
    return text;
}

@end
