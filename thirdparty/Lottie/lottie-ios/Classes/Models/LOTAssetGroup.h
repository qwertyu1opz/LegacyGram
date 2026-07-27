#import "../LOTXcode46Compat.h"
//
//  LOTAssetGroup.h
//  Pods
//
//  Created by Brandon Withrow on 2/17/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class LOTAsset;
@class LOTLayerGroup;
@interface LOTAssetGroup : NSObject
@property (nonatomic, readwrite) NSString *  rootDirectory;
@property (nonatomic, readonly) NSBundle *assetBundle;

- (instancetype )initWithJSON:(NSArray * )jsonArray
                      withAssetBundle:(NSBundle *)bundle
                        withFramerate:(NSNumber * )framerate;

- (void)buildAssetNamed:(NSString * )refID withFramerate:(NSNumber * )framerate;

- (void)finalizeInitializationWithFramerate:(NSNumber * )framerate;

- (LOTAsset * )assetModelForID:(NSString * )assetID;

@end
