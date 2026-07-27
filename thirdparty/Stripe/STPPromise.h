//
//  STPPromise.h
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPBlocks.h"

NS_ASSUME_NONNULL_BEGIN

@class STPVoidPromise;

@interface STPPromise: NSObject

typedef void (^STPPromiseErrorBlock)(NSError *error);
typedef void (^STPPromiseValueBlock)(id value);
typedef void (^STPPromiseCompletionBlock)(id value,  NSError * error);
typedef id (^STPPromiseMapBlock)(id value);
typedef STPPromise* (^STPPromiseFlatMapBlock)(id value);

@property(atomic, readonly)BOOL completed;
@property(atomic, readonly)id value;
@property(atomic, readonly)NSError *error;

+ (instancetype)promiseWithError:(NSError *)error;
+ (instancetype)promiseWithValue:(id)value;

- (void)succeed:(id)value;
- (void)fail:(NSError *)error;

- (void)completeWith:(STPPromise *)promise;

- (instancetype)onSuccess:(STPPromiseValueBlock)callback;
- (instancetype)onFailure:(STPPromiseErrorBlock)callback;
- (instancetype)onCompletion:(STPPromiseCompletionBlock)callback;

- (STPPromise *)map:(STPPromiseMapBlock)callback;
- (STPPromise *)flatMap:(STPPromiseFlatMapBlock)callback;
- (STPVoidPromise *)asVoid;

@end

typedef STPPromise* (^STPVoidPromiseFlatMapBlock)();

@interface STPVoidPromise : STPPromise

- (void)succeed;
- (void)voidCompleteWith:(STPVoidPromise *)promise;
- (instancetype)voidOnSuccess:(STPVoidBlock)block;
- (STPPromise *)voidFlatMap:(STPVoidPromiseFlatMapBlock)block;

@end

NS_ASSUME_NONNULL_END
