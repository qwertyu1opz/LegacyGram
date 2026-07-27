//
//  STPBINRange.h
//  Stripe
//
//  Created by Jack Flintermann on 5/24/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPCardBrand.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPBINRange : NSObject

@property(nonatomic, readonly)NSUInteger length;
@property(nonatomic, readonly)STPCardBrand brand;

+ (NSArray *)allRanges;
+ (NSArray *)binRangesForNumber:(NSString *)number;
+ (NSArray *)binRangesForBrand:(STPCardBrand)brand;
+ (instancetype)mostSpecificBINRangeForNumber:(NSString *)number;

@end

NS_ASSUME_NONNULL_END
