#ifndef TG_LEGACY_TL_TLLANGPACKLANGUAGE_H
#define TG_LEGACY_TL_TLLANGPACKLANGUAGE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLLangPackLanguage : NSObject <TLObject>

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *native_name;
@property (nonatomic, retain) NSString *lang_code;

@end

@interface TLLangPackLanguage$langPackLanguage : TLLangPackLanguage


@end

#endif
