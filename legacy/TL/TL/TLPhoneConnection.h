#ifndef TG_LEGACY_TL_TLPHONECONNECTION_H
#define TG_LEGACY_TL_TLPHONECONNECTION_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLPhoneConnection : NSObject <TLObject>


@end

@interface TLPhoneConnection$phoneConnectionNotReady : TLPhoneConnection


@end

@interface TLPhoneConnection$phoneConnection : TLPhoneConnection

@property (nonatomic) int32_t flags;
@property (nonatomic) int64_t n_id;
@property (nonatomic, retain) NSString *ip;
@property (nonatomic, retain) NSString *ipv6;
@property (nonatomic) int32_t port;
@property (nonatomic, retain) NSData *peer_tag;

@end

@interface TLPhoneConnection$phoneConnectionWebrtc : TLPhoneConnection

@property (nonatomic) int32_t flags;
@property (nonatomic) int64_t n_id;
@property (nonatomic, retain) NSString *ip;
@property (nonatomic, retain) NSString *ipv6;
@property (nonatomic) int32_t port;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;

@end

#endif
