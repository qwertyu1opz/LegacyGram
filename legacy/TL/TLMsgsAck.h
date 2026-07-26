#ifndef TG_LEGACY_TL_TLMSGSACK_H
#define TG_LEGACY_TL_TLMSGSACK_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLMsgsAck : NSObject <TLObject>

@property (nonatomic, retain) NSArray *msg_ids;

@end

@interface TLMsgsAck$msgs_ack : TLMsgsAck


@end

#endif
