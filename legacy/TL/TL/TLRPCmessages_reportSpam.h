#ifndef TG_LEGACY_TL_TLRPCMESSAGES_REPORTSPAM_H
#define TG_LEGACY_TL_TLRPCMESSAGES_REPORTSPAM_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPeer;

@interface TLRPCmessages_reportSpam : TLMetaRpc

@property (nonatomic, retain) TLInputPeer *peer;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_reportSpam$messages_reportSpam : TLRPCmessages_reportSpam


@end

#endif
