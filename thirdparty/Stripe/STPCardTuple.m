//
//  STPCardTuple.m
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPCardTuple.h"

@interface STPCardTuple()

@property(nonatomic)STPCard *selectedCard;
@property(nonatomic)NSArray *cards;

@end

@implementation STPCardTuple

+ (instancetype)tupleWithSelectedCard:(STPCard *)selectedCard
                                cards:(NSArray *)cards {
    STPCardTuple *tuple = [self new];
    tuple.selectedCard = selectedCard;
    tuple.cards = cards ?: @[];
    return tuple;
}

@end
