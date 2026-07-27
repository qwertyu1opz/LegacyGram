#import "../../LOTXcode46Compat.h"
//
//  LOTFillRenderer.h
//  Lottie
//
//  Created by brandon_withrow on 6/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTRenderNode.h"
#import "LOTShapeFill.h"

@interface LOTFillRenderer : LOTRenderNode

- (instancetype )initWithInputNode:(LOTAnimatorNode *)inputNode
                                  shapeFill:(LOTShapeFill *)fill;

@end
