#ifndef TG_LEGACY_TL_TLRPCMESSAGES_GETPINNEDDIALOGS_H
#define TG_LEGACY_TL_TLRPCMESSAGES_GETPINNEDDIALOGS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLmessages_PeerDialogs;

@interface TLRPCmessages_getPinnedDialogs : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_getPinnedDialogs$messages_getPinnedDialogs : TLRPCmessages_getPinnedDialogs


@end

#endif
