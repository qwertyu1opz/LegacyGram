#import "../LOTXcode46Compat.h"
//
//  LOTAnimationView_Internal.h
//  Lottie
//
//  Created by Brandon Withrow on 12/7/16.
//  Copyright © 2016 Brandon Withrow. All rights reserved.
//

#import "LOTAnimationView.h"

typedef enum : NSUInteger {
  LOTConstraintTypeAlignToBounds,
  LOTConstraintTypeAlignToLayer,
  LOTConstraintTypeNone
} LOTConstraintType;

@interface LOTAnimationView () <CAAnimationDelegate>

- (CALayer * )layerForKey:(NSString * )keyname;
- (NSArray * )compositionLayers;

@end
