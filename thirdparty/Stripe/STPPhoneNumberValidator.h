//
//  STPPhoneNumberValidator.h
//  Stripe
//
//  Created by Jack Flintermann on 10/16/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPPhoneNumberValidator : NSObject

+ (BOOL)stringIsValidPartialPhoneNumber:(NSString *)string;
+ (BOOL)stringIsValidPhoneNumber:(NSString *)string;
+ (BOOL)stringIsValidPartialPhoneNumber:(NSString *)string
                         forCountryCode:(NSString *)countryCode;
+ (BOOL)stringIsValidPhoneNumber:(NSString *)string
                  forCountryCode:(NSString *)countryCode;

+ (NSString *)formattedSanitizedPhoneNumberForString:(NSString *)string;
+ (NSString *)formattedSanitizedPhoneNumberForString:(NSString *)string
                                      forCountryCode:(NSString *)countryCode;
+ (NSString *)formattedRedactedPhoneNumberForString:(NSString *)string;
+ (NSString *)formattedRedactedPhoneNumberForString:(NSString *)string
                                     forCountryCode:(NSString *)countryCode;

@end

NS_ASSUME_NONNULL_END
