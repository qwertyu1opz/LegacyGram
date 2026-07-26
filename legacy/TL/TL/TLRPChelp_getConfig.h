#ifndef TG_LEGACY_TL_TLRPCHELP_GETCONFIG_H
#define TG_LEGACY_TL_TLRPCHELP_GETCONFIG_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLConfig;

@interface TLRPChelp_getConfig : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPChelp_getConfig$help_getConfig : TLRPChelp_getConfig


@end

#endif
