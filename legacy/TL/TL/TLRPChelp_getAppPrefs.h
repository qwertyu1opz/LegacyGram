#ifndef TG_LEGACY_TL_TLRPCHELP_GETAPPPREFS_H
#define TG_LEGACY_TL_TLRPCHELP_GETAPPPREFS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLhelp_AppPrefs;

@interface TLRPChelp_getAppPrefs : TLMetaRpc

@property (nonatomic) int32_t api_id;
@property (nonatomic, retain) NSString *api_hash;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPChelp_getAppPrefs$help_getAppPrefs : TLRPChelp_getAppPrefs


@end

#endif
