#import "../LOTXcode46Compat.h"
//
//  LOTLayerContainer.h
//  Lottie
//
//  Created by brandon_withrow on 7/18/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTPlatformCompat.h"
#import "LOTLayer.h"
#import "LOTLayerGroup.h"
#import "LOTKeypath.h"
#import "LOTValueDelegate.h"

@class LOTValueCallback;

@interface LOTLayerContainer : CALayer

- (instancetype )initWithModel:(LOTLayer * )layer
                 inLayerGroup:(LOTLayerGroup * )layerGroup;

@property (nonatomic,  readonly, strong) NSString *layerName;
@property (nonatomic) NSNumber *currentFrame;
@property (nonatomic, readonly) NSNumber *timeStretchFactor;
@property (nonatomic, assign) CGRect viewportBounds;
@property (nonatomic, readonly) CALayer *wrapperLayer;
@property (nonatomic, readonly) NSDictionary *valueInterpolators;

- (void)displayWithFrame:(NSNumber * )frame;
- (void)displayWithFrame:(NSNumber * )frame forceUpdate:(BOOL)forceUpdate;

- (void)searchNodesForKeypath:(LOTKeypath * )keypath;

- (void)setValueDelegate:(id<LOTValueDelegate> )delegate
              forKeypath:(LOTKeypath * )keypath;

@end
