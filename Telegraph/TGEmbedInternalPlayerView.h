#import "../submodules/LegacyComponents/LegacyComponents/TGEmbedPlayerView.h"

@interface TGEmbedInternalPlayerView : TGEmbedPlayerView

- (instancetype)initWithDocumentAttachment:(TGDocumentMediaAttachment *)attachment thumbnailSignal:(SSignal *)thumbnailSignal;

@end
