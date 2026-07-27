#import "TGBridgeMessageEntities.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@interface TGBridgeMessageEntity (TGMessageEntity)

+ (TGBridgeMessageEntity *)entityWithTGMessageEntity:(TGMessageEntity *)entity;

@end
