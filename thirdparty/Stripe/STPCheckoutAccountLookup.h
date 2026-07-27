//
//  STPCheckoutAccountLookup.h
//  Stripe
//
//  Created by Jack Flintermann on 5/4/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPCheckoutAccountLookup : NSObject

+ (instancetype)lookupWithData:(NSData *)data
                            URLResponse:(NSURLResponse *)response;

@property(nonatomic, readonly)NSString *email;
@property(nonatomic, readonly)NSString *redactedPhone;

@end

NS_ASSUME_NONNULL_END
