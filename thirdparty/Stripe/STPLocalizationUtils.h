//
//  STPLocalizationUtils.h
//  Stripe
//
//  Created by Brian Dorfman on 8/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPLocalizationUtils : NSObject

/**
 Acts like NSLocalizedString but tries to find the string in the Stripe
 bundle first if possible.
 */
+ (NSString *)localizedStripeStringForKey:(NSString *)key;

@end

static inline NSString * STPLocalizedString(NSString* key, NSString * __unused comment) {
    return [STPLocalizationUtils localizedStripeStringForKey:key];
}
