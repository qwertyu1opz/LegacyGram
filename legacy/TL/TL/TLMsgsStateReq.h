#ifndef TG_LEGACY_TL_TLMSGSSTATEREQ_H
#define TG_LEGACY_TL_TLMSGSSTATEREQ_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLMsgsStateReq : NSObject <TLObject>

@property (nonatomic, retain) NSArray *msg_ids;

@end

@interface TLMsgsStateReq$msgs_state_req : TLMsgsStateReq


@end

#endif
