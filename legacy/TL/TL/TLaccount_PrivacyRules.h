#ifndef TG_LEGACY_TL_TLACCOUNT_PRIVACYRULES_H
#define TG_LEGACY_TL_TLACCOUNT_PRIVACYRULES_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLaccount_PrivacyRules : NSObject <TLObject>

@property (nonatomic, retain) NSArray *rules;
@property (nonatomic, retain) NSArray *users;

@end

@interface TLaccount_PrivacyRules$account_privacyRules : TLaccount_PrivacyRules


@end

#endif
