#ifndef TG_LEGACY_TL_TLRPCMESSAGES_REPORTENCRYPTEDSPAM_H
#define TG_LEGACY_TL_TLRPCMESSAGES_REPORTENCRYPTEDSPAM_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLInputEncryptedChat;

@interface TLRPCmessages_reportEncryptedSpam : TLMetaRpc

@property (nonatomic, retain) TLInputEncryptedChat *peer;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCmessages_reportEncryptedSpam$messages_reportEncryptedSpam : TLRPCmessages_reportEncryptedSpam


@end

#endif
