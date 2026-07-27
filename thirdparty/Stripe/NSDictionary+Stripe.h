//
//  NSDictionary+Stripe.h
//  Stripe
//
//  Created by Jack Flintermann on 10/15/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Stripe)

- (NSDictionary *)stp_dictionaryByRemovingNullsValidatingRequiredFields:(NSArray *)requiredFields;

@end

void linkNSDictionaryCategory(void);
