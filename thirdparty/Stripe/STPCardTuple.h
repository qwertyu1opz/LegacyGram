//
//  STPCardTuple.h
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class STPCard;

@interface STPCardTuple : NSObject

+ (instancetype)tupleWithSelectedCard:(STPCard *)selectedCard
                                cards:(NSArray *)cards;

@property(nonatomic, readonly)STPCard *selectedCard;
@property(nonatomic, readonly)NSArray *cards;

@end

NS_ASSUME_NONNULL_END
