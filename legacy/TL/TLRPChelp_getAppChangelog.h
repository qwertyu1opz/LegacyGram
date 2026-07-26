#ifndef TG_LEGACY_TL_TLRPCHELP_GETAPPCHANGELOG_H
#define TG_LEGACY_TL_TLRPCHELP_GETAPPCHANGELOG_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLUpdates;

@interface TLRPChelp_getAppChangelog : TLMetaRpc

@property (nonatomic, retain) NSString *prev_app_version;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPChelp_getAppChangelog$help_getAppChangelog : TLRPChelp_getAppChangelog


@end

#endif
