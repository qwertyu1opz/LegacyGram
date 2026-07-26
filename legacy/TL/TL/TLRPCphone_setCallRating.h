#ifndef TG_LEGACY_TL_TLRPCPHONE_SETCALLRATING_H
#define TG_LEGACY_TL_TLRPCPHONE_SETCALLRATING_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPhoneCall;
@class TLUpdates;

@interface TLRPCphone_setCallRating : TLMetaRpc

@property (nonatomic, retain) TLInputPhoneCall *peer;
@property (nonatomic) int32_t rating;
@property (nonatomic, retain) NSString *comment;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCphone_setCallRating$phone_setCallRating : TLRPCphone_setCallRating


@end

#endif
