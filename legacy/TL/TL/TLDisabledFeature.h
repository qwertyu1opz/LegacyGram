#ifndef TG_LEGACY_TL_TLDISABLEDFEATURE_H
#define TG_LEGACY_TL_TLDISABLEDFEATURE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLDisabledFeature : NSObject <TLObject>

@property (nonatomic, retain) NSString *feature;
@property (nonatomic, retain) NSString *n_description;

@end

@interface TLDisabledFeature$disabledFeature : TLDisabledFeature


@end

#endif
