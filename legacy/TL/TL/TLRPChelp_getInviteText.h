#ifndef TG_LEGACY_TL_TLRPCHELP_GETINVITETEXT_H
#define TG_LEGACY_TL_TLRPCHELP_GETINVITETEXT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLhelp_InviteText;

@interface TLRPChelp_getInviteText : TLMetaRpc

@property (nonatomic, retain) NSString *lang_code;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPChelp_getInviteText$help_getInviteText : TLRPChelp_getInviteText


@end

#endif
