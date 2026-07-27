//
//  STPCardParams.h
//  Stripe
//
//  Created by Jack Flintermann on 10/4/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPFormEncodable.h"
#if TARGET_OS_IPHONE
#import "STPAddress.h"
#endif

/**
 *  Representation of a user's credit card details. You can assemble these with information that your user enters and
 *  then create Stripe tokens with them using an STPAPIClient. @see https://stripe.com/docs/api#cards
 */
@interface STPCardParams : NSObject<STPFormEncodable>

/**
 *  The card's number.
 */
@property (nonatomic, copy) NSString *number;

/**
 *  The last 4 digits of the card's number, if it's been set, otherwise nil.
 */
- (NSString *)last4;

/**
 *  The card's expiration month.
 */
@property (nonatomic) NSUInteger expMonth;

/**
 *  The card's expiration year.
 */
@property (nonatomic) NSUInteger expYear;

/**
 *  The card's security code, found on the back.
 */
@property (nonatomic, copy) NSString *cvc;

/**
 *  The cardholder's name.
 */
@property (nonatomic, copy) NSString *name;

/**
 *  The cardholder's address.
 */
#if TARGET_OS_IPHONE
@property(nonatomic, copy) STPAddress *address;
#endif

@property (nonatomic, copy) NSString *addressLine1;
@property (nonatomic, copy) NSString *addressLine2;
@property (nonatomic, copy) NSString *addressCity;
@property (nonatomic, copy) NSString *addressState;
@property (nonatomic, copy) NSString *addressZip;
@property (nonatomic, copy) NSString *addressCountry;

/**
 *  Three-letter ISO currency code representing the currency paid out to the bank account. This is only applicable when tokenizing debit cards to issue payouts to managed accounts. You should not set it otherwise. The card can then be used as a transfer destination for funds in this currency.
 */
@property (nonatomic, copy) NSString *currency;

/**
 *  Validate each field of the card.
 *  @return whether or not that field is valid.
 *  @deprecated use STPCardValidator instead.
 */
- (BOOL)validateNumber:(id * )ioValue
                 error:(NSError * * )outError __attribute__((deprecated("Use STPCardValidator instead.")));
- (BOOL)validateCvc:(id * )ioValue
              error:(NSError * * )outError __attribute__((deprecated("Use STPCardValidator instead.")));
- (BOOL)validateExpMonth:(id * )ioValue
                   error:(NSError * * )outError __attribute__((deprecated("Use STPCardValidator instead.")));
- (BOOL)validateExpYear:(id *)ioValue
                  error:(NSError * * )outError __attribute__((deprecated("Use STPCardValidator instead.")));

/**
 *  This validates a fully populated card to check for all errors, including ones that come about
 *  from the interaction of more than one property. It will also do all the validations on individual
 *  properties, so if you only want to call one method on your card to validate it after setting all the
 *  properties, call this one
 *
 *  @param outError a pointer to an NSError that, after calling this method, will be populated with an error if the card is not valid. See StripeError.h for
 possible values
 *
 *  @return whether or not the card is valid.
 *  @deprecated use STPCardValidator instead.
 */
- (BOOL)validateCardReturningError:(NSError * *)outError __attribute__((deprecated("Use STPCardValidator instead.")));

@end
