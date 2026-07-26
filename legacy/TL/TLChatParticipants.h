#ifndef TG_LEGACY_TL_TLCHATPARTICIPANTS_H
#define TG_LEGACY_TL_TLCHATPARTICIPANTS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLChatParticipants : NSObject <TLObject>

@property (nonatomic) int32_t chat_id;
@property (nonatomic, retain) NSArray *participants;
@property (nonatomic) int32_t version;

@end

@interface TLChatParticipants$chatParticipants : TLChatParticipants


@end

#endif
