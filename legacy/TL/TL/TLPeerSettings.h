#ifndef TG_LEGACY_TL_TLPEERSETTINGS_H
#define TG_LEGACY_TL_TLPEERSETTINGS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLPeerSettings : NSObject <TLObject>

@property (nonatomic) int32_t flags;

@end

@interface TLPeerSettings$peerSettings : TLPeerSettings


@end

#endif
