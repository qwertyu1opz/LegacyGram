#ifndef TG_LEGACY_TL_TLAUTH_CHECKEDPHONE_H
#define TG_LEGACY_TL_TLAUTH_CHECKEDPHONE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLauth_CheckedPhone : NSObject <TLObject>

@property (nonatomic) bool phone_registered;

@end

@interface TLauth_CheckedPhone$auth_checkedPhone : TLauth_CheckedPhone


@end

#endif
