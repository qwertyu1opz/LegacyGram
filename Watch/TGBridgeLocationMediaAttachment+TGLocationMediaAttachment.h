#import "TGBridgeLocationMediaAttachment.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@interface TGBridgeLocationMediaAttachment (TGLocationMediaAttachment)

+ (TGBridgeLocationMediaAttachment *)attachmentWithTGLocationMediaAttachment:(TGLocationMediaAttachment *)attachment;

+ (TGLocationMediaAttachment *)tgLocationMediaAttachmentWithBridgeLocationMediaAttachment:(TGBridgeLocationMediaAttachment *)bridgeAttachment;

@end
