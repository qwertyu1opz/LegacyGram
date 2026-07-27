#import "TGBridgeForwardedMessageMediaAttachment.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@interface TGBridgeForwardedMessageMediaAttachment (TGForwardedMessageMediaAttachment)

+ (TGBridgeForwardedMessageMediaAttachment *)attachmentWithTGForwardedMessageMediaAttachment:(TGForwardedMessageMediaAttachment *)attachment;

@end
