//
//  STPCheckoutBootstrapResponse.h
//  Stripe
//
//  Created by Jack Flintermann on 5/4/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STPAPIClient;

@interface STPCheckoutBootstrapResponse : NSObject

+ (instancetype)bootstrapResponseWithData:(NSData *)data
                                       URLResponse:(NSURLResponse *)response;

@property(nonatomic, readonly)BOOL liveMode;
@property(nonatomic, readonly)BOOL accountsDisabled;
@property(nonatomic, readonly)NSString *sessionID;
@property(nonatomic, readonly)NSString *csrfToken;
@property(nonatomic, readonly)STPAPIClient *tokenClient;

@end
