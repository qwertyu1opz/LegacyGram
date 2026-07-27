//
//  STPCheckoutAccount.h
//  Stripe
//
//  Created by Jack Flintermann on 5/3/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPCard.h"

@interface STPCheckoutAccount : NSObject

+ (instancetype)accountWithData:(NSData *)data
                             URLResponse:(NSURLResponse *)response;

@property(nonatomic, readonly)NSString *email;
@property(nonatomic, readonly)NSString *phone;
@property(nonatomic, readonly)NSString *csrfToken;
@property(nonatomic, readonly)NSString *sessionID;
@property(nonatomic, readonly)STPCard *card;

@end
