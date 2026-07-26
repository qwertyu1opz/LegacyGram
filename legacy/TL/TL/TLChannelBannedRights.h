#ifndef TG_LEGACY_TL_TLCHANNELBANNEDRIGHTS_H
#define TG_LEGACY_TL_TLCHANNELBANNEDRIGHTS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLChannelBannedRights : NSObject <TLObject>

@property (nonatomic) int32_t flags;
@property (nonatomic) int32_t until_date;

@end

@interface TLChannelBannedRights$channelBannedRights : TLChannelBannedRights


@end

#endif
