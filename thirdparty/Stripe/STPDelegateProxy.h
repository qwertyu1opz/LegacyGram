//
//  STPDelegateProxy.h
//  Stripe
//
//  Created by Jack Flintermann on 10/20/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPDelegateProxy : NSObject

@property(nonatomic, weak)id delegate;
- (instancetype)init;

@end
