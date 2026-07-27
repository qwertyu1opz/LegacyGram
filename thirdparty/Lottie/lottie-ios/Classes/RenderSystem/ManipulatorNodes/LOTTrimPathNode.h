#import "../../LOTXcode46Compat.h"
//
//  LOTTrimPathNode.h
//  Lottie
//
//  Created by brandon_withrow on 7/21/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTAnimatorNode.h"
#import "LOTShapeTrimPath.h"

@interface LOTTrimPathNode : LOTAnimatorNode

- (instancetype )initWithInputNode:(LOTAnimatorNode *)inputNode
                                  trimPath:(LOTShapeTrimPath *)trimPath;

@end
