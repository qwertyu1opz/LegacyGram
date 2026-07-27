#import "TGBridgeContactMediaAttachment.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@interface TGBridgeContactMediaAttachment (TGContactMediaAttachment)

+ (TGBridgeContactMediaAttachment *)attachmentWithTGContactMediaAttachment:(TGContactMediaAttachment *)attachment;

@end
