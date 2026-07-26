#ifndef TG_LEGACY_TL_TLRPCCHANNELS_EDITABOUT_H
#define TG_LEGACY_TL_TLRPCCHANNELS_EDITABOUT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputChannel;

@interface TLRPCchannels_editAbout : TLMetaRpc

@property (nonatomic, retain) TLInputChannel *channel;
@property (nonatomic, retain) NSString *about;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCchannels_editAbout$channels_editAbout : TLRPCchannels_editAbout


@end

#endif
