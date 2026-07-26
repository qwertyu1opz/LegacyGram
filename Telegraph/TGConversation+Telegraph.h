/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TL/TLMetaScheme.h"

#ifdef __cplusplus
extern "C" {
#endif

int64_t TGIOS6ApiChannelIdForConversation(TGConversation *conversation);
int64_t TGIOS6ApiChatIdForConversation(TGConversation *conversation);

#ifdef __cplusplus
}
#endif

@interface TGConversationParticipantsData (Telegraph)

- (id)initWithTelegraphParticipantsDesc:(TLChatParticipants *)participantsDesc;

@end

@interface TGConversation (Telegraph)

- (id)initWithTelegraphChatDesc:(TLChat *)chatDesc;
- (id)initWithTelegraphEncryptedChatDesc:(TLEncryptedChat *)chatDesc;

@end
