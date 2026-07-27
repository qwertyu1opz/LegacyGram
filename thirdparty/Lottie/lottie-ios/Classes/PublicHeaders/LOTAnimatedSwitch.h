#import "../LOTXcode46Compat.h"
//
//  LOTAnimatedSwitch.h
//  Lottie
//
//  Created by brandon_withrow on 8/25/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "LOTAnimatedControl.h"



@interface LOTAnimatedSwitch : LOTAnimatedControl

/// Convenience method to initialize a control from the Main Bundle by name
+ (instancetype )switchNamed:(NSString * )toggleName;

/// Convenience method to initialize a control from the specified bundle by name
+ (instancetype )switchNamed:(NSString * )toggleName inBundle:(NSBundle * )bundle;


/// The ON/OFF state of the control. Setting will toggle without animation
@property (nonatomic, getter=isOn) BOOL on;

/// Enable interactive sliding gesture for toggle
@property (nonatomic) BOOL interactiveGesture;

/// Set the state of the control with animation
- (void)setOn:(BOOL)on animated:(BOOL)animated; // does not send action

/// Styling

/**
 * Sets the animation play range for the ON state animation.
 * fromProgress is the start of the animation
 * toProgress is the end of the animation and also the ON static state
 * Defaults 0-1
 **/
- (void)setProgressRangeForOnState:(CGFloat)fromProgress
                        toProgress:(CGFloat)toProgress;

/**
 * Sets the animation play range for the OFF state animation.
 * fromProgress is the start of the animation
 * toProgress is the end of the animation and also the OFF static state
 * Defaults 1-0
 **/
- (void)setProgressRangeForOffState:(CGFloat)fromProgress
                         toProgress:(CGFloat)toProgress;

@end


