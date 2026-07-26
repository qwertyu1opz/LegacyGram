#import "../../LOTXcode46Compat.h"
//
//  LOTColorInterpolator.h
//  Lottie
//
//  Created by brandon_withrow on 7/13/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTValueInterpolator.h"
#import "LOTPlatformCompat.h"
#import "LOTValueDelegate.h"



@interface LOTColorInterpolator : LOTValueInterpolator

- (CGColorRef)colorForFrame:(NSNumber *)frame;

@property (nonatomic, weak) id<LOTColorValueDelegate> delegate;

@end


