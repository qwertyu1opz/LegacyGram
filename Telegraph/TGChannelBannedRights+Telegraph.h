#import <Foundation/Foundation.h>

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TL/TLMetaScheme.h"

@interface TGChannelBannedRights (TG)

- (instancetype)initWithTL:(TLChannelBannedRights *)tlRights;
- (TLChannelBannedRights *)tlRights;

@end
