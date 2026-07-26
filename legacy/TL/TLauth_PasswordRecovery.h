#ifndef TG_LEGACY_TL_TLAUTH_PASSWORDRECOVERY_H
#define TG_LEGACY_TL_TLAUTH_PASSWORDRECOVERY_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLauth_PasswordRecovery : NSObject <TLObject>

@property (nonatomic, retain) NSString *email_pattern;

@end

@interface TLauth_PasswordRecovery$auth_passwordRecovery : TLauth_PasswordRecovery


@end

#endif
