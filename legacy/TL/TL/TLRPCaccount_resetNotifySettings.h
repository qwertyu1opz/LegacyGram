#ifndef TG_LEGACY_TL_TLRPCACCOUNT_RESETNOTIFYSETTINGS_H
#define TG_LEGACY_TL_TLRPCACCOUNT_RESETNOTIFYSETTINGS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPCaccount_resetNotifySettings : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCaccount_resetNotifySettings$account_resetNotifySettings : TLRPCaccount_resetNotifySettings


@end

#endif
