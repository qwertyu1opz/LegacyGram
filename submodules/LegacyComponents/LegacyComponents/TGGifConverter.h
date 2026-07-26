#import <Foundation/Foundation.h>
#import "../../../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGGifConverter : NSObject

+ (SSignal *)convertGifToMp4:(NSData *)data;

@end
