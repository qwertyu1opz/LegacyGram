#ifndef TG_LEGACY_TL_TLSCHEMEPARAM_H
#define TG_LEGACY_TL_TLSCHEMEPARAM_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLSchemeParam : NSObject <TLObject>

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *type;

@end

@interface TLSchemeParam$schemeParam : TLSchemeParam


@end

#endif
