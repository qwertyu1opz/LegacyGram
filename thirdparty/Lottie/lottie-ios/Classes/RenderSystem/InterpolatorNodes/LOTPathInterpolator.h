#import "../../LOTXcode46Compat.h"
//
//  LOTPathInterpolator.h
//  Lottie
//
//  Created by brandon_withrow on 7/13/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTValueInterpolator.h"
#import "LOTPlatformCompat.h"
#import "LOTBezierPath.h"
#import "LOTValueDelegate.h"



@interface LOTPathInterpolator : LOTValueInterpolator

- (LOTBezierPath *)pathForFrame:(NSNumber *)frame cacheLengths:(BOOL)cacheLengths;

@property (nonatomic, weak) id<LOTPathValueDelegate> delegate;

@end


