#ifndef TG_LEGACY_TL_TLRPCMESSAGES_GETMESSAGESVIEWS_H
#define TG_LEGACY_TL_TLRPCMESSAGES_GETMESSAGESVIEWS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPeer;
@class NSArray_int;

@interface TLRPCmessages_getMessagesViews : TLMetaRpc

@property (nonatomic, retain) TLInputPeer *peer;
@property (nonatomic, retain) NSArray *n_id;
@property (nonatomic) bool increment;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_getMessagesViews$messages_getMessagesViews : TLRPCmessages_getMessagesViews


@end

#endif
