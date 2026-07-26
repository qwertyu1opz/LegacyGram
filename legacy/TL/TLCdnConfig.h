#ifndef TG_LEGACY_TL_TLCDNCONFIG_H
#define TG_LEGACY_TL_TLCDNCONFIG_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLCdnConfig : NSObject <TLObject>

@property (nonatomic, retain) NSArray *public_keys;

@end

@interface TLCdnConfig$cdnConfig : TLCdnConfig


@end

#endif
