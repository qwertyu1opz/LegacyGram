#import "TGBridgeReplyMessageMediaAttachment.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@interface TGBridgeReplyMessageMediaAttachment (TGReplyMessageMediaAttachment)

+ (TGBridgeReplyMessageMediaAttachment *)attachmentWithTGReplyMessageMediaAttachment:(TGReplyMessageMediaAttachment *)attachment;

@end
