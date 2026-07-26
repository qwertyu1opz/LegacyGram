#ifndef TG_LEGACY_TL_TLSCHEMEMETHOD_H
#define TG_LEGACY_TL_TLSCHEMEMETHOD_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLSchemeMethod : NSObject <TLObject>

@property (nonatomic) int32_t n_id;
@property (nonatomic, retain) NSString *method;
@property (nonatomic, retain) NSArray *params;
@property (nonatomic, retain) NSString *type;

@end

@interface TLSchemeMethod$schemeMethod : TLSchemeMethod


@end

#endif
