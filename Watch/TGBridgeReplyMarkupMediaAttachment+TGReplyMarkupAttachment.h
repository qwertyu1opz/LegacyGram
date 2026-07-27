#import "TGBridgeReplyMarkupMediaAttachment.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@interface TGBridgeReplyMarkupMediaAttachment (TGReplyMarkupAttachment)

+ (TGBridgeReplyMarkupMediaAttachment *)attachmentWithTGReplyMarkupAttachment:(TGReplyMarkupAttachment *)attachment;

@end
