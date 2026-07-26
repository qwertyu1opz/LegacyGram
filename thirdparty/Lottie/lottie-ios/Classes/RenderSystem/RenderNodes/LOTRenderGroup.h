#import "../../LOTXcode46Compat.h"
//
//  LOTRenderGroup.h
//  Lottie
//
//  Created by brandon_withrow on 6/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTRenderNode.h"

@interface LOTRenderGroup : LOTRenderNode

- (instancetype )initWithInputNode:(LOTAnimatorNode * )inputNode
                                   contents:(NSArray * )contents
                                    keyname:(NSString * )keyname;

@property (nonatomic, strong, readonly) CALayer *  containerLayer;

@end


