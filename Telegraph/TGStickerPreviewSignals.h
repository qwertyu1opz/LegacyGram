#import <Foundation/Foundation.h>
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

#import "EMInMemoryImageCache.h"

@class TGDocumentMediaAttachment;

@interface TGStickerPreviewSignals : NSObject

+ (SSignal *)stickerThumbnail:(TGDocumentMediaAttachment *)documentAttachment ofSize:(CGSize)size threadPool:(SThreadPool *)threadPool memoryCache:(EMInMemoryImageCache *)memoryCache;

@end
