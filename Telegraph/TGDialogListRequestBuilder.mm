#import "TGDialogListRequestBuilder.h"
#import "IOS6Trace.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGTelegraph.h"

#import "TGMessage+Telegraph.h"
#import "TGConversation+Telegraph.h"

#import "../submodules/LegacyComponents/LegacyComponents/ActionStage.h"
#import "../submodules/LegacyComponents/LegacyComponents/SGraphListNode.h"

#import "TGUserDataRequestBuilder.h"

#import "TGDatabase.h"
#import "TGTelegramNetworking.h"
#import "TLPeerNotifySettings$peerNotifySettings.h"
#import "TLChat$chat.h"
#import "TLInputChannel.h"
#import "TLmessages_Dialogs.h"

#include <set>

#import "TGDownloadMessagesSignal.h"

#import "TLUser$modernUser.h"

#import "TGFeedPosition.h"

static inline bool TGIOS6DialogPeerIdLooksLikeModernRawChannel(int64_t peerId)
{
    return peerId <= ((int64_t)INT32_MIN) * 3 && peerId > ((int64_t)INT32_MIN) * 4;
}

static void TGIOS6DListMismatchLog(NSString *format, ...)
{
    // Private remote diagnostics are disabled in the public source snapshot.
    (void)format;
}

static void TGIOS6EnsureDialogListCacheVersion()
{
    const int32_t currentVersion = 6;
    NSData *data = [TGDatabaseInstance() customProperty:@"ios6DialogListCacheVersion"];
    int32_t storedVersion = 0;
    if (data.length == 4)
        [data getBytes:&storedVersion length:4];
    
    if (storedVersion == currentVersion)
        return;
    
    TGLog(@"IOS6ARCHIVE cache.reset old=%d new=%d", storedVersion, currentVersion);
    [TGDatabaseInstance() setCustomProperty:@"dialogListLoaded" value:nil];
    [TGDatabaseInstance() setCustomProperty:@"dialogListRemoteOffset" value:nil];
    [TGDatabaseInstance() setCustomProperty:@"dialogListHash" value:nil];
    [TGDatabaseInstance() setCustomProperty:@"ios6ArchivePeerIds" value:nil];
    [TGDatabaseInstance() setCustomProperty:@"ios6ArchivePeerIdsComplete" value:nil];
    [TGDatabaseInstance() setCustomProperty:@"ios6DialogListCacheVersion" value:[NSData dataWithBytes:&currentVersion length:4]];
}

@interface TGDialogListRequestBuilder ()
{
    std::set<int64_t> _ignoreConversationIds;
    NSArray *_cutoffConversations;
    int _lastRequestedLimit;
    int32_t _folderId;
}

@property (nonatomic) bool replaceList;

@end

@implementation TGDialogListRequestBuilder

+ (NSString *)genericPath
{
    return @"/tg/dialoglist/@";
}

- (void)prepare:(NSDictionary *)options
{
    if (![[options objectForKey:@"inline"] boolValue] && [options objectForKey:@"date"] == nil)
    {
        self.requestQueueName = @"messages";
    }
}

