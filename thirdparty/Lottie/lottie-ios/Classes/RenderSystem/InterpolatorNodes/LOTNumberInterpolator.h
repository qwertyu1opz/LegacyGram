#import "../../LOTXcode46Compat.h"
//
//  LOTNumberInterpolator.h
//  Lottie
//
//  Created by brandon_withrow on 7/11/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LOTValueInterpolator.h"
#import "LOTValueDelegate.h"


@interface LOTNumberInterpolator : LOTValueInterpolator

- (CGFloat)floatValueForFrame:(NSNumber *)frame;

@property (nonatomic, weak) id<LOTNumberValueDelegate> delegate;

@end


