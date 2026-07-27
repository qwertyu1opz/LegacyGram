#import "TGBridgeVideoMediaAttachment.h"

#import "../../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@interface TGBridgeVideoMediaAttachment (TGVideoMediaAttachment)

+ (TGBridgeVideoMediaAttachment *)attachmentWithTGVideoMediaAttachment:(TGVideoMediaAttachment *)attachment;

+ (TGVideoMediaAttachment *)tgVideoMediaAttachmentWithBridgeVideoMediaAttachment:(TGBridgeVideoMediaAttachment *)bridgeAttachment;

@end
