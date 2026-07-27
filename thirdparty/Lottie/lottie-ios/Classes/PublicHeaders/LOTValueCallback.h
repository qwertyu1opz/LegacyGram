#import "../LOTXcode46Compat.h"
//
//  LOTValueCallback.h
//  Lottie
//
//  Created by brandon_withrow on 12/15/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "LOTValueDelegate.h"

/*!
 @brief LOTColorValueCallback is a container for a CGColorRef. This container is a LOTColorValueDelegate that always returns the colorValue property to its animation delegate.
 @discussion LOTColorValueCallback is used in conjunction with LOTAnimationView setValueDelegate:forKeypath to set a color value of an animation property.
 */

@interface LOTColorValueCallback : NSObject <LOTColorValueDelegate>

+ (instancetype )withCGColor:(CGColorRef )color;

@property (nonatomic) CGColorRef colorValue;

@end

/*!
 @brief LOTNumberValueCallback is a container for a CGFloat value. This container is a LOTNumberValueDelegate that always returns the numberValue property to its animation delegate.
 @discussion LOTNumberValueCallback is used in conjunction with LOTAnimationView setValueDelegate:forKeypath to set a number value of an animation property.
 */

@interface LOTNumberValueCallback : NSObject <LOTNumberValueDelegate>

+ (instancetype )withFloatValue:(CGFloat)numberValue;

@property (nonatomic, assign) CGFloat numberValue;

@end

/*!
 @brief LOTPointValueCallback is a container for a CGPoint value. This container is a LOTPointValueDelegate that always returns the pointValue property to its animation delegate.
 @discussion LOTPointValueCallback is used in conjunction with LOTAnimationView setValueDelegate:forKeypath to set a point value of an animation property.
 */

@interface LOTPointValueCallback : NSObject <LOTPointValueDelegate>

+ (instancetype )withPointValue:(CGPoint)pointValue;

@property (nonatomic, assign) CGPoint pointValue;

@end

/*!
 @brief LOTSizeValueCallback is a container for a CGSize value. This container is a LOTSizeValueDelegate that always returns the sizeValue property to its animation delegate.
 @discussion LOTSizeValueCallback is used in conjunction with LOTAnimationView setValueDelegate:forKeypath to set a size value of an animation property.
 */

@interface LOTSizeValueCallback : NSObject <LOTSizeValueDelegate>

+ (instancetype )withPointValue:(CGSize)sizeValue;

@property (nonatomic, assign) CGSize sizeValue;

@end

/*!
 @brief LOTPathValueCallback is a container for a CGPathRef value. This container is a LOTPathValueDelegate that always returns the pathValue property to its animation delegate.
 @discussion LOTPathValueCallback is used in conjunction with LOTAnimationView setValueDelegate:forKeypath to set a path value of an animation property.
 */

@interface LOTPathValueCallback : NSObject <LOTPathValueDelegate>

+ (instancetype )withCGPath:(CGPathRef )path;

@property (nonatomic) CGPathRef pathValue;

@end
