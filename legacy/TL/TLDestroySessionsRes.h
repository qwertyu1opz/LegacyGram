#ifndef TG_LEGACY_TL_TLDESTROYSESSIONSRES_H
#define TG_LEGACY_TL_TLDESTROYSESSIONSRES_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLDestroySessionsRes : NSObject <TLObject>

@property (nonatomic, retain) NSArray *destroy_results;

@end

@interface TLDestroySessionsRes$destroy_sessions_res : TLDestroySessionsRes


@end

#endif
