//
//  PKPayment+Stripe.h
//  Stripe
//
//  Created by Ben Guo on 7/2/15.
//

#import <PassKit/PassKit.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
@interface PKPayment (Stripe)

/// Returns true if the instance is a payment from the simulator.
- (BOOL)stp_isSimulated;

/// Returns a fake transaction identifier with the expected ~-separated format.
+ (NSString *)stp_testTransactionIdentifier;

@end
#endif

void linkPKPaymentCategory(void);
