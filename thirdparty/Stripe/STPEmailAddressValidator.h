//
//  STPEmailAddressValidator.h
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPEmailAddressValidator : NSObject

+ (BOOL)stringIsValidPartialEmailAddress:(NSString *)string;
+ (BOOL)stringIsValidEmailAddress:(NSString *)string;

@end
