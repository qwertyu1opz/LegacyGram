#ifndef TG_LEGACY_TL_TLRPCDESTROY_SESSIONS_H
#define TG_LEGACY_TL_TLRPCDESTROY_SESSIONS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLDestroySessionsRes;

@interface TLRPCdestroy_sessions : TLMetaRpc

@property (nonatomic, retain) NSArray *session_ids;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCdestroy_sessions$destroy_sessions : TLRPCdestroy_sessions


@end

#endif
