#import "../../LOTXcode46Compat.h"
//
//  LOTPolygonAnimator.h
//  Lottie
//
//  Created by brandon_withrow on 7/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTAnimatorNode.h"
#import "LOTShapeStar.h"

@interface LOTPolygonAnimator : LOTAnimatorNode

- (instancetype )initWithInputNode:(LOTAnimatorNode *)inputNode
                             shapePolygon:(LOTShapeStar *)shapeStar;

@end
