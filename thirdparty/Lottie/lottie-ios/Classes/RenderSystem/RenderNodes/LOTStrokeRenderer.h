#import "../../LOTXcode46Compat.h"
//
//  LOTStrokeRenderer.h
//  Lottie
//
//  Created by brandon_withrow on 7/17/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTRenderNode.h"
#import "LOTShapeStroke.h"

@interface LOTStrokeRenderer : LOTRenderNode

- (instancetype )initWithInputNode:(LOTAnimatorNode *)inputNode
                                shapeStroke:(LOTShapeStroke *)stroke;


@end
