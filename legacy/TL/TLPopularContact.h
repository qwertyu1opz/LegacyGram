#ifndef TG_LEGACY_TL_TLPOPULARCONTACT_H
#define TG_LEGACY_TL_TLPOPULARCONTACT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLPopularContact : NSObject <TLObject>

@property (nonatomic) int64_t client_id;
@property (nonatomic) int32_t importers;

@end

@interface TLPopularContact$popularContact : TLPopularContact


@end

#endif
