#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGPassportAttachMenu.h"

@interface TGPassportICloud : NSObject

+ (SSignal *)fetchICloudFileWith:(NSURL *)url;

@end
