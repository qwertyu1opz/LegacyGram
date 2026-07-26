#ifndef TG_LEGACY_TL_TLDESTROYSESSIONRES_H
#define TG_LEGACY_TL_TLDESTROYSESSIONRES_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLDestroySessionRes : NSObject <TLObject>

@property (nonatomic) int64_t session_id;

@end

@interface TLDestroySessionRes$destroy_session_ok : TLDestroySessionRes


@end

@interface TLDestroySessionRes$destroy_session_none : TLDestroySessionRes


@end

#endif
