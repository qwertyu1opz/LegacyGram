#ifndef TG_LEGACY_TL_TLMESSAGES_CHAT_H
#define TG_LEGACY_TL_TLMESSAGES_CHAT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLChat;

@interface TLmessages_Chat : NSObject <TLObject>

@property (nonatomic, retain) TLChat *chat;
@property (nonatomic, retain) NSArray *users;

@end

@interface TLmessages_Chat$messages_chat : TLmessages_Chat


@end

#endif
