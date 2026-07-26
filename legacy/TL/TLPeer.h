#ifndef TG_LEGACY_TL_TLPEER_H
#define TG_LEGACY_TL_TLPEER_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLPeer : NSObject <TLObject>


@end

@interface TLPeer$peerUser : TLPeer

@property (nonatomic) int32_t user_id;

@end

@interface TLPeer$peerChat : TLPeer

@property (nonatomic) int32_t chat_id;

@end

@interface TLPeer$peerChannel : TLPeer

@property (nonatomic) int32_t channel_id;

@end

#endif
