#import <Foundation/Foundation.h>

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@interface TGMessageUniqueIdContentProperty : NSObject <PSCoding>

@property (nonatomic, readonly) int32_t value;

- (instancetype)initWithValue:(int32_t)value;

@end
