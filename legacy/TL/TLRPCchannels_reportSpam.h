#ifndef TG_LEGACY_TL_TLRPCCHANNELS_REPORTSPAM_H
#define TG_LEGACY_TL_TLRPCCHANNELS_REPORTSPAM_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;
@class TLInputUser;

@interface TLRPCchannels_reportSpam : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic, retain) TLInputUser *user_id;
@property (nonatomic, retain) NSArray *n_id;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_reportSpam$channels_reportSpam : TLRPCchannels_reportSpam


@end

#endif
