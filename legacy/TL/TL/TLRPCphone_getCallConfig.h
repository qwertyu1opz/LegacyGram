#ifndef TG_LEGACY_TL_TLRPCPHONE_GETCALLCONFIG_H
#define TG_LEGACY_TL_TLRPCPHONE_GETCALLCONFIG_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLDataJSON;

@interface TLRPCphone_getCallConfig : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCphone_getCallConfig$phone_getCallConfig : TLRPCphone_getCallConfig


@end

#endif
