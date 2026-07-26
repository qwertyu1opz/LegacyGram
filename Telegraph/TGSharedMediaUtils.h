#import <Foundation/Foundation.h>

#import "../submodules/LegacyComponents/LegacyComponents/TGMemoryImageCache.h"
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGModernCache.h"
#import "EMInMemoryImageCache.h"

@interface TGSharedMediaUtils : NSObject

+ (TGMemoryImageCache *)sharedMediaMemoryImageCache;
+ (EMInMemoryImageCache *)inMemoryImageCache;
+ (SThreadPool *)sharedMediaImageProcessingThreadPool;
+ (TGModernCache *)sharedMediaTemporaryPersistentCache;

@end
