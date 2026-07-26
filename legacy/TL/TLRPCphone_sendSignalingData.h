#ifndef TG_LEGACY_TL_TLRPCPHONE_SENDSIGNALINGDATA_H
#define TG_LEGACY_TL_TLRPCPHONE_SENDSIGNALINGDATA_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPhoneCall;

@interface TLRPCphone_sendSignalingData : TLMetaRpc

@property (nonatomic, retain) TLInputPhoneCall *peer;
@property (nonatomic, retain) NSData *data;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCphone_sendSignalingData$phone_sendSignalingData : TLRPCphone_sendSignalingData


@end

#endif
