#ifndef TG_LEGACY_TL_TLRPCMESSAGES_GETWEBPAGEPREVIEW_H
#define TG_LEGACY_TL_TLRPCMESSAGES_GETWEBPAGEPREVIEW_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLMessageMedia;

@interface TLRPCmessages_getWebPagePreview : TLMetaRpc

@property (nonatomic, retain) NSString *message;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_getWebPagePreview$messages_getWebPagePreview : TLRPCmessages_getWebPagePreview


@end

#endif
