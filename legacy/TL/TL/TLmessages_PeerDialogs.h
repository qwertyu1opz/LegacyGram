#ifndef TG_LEGACY_TL_TLMESSAGES_PEERDIALOGS_H
#define TG_LEGACY_TL_TLMESSAGES_PEERDIALOGS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLupdates_State;

@interface TLmessages_PeerDialogs : NSObject <TLObject>

@property (nonatomic, retain) NSArray *dialogs;
@property (nonatomic, retain) NSArray *messages;
@property (nonatomic, retain) NSArray *chats;
@property (nonatomic, retain) NSArray *users;
@property (nonatomic, retain) TLupdates_State *state;

@end

@interface TLmessages_PeerDialogs$messages_peerDialogs : TLmessages_PeerDialogs


@end

#endif
