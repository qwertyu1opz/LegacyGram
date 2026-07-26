#ifndef TG_LEGACY_TL_TLMESSAGES_CHATFULL_H
#define TG_LEGACY_TL_TLMESSAGES_CHATFULL_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLChatFull;

@interface TLmessages_ChatFull : NSObject <TLObject>

@property (nonatomic, retain) TLChatFull *full_chat;
@property (nonatomic, retain) NSArray *chats;
@property (nonatomic, retain) NSArray *users;

@end

@interface TLmessages_ChatFull$messages_chatFull : TLmessages_ChatFull


@end

#endif
