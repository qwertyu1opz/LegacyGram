#ifndef TG_LEGACY_TL_TLRPCHELP_GETNEARESTDC_H
#define TG_LEGACY_TL_TLRPCHELP_GETNEARESTDC_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLNearestDc;

@interface TLRPChelp_getNearestDc : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPChelp_getNearestDc$help_getNearestDc : TLRPChelp_getNearestDc


@end

#endif
