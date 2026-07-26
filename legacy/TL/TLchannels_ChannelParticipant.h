#ifndef TG_LEGACY_TL_TLCHANNELS_CHANNELPARTICIPANT_H
#define TG_LEGACY_TL_TLCHANNELS_CHANNELPARTICIPANT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLChannelParticipant;

@interface TLchannels_ChannelParticipant : NSObject <TLObject>

@property (nonatomic, retain) TLChannelParticipant *participant;
@property (nonatomic, retain) NSArray *users;

@end

@interface TLchannels_ChannelParticipant$channels_channelParticipant : TLchannels_ChannelParticipant


@end

#endif
