#ifndef TG_LEGACY_TL_TLRPCHELP_TEST_H
#define TG_LEGACY_TL_TLRPCHELP_TEST_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPChelp_test : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPChelp_test$help_test : TLRPChelp_test


@end

#endif
