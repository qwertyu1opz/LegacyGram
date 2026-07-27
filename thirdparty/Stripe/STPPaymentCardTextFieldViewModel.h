//
//  STPPaymentCardTextFieldViewModel.h
//  Stripe
//
//  Created by Jack Flintermann on 7/21/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "STPCard.h"
#import "STPCardValidator.h"

typedef NS_ENUM(NSInteger, STPCardFieldType) {
    STPCardFieldTypeNumber,
    STPCardFieldTypeExpiration,
    STPCardFieldTypeCVC,
};

@interface STPPaymentCardTextFieldViewModel : NSObject

@property(nonatomic, readwrite, copy)NSString *cardNumber;
@property(nonatomic, readwrite, copy)NSString *rawExpiration;
@property(nonatomic, readonly)NSString *expirationMonth;
@property(nonatomic, readonly)NSString *expirationYear;
@property(nonatomic, readwrite, copy)NSString *cvc;
@property(nonatomic, readonly) STPCardBrand brand;

- (NSString *)defaultPlaceholder;
- (NSString *)numberWithoutLastDigits;

- (BOOL)isValid;

- (STPCardValidationState)validationStateForField:(STPCardFieldType)fieldType;

@end
