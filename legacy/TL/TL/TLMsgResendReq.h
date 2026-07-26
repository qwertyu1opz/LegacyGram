#ifndef TG_LEGACY_TL_TLMSGRESENDREQ_H
#define TG_LEGACY_TL_TLMSGRESENDREQ_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLMsgResendReq : NSObject <TLObject>

@property (nonatomic, retain) NSArray *msg_ids;

@end

@interface TLMsgResendReq$msg_resend_req : TLMsgResendReq


@end

#endif
