#import "../LOTXcode46Compat.h"
//
//  LOTAssetGroup.m
//  Pods
//
//  Created by Brandon Withrow on 2/17/17.
//
//

#import "LOTAssetGroup.h"
#import "LOTAsset.h"

@implementation LOTAssetGroup {
  NSMutableDictionary *_assetMap;
  NSDictionary *_assetJSONMap;
}

- (instancetype )initWithJSON:(NSArray * )jsonArray
                      withAssetBundle:(NSBundle * )bundle
                        withFramerate:(NSNumber * )framerate {
  self = [super init];
  if (self) {
    _assetBundle = bundle;
    _assetMap = [NSMutableDictionary dictionary];
    NSMutableDictionary *assetJSONMap = [NSMutableDictionary dictionary];
    for (NSDictionary *assetDictionary in jsonArray) {
      NSString *referenceID = [assetDictionary objectForKey:@2];
      if (referenceID) {
        assetJSONMap[referenceID] = assetDictionary;
      }
    }
    _assetJSONMap = assetJSONMap;
  }
  return self;
}

- (void)buildAssetNamed:(NSString *)refID
          withFramerate:(NSNumber * )framerate {
  
  if ([self assetModelForID:refID]) {
    return;
  }
  
  NSDictionary *assetDictionary = _assetJSONMap[refID];
  if (assetDictionary) {
    LOTAsset *asset = [[LOTAsset alloc] initWithJSON:assetDictionary
                                      withAssetGroup:self
                                     withAssetBundle:_assetBundle
                                       withFramerate:framerate];
    _assetMap[refID] = asset;
  }
}

- (void)finalizeInitializationWithFramerate:(NSNumber * )framerate {
  for (NSString *refID in _assetJSONMap.allKeys) {
    [self buildAssetNamed:refID withFramerate:framerate];
  }
  _assetJSONMap = nil;
}

- (LOTAsset *)assetModelForID:(NSString *)assetID {
  return _assetMap[assetID];
}

- (void)setRootDirectory:(NSString *)rootDirectory {
    _rootDirectory = rootDirectory;
    [_assetMap enumerateKeysAndObjectsUsingBlock:^(NSString *  key, LOTAsset *  obj, BOOL *  stop) {
        obj.rootDirectory = rootDirectory;
    }];
}
@end