- (void)execute:(NSDictionary *)__unused options
{
    TGIOS6EnsureDialogListCacheVersion();
    
    NSNumber *date = [options objectForKey:@"date"];
    NSNumber *limitOption = [options objectForKey:@"limit"];
    NSNumber *force = [options objectForKey:@"force"];
    NSNumber *folderIdOption = [options objectForKey:@"folderId"];
    _folderId = folderIdOption == nil ? 0 : [folderIdOption intValue];
    IOS6Trace(@"IOS6FULL dialogList.execute path=%@ date=%@ limit=%@ force=%@ folder=%d inline=%@ replaceBefore=%d", self.path, date, limitOption, force, _folderId, [options objectForKey:@"inline"], _replaceList ? 1 : 0);
    
    if (date == nil)
    {
        _replaceList = true;
    
        int limit = limitOption == nil ? 50 : MAX(1, [limitOption intValue]);
        _lastRequestedLimit = limit;
//#ifdef DEBUG
//        limit = 5;
//#endif
        IOS6Trace(@"IOS6FULL dialogList.execute.initial limit=%d", limit);
        
        self.cancelToken = [TGTelegraphInstance doRequestDialogsListWithOffset:0 limit:limit folderId:_folderId requestArchive:(_folderId == 0) requestBuilder:self];
    }
    else if (force != nil)
    {
        NSData *data = [TGDatabaseInstance() customProperty:@"dialogListRemoteOffset"];
        TGDialogListRemoteOffset *remoteOffset = nil;
        if (data.length != 0) {
            remoteOffset = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        
        if (remoteOffset == nil) {
            remoteOffset = [[TGDialogListRemoteOffset alloc] initWithDate:[TGDatabaseInstance() loadConversationListRemoteOffsetDate] peerId:0 accessHash:0 messageId:0];
        }
        
        [ActionStageInstance() dispatchOnStageQueue:^
        {
            TGLog(@"Requesting dialog list with offset = %@", remoteOffset);
            IOS6Trace(@"IOS6FULL dialogList.execute.force offset=%@", remoteOffset);
            _lastRequestedLimit = 50;
            self.cancelToken = [TGTelegraphInstance doRequestDialogsListWithOffset:remoteOffset limit:_lastRequestedLimit folderId:_folderId requestArchive:(_folderId == 0) requestBuilder:self];
        }];
    }
    else
    {        
        int localLimit = limitOption == nil ? 50 : MAX(1, [limitOption intValue]);
        [TGDatabaseInstance() loadConversationListFromDate:[date intValue] limit:localLimit excludeConversationIds:options[@"excludeConversationIds"] folderId:_folderId completion:^(NSArray *result, bool loadedAllRegular)
        {
            bool dialogListLoaded = [TGDatabaseInstance() customProperty:@"dialogListLoaded"].length != 0;
            
            NSMutableArray *filteredResult = [[NSMutableArray alloc] initWithArray:result];
            [filteredResult sortUsingComparator:^NSComparisonResult(TGConversation *lhs, TGConversation *rhs) {
                if (lhs.date > rhs.date) {
                    return NSOrderedAscending;
                } else if (lhs.date < rhs.date) {
                    return NSOrderedDescending;
                } else {
                    if (lhs.conversationId < rhs.conversationId) {
                        return NSOrderedDescending;
                    } else {
                        return NSOrderedAscending;
                    }
                }
            }];
            
            _cutoffConversations = nil;
            
            if (filteredResult.count != 0 && (![force boolValue] || dialogListLoaded)) {
                IOS6Trace(@"IOS6FULL dialogList.execute.localPage count=%d loadedAll=%d dialogListLoaded=%d", (int)filteredResult.count, loadedAllRegular ? 1 : 0, dialogListLoaded ? 1 : 0);
                [ActionStageInstance() nodeRetrieved:self.path node:[[SGraphListNode alloc] initWithItems:filteredResult]];
                
                int32_t dateValue = [date intValue];
                if ((dateValue <= 0 || dateValue == INT_MAX) && dialogListLoaded)
                {
                    [ActionStageInstance() dispatchOnStageQueue:^
                    {
                        _replaceList = true;
                        _lastRequestedLimit = 50;
                        TGLog(@"IOS6ARCHIVE localCache.refreshRemote count=%d date=%d", (int)filteredResult.count, dateValue);
                        IOS6Trace(@"IOS6FULL archive.localCache.refreshRemote count=%d date=%d", (int)filteredResult.count, dateValue);
                        self.cancelToken = [TGTelegraphInstance doRequestDialogsListWithOffset:0 limit:_lastRequestedLimit requestBuilder:self];
                    }];
                }
            } else {
                IOS6Trace(@"IOS6FULL dialogList.execute.remotePage reason=localEmpty local=%d loadedAll=%d dialogListLoaded=%d", (int)filteredResult.count, loadedAllRegular ? 1 : 0, dialogListLoaded ? 1 : 0);
                NSData *data = [TGDatabaseInstance() customProperty:@"dialogListRemoteOffset"];
                TGDialogListRemoteOffset *remoteOffset = nil;
                if (data.length != 0) {
                    remoteOffset = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                }
                
                if (remoteOffset == nil) {
                    remoteOffset = [[TGDialogListRemoteOffset alloc] initWithDate:[TGDatabaseInstance() loadConversationListRemoteOffsetDate] peerId:0 accessHash:0 messageId:0];
                }
                
                [ActionStageInstance() dispatchOnStageQueue:^
                {
                    for (NSNumber *nConversationId in options[@"excludeConversationIds"])
                    {
                        _ignoreConversationIds.insert([nConversationId longLongValue]);
                    }
                    
                    TGLog(@"Requesting dialog list with offset = %@", remoteOffset);
                    IOS6Trace(@"IOS6FULL dialogList.execute.page offset=%@ exclude=%d", remoteOffset, (int)((NSArray *)options[@"excludeConversationIds"]).count);
                    _lastRequestedLimit = localLimit;
                    self.cancelToken = [TGTelegraphInstance doRequestDialogsListWithOffset:remoteOffset limit:_lastRequestedLimit requestBuilder:self];
                }];
            }
        }];
    }
}

- (void)dialogListRequestSuccess:(TLmessages_Dialogs *)dialogs
{
    IOS6Trace(@"IOS6FULL dialogList.success dialogs=%d messages=%d chats=%d users=%d replace=%d path=%@", (int)dialogs.dialogs.count, (int)dialogs.messages.count, (int)dialogs.chats.count, (int)dialogs.users.count, _replaceList ? 1 : 0, self.path);
    [TGUserDataRequestBuilder executeUserDataUpdate:dialogs.users];
    
    NSMutableDictionary *chatItems = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *channelItems = [[NSMutableDictionary alloc] init];
    int rawChatIndex = 0;
    
    for (TLChat *chatDesc in dialogs.chats)
    {
        TGConversation *conversation = [[TGConversation alloc] initWithTelegraphChatDesc:chatDesc];
        int64_t apiChannelId = TGIOS6ApiChannelIdForConversation(conversation);
        int64_t apiChatId = TGIOS6ApiChatIdForConversation(conversation);
        if (apiChannelId > 0)
        {
            [TGDatabaseInstance() setConversationCustomProperty:conversation.conversationId name:murMurHash32(@"ios6ApiChannelId") value:[NSData dataWithBytes:&apiChannelId length:sizeof(apiChannelId)]];
            [TGDatabaseInstance() setConversationCustomProperty:conversation.conversationId name:murMurHash32(@"ios6InvalidPeer") value:nil];
        }
        else if (apiChatId > 0)
        {
            [TGDatabaseInstance() setConversationCustomProperty:conversation.conversationId name:murMurHash32(@"ios6ApiChatId") value:[NSData dataWithBytes:&apiChatId length:sizeof(apiChatId)]];
            [TGDatabaseInstance() setConversationCustomProperty:conversation.conversationId name:murMurHash32(@"ios6InvalidPeer") value:nil];
        }
        IOS6Trace(@"IOS6FULL dialogList.rawChat[%d] tl=%@ rawId=%d convId=%lld title=%@ isChannel=%d group=%d min=%d left=%d kicked=%d access=%lld username=%@ kind=%d version=%d participants=%d", rawChatIndex, NSStringFromClass([chatDesc class]), chatDesc.n_id, conversation.conversationId, conversation.chatTitle, conversation.isChannel ? 1 : 0, conversation.isChannelGroup ? 1 : 0, conversation.isMin ? 1 : 0, conversation.leftChat ? 1 : 0, conversation.kickedFromChat ? 1 : 0, conversation.accessHash, conversation.username, (int)conversation.kind, conversation.chatVersion, conversation.chatParticipantCount);
        if ([conversation.chatTitle rangeOfString:@"Arbeit" options:NSCaseInsensitiveSearch].location != NSNotFound || [conversation.chatTitle rangeOfString:@"WSG" options:NSCaseInsensitiveSearch].location != NSNotFound)
        {
            int64_t migratedChannelId = 0;
            int64_t migratedAccessHash = 0;
            int32_t rawFlags = 0;
            if ([chatDesc isKindOfClass:[TLChat$chat class]])
            {
                TLChat$chat *chat = (TLChat$chat *)chatDesc;
                rawFlags = chat.flags;
                if ([chat.migrated_to isKindOfClass:[TLInputChannel$inputChannel class]])
                {
                    TLInputChannel$inputChannel *inputChannel = (TLInputChannel$inputChannel *)chat.migrated_to;
                    migratedChannelId = inputChannel.channel_id;
                    migratedAccessHash = inputChannel.access_hash;
                }
            }
            IOS6Trace(@"IOS6FULL dialogList.targetChat tl=%@ rawId=%d flags=0x%08x convId=%lld title=%@ isChannel=%d access=%lld migratedChannel=%lld migratedHash=%lld", NSStringFromClass([chatDesc class]), chatDesc.n_id, rawFlags, conversation.conversationId, conversation.chatTitle, conversation.isChannel ? 1 : 0, conversation.accessHash, migratedChannelId, migratedAccessHash);
        }
        rawChatIndex++;
        if (conversation.conversationId != 0) {
            if (conversation.isChannel) {
                channelItems[@(conversation.conversationId)] = conversation;
            } else {
                [chatItems setObject:conversation forKey:[NSNumber numberWithLongLong:conversation.conversationId]];
            }
        }
    }
    
    NSMutableArray *parsedMessages = [[NSMutableArray alloc] init];
    
    NSMutableDictionary *messagesDict = [[NSMutableDictionary alloc] init];
    for (TLMessage *messageDesc in dialogs.messages)
    {
        TGMessage *message = [[TGMessage alloc] initWithTelegraphMessageDesc:messageDesc];
        if (message.mid != 0)
        {
            IOS6Trace(@"IOS6FULL dialogList.message mid=%d cid=%lld from=%d to=%lld date=%d outgoing=%d text=%@", message.mid, message.cid, (int32_t)message.fromUid, message.toUid, (int32_t)message.date, message.outgoing ? 1 : 0, message.text);
            [parsedMessages addObject:message];
        }
    }
    IOS6Trace(@"IOS6FULL dialogList.parsed messages=%d chatItems=%d channelItems=%d", (int)parsedMessages.count, (int)chatItems.count, (int)channelItems.count);
    
    [[[TGDialogListRequestBuilder signalForCompleteMessages:parsedMessages channels:channelItems] catch:^SSignal *(__unused id error)
    {
        return [SSignal single:parsedMessages];
    }] startWithNext:^(NSArray *completeMessages)
    {
        NSMutableDictionary *multipleMessagesByConversation = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *updatePeerDrafts = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *resetPeerUnseenMentionsStates = [[NSMutableDictionary alloc] init];
        
        for (TGMessage *message in completeMessages)
        {
            if (!TGPeerIdIsChannel(message.cid)) {
                [messagesDict setObject:message forKey:[NSNumber numberWithInt:message.mid]];
            } else {
                NSMutableArray *array = multipleMessagesByConversation[@(message.cid)];
                if (array == nil) {
                    array = [[NSMutableArray alloc] init];
                    multipleMessagesByConversation[@(message.cid)] = array;
                }
                [array addObject:message];
            }
        }
        
        NSMutableArray *conversations = [[NSMutableArray alloc] init];
        NSMutableArray *channels = [[NSMutableArray alloc] init];
        NSMutableArray *feeds = [[NSMutableArray alloc] init];
        
        NSMutableArray *pinnedPeerIds = [[NSMutableArray alloc] init];
        
        int32_t unreadChatsCount = 0;
        int32_t unreadChannelsCount = 0;
        int dialogIndex = 0;
        int userDialogs = 0;
        int chatDialogs = 0;
        int channelDialogs = 0;
        int feedDialogs = 0;
        int archivedDialogs = 0;
        int skippedDialogs = 0;
        
        for (TLDialog *baseDialog in dialogs.dialogs)
        {
            if ([baseDialog isKindOfClass:[TLDialog$dialogMeta class]])
            {
                TLDialog$dialogMeta *dialog = (TLDialog$dialogMeta *)baseDialog;
                int64_t peerId = 0;
                if ([dialog.peer isKindOfClass:[TLPeer$peerUser class]])
                {
                    userDialogs++;
                    IOS6Trace(@"IOS6FULL dialogList.dialog[%d] type=user raw=%d top=%d unread=%d mentions=%d readIn=%d readOut=%d flags=%d pinned=%d draft=%@", dialogIndex, ((TLPeer$peerUser *)dialog.peer).user_id, dialog.top_message, dialog.unread_count, dialog.unread_mentions_count, dialog.read_inbox_max_id, dialog.read_outbox_max_id, dialog.flags, (dialog.flags & (1 << 2)) != 0 ? 1 : 0, NSStringFromClass([dialog.draft class]));
                    if (_ignoreConversationIds.find(((TLPeer$peerUser *)dialog.peer).user_id) == _ignoreConversationIds.end())
                    {
                        TGConversation *conversation = [[TGConversation alloc] initWithConversationId:((TLPeer$peerUser *)dialog.peer).user_id unreadCount:dialog.unread_count serviceUnreadCount:0];
                        peerId = conversation.conversationId;
                        
                        conversation.unreadMark = dialog.flags & (1 << 3);
                        conversation.maxReadMessageId = dialog.read_inbox_max_id;
                        conversation.maxOutgoingReadMessageId = dialog.read_outbox_max_id;
                        conversation.maxKnownMessageId = dialog.top_message;
                        conversation.isArchived = _folderId == 1 || dialog.folder_id == 1;
                        if (conversation.isArchived)
                            archivedDialogs++;
                        
                        TGMessage *message = [messagesDict objectForKey:[NSNumber numberWithInt:dialog.top_message]];
                        if (message != nil)
                            [conversation mergeMessage:message];
                        else if (dialog.top_message != 0)
                            TGIOS6DListMismatchLog(@"IOS6DLIST user.missingTop peer=%lld top=%d unread=%d convDate=%d folder=%d", peerId, dialog.top_message, dialog.unread_count, conversation.date, dialog.folder_id);
                        
                        if (conversation.conversationId != 0)
                        {
                            //TGLog(@"Dialog with %@", [TGDatabaseInstance() loadUser:conversation.conversationId].displayName);
                            
                            [conversations addObject:conversation];
                            
                            if (message != nil) {
                                NSMutableArray *array = multipleMessagesByConversation[@(conversation.conversationId)];
                                if (array == nil) {
                                    array = [[NSMutableArray alloc] init];
                                    multipleMessagesByConversation[@(conversation.conversationId)] = array;
                                }
                                [array addObject:message];
                            }
                        }
                        
                        if ([dialog.notify_settings isKindOfClass:[TLPeerNotifySettings$peerNotifySettings class]])
                        {
                            TLPeerNotifySettings$peerNotifySettings *concreteSettings = (TLPeerNotifySettings$peerNotifySettings *)dialog.notify_settings;
                            
                            NSNumber *peerSoundId = nil;
                            NSNumber *peerMuteUntil = nil;
                            NSNumber *peerPreviewText = nil;
                            NSNumber *messagesMuted = nil;
                            
                            if (concreteSettings.flags & (1 << 0)) {
                                peerPreviewText = @(concreteSettings.showPreviews);
                            }
                            if (concreteSettings.flags & (1 << 1)) {
                                messagesMuted = @(concreteSettings.silent);
                            }
                            if (concreteSettings.flags & (1 << 2)) {
                                if (concreteSettings.mute_until > [[TGTelegramNetworking instance] approximateRemoteTime])
                                    peerMuteUntil = @(concreteSettings.mute_until);
                                else
                                    peerMuteUntil = @0;
                            }
                            if (concreteSettings.flags & (1 << 3)) {
                                if (concreteSettings.sound.length == 0)
                                    peerSoundId = @(0);
                                else if ([concreteSettings.sound isEqualToString:@"default"])
                                    peerSoundId = @(1);
                                else
                                    peerSoundId = @([concreteSettings.sound intValue]);
                            }
                            
                            [TGDatabaseInstance() storePeerNotificationSettings:conversation.conversationId soundId:peerSoundId muteUntil:peerMuteUntil previewText:peerPreviewText messagesMuted:messagesMuted writeToActionQueue:false completion:nil];
                        }
                        
                        if (conversation.unreadMark || conversation.unreadCount > 0)
                            unreadChatsCount++;
                    }
                }
                else if ([dialog.peer isKindOfClass:[TLPeer$peerChat class]])
                {
                    chatDialogs++;
                    TGConversation *traceConversation = [chatItems objectForKey:[[NSNumber alloc] initWithLongLong:-((TLPeer$peerChat *)dialog.peer).chat_id]];
                    IOS6Trace(@"IOS6FULL dialogList.dialog[%d] type=chat raw=%d peer=%lld title=%@ top=%d unread=%d mentions=%d readIn=%d readOut=%d flags=%d pinned=%d draft=%@", dialogIndex, ((TLPeer$peerChat *)dialog.peer).chat_id, traceConversation.conversationId, traceConversation.chatTitle, dialog.top_message, dialog.unread_count, dialog.unread_mentions_count, dialog.read_inbox_max_id, dialog.read_outbox_max_id, dialog.flags, (dialog.flags & (1 << 2)) != 0 ? 1 : 0, NSStringFromClass([dialog.draft class]));
                    if (_ignoreConversationIds.find(-((TLPeer$peerChat *)dialog.peer).chat_id) == _ignoreConversationIds.end())
                    {
                        TGConversation *conversation = [chatItems objectForKey:[[NSNumber alloc] initWithLongLong:-((TLPeer$peerChat *)dialog.peer).chat_id]];
                        if (conversation == nil)
                        {
                            skippedDialogs++;
                            TGIOS6DListMismatchLog(@"IOS6DLIST chat.missingPeer chatId=%d top=%d unread=%d folder=%d", ((TLPeer$peerChat *)dialog.peer).chat_id, dialog.top_message, dialog.unread_count, dialog.folder_id);
                            dialogIndex++;
                            continue;
                        }
                        peerId = conversation.conversationId;
                        conversation.unreadMark = dialog.flags & (1 << 3);
                        conversation.unreadCount = dialog.unread_count;
                        conversation.maxReadMessageId = dialog.read_inbox_max_id;
                        conversation.maxOutgoingReadMessageId = dialog.read_outbox_max_id;
                        conversation.maxKnownMessageId = dialog.top_message;
                        conversation.isArchived = _folderId == 1 || dialog.folder_id == 1;
                        if (conversation.isArchived)
                            archivedDialogs++;
                        
                        TGMessage *message = [messagesDict objectForKey:[NSNumber numberWithInt:dialog.top_message]];
                        if (message != nil)
                            [conversation mergeMessage:message];
                        else if (dialog.top_message != 0)
                            TGIOS6DListMismatchLog(@"IOS6DLIST chat.missingTop peer=%lld title=%@ top=%d unread=%d convDate=%d folder=%d", peerId, conversation.chatTitle, dialog.top_message, dialog.unread_count, conversation.date, dialog.folder_id);
                        
                        if (conversation.conversationId != 0)
                        {
                            //TGLog(@"Chat %@", conversation.chatTitle);
                            
                            [conversations addObject:conversation];
                            
                            if (message != nil) {
                                NSMutableArray *array = multipleMessagesByConversation[@(conversation.conversationId)];
                                if (array == nil) {
                                    array = [[NSMutableArray alloc] init];
                                    multipleMessagesByConversation[@(conversation.conversationId)] = array;
                                }
                                [array addObject:message];
                            }
                        }
                        
                        if ([dialog.notify_settings isKindOfClass:[TLPeerNotifySettings$peerNotifySettings class]])
                        {
                            TLPeerNotifySettings$peerNotifySettings *concreteSettings = (TLPeerNotifySettings$peerNotifySettings *)dialog.notify_settings;
                            
                            NSNumber *peerSoundId = nil;
                            NSNumber *peerMuteUntil = nil;
                            NSNumber *peerPreviewText = nil;
                            NSNumber *messagesMuted = nil;
                            
                            if (concreteSettings.flags & (1 << 0)) {
                                peerPreviewText = @(concreteSettings.showPreviews);
                            }
                            if (concreteSettings.flags & (1 << 1)) {
                                messagesMuted = @(concreteSettings.silent);
                            }
                            if (concreteSettings.flags & (1 << 2)) {
                                if (concreteSettings.mute_until > [[TGTelegramNetworking instance] approximateRemoteTime])
                                    peerMuteUntil = @(concreteSettings.mute_until);
                                else
                                    peerMuteUntil = @0;
                            }
                            if (concreteSettings.flags & (1 << 3)) {
                                if (concreteSettings.sound.length == 0)
                                    peerSoundId = @(0);
                                else if ([concreteSettings.sound isEqualToString:@"default"])
                                    peerSoundId = @(1);
                                else
                                    peerSoundId = @([concreteSettings.sound intValue]);
                            }
                            
                            [TGDatabaseInstance() storePeerNotificationSettings:conversation.conversationId soundId:peerSoundId muteUntil:peerMuteUntil previewText:peerPreviewText messagesMuted:messagesMuted writeToActionQueue:false completion:nil];
                        }
                        
                        if (conversation.unreadMark || conversation.unreadCount > 0)
                            unreadChatsCount++;
                    }
                }
                else if ([dialog.peer isKindOfClass:[TLPeer$peerChannel class]]) {
                    channelDialogs++;
                    TGConversation *traceConversation = channelItems[@(TGPeerIdFromChannelId(((TLPeer$peerChannel *)dialog.peer).channel_id))];
                    IOS6Trace(@"IOS6FULL dialogList.dialog[%d] type=channel raw=%d peer=%lld title=%@ access=%lld group=%d min=%d top=%d unread=%d mentions=%d readIn=%d readOut=%d pts=%d flags=%d pinned=%d draft=%@", dialogIndex, ((TLPeer$peerChannel *)dialog.peer).channel_id, traceConversation.conversationId, traceConversation.chatTitle, traceConversation.accessHash, traceConversation.isChannelGroup ? 1 : 0, traceConversation.isMin ? 1 : 0, dialog.top_message, dialog.unread_count, dialog.unread_mentions_count, dialog.read_inbox_max_id, dialog.read_outbox_max_id, dialog.pts, dialog.flags, (dialog.flags & (1 << 2)) != 0 ? 1 : 0, NSStringFromClass([dialog.draft class]));
                    TGConversation *conversation = channelItems[@(TGPeerIdFromChannelId(((TLPeer$peerChannel *)dialog.peer).channel_id))];
                    if (conversation != nil) {
                        peerId = conversation.conversationId;
                        conversation.unreadMark = dialog.flags & (1 << 3);
                        conversation.unreadCount = dialog.unread_count;
                        conversation.maxReadMessageId = dialog.read_inbox_max_id;
                        conversation.maxOutgoingReadMessageId = dialog.read_outbox_max_id;
                        conversation.maxKnownMessageId = dialog.top_message;
                        conversation.isArchived = _folderId == 1 || dialog.folder_id == 1;
                        if (conversation.isArchived)
                            archivedDialogs++;
                        
                        NSArray *messages = multipleMessagesByConversation[@(peerId)];
                        TGMessage *message = nil;
                        if (messages.count != 0) {
                            NSArray *sortedMessages = [messages sortedArrayUsingComparator:^NSComparisonResult(TGMessage *lhs, TGMessage *rhs) {
                                int result = TGMessageTransparentSortKeyCompare(lhs.transparentSortKey, rhs.transparentSortKey);
                                if (result > 0) {
                                    return NSOrderedAscending;
                                } else if (result < 0) {
                                    return NSOrderedDescending;
                                } else {
                                    return NSOrderedSame;
                                }
                            }];
                            message = sortedMessages.lastObject;
                        }
                        if (message != nil)
                            [conversation mergeMessage:message];
                        else if (dialog.top_message != 0)
                            TGIOS6DListMismatchLog(@"IOS6DLIST channel.missingTop peer=%lld title=%@ top=%d unread=%d convDate=%d folder=%d", peerId, conversation.chatTitle, dialog.top_message, dialog.unread_count, conversation.date, dialog.folder_id);
                        
                        [channels addObject:conversation];
                        
                        if ([dialog.notify_settings isKindOfClass:[TLPeerNotifySettings$peerNotifySettings class]])
                        {
                            TLPeerNotifySettings$peerNotifySettings *concreteSettings = (TLPeerNotifySettings$peerNotifySettings *)dialog.notify_settings;
                            
                            NSNumber *peerSoundId = nil;
                            NSNumber *peerMuteUntil = nil;
                            NSNumber *peerPreviewText = nil;
                            NSNumber *messagesMuted = nil;
                            
                            if (concreteSettings.flags & (1 << 0)) {
                                peerPreviewText = @(concreteSettings.showPreviews);
                            }
                            if (concreteSettings.flags & (1 << 1)) {
                                messagesMuted = @(concreteSettings.silent);
                            }
                            if (concreteSettings.flags & (1 << 2)) {
                                if (concreteSettings.mute_until > [[TGTelegramNetworking instance] approximateRemoteTime])
                                    peerMuteUntil = @(concreteSettings.mute_until);
                                else
                                    peerMuteUntil = @0;
                            }
                            if (concreteSettings.flags & (1 << 3)) {
                                if (concreteSettings.sound.length == 0)
                                    peerSoundId = @(0);
                                else if ([concreteSettings.sound isEqualToString:@"default"])
                                    peerSoundId = @(1);
                                else
                                    peerSoundId = @([concreteSettings.sound intValue]);
                            }
                            
                            [TGDatabaseInstance() storePeerNotificationSettings:conversation.conversationId soundId:peerSoundId muteUntil:peerMuteUntil previewText:peerPreviewText messagesMuted:messagesMuted writeToActionQueue:false completion:nil];
                        }
                        
                        if (conversation.unreadMark || conversation.unreadCount > 0)
                            unreadChannelsCount++;
                    }
                    else
                    {
                        skippedDialogs++;
                        TGIOS6DListMismatchLog(@"IOS6DLIST channel.missingPeer channelId=%d top=%d unread=%d folder=%d", ((TLPeer$peerChannel *)dialog.peer).channel_id, dialog.top_message, dialog.unread_count, dialog.folder_id);
                    }
                }
                else
                {
                    skippedDialogs++;
                    TGLog(@"IOS6DIALOGS unknown dialog peer class=%@ top=%d flags=%d", NSStringFromClass([dialog.peer class]), dialog.top_message, dialog.flags);
                }
                
                if (peerId != 0) {
                    TGDatabaseMessageDraft *draft = nil;
                    if ([dialog.draft isKindOfClass:[TLDraftMessage$draftMessageMeta class]]) {
                        TLDraftMessage$draftMessageMeta *concreteDraft = (TLDraftMessage$draftMessageMeta *)dialog.draft;
                        draft = [[TGDatabaseMessageDraft alloc] initWithText:concreteDraft.message entities:[TGMessage parseTelegraphEntities:concreteDraft.entities] disableLinkPreview:concreteDraft.flags & (1 << 1) replyToMessageId:concreteDraft.reply_to_msg_id date:concreteDraft.date];
                    }
                    
                    if (draft != nil) {
                        updatePeerDrafts[@(peerId)] = draft == nil ? (id)[NSNull null] : draft;
                    }
                    
                    if (dialog.flags & (1 << 2)) {
                        [pinnedPeerIds addObject:@(peerId)];
                    }
                    
                    if (dialog.unread_mentions_count != 0) {
                        resetPeerUnseenMentionsStates[@(peerId)] = [[TGUnseenPeerMentionsState alloc] initWithVersion:0 count:dialog.unread_mentions_count maxIdWithPrecalculatedCount:dialog.top_message];
                    }
                }
            } else if ([baseDialog isKindOfClass:[TLDialog$dialogFeedMeta class]]) {
                feedDialogs++;
                TLDialog$dialogFeedMeta *dialog = (TLDialog$dialogFeedMeta *)baseDialog;
                IOS6Trace(@"IOS6FULL dialogList.dialog[%d] type=feed id=%d top=%d unread=%d muted=%d channels=%d", dialogIndex, dialog.feed_id, dialog.top_message, dialog.unread_count, dialog.unread_muted_count, (int)dialog.feed_other_channels.count);
                
                //NSMutableSet *channelIds = [[NSMutableSet alloc] init];
                NSMutableArray *chatIds = [[NSMutableArray alloc] init];
                NSMutableArray *chatTitles = [[NSMutableArray alloc] init];
                NSMutableArray *chatPhotosSmall = [[NSMutableArray alloc] init];
                for (NSNumber *channelId in dialog.feed_other_channels)
                {
                    //[channelIds addObject:@(TGPeerIdFromChannelId(channelId.intValue))];
                    
                    TGConversation *conversation = channelItems[@(TGPeerIdFromChannelId([channelId intValue]))];
                    if (conversation == nil)
                    {
                        TGIOS6DListMismatchLog(@"IOS6DLIST feed.missingChannel feed=%d channelId=%d top=%d unread=%d", dialog.feed_id, [channelId intValue], dialog.top_message, dialog.unread_count);
                        continue;
                    }
                    [chatIds addObject:@(conversation.conversationId)];
                    [chatTitles addObject:conversation.chatTitle ?: @""];
                    [chatPhotosSmall addObject:conversation.chatPhotoSmall ?: @""];
                }
                
                TGFeed *feed = [[TGFeed alloc] init];
                feed.fid = dialog.feed_id;
                //feed.channelIds = channelIds;
                feed.chatIds = chatIds;
                feed.chatTitles = chatTitles;
                feed.chatPhotosSmall = chatPhotosSmall;
                feed.maxReadPosition = [[TGFeedPosition alloc] initWithTelegraphDesc:dialog.read_max_position];
                feed.unreadCount = dialog.unread_count + dialog.unread_muted_count;
                
                TGMessage *message = [messagesDict objectForKey:[NSNumber numberWithInt:dialog.top_message]];
                if (message != nil)
                {
                    feed.messageDate = (int32_t)message.date;
                    feed.text = message.text;
                    feed.media = message.mediaAttachments;
                }
                else if (dialog.top_message != 0)
                {
                    TGIOS6DListMismatchLog(@"IOS6DLIST feed.missingTop feed=%d top=%d unread=%d channels=%d", dialog.feed_id, dialog.top_message, dialog.unread_count, (int)dialog.feed_other_channels.count);
                }
                
                [feeds addObject:feed];
            }
            else
            {
                skippedDialogs++;
                TGLog(@"IOS6DIALOGS unknown base dialog class=%@", NSStringFromClass([baseDialog class]));
            }
            dialogIndex++;
        }
        IOS6Trace(@"IOS6FULL dialogList.classified total=%d user=%d chat=%d channel=%d feed=%d archived=%d skipped=%d conversations=%d channels=%d feeds=%d", (int)dialogs.dialogs.count, userDialogs, chatDialogs, channelDialogs, feedDialogs, archivedDialogs, skippedDialogs, (int)conversations.count, (int)channels.count, (int)feeds.count);
        bool reachedFolderEnd = [dialogs isKindOfClass:[TLmessages_Dialogs$messages_dialogs class]];
        [TGDatabaseInstance() storeConversationList:conversations replace:(_replaceList && reachedFolderEnd) folderId:_folderId];
        [TGDatabaseInstance() storeSynchronizedChannels:channels];
        [TGDatabaseInstance() updateFeeds:feeds replace:false];
        IOS6Trace(@"IOS6FULL dialogList.stored conversations=%d channels=%d feeds=%d replace=%d", (int)conversations.count, (int)channels.count, (int)feeds.count, _replaceList ? 1 : 0);
        
        TGDialogListRemoteOffset *remoteOffset = nil;
        
        for (TLDialog *baseDialog in dialogs.dialogs) {
            if ([baseDialog isKindOfClass:[TLDialog$dialogMeta class]]) {
                TLDialog$dialogMeta *dialog = (TLDialog$dialogMeta *)baseDialog;
                int64_t peerId = 0;
                int64_t accessHash = 0;
                TGMessage *message = nil;
                if ([dialog.peer isKindOfClass:[TLPeer$peerChat class]]) {
                    peerId = TGPeerIdFromGroupId(((TLPeer$peerChat *)dialog.peer).chat_id);
                    message = [messagesDict objectForKey:[NSNumber numberWithInt:dialog.top_message]];
                } else if ([dialog.peer isKindOfClass:[TLPeer$peerUser class]]) {
                    peerId = ((TLPeer$peerUser *)dialog.peer).user_id;
                    message = [messagesDict objectForKey:[NSNumber numberWithInt:dialog.top_message]];
                    for (TLUser *user in dialogs.users) {
                        if ([user isKindOfClass:[TLUser$modernUser class]] && ((TLUser$modernUser *)user).n_id == peerId) {
                            accessHash = ((TLUser$modernUser *)user).access_hash;
                            break;
                        }
                    }
                } else if ([dialog.peer isKindOfClass:[TLPeer$peerChannel class]]) {
                    peerId = TGPeerIdFromChannelId(((TLPeer$peerChannel *)dialog.peer).channel_id);
                    for (TGConversation *conversation in channels) {
                        if (conversation.conversationId == peerId) {
                            accessHash = conversation.accessHash;
                            conversation.pts = dialog.pts;
                            break;
                        }
                    }
                    NSArray *messages = multipleMessagesByConversation[@(peerId)];
                    if (messages != nil) {
                        NSArray *sortedMessages = [messages sortedArrayUsingComparator:^NSComparisonResult(TGMessage *lhs, TGMessage *rhs) {
                            int result = TGMessageTransparentSortKeyCompare(lhs.transparentSortKey, rhs.transparentSortKey);
                            if (result > 0) {
                                return NSOrderedAscending;
                            } else if (result < 0) {
                                return NSOrderedDescending;
                            } else {
                                return NSOrderedSame;
                            }
                        }];
                        
                        message = sortedMessages.lastObject;
                    }
                }
                
                if (message != nil && (dialog.flags & (1 << 2)) == 0) {
                    TGDialogListRemoteOffset *currentOffset = [[TGDialogListRemoteOffset alloc] initWithDate:(int32_t)message.date peerId:peerId accessHash:accessHash messageId:message.mid];
                    if (remoteOffset == nil || [currentOffset compare:remoteOffset] == NSOrderedAscending) {
                        remoteOffset = currentOffset;
                    }
                }
            } else if ([baseDialog isKindOfClass:[TLDialog$dialogFeedMeta class]]) {
                TLDialog$dialogFeedMeta *dialog = (TLDialog$dialogFeedMeta *)baseDialog;
                int64_t conversationId = TGPeerIdFromAdminLogId(dialog.feed_id);
                TGMessage *message = [messagesDict objectForKey:[NSNumber numberWithInt:dialog.top_message]];
                
                if (message != nil) {
                    NSMutableArray *array = multipleMessagesByConversation[@(conversationId)];
                    if (array == nil) {
                        array = [[NSMutableArray alloc] init];
                        multipleMessagesByConversation[@(conversationId)] = array;
                    }
                    [array addObject:message];
                }
            }
        }
        
        if (remoteOffset != nil) {
            TGLog(@"storing offset %@", remoteOffset);
            IOS6Trace(@"IOS6FULL dialogList.remoteOffset.store %@", remoteOffset);
            if (_folderId == 0)
                [TGDatabaseInstance() setCustomProperty:@"dialogListRemoteOffset" value:[NSKeyedArchiver archivedDataWithRootObject:remoteOffset]];
            else
                TGLog(@"IOS6ARCHIVE archive builder skip main remoteOffset %@", remoteOffset);
        }
        else
        {
            TGLog(@"IOS6DIALOGS remoteOffset is nil after dialogs=%d", (int)dialogs.dialogs.count);
            IOS6Trace(@"IOS6FULL dialogList.remoteOffset.nil dialogs=%d", (int)dialogs.dialogs.count);
        }
        
        [multipleMessagesByConversation enumerateKeysAndObjectsUsingBlock:^(NSNumber *nConversationId, NSArray *messages, __unused  BOOL *stop)
        {
            int64_t conversationId = [nConversationId longLongValue];
            bool isModernRawChannel = TGIOS6DialogPeerIdLooksLikeModernRawChannel(conversationId) && channelItems[nConversationId] != nil;
            if (TGPeerIdIsAdminLog(conversationId) && !isModernRawChannel) {
                NSMutableArray *addedHoles = [[NSMutableArray alloc] init];
                
                NSArray *sortedMessages = [messages sortedArrayUsingComparator:^NSComparisonResult(TGMessage *lhs, TGMessage *rhs) {
                    int result = TGMessageTransparentSortKeyCompare(lhs.transparentSortKey, rhs.transparentSortKey);
                    if (result > 0) {
                        return NSOrderedAscending;
                    } else if (result < 0) {
                        return NSOrderedDescending;
                    } else {
                        return NSOrderedSame;
                    }
                }];
                
                for (NSUInteger i = 0; i < sortedMessages.count; i++) {
                    TGMessage *message = sortedMessages[i];
                    TGMessage *earlierMessage = i == sortedMessages.count - 1 ? nil : sortedMessages[i + 1];
                    if (earlierMessage == nil) {
                        [addedHoles addObject:[[TGMessageHole alloc] initWithMinId:1 minTimestamp:1 minPeerId:0 maxId:message.mid maxTimestamp:(int32_t)message.date maxPeerId:message.fromUid]];
                    } else {
                        [addedHoles addObject:[[TGMessageHole alloc] initWithMinId:earlierMessage.mid minTimestamp:(int32_t)earlierMessage.date maxId:message.mid maxTimestamp:(int32_t)message.date]];
                    }
                }
                
                [TGDatabaseInstance() addMessagesToFeed:TGAdminLogIdFromPeerId(conversationId) messages:messages deleteMessages:nil addedHoles:addedHoles removedHoles:nil keepUnreadCounters:true changedMessages:nil];
            }
            else if (TGPeerIdIsChannel(conversationId) || isModernRawChannel) {
                NSMutableArray *addedHoles = [[NSMutableArray alloc] init];
                
                NSArray *sortedMessages = [messages sortedArrayUsingComparator:^NSComparisonResult(TGMessage *lhs, TGMessage *rhs) {
                    int result = TGMessageTransparentSortKeyCompare(lhs.transparentSortKey, rhs.transparentSortKey);
                    if (result > 0) {
                        return NSOrderedAscending;
                    } else if (result < 0) {
                        return NSOrderedDescending;
                    } else {
                        return NSOrderedSame;
                    }
                }];
                
                for (NSUInteger i = 0; i < sortedMessages.count; i++) {
                    TGMessage *message = sortedMessages[i];
                    TGMessage *earlierMessage = i == sortedMessages.count - 1 ? nil : sortedMessages[i + 1];
                    if (earlierMessage == nil) {
                        if (message.mid != 1) {
                            [addedHoles addObject:[[TGMessageHole alloc] initWithMinId:1 minTimestamp:1 maxId:message.mid - 1 maxTimestamp:(int32_t)message.date]];
                        }
                    } else if (earlierMessage.mid != message.mid - 1) {
                        [addedHoles addObject:[[TGMessageHole alloc] initWithMinId:earlierMessage.mid + 1 minTimestamp:(int32_t)earlierMessage.date + 1 maxId:message.mid - 1 maxTimestamp:(int32_t)message.date]];
                    }
                }
                
                [TGDatabaseInstance() addMessagesToChannel:[nConversationId longLongValue] messages:messages deleteMessages:nil unimportantGroups:nil addedHoles:addedHoles removedHoles:nil removedUnimportantHoles:nil updatedMessageSortKeys:nil returnGroups:false keepUnreadCounters:true skipFeedUpdate:true changedMessages:nil];
            } else {
                [TGDatabaseInstance() transactionAddMessages:messages updateConversationDatas:nil notifyAdded:false];
                if (messages.count != 0) {
                    TGMessage *message = messages.firstObject;
                    [TGDatabaseInstance() fillConversationHistoryHole:[nConversationId longLongValue] indexSet:[NSIndexSet indexSetWithIndex:message.mid]];
                }
            }
        }];
        
        if (_replaceList)
        {
            [TGDatabaseInstance() setUnreadChatsCount:unreadChatsCount notify:false];
            [TGDatabaseInstance() setUnreadChannelsCount:unreadChannelsCount notify:true];
        }
        else
        {
            int previousUnreadChatsCount = [TGDatabaseInstance() unreadChatsCount];
            int previousUnreadChannelsCount = [TGDatabaseInstance() unreadChannelsCount];
            
            [TGDatabaseInstance() setUnreadChatsCount:previousUnreadChatsCount + unreadChatsCount notify:false];
            [TGDatabaseInstance() setUnreadChannelsCount:previousUnreadChannelsCount + unreadChannelsCount notify:true];
        }
        
        [TGDatabaseInstance() transactionAddMessages:nil notifyAddedMessages:false removeMessages:nil updateMessages:nil updatePeerDrafts:updatePeerDrafts removeMessagesInteractive:nil keepDates:false removeMessagesInteractiveForEveryone:false updateConversationDatas:nil applyMaxIncomingReadIds:nil applyMaxOutgoingReadIds:nil applyMaxOutgoingReadDates:nil applyUnreadMarks:nil readHistoryForPeerIds:nil resetPeerReadStates:nil resetPeerUnseenMentionsStates:resetPeerUnseenMentionsStates clearConversationsWithPeerIds:nil clearConversationsInteractive:false removeConversationsWithPeerIds:nil updatePinnedConversations:(_replaceList && _folderId == 0) ? pinnedPeerIds : nil synchronizePinnedConversations:false forceReplacePinnedConversations:false readMessageContentsInteractive:nil deleteEarlierHistory:nil updateFeededChannels:nil newlyJoinedFeedId:nil synchronizeFeededChannels:false calculateUnreadChats:false];
        
        [ActionStageInstance() dispatchResource:@"/dialogListReloaded" resource:@true];
        
        bool remoteListFullyLoaded = dialogs.dialogs.count == 0 || (_lastRequestedLimit > 0 && dialogs.dialogs.count < _lastRequestedLimit);
        IOS6Trace(@"IOS6FULL dialogList.loadedFlag replace=%d dialogs=%d limit=%d fully=%d", _replaceList ? 1 : 0, (int)dialogs.dialogs.count, _lastRequestedLimit, remoteListFullyLoaded ? 1 : 0);
        if (_folderId == 0)
        {
            if (remoteListFullyLoaded)
            {
                uint8_t loaded = 1;
                [TGDatabaseInstance() setCustomProperty:@"dialogListLoaded" value:[[NSData alloc] initWithBytes:&loaded length:1]];
            }
            else
            {
                [TGDatabaseInstance() setCustomProperty:@"dialogListLoaded" value:[NSData data]];
            }
        }
        else
            TGLog(@"IOS6ARCHIVE archive builder skip main loadedFlag dialogs=%d", (int)dialogs.dialogs.count);
        
        NSArray *dialogListItems = [conversations arrayByAddingObjectsFromArray:channels];
        SGraphListNode *dialogListNode = [[SGraphListNode alloc] initWithItems:dialogListItems];
        [ActionStageInstance() nodeRetrieved:self.path node:dialogListNode];
    }];
}

- (void)dialogListRequestNotModified:(int32_t)count
{
    IOS6Trace(@"IOS6FULL dialogList.notModified count=%d", count);
    
    [TGDatabaseInstance() loadConversationListFromDate:INT_MAX limit:50 excludeConversationIds:@[] folderId:0 completion:^(NSArray *result, __unused bool loadedAllRegular)
    {
        if (result.count != 0)
            [ActionStageInstance() nodeRetrieved:self.path node:[[SGraphListNode alloc] initWithItems:result]];
        [ActionStageInstance() dispatchResource:@"/dialogListReloaded" resource:@true];
    }];
}

- (void)dialogListRequestFailed
{
    TGLog(@"IOS6DIALOGS builder failed path=%@", self.path);
    if (_folderId != 0)
    {
        TGLog(@"IOS6ARCHIVE archive builder failed path=%@", self.path);
        [ActionStageInstance() nodeRetrieveFailed:self.path];
        return;
    }
    
    [TGDatabaseInstance() loadConversationListFromDate:INT_MAX limit:50 excludeConversationIds:@[] folderId:0 completion:^(NSArray *result, __unused bool loadedAllRegular)
    {
        if (result.count != 0 || _replaceList)
        {
            if (_replaceList)
            {
                uint8_t loaded = 1;
                [TGDatabaseInstance() setCustomProperty:@"dialogListLoaded" value:[[NSData alloc] initWithBytes:&loaded length:1]];
            }
            else
            {
                [TGDatabaseInstance() setCustomProperty:@"dialogListLoaded" value:[NSData data]];
            }
            TGLog(@"IOS6DIALOGS fallback local items=%d path=%@", (int)result.count, self.path);
            [ActionStageInstance() nodeRetrieved:self.path node:[[SGraphListNode alloc] initWithItems:result]];
        }
        else
        {
            [ActionStageInstance() nodeRetrieveFailed:self.path];
        }
    }];
}

+ (SSignal *)signalForCompleteMessages:(NSArray *)completeMessages channels:(NSDictionary *)channels
{
    NSMutableArray *downloadMessages = [[NSMutableArray alloc] init];
    
    for (TGMessage *message in completeMessages)
    {
        for (id attachment in message.mediaAttachments)
        {
            if ([attachment isKindOfClass:[TGReplyMessageMediaAttachment class]])
            {
                if (((TGReplyMessageMediaAttachment *)attachment).replyMessage == nil) {
                    if (TGPeerIdIsChannel(message.cid)) {
                        TGConversation *conversation = channels[@(message.cid)];
                        if (conversation != nil) {
                            [downloadMessages addObject:[[TGDownloadMessage alloc] initWithPeerId:message.cid accessHash:conversation.accessHash messageId:((TGReplyMessageMediaAttachment *)attachment).replyMessageId]];
                        }
                    } else {
                        [downloadMessages addObject:[[TGDownloadMessage alloc] initWithPeerId:0 accessHash:0 messageId:((TGReplyMessageMediaAttachment *)attachment).replyMessageId]];
                    }
                }
            }
        }
    }
    
    if (downloadMessages.count == 0)
        return [SSignal single:completeMessages];
    else
    {
        return [[TGDownloadMessagesSignal downloadMessages:downloadMessages] map:^id(NSArray *messages)
        {
            NSMutableDictionary *peerIdMessageIdToMessage = [[NSMutableDictionary alloc] init];
            for (TGMessage *message in messages)
            {
                peerIdMessageIdToMessage[[[NSString alloc] initWithFormat:@"%lld:%d", message.cid, message.mid]] = message;
            }
            
            for (TGMessage *message in completeMessages)
            {
                for (id attachment in message.mediaAttachments)
                {
                    if ([attachment isKindOfClass:[TGReplyMessageMediaAttachment class]])
                    {
                        TGMessage *requiredMessage = peerIdMessageIdToMessage[[[NSString alloc] initWithFormat:@"%lld:%d", message.cid, ((TGReplyMessageMediaAttachment *)attachment).replyMessageId]];
                        if (requiredMessage != nil)
                            ((TGReplyMessageMediaAttachment *)attachment).replyMessage = requiredMessage;
                        
                        break;
                    }
                }
            }
            
            return completeMessages;
        }];
    }
}


@end
