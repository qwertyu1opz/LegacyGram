#import "../../LOTXcode46Compat.h"
//
//  LOTArrayInterpolator.h
//  Lottie
//
//  Created by brandon_withrow on 7/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTValueInterpolator.h"



@interface LOTArrayInterpolator : LOTValueInterpolator

- (NSArray *)numberArrayForFrame:(NSNumber *)frame;

@end


