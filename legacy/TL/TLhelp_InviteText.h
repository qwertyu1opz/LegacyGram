#ifndef TG_LEGACY_TL_TLHELP_INVITETEXT_H
#define TG_LEGACY_TL_TLHELP_INVITETEXT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLhelp_InviteText : NSObject <TLObject>

@property (nonatomic, retain) NSString *message;

@end

@interface TLhelp_InviteText$help_inviteText : TLhelp_InviteText


@end

#endif
