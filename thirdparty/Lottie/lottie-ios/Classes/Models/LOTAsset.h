#import "../LOTXcode46Compat.h"
//
//  LOTAsset.h
//  Pods
//
//  Created by Brandon Withrow on 2/16/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>



@class LOTLayerGroup;
@class LOTLayer;
@class LOTAssetGroup;

@interface LOTAsset : NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonDictionary
              withAssetGroup:(LOTAssetGroup * )assetGroup
             withAssetBundle:(NSBundle *)bundle
               withFramerate:(NSNumber *)framerate;

@property (nonatomic, readonly) NSString *referenceID;
@property (nonatomic, readonly) NSNumber *assetWidth;
@property (nonatomic, readonly) NSNumber *assetHeight;

@property (nonatomic, readonly) NSString *imageName;
@property (nonatomic, readonly) NSString *imageDirectory;

@property (nonatomic, readonly) LOTLayerGroup *layerGroup;

@property (nonatomic, readwrite) NSString *rootDirectory;
@property (nonatomic, readonly) NSBundle *assetBundle;
@end


