#import "TGBridgeAudioMediaAttachment.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@interface TGBridgeAudioMediaAttachment (TGAudioMediaAttachment)

+ (TGBridgeAudioMediaAttachment *)attachmentWithTGAudioMediaAttachment:(TGAudioMediaAttachment *)attachment;

+ (TGAudioMediaAttachment *)tgAudioMediaAttachmentWithBridgeAudioMediaAttachment:(TGBridgeAudioMediaAttachment *)bridgeAttachment;

@end
