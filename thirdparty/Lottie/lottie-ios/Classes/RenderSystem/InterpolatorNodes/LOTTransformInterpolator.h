#import "../../LOTXcode46Compat.h"
//
//  LOTTransformInterpolator.h
//  Lottie
//
//  Created by brandon_withrow on 7/18/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LOTNumberInterpolator.h"
#import "LOTPointInterpolator.h"
#import "LOTSizeInterpolator.h"
#import "LOTKeyframe.h"
#import "LOTLayer.h"



@interface LOTTransformInterpolator : NSObject

+ (instancetype)transformForLayer:(LOTLayer *)layer;

- (instancetype)initWithPosition:(NSArray *)position
                        rotation:(NSArray *)rotation
                          anchor:(NSArray *)anchor
                           scale:(NSArray *)scale;

- (instancetype)initWithPositionX:(NSArray *)positionX
                        positionY:(NSArray *)positionY
                         rotation:(NSArray *)rotation
                           anchor:(NSArray *)anchor
                            scale:(NSArray *)scale;

@property (nonatomic, strong) LOTTransformInterpolator * inputNode;

@property (nonatomic, readonly) LOTPointInterpolator *positionInterpolator;
@property (nonatomic, readonly) LOTPointInterpolator *anchorInterpolator;
@property (nonatomic, readonly) LOTSizeInterpolator *scaleInterpolator;
@property (nonatomic, readonly) LOTNumberInterpolator *rotationInterpolator;
@property (nonatomic, readonly) LOTNumberInterpolator *positionXInterpolator;
@property (nonatomic, readonly) LOTNumberInterpolator *positionYInterpolator;
@property (nonatomic, strong) NSString *parentKeyName;

- (CATransform3D)transformForFrame:(NSNumber *)frame;
- (BOOL)hasUpdateForFrame:(NSNumber *)frame;

@end


