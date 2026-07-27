//
//  STPPaymentContextAmountModel.m
//  Stripe
//
//  Created by Brian Dorfman on 8/16/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentContextAmountModel.h"

#import "NSDecimalNumber+Stripe_Currency.h"

@implementation STPPaymentContextAmountModel {
    NSInteger _paymentAmount;
    NSArray *_paymentSummaryItems;
}

FAUXPAS_IGNORED_IN_CLASS(APIAvailability)

- (instancetype)initWithAmount:(NSInteger)paymentAmount {
    self = [super init];
    if (self) {
        _paymentAmount = paymentAmount;
        _paymentSummaryItems = nil;
    }
    return self;
}

- (instancetype)initWithPaymentSummaryItems:(NSArray *)paymentSummaryItems {
    self = [super init];
    if (self) {
        _paymentAmount = 0;
        _paymentSummaryItems = paymentSummaryItems;
    }
    return self;
}

- (NSInteger)paymentAmountWithCurrency:(NSString *)paymentCurrency {
    if (_paymentSummaryItems == nil) {
        return _paymentAmount;
    }
    else {
        id lastItem = _paymentSummaryItems.lastObject;
        return [[lastItem amount] stp_amountWithCurrency:paymentCurrency];
    }
}

- (NSArray *)paymentSummaryItemsWithCurrency:(NSString *)paymentCurrency
                                                         companyName:(NSString *)companyName {
    if (_paymentSummaryItems == nil) {
        NSDecimalNumber *amount = [NSDecimalNumber stp_decimalNumberWithAmount:_paymentAmount
                                                                      currency:paymentCurrency];
        id totalItem = [(id)NSClassFromString(@"PKPaymentSummaryItem") summaryItemWithLabel:companyName
                                                                              amount:amount];
        return @[totalItem];
        
    }
    else {
        return _paymentSummaryItems;
    }
}

@end
