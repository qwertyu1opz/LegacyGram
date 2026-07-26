#import "../submodules/LegacyComponents/LegacyComponents/TGMenuSheetItemView.h"

@class TGDocumentMediaAttachment;

@interface TGPreviewStickerItemView : TGMenuSheetItemView

- (instancetype)initWithDocument:(TGDocumentMediaAttachment *)document;

@end
