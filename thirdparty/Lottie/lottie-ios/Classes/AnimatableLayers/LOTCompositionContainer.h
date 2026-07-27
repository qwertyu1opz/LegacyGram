#import "../LOTXcode46Compat.h"
//
//  LOTCompositionContainer.h
//  Lottie
//
//  Created by brandon_withrow on 7/18/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTLayerContainer.h"
#import "LOTAssetGroup.h"

@interface LOTCompositionContainer : LOTLayerContainer

- (instancetype )initWithModel:(LOTLayer * )layer
                          inLayerGroup:(LOTLayerGroup * )layerGroup
                        withLayerGroup:(LOTLayerGroup * )childLayerGroup
                       withAssestGroup:(LOTAssetGroup * )assetGroup;

- ( NSArray *)keysForKeyPath:( LOTKeypath *)keypath;

- (CGPoint)convertPoint:(CGPoint)point
         toKeypathLayer:( LOTKeypath *)keypath
        withParentLayer:(CALayer *)parent;

- (CGRect)convertRect:(CGRect)rect
       toKeypathLayer:( LOTKeypath *)keypath
      withParentLayer:(CALayer *)parent;

- (CGPoint)convertPoint:(CGPoint)point
       fromKeypathLayer:( LOTKeypath *)keypath
        withParentLayer:(CALayer *)parent;

- (CGRect)convertRect:(CGRect)rect
     fromKeypathLayer:( LOTKeypath *)keypath
      withParentLayer:(CALayer *)parent;

- (void)addSublayer:( CALayer *)subLayer
    toKeypathLayer:( LOTKeypath *)keypath;

- (void)maskSublayer:( CALayer *)subLayer
     toKeypathLayer:( LOTKeypath *)keypath;

@property (nonatomic, readonly) NSArray *childLayers;
@property (nonatomic, readonly)  NSDictionary *childMap;

@end
