#import "../../LOTXcode46Compat.h"
//
//  LOTPathAnimator.h
//  Pods
//
//  Created by brandon_withrow on 6/27/17.
//
//

#import "LOTAnimatorNode.h"
#import "LOTShapePath.h"

@interface LOTPathAnimator : LOTAnimatorNode

- (instancetype )initWithInputNode:(LOTAnimatorNode *)inputNode
                                  shapePath:(LOTShapePath *)shapePath;

@end
