#ifndef TG_LEGACY_TL_TLRPCHELP_GETAPPUPDATE_H
#define TG_LEGACY_TL_TLRPCHELP_GETAPPUPDATE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLhelp_AppUpdate;

@interface TLRPChelp_getAppUpdate : TLMetaRpc

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPChelp_getAppUpdate$help_getAppUpdate : TLRPChelp_getAppUpdate


@end

#endif
