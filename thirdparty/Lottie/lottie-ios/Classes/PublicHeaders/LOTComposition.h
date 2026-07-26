#import "../LOTXcode46Compat.h"
//
//  LOTScene.h
//  LottieAnimator
//
//  Created by Brandon Withrow on 12/14/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class LOTLayerGroup;
@class LOTLayer;
@class LOTAssetGroup;

@interface LOTComposition : NSObject

/// Load animation by name from the default bundle, Images are also loaded from the bundle
+ ( instancetype)animationNamed:( NSString *)animationName;

/// Loads animation by name from specified bundle, Images are also loaded from the bundle
+ ( instancetype)animationNamed:( NSString *)animationName
                              inBundle:( NSBundle *)bundle;

/// Loads an animation from a specific file path. WARNING Do not use a web URL for file path.
+ ( instancetype)animationWithFilePath:( NSString *)filePath;

/// Creates an animation from the deserialized JSON Dictionary
+ ( instancetype)animationFromJSON:( NSDictionary *)animationJSON;

/// Creates an animation from the deserialized JSON Dictionary, images are loaded from the specified bundle
+ ( instancetype)animationFromJSON:( NSDictionary *)animationJSON
                                 inBundle:( NSBundle *)bundle;

- (instancetype )initWithJSON:(NSDictionary * )jsonDictionary
                      withAssetBundle:(NSBundle * )bundle;

@property (nonatomic, readonly) CGRect compBounds;
@property (nonatomic, readonly) NSNumber *startFrame;
@property (nonatomic, readonly) NSNumber *endFrame;
@property (nonatomic, readonly) NSNumber *framerate;
@property (nonatomic, readonly) NSTimeInterval timeDuration;
@property (nonatomic, readonly) LOTLayerGroup *layerGroup;
@property (nonatomic, readonly) LOTAssetGroup *assetGroup;
@property (nonatomic, readwrite) NSString *rootDirectory;
@property (nonatomic, readonly) NSBundle *assetBundle;
@property (nonatomic, copy) NSString *cacheKey;

@end
