#import "TGBridgeImageMediaAttachment.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@interface TGBridgeImageMediaAttachment (TGImageMediaAttachment)

+ (TGBridgeImageMediaAttachment *)attachmentWithTGImageMediaAttachment:(TGImageMediaAttachment *)attachment;

+ (TGImageMediaAttachment *)tgImageMediaAttachmentWithBridgeImageMediaAttachment:(TGBridgeImageMediaAttachment *)bridgeAttachment;

@end
