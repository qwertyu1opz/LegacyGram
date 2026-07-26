#ifndef TG_LEGACY_TL_TLCHATLOCATED_H
#define TG_LEGACY_TL_TLCHATLOCATED_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLChatLocated : NSObject <TLObject>

@property (nonatomic) int32_t chat_id;
@property (nonatomic) int32_t distance;

@end

@interface TLChatLocated$chatLocated : TLChatLocated


@end

#endif
