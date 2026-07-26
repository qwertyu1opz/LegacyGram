#ifndef TG_LEGACY_TL_TLRPCMESSAGES_READMENTIONS_H
#define TG_LEGACY_TL_TLRPCMESSAGES_READMENTIONS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPeer;
@class TLmessages_AffectedHistory;

@interface TLRPCmessages_readMentions : TLMetaRpc

@property (nonatomic, retain) TLInputPeer *peer;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_readMentions$messages_readMentions : TLRPCmessages_readMentions


@end

#endif
