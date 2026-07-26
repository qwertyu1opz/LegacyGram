#ifndef TG_LEGACY_TL_TLRPCLANGPACK_GETLANGUAGES_H
#define TG_LEGACY_TL_TLRPCLANGPACK_GETLANGUAGES_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class NSArray_LangPackLanguage;

@interface TLRPClangpack_getLanguages : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPClangpack_getLanguages$langpack_getLanguages : TLRPClangpack_getLanguages


@end

#endif
