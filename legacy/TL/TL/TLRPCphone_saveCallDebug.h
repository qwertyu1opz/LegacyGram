#ifndef TG_LEGACY_TL_TLRPCPHONE_SAVECALLDEBUG_H
#define TG_LEGACY_TL_TLRPCPHONE_SAVECALLDEBUG_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPhoneCall;
@class TLDataJSON;

@interface TLRPCphone_saveCallDebug : TLMetaRpc

@property (nonatomic, retain) TLInputPhoneCall *peer;
@property (nonatomic, retain) TLDataJSON *debug;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCphone_saveCallDebug$phone_saveCallDebug : TLRPCphone_saveCallDebug


@end

#endif
