#ifndef TG_LEGACY_TL_TLRPCMESSAGES_SENDBROADCAST_H
#define TG_LEGACY_TL_TLRPCMESSAGES_SENDBROADCAST_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputMedia;
@class TLUpdates;

@interface TLRPCmessages_sendBroadcast : TLMetaRpc

@property (nonatomic, retain) NSArray *contacts;
@property (nonatomic, retain) NSArray *random_id;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) TLInputMedia *media;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_sendBroadcast$messages_sendBroadcast : TLRPCmessages_sendBroadcast


@end

#endif
