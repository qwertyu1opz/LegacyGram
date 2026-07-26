#import "../../LOTXcode46Compat.h"
//
//  LOTCircleAnimator.h
//  Lottie
//
//  Created by brandon_withrow on 7/19/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTAnimatorNode.h"
#import "LOTShapeCircle.h"

@interface LOTCircleAnimator : LOTAnimatorNode

- (instancetype )initWithInputNode:(LOTAnimatorNode *)inputNode
                                  shapeCircle:(LOTShapeCircle *)shapeCircle;

@end
