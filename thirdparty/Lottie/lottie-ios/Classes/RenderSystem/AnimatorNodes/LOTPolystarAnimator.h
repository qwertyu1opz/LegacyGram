#import "../../LOTXcode46Compat.h"
//
//  LOTPolystarAnimator.h
//  Lottie
//
//  Created by brandon_withrow on 7/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTAnimatorNode.h"
#import "LOTShapeStar.h"

@interface LOTPolystarAnimator : LOTAnimatorNode

- (instancetype )initWithInputNode:(LOTAnimatorNode *)inputNode
                             shapeStar:(LOTShapeStar *)shapeStar;

@end
