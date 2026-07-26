#ifndef TG_LEGACY_TL_TLRPCMESSAGES_HIDEREPORTSPAM_H
#define TG_LEGACY_TL_TLRPCMESSAGES_HIDEREPORTSPAM_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputPeer;

@interface TLRPCmessages_hideReportSpam : TLMetaRpc

@property (nonatomic, retain) TLInputPeer *peer;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_hideReportSpam$messages_hideReportSpam : TLRPCmessages_hideReportSpam


@end

#endif
