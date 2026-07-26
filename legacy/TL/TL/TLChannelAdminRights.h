#ifndef TG_LEGACY_TL_TLCHANNELADMINRIGHTS_H
#define TG_LEGACY_TL_TLCHANNELADMINRIGHTS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLChannelAdminRights : NSObject <TLObject>

@property (nonatomic) int32_t flags;

@end

@interface TLChannelAdminRights$channelAdminRights : TLChannelAdminRights


@end

#endif
