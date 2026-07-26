#import "../../LOTXcode46Compat.h"
//
//  LOTRoundedRectAnimator.h
//  Lottie
//
//  Created by brandon_withrow on 7/19/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTAnimatorNode.h"
#import "LOTShapeRectangle.h"

@interface LOTRoundedRectAnimator : LOTAnimatorNode

- (instancetype )initWithInputNode:(LOTAnimatorNode *)inputNode
                                shapeRectangle:(LOTShapeRectangle *)shapeRectangle;


@end
