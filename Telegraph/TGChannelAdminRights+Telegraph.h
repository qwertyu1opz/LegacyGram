#import <Foundation/Foundation.h>

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TL/TLMetaScheme.h"

@interface TGChannelAdminRights (TG)

- (instancetype)initWithTL:(TLChannelAdminRights *)rights;
- (TLChannelAdminRights *)tlRights;

@end
