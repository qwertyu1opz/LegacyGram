#ifndef TG_LEGACY_TL_TLLANGPACKDIFFERENCE_H
#define TG_LEGACY_TL_TLLANGPACKDIFFERENCE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLLangPackDifference : NSObject <TLObject>

@property (nonatomic, retain) NSString *lang_code;
@property (nonatomic) int32_t from_version;
@property (nonatomic) int32_t version;
@property (nonatomic, retain) NSArray *strings;

@end

@interface TLLangPackDifference$langPackDifference : TLLangPackDifference


@end

#endif
