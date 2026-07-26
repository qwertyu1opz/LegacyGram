#import <Foundation/Foundation.h>

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@interface TGLegacyComponentsContext : NSObject <LegacyComponentsContext>

+ (TGLegacyComponentsContext *)shared;

@end
