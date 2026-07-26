#ifndef TG_LEGACY_TL_TLRPCLANGPACK_GETLANGPACK_H
#define TG_LEGACY_TL_TLRPCLANGPACK_GETLANGPACK_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLLangPackDifference;

@interface TLRPClangpack_getLangPack : TLMetaRpc

@property (nonatomic, retain) NSString *lang_code;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPClangpack_getLangPack$langpack_getLangPack : TLRPClangpack_getLangPack


@end

#endif
