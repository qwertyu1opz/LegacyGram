#ifndef TG_LEGACY_TL_TLRPCLANGPACK_GETSTRINGS_H
#define TG_LEGACY_TL_TLRPCLANGPACK_GETSTRINGS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class NSArray_LangPackString;

@interface TLRPClangpack_getStrings : TLMetaRpc

@property (nonatomic, retain) NSString *lang_code;
@property (nonatomic, retain) NSArray *keys;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPClangpack_getStrings$langpack_getStrings : TLRPClangpack_getStrings


@end

#endif
