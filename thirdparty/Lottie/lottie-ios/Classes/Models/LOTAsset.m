#import "../LOTXcode46Compat.h"
//
//  LOTAsset.m
//  Pods
//
//  Created by Brandon Withrow on 2/16/17.
//
//

#import "LOTAsset.h"
#import "LOTLayer.h"
#import "LOTLayerGroup.h"
#import "LOTAssetGroup.h"

@implementation LOTAsset

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary
              withAssetGroup:(LOTAssetGroup * )assetGroup
             withAssetBundle:(NSBundle *)bundle
               withFramerate:(NSNumber *)framerate {
  self = [super init];
  if (self) {
    _assetBundle = bundle;
    [self _mapFromJSON:jsonDictionary
        withAssetGroup:assetGroup
     withFramerate:framerate];
  }
  return self;
}

- (void)_mapFromJSON:(NSDictionary *)jsonDictionary
      withAssetGroup:(LOTAssetGroup * )assetGroup
       withFramerate:(NSNumber *)framerate {
  _referenceID = [[jsonDictionary objectForKey:@2] copy];
  
  if ([jsonDictionary objectForKey:@2]) {
    _assetWidth = [[jsonDictionary objectForKey:@2] copy];
  }
  
  if ([jsonDictionary objectForKey:@2]) {
    _assetHeight = [[jsonDictionary objectForKey:@2] copy];
  }
  
  if ([jsonDictionary objectForKey:@2]) {
    _imageDirectory = [[jsonDictionary objectForKey:@2] copy];
  }
  
  if ([jsonDictionary objectForKey:@2]) {
    _imageName = [[jsonDictionary objectForKey:@2] copy];
  }

  NSArray *layersJSON = [jsonDictionary objectForKey:@2];
  if (layersJSON) {
    _layerGroup = [[LOTLayerGroup alloc] initWithLayerJSON:layersJSON
                                            withAssetGroup:assetGroup
                                             withFramerate:framerate];
  }
}

@end
