#ifndef TG_LEGACY_TL_TLACCOUNT_WEBAUTHORIZATIONS_H
#define TG_LEGACY_TL_TLACCOUNT_WEBAUTHORIZATIONS_H

#import "TLObject.h"
#import "TLMetaRpc.h"

@interface TLaccount_WebAuthorizations : NSObject <TLObject>

@property (nonatomic, strong) NSArray *authorizations;
@property (nonatomic, strong) NSArray *users;

@end


@interface TLaccount_WebAuthorizations$account_webAuthorizations : TLaccount_WebAuthorizations


@end

#endif
