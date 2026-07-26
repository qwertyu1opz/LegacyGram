#ifndef TG_LEGACY_TL_TLACCOUNT_AUTHORIZATIONS_H
#define TG_LEGACY_TL_TLACCOUNT_AUTHORIZATIONS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLaccount_Authorizations : NSObject <TLObject>

@property (nonatomic, retain) NSArray *authorizations;

@end

@interface TLaccount_Authorizations$account_authorizations : TLaccount_Authorizations


@end

#endif
