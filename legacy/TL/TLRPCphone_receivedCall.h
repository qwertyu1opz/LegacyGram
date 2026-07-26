#ifndef TG_LEGACY_TL_TLRPCPHONE_RECEIVEDCALL_H
#define TG_LEGACY_TL_TLRPCPHONE_RECEIVEDCALL_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPhoneCall;

@interface TLRPCphone_receivedCall : TLMetaRpc

@property (nonatomic, retain) TLInputPhoneCall *peer;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCphone_receivedCall$phone_receivedCall : TLRPCphone_receivedCall


@end

#endif
