//
//  STPPaymentContext+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "Stripe.h"
#import "STPPromise.h"
#import "STPPaymentMethodTuple.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentContext (Private)<STPPaymentMethodsViewControllerDelegate>

@property(nonatomic, readonly)STPPromise *currentValuePromise;

@end

NS_ASSUME_NONNULL_END
