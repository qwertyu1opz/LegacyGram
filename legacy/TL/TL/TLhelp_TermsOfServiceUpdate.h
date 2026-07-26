#ifndef TG_LEGACY_TL_TLHELP_TERMSOFSERVICEUPDATE_H
#define TG_LEGACY_TL_TLHELP_TERMSOFSERVICEUPDATE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLhelp_TermsOfService;

@interface TLhelp_TermsOfServiceUpdate : NSObject <TLObject>

@property (nonatomic) int32_t expires;

@end

@interface TLhelp_TermsOfServiceUpdate$help_termsOfServiceUpdateEmpty : TLhelp_TermsOfServiceUpdate

@end

@interface TLhelp_TermsOfServiceUpdate$help_termsOfServiceUpdate : TLhelp_TermsOfServiceUpdate

@property (nonatomic, retain) TLhelp_TermsOfService *terms_of_service;

@end

#endif
