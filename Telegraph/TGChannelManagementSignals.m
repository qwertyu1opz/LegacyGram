#import "TGChannelManagementSignals.h"

#import "IOS6Trace.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TL/TLMetaScheme.h"
#import "TGTelegramNetworking.h"

#import "TLUpdates+TG.h"
#import "TGDatabase.h"
#import "TGTelegraph.h"

#import "TGConversation+Telegraph.h"
#import "TGMessage+Telegraph.h"
#import "TGUser+Telegraph.h"

#import "TGUserDataRequestBuilder.h"

#import "TLmessages_Messages$modernChannelMessages.h"
#import "TLUpdates_ChannelDifference_manual.h"
#import "TLPeerNotifySettings$peerNotifySettings.h"

#import "TGUpdateStateRequestBuilder.h"

#import "TLChat$channel.h"

#import "TGChannelStateSignals.h"
#import "TGDownloadMessagesSignal.h"

#import "TLChatFull$channelFull.h"

#import "TGBotSignals.h"
#import "TGStickersSignals.h"

#import "TLRPCmessages_editMessage.h"

#import "TLUpdate$updateChannelTooLong.h"

#import "TGChannelBannedRights+Telegraph.h"
#import "TGChannelAdminRights+Telegraph.h"

#import "TLRPCchannels_getAdminLog.h"
#import "TLRPCmessages_markDialogUnread.h"

static inline bool TGIOS6ChannelPeerIdIsModernRawChannel(int64_t peerId, int64_t accessHash)
{
    int64_t channelId = -peerId - 4294967296LL;
    return accessHash != 0 && channelId > 0 && channelId <= UINT32_MAX;
}

static inline bool TGIOS6ChannelPeerIdIsModernChannel(int64_t peerId, int64_t accessHash)
{
    return TGIOS6ChannelPeerIdIsModernRawChannel(peerId, accessHash) || TGPeerIdIsChannel(peerId);
}

static inline int64_t TGIOS6ChannelIdFromPeerId(int64_t peerId, int64_t accessHash)
{
    NSData *apiIdData = [TGDatabaseInstance() conversationCustomPropertySync:peerId name:murMurHash32(@"ios6ApiChannelId")];
    int64_t apiChannelId = 0;
    if (apiIdData.length == sizeof(int64_t))
        [apiIdData getBytes:&apiChannelId length:sizeof(apiChannelId)];
    if (apiChannelId > 0)
        return apiChannelId;

    if (TGIOS6ChannelPeerIdIsModernRawChannel(peerId, accessHash))
        return -peerId - 4294967296LL;

    int32_t channelId = TGChannelIdFromPeerId(peerId);
    if (channelId != 0)
        return channelId < 0 ? (int64_t)(uint32_t)channelId : (int64_t)channelId;
    
    return 0;
}

static inline int64_t TGIOS6ChannelAccessHashForPeerId(int64_t peerId, int64_t accessHash)
{
    TGConversation *conversation = [TGDatabaseInstance() loadConversationWithId:peerId];
    if (conversation != nil && conversation.accessHash != 0 && conversation.accessHash != accessHash)
    {
        TGLog(@"IOS6AUTH channel accessHash repair peer=%lld old=%lld db=%lld", peerId, accessHash, conversation.accessHash);
        return conversation.accessHash;
    }

    return accessHash;
}

static inline void TGIOS6MarkChannelInvalidPeer(int64_t peerId, NSString *reason)
{
    uint8_t one = 1;
    [TGDatabaseInstance() setConversationCustomProperty:peerId name:murMurHash32(@"ios6InvalidPeer") value:[NSData dataWithBytes:&one length:1]];
    TGLog(@"IOS6FULL channel.markInvalidPeer peer=%lld reason=%@", peerId, reason);
}

@implementation TGChannelManagementSignals

+ (SSignal *)makeChannelWithTitle:(NSString *)title about:(NSString *)about group:(bool)group
{
    TLRPCchannels_createChannel$channels_createChannel *createChannel = [[TLRPCchannels_createChannel$channels_createChannel alloc] init];
    createChannel.title = title;
    if (group) {
        createChannel.flags = (1 << 1);
    } else {
        createChannel.flags = (1 << 0);
    }
    createChannel.about = about;
    return [[[TGTelegramNetworking instance] requestSignal:createChannel continueOnServerErrors:false failOnFloodErrors:true] mapToSignal:^SSignal *(TLUpdates *updates) {
        TLChat *chat = [updates chats].firstObject;
        if (chat == nil) {
            return [SSignal fail:nil];
        } else {
            TGConversation *conversation = [[TGConversation alloc] initWithTelegraphChatDesc:chat];
            if (conversation.conversationId == 0)
                return [SSignal fail:nil];
            else
            {
                return [[TGDatabaseInstance() modifyChannel:conversation.conversationId block:^id(__unused int32_t pts) {
                    [TGDatabaseInstance() initializeChannel:conversation];
                    [TGChannelStateSignals addChannelUpdates:conversation.conversationId updates:updates.updatesList];
                    
                    return [[[[TGDatabaseInstance() existingChannel:conversation.conversationId] take:1] mapToSignal:^SSignal *(TGConversation *next) {
                        
                        return [SSignal single:next];
                    }] timeout:6.0 onQueue:[SQueue concurrentDefaultQueue] orSignal:[SSignal fail:nil]];
                }] switchToLatest];
            }
        }
    }];
}

+ (SSignal *)preloadChannelTail:(int64_t)peerId accessHash:(int64_t)accessHash important:(bool)important {
    TGMessageHole *hole = [[TGMessageHole alloc] initWithMinId:1 minTimestamp:1 maxId:INT32_MAX maxTimestamp:INT32_MAX];
    
    [TGDatabaseInstance() addMessagesToChannel:peerId messages:nil deleteMessages:nil unimportantGroups:nil addedHoles:@[hole] removedHoles:nil removedUnimportantHoles:nil updatedMessageSortKeys:nil returnGroups:false keepUnreadCounters:false skipFeedUpdate:true changedMessages:nil];
    
    return [[self channelMessageHoleForPeerId:peerId accessHash:accessHash hole:hole direction:TGChannelHistoryHoleDirectionEarlier important:important] mapToSignal:^SSignal *(NSDictionary *dict) {
        NSArray *removedImportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
        NSArray *removedUnimportantHoles = nil;
        
        return [[TGDatabaseInstance() modify:^id {
            [TGDatabaseInstance() addMessagesToChannel:peerId messages:dict[@"messages"] deleteMessages:nil unimportantGroups:dict[@"unimportantGroups"] addedHoles:nil removedHoles:removedImportantHoles removedUnimportantHoles:removedUnimportantHoles updatedMessageSortKeys:nil returnGroups:important keepUnreadCounters:false skipFeedUpdate:true changedMessages:nil];
            if ([dict[@"pts"] intValue] > 0) {
                [TGDatabaseInstance() addMessagesToChannelAndDispatch:peerId messages:nil deletedMessages:nil holes:nil pts:[dict[@"pts"] intValue] skipFeedUpdate:true];
            }
            
            return [SSignal complete];
        }] switchToLatest];
    }];
}

+ (SSignal *)addChannel:(TGConversation *)conversation {
    return [[TGDatabaseInstance() modifyChannel:conversation.conversationId block:^id(int32_t pts) {
        [TGDatabaseInstance() updateChannels:@[conversation]];
        
        SSignal *signal = [SSignal complete];
        
        if (pts <= 1) {
            signal = [self preloadChannelTail:conversation.conversationId accessHash:conversation.accessHash important:!conversation.isChannelGroup];
        } else {
            signal = [[TGChannelStateSignals pollOnce:conversation.conversationId] mapToSignal:^SSignal *(__unused id next) {
                return [SSignal complete];
            }];
        }

        return [signal then:[[[[TGDatabaseInstance() existingChannel:conversation.conversationId] take:1] mapToSignal:^SSignal *(TGConversation *next) {
            
            return [SSignal single:next];
        }] timeout:6.0 onQueue:[SQueue concurrentDefaultQueue] orSignal:[SSignal fail:nil]]];
    }] switchToLatest];
}

static dispatch_block_t recursiveBlock(void (^block)(dispatch_block_t recurse))
{
    return ^
    {
        block(recursiveBlock(block));
    };
}

+ (bool)_containsPreloadedHistoryForPeerId:(int64_t)peerId aroundMessageId:(int32_t)messageId {
    __block bool result = false;
    [TGDatabaseInstance() dispatchOnDatabaseThread:^{
        __block bool messageExists = false;
        __block TGMessageSortKey messageSortKey;
        
        [TGDatabaseInstance() closestChannelMessageKey:peerId messageId:messageId completion:^(bool exists, TGMessageSortKey key) {
            messageExists = exists;
            messageSortKey = key;
        }];
        
        if (!messageExists) {
            result = false;
        } else {
            __block bool hasHoles = false;
            [TGDatabaseInstance() channelMessages:peerId maxTransparentSortKey:TGMessageTransparentSortKeyMake(peerId, TGMessageSortKeyTimestamp(messageSortKey), messageId, TGMessageSortKeySpace(messageSortKey)) count:30 important:false mode:TGChannelHistoryRequestLater completion:^(NSArray *messages, __unused bool hasLater) {
                for (TGMessage *message in messages) {
                    if (message.hole != nil) {
                        hasHoles = true;
                        break;
                    }
                }
            }];
            
            if (!hasHoles) {
                result = true;
            } else {
                result = false;
            }
        }
    } synchronous:true];
    
    return result;
}

+ (SSignal *)messagesWithDownloadedReplyMessages:(int64_t)peerId accessHash:(int64_t)accessHash messages:(NSArray *)messages {
    return [SSignal defer:^SSignal *{
        NSMutableDictionary *addedMessageIdToMessage = [[NSMutableDictionary alloc] init];
        for (TGMessage *message in messages) {
            addedMessageIdToMessage[@(message.mid)] = message;
        }
        
        NSUInteger unresolvedReplyCount = 0;
        
        for (TGMessage *message in messages) {
            if (message.mediaAttachments.count != 0) {
                for (id attachment in message.mediaAttachments) {
                    if ([attachment isKindOfClass:[TGReplyMessageMediaAttachment class]]) {
                        TGReplyMessageMediaAttachment *replyAttachment = attachment;
                        if (replyAttachment.replyMessage == nil && replyAttachment.replyMessageId != 0) {
                            TGMessage *replyMessage = addedMessageIdToMessage[@(replyAttachment.replyMessageId)];
                            if (replyMessage != nil) {
                                replyAttachment.replyMessage = replyMessage;
                            } else {
                                unresolvedReplyCount++;
                            }
                        }
                    }
                }
            }
        }
        
        // History must not wait for auxiliary reply lookups. A deleted or
        // inaccessible reply target can otherwise hold the entire initial
        // channel page forever, leaving only the dialog's top message visible.
        // Reply targets already present in this page were linked above; missing
        // targets can be resolved later without blocking the conversation.
        if (unresolvedReplyCount != 0)
            IOS6Trace(@"IOS6HISTORY replyLookupDeferred peer=%lld messages=%d replies=%d", peerId, (int)messages.count, (int)unresolvedReplyCount);
        return [SSignal single:messages];
    }];
}

+ (SSignal *)preloadedHistoryForPeerId:(int64_t)peerId accessHash:(int64_t)accessHash aroundMessageId:(int32_t)messageId {
    int32_t limit = 64;
    IOS6Trace(@"IOS6TRACE channelHistoryAround start peer=%lld hash=%lld around=%d limit=%d", peerId, accessHash, messageId, limit);
    
    return [[TGDatabaseInstance() modifyChannel:peerId block:^id(__unused int32_t pts) {
        __block bool messageExists = false;
        __block TGMessageSortKey messageSortKey;
        [TGDatabaseInstance() channelMessageExists:peerId messageId:messageId completion:^(bool exists, TGMessageSortKey key) {
            messageExists = exists;
            messageSortKey = key;
        }];
        
        if (messageExists) {
            __block bool hasHoles = false;
            [TGDatabaseInstance() channelMessages:peerId maxTransparentSortKey:TGMessageTransparentSortKeyMake(peerId, TGMessageSortKeyTimestamp(messageSortKey), messageId, TGMessageSortKeySpace(messageSortKey)) count:30 important:false mode:TGChannelHistoryRequestAround completion:^(NSArray *messages, __unused bool hasLater) {
                for (TGMessage *message in messages) {
                    if (message.hole != nil) {
                        hasHoles = true;
                        break;
                    }
                }
            }];
            
            if (!hasHoles) {
                IOS6Trace(@"IOS6TRACE channelHistoryAround cacheHit peer=%lld around=%d hasHoles=0", peerId, messageId);
                return [SSignal single:@{}];
            }
        }
        
        TLRPCmessages_getHistory$messages_getHistory *getHistory = [[TLRPCmessages_getHistory$messages_getHistory alloc] init];
        TLInputPeer$inputPeerChannel *inputChannel = [[TLInputPeer$inputPeerChannel alloc] init];
        inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
        inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
        if (inputChannel.access_hash == 0)
        {
            IOS6Trace(@"IOS6HISTORY aroundMissingAccessHash peer=%lld channel=%lld originalHash=%lld", peerId, inputChannel.channel_id, accessHash);
            return [SSignal single:@{}];
        }
        getHistory.peer = inputChannel;
        getHistory.min_id = 1;
        getHistory.max_id = INT32_MAX;
        getHistory.offset_id = messageId;
        getHistory.add_offset = -limit / 2;
        getHistory.limit = limit;
        IOS6Trace(@"IOS6TRACE channelHistoryAround request peer=%lld channel=%lld hash=%lld min=%d max=%d offset=%d add=%d limit=%d", peerId, inputChannel.channel_id, inputChannel.access_hash, getHistory.min_id, getHistory.max_id, getHistory.offset_id, getHistory.add_offset, getHistory.limit);
        
        return [[[[TGTelegramNetworking instance] requestSignal:getHistory] mapToSignal:^SSignal *(TLmessages_Messages *messages) {
            [TGUserDataRequestBuilder executeUserDataUpdate:messages.users];
            IOS6Trace(@"IOS6TRACE channelHistoryAround success peer=%lld messages=%d chats=%d users=%d response=%@", peerId, (int)messages.messages.count, (int)messages.chats.count, (int)messages.users.count, NSStringFromClass([messages class]));
            
            int32_t pts = 0;
            NSArray *collapsed = nil;
            if ([messages isKindOfClass:[TLmessages_Messages$modernChannelMessages class]]) {
                TLmessages_Messages$modernChannelMessages *concreteMessages = (TLmessages_Messages$modernChannelMessages *)messages;
                pts = concreteMessages.pts;
                collapsed = concreteMessages.collapsed;
            }
            
            int32_t minParsedId = 0;
            int32_t maxParsedId = 0;
            int32_t maxParsedDate = 0;
            int32_t minParsedDate = 0;
            NSMutableArray *parsedMessages = [[NSMutableArray alloc] init];
            for (id desc in messages.messages) {
                TGMessage *message = [[TGMessage alloc] initWithTelegraphMessageDesc:desc];
                message.pts = pts;
                if (message.mid != 0) {
                    [parsedMessages addObject:message];
                    if (minParsedId == 0 || minParsedId > message.mid) {
                        minParsedId = message.mid;
                        minParsedDate = (int32_t)message.date;
                    }
                    
                    if (maxParsedId == 0 || maxParsedId < message.mid) {
                        maxParsedId = message.mid;
                        maxParsedDate = (int32_t)message.date;
                    }
                }
            }
            
            return [[self messagesWithDownloadedReplyMessages:peerId accessHash:accessHash messages:parsedMessages] mapToSignal:^SSignal *(NSArray *parsedMessages) {
                TGMessageHole *closedHole = [[TGMessageHole alloc] initWithMinId:minParsedId minTimestamp:minParsedDate maxId:maxParsedId maxTimestamp:maxParsedDate];
                
                return [SSignal single:@{@"messages": parsedMessages, @"hole": closedHole}];
            }];
        }] catch:^SSignal *(id error) {
            IOS6Trace(@"IOS6TRACE channelHistoryAround error peer=%lld channel=%lld hash=%lld error=%@", peerId, inputChannel.channel_id, inputChannel.access_hash, error);
            return [SSignal single:@{}];
        }];
    }] switchToLatest];
}

+ (SSignal *)preloadedHistoryTailForPeerId:(int64_t)peerId accessHash:(int64_t)accessHash {
    int32_t limit = 64;
    IOS6Trace(@"IOS6TRACE channelHistoryTail start peer=%lld hash=%lld limit=%d", peerId, accessHash, limit);
    
    return [[TGDatabaseInstance() modify:^{
        __block bool hasHoles = false;
        __block int32_t existingCount = 0;
        [TGDatabaseInstance() channelMessages:peerId maxTransparentSortKey:TGMessageTransparentSortKeyUpperBound(peerId) count:50 important:false mode:TGChannelHistoryRequestEarlier completion:^(NSArray *messages, __unused bool hasLater) {
            existingCount = (int32_t)messages.count;
            for (TGMessage *message in messages) {
                if (message.hole != nil) {
                    hasHoles = true;
                    break;
                }
            }
        }];
        
        bool forceRemoteTailRefresh = TGIOS6ChannelPeerIdIsModernRawChannel(peerId, accessHash);
        // One locally delivered message is not proof that channel history is
        // complete. Sparse caches must be refreshed from the server.
        if (existingCount >= 20 && !hasHoles && !forceRemoteTailRefresh) {
            IOS6Trace(@"IOS6TRACE channelHistoryTail cacheHit peer=%lld existing=%d hasHoles=0", peerId, existingCount);
            return [SSignal single:@{}];
        }
        IOS6Trace(@"IOS6TRACE channelHistoryTail remoteRequired peer=%lld existing=%d hasHoles=%d forceModern=%d", peerId, existingCount, hasHoles ? 1 : 0, forceRemoteTailRefresh ? 1 : 0);
        TLRPCmessages_getHistory$messages_getHistory *getHistory = [[TLRPCmessages_getHistory$messages_getHistory alloc] init];
        TLInputPeer$inputPeerChannel *inputChannel = [[TLInputPeer$inputPeerChannel alloc] init];
        inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
        inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
        if (inputChannel.access_hash == 0)
        {
            IOS6Trace(@"IOS6HISTORY tailMissingAccessHash peer=%lld channel=%lld originalHash=%lld", peerId, inputChannel.channel_id, accessHash);
            return [SSignal single:@{}];
        }
        getHistory.peer = inputChannel;
        getHistory.min_id = 0;
        getHistory.max_id = 0;
        getHistory.offset_id = 0;
        getHistory.add_offset = 0;
        getHistory.limit = limit;
        IOS6Trace(@"IOS6TRACE channelHistoryTail request peer=%lld channel=%lld hash=%lld min=%d max=%d offset=%d add=%d limit=%d", peerId, inputChannel.channel_id, inputChannel.access_hash, getHistory.min_id, getHistory.max_id, getHistory.offset_id, getHistory.add_offset, getHistory.limit);
        
        return [[[[TGTelegramNetworking instance] requestSignal:getHistory] mapToSignal:^SSignal *(TLmessages_Messages *messages) {
            [TGUserDataRequestBuilder executeUserDataUpdate:messages.users];
            IOS6Trace(@"IOS6TRACE channelHistoryTail success peer=%lld messages=%d chats=%d users=%d response=%@", peerId, (int)messages.messages.count, (int)messages.chats.count, (int)messages.users.count, NSStringFromClass([messages class]));
            int32_t pts = 0;
            NSArray *collapsed = nil;
            if ([messages isKindOfClass:[TLmessages_Messages$modernChannelMessages class]]) {
                TLmessages_Messages$modernChannelMessages *concreteMessages = (TLmessages_Messages$modernChannelMessages *)messages;
                pts = concreteMessages.pts;
                collapsed = concreteMessages.collapsed;
            }
            
            int32_t minParsedId = 0;
            int32_t maxParsedId = 0;
            int32_t maxParsedDate = 0;
            int32_t minParsedDate = 0;
            NSMutableArray *parsedMessages = [[NSMutableArray alloc] init];
            for (id desc in messages.messages) {
                TGMessage *message = [[TGMessage alloc] initWithTelegraphMessageDesc:desc];
                message.pts = pts;
                if (message.mid != 0) {
                    [parsedMessages addObject:message];
                    if (minParsedId == 0 || minParsedId > message.mid) {
                        minParsedId = message.mid;
                        minParsedDate = (int32_t)message.date;
                    }
                    
                    if (maxParsedId == 0 || maxParsedId < message.mid) {
                        maxParsedId = message.mid;
                        maxParsedDate = (int32_t)message.date;
                    }
                }
            }
            IOS6Trace(@"IOS6TRACE channelHistoryTail parsed peer=%lld parsed=%d minMid=%d maxMid=%d minDate=%d maxDate=%d pts=%d", peerId, (int)parsedMessages.count, minParsedId, maxParsedId, minParsedDate, maxParsedDate, pts);
            return [[self messagesWithDownloadedReplyMessages:peerId accessHash:accessHash messages:parsedMessages] mapToSignal:^SSignal *(NSArray *parsedMessages) {
                TGMessageHole *closedHole = [[TGMessageHole alloc] initWithMinId:minParsedId minTimestamp:minParsedDate maxId:maxParsedId maxTimestamp:maxParsedDate];
                
                return [SSignal single:@{@"messages": parsedMessages, @"hole": closedHole}];
            }];
        }] catch:^SSignal *(id error) {
            IOS6Trace(@"IOS6TRACE channelHistoryTail error peer=%lld channel=%lld hash=%lld error=%@", peerId, inputChannel.channel_id, inputChannel.access_hash, error);
            return [SSignal single:@{}];
        }];
    }] switchToLatest];
}

+ (SSignal *)preloadedChannelAtMessage:(int64_t)peerId messageId:(int32_t)messageId {
    IOS6Trace(@"IOS6TRACE preloadedChannelAtMessage start peer=%lld messageId=%d", peerId, messageId);
    SSignal *channelSignal = [[[[TGDatabaseInstance() existingChannel:peerId] take:1] timeout:5.0 onQueue:[SQueue concurrentDefaultQueue] orSignal:[SSignal fail:nil]] catch:^SSignal *(id error) {
        IOS6Trace(@"IOS6TRACE preloadedChannelAtMessage missing peer=%lld messageId=%d error=%@", peerId, messageId, error);
        return [SSignal fail:error];
    }];
    
    return [channelSignal mapToSignal:^SSignal *(TGConversation *conversation) {
        IOS6Trace(@"IOS6TRACE preloadedChannelAtMessage found peer=%lld messageId=%d hash=%lld isGroup=%d ptsPath=check", peerId, messageId, conversation.accessHash, conversation.isChannelGroup ? 1 : 0);
        if (messageId == 0) {
            SSignal *historySignal = [[self preloadedHistoryTailForPeerId:peerId accessHash:conversation.accessHash] mapToSignal:^SSignal *(NSDictionary *dict) {
                return [[TGDatabaseInstance() modify:^{
                    NSArray *removedImportantHoles = nil;
                    NSArray *removedUnimportantHoles = nil;
                    
                    removedImportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                    removedUnimportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                    
                    [TGDatabaseInstance() addMessagesToChannel:peerId messages:dict[@"messages"] deleteMessages:nil unimportantGroups:dict[@"unimportantGroups"] addedHoles:nil removedHoles:removedImportantHoles removedUnimportantHoles:removedUnimportantHoles updatedMessageSortKeys:nil returnGroups:false keepUnreadCounters:false skipFeedUpdate:true changedMessages:nil];
                    
                    return [SSignal complete];
                }] switchToLatest];
            }];
            
            return [[[TGDatabaseInstance() modifyChannel:peerId block:^id(int32_t pts) {
                if (pts <= 1) {
                    return [[self preloadChannelTail:peerId accessHash:conversation.accessHash important:!conversation.isChannelGroup] then:historySignal];
                } else {
                    return historySignal;
                }
            }] switchToLatest] then:channelSignal];
        } else {
            SSignal *historySignal = [[self preloadedHistoryForPeerId:peerId accessHash:conversation.accessHash aroundMessageId:messageId] mapToSignal:^SSignal *(NSDictionary *dict) {
                return [[TGDatabaseInstance() modify:^{
                    NSArray *removedImportantHoles = nil;
                    NSArray *removedUnimportantHoles = nil;
                    
                    removedImportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                    removedUnimportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                    
                    [TGDatabaseInstance() addMessagesToChannel:peerId messages:dict[@"messages"] deleteMessages:nil unimportantGroups:dict[@"unimportantGroups"] addedHoles:nil removedHoles:removedImportantHoles removedUnimportantHoles:removedUnimportantHoles updatedMessageSortKeys:nil returnGroups:false keepUnreadCounters:false skipFeedUpdate:true changedMessages:nil];
                    
                    return [SSignal complete];
                }] switchToLatest];
            }];
            
            return [[[TGDatabaseInstance() modifyChannel:peerId block:^id(int32_t pts) {
                if (pts <= 1) {
                    return [[self preloadChannelTail:peerId accessHash:conversation.accessHash important:!conversation.isChannelGroup] then:historySignal];
                } else {
                    return historySignal;
                }
            }] switchToLatest] then:channelSignal];
        }
    }];
}

+ (SSignal *)preloadedChannel:(int64_t)peerId {
    return [self preloadedChannelAtMessage:peerId messageId:0];
}

+ (SSignal *)channelMessageHoleForPeerId:(int64_t)peerId accessHash:(int64_t)accessHash hole:(TGMessageHole *)hole direction:(TGChannelHistoryHoleDirection)direction important:(bool)important {
    
    int32_t limit = 100;
    IOS6Trace(@"IOS6TRACE channelHole start peer=%lld hash=%lld min=%d max=%d direction=%d important=%d", peerId, accessHash, hole.minId, hole.maxId, (int)direction, important ? 1 : 0);
#ifdef DEBUG
    //limit = 2;
#endif
    
    id request = nil;
    TLRPCmessages_getHistory$messages_getHistory *getHistory = [[TLRPCmessages_getHistory$messages_getHistory alloc] init];
    TLInputPeer$inputPeerChannel *inputChannel = [[TLInputPeer$inputPeerChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    if (inputChannel.access_hash == 0)
    {
        IOS6Trace(@"IOS6HISTORY holeMissingAccessHash peer=%lld channel=%lld originalHash=%lld", peerId, inputChannel.channel_id, accessHash);
        return [SSignal single:@{}];
    }
    getHistory.peer = inputChannel;
    getHistory.min_id = hole.minId - 1;
    getHistory.max_id = hole.maxId == INT32_MAX ? hole.maxId : (hole.maxId + 1);
    getHistory.limit = limit;
    switch (direction) {
        case TGChannelHistoryHoleDirectionEarlier:
            getHistory.offset_id = getHistory.max_id;
            getHistory.add_offset = 0;
            break;
        case TGChannelHistoryHoleDirectionLater:
            getHistory.offset_id = getHistory.min_id;
            getHistory.add_offset = -getHistory.limit;
            break;
    }
    
    request = getHistory;
    IOS6Trace(@"IOS6TRACE channelHole request peer=%lld modernRaw=%d channel=%lld hash=%lld min=%d max=%d offset=%d add=%d limit=%d", peerId, TGIOS6ChannelPeerIdIsModernRawChannel(peerId, accessHash) ? 1 : 0, inputChannel.channel_id, inputChannel.access_hash, getHistory.min_id, getHistory.max_id, getHistory.offset_id, getHistory.add_offset, getHistory.limit);
    
    return [[[[[TGTelegramNetworking instance] requestSignal:request] mapToSignal:^SSignal *(TLmessages_Messages *messages) {
        [TGUserDataRequestBuilder executeUserDataUpdate:messages.users];
        IOS6Trace(@"IOS6TRACE channelHole success peer=%lld messages=%d chats=%d users=%d response=%@", peerId, (int)messages.messages.count, (int)messages.chats.count, (int)messages.users.count, NSStringFromClass([messages class]));
        int32_t pts = 0;
        NSArray *collapsed = nil;
        if ([messages isKindOfClass:[TLmessages_Messages$modernChannelMessages class]]) {
            TLmessages_Messages$modernChannelMessages *concreteMessages = (TLmessages_Messages$modernChannelMessages *)messages;
            pts = concreteMessages.pts;
            collapsed = concreteMessages.collapsed;
        }
        
        int32_t minParsedId = 0;
        int32_t maxParsedId = 0;
        int32_t maxParsedDate = 0;
        int32_t minParsedDate = 0;
        NSMutableArray *parsedMessages = [[NSMutableArray alloc] init];
        for (id desc in messages.messages) {
            TGMessage *message = [[TGMessage alloc] initWithTelegraphMessageDesc:desc];
            message.pts = pts;
            if (message.mid != 0) {
                [parsedMessages addObject:message];
                if (minParsedId == 0 || minParsedId > message.mid) {
                    minParsedId = message.mid;
                    minParsedDate = (int32_t)message.date;
                }
                
                if (maxParsedId == 0 || maxParsedId < message.mid) {
                    maxParsedId = message.mid;
                    maxParsedDate = (int32_t)message.date;
                }
            }
        }
        
        NSMutableArray *unimportantGroups = [[NSMutableArray alloc] init];
        if (important) {
            for (TLMessageGroup *groupDesc in collapsed) {
                TGMessageGroup *group = [[TGMessageGroup alloc] initWithMinId:groupDesc.min_id + 1 minTimestamp:1 maxId:groupDesc.max_id - 1 maxTimestamp:groupDesc.date count:groupDesc.count];
                if (group.count != 0) {
                    [unimportantGroups addObject:group];
                }
                
                if (minParsedId == 0 || minParsedId > group.minId) {
                    minParsedId = group.minId;
                    minParsedDate = group.maxTimestamp;
                }
                
                if (maxParsedId == 0 || maxParsedId < group.maxId) {
                    maxParsedId = group.maxId;
                    maxParsedDate = group.maxTimestamp;
                }
            }
        }
        
        bool isSlice = (int32_t)parsedMessages.count >= limit;
        if (parsedMessages.count == 0 || minParsedId <= hole.minId) {
            isSlice = false;
        }
        
        TGMessageHole *closedHole = nil;
        if (!isSlice) {
            closedHole = hole;
        } else {
            closedHole = [[TGMessageHole alloc] initWithMinId:minParsedId minTimestamp:minParsedDate maxId:hole.maxId maxTimestamp:hole.maxTimestamp];
        }
        
        if (closedHole == nil)
            closedHole = [[TGMessageHole alloc] initWithMinId:0 minTimestamp:0 maxId:0 maxTimestamp:0];
        return [SSignal single:@{@"messages": parsedMessages ?: @[], @"hole": closedHole, @"unimportantGroups": unimportantGroups ?: @[], @"pts": @(pts)}];
    }] catch:^SSignal *(id error) {
        IOS6Trace(@"IOS6TRACE channelHole error peer=%lld channel=%lld hash=%lld error=%@", peerId, inputChannel.channel_id, inputChannel.access_hash, error);
        TGMessageHole *fallbackHole = hole ?: [[TGMessageHole alloc] initWithMinId:0 minTimestamp:0 maxId:0 maxTimestamp:0];
        return [SSignal single:@{@"messages": @[], @"hole": fallbackHole, @"unimportantGroups": @[], @"pts": @(0)}];
    }] mapToSignal:^SSignal *(NSDictionary *next) {
        NSArray *addedMessages = next[@"messages"];
        
        NSMutableArray *downloadMessages = [[NSMutableArray alloc] init];
        
        NSMutableDictionary *addedMessageIdToMessage = [[NSMutableDictionary alloc] init];
        for (TGMessage *message in addedMessages) {
            addedMessageIdToMessage[@(message.mid)] = message;
        }
        
        for (TGMessage *message in addedMessages)
        {
            if (message.mediaAttachments.count != 0)
            {
                for (id attachment in message.mediaAttachments)
                {
                    if ([attachment isKindOfClass:[TGReplyMessageMediaAttachment class]])
                    {
                        TGReplyMessageMediaAttachment *replyAttachment = attachment;
                        if (replyAttachment.replyMessage == nil && replyAttachment.replyMessageId != 0) {
                            TGMessage *replyMessage = addedMessageIdToMessage[@(replyAttachment.replyMessageId)];
                            if (replyMessage != nil) {
                                replyAttachment.replyMessage = replyMessage;
                            } else {
                                [downloadMessages addObject:[[TGDownloadMessage alloc] initWithPeerId:peerId accessHash:accessHash messageId:replyAttachment.replyMessageId]];
                            }
                        }
                    }
                }
            }
        }
        
        if (downloadMessages.count != 0) {
            return [[TGDownloadMessagesSignal downloadMessages:downloadMessages] mapToSignal:^SSignal *(NSArray *messages) {
                for (TGMessage *message in messages) {
                    addedMessageIdToMessage[@(message.mid)] = message;
                }
                
                for (TGMessage *message in addedMessages)
                {
                    if (message.mediaAttachments.count != 0)
                    {
                        for (id attachment in message.mediaAttachments)
                        {
                            if ([attachment isKindOfClass:[TGReplyMessageMediaAttachment class]])
                            {
                                TGReplyMessageMediaAttachment *replyAttachment = attachment;
                                if (replyAttachment.replyMessage == nil && replyAttachment.replyMessageId != 0) {
                                    TGMessage *replyMessage = addedMessageIdToMessage[@(replyAttachment.replyMessageId)];
                                    if (replyMessage != nil) {
                                        replyAttachment.replyMessage = replyMessage;
                                    }
                                }
                            }
                        }
                    }
                }
                
                return [SSignal single:next];
            }];
        } else {
            return [SSignal single:next];
        }
    }];
}

+ (SSignal *)exportChannelInvitationLink:(int64_t)peerId accessHash:(int64_t)accessHash
{
    TLRPCchannels_exportInvite$channels_exportInvite *exportChatInvite = [[TLRPCchannels_exportInvite$channels_exportInvite alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    exportChatInvite.channel = inputChannel;
    return [[[TGTelegramNetworking instance] requestSignal:exportChatInvite] mapToSignal:^SSignal *(TLExportedChatInvite *result)
    {
        if ([result isKindOfClass:[TLExportedChatInvite$chatInviteExported class]])
        {
            NSString *link = ((TLExportedChatInvite$chatInviteExported *)result).link;
            
            [TGDatabaseInstance() updateChannelCachedData:peerId block:^TGCachedConversationData *(TGCachedConversationData *currentData) {
                if (currentData == nil) {
                    currentData = [[TGCachedConversationData alloc] init];
                }
                return [currentData updatePrivateLink:link];
            }];
            
            return [SSignal single:link];
        }
        else
            return [SSignal fail:nil];
    }];
}

+ (SSignal *)_channelDifference:(int64_t)peerId accessHash:(int64_t)accessHash pts:(int32_t)pts {
    NSData *invalidPeerMarker = [TGDatabaseInstance() conversationCustomPropertySync:peerId name:murMurHash32(@"ios6InvalidPeer")];
    if (invalidPeerMarker.length != 0)
    {
        TGLog(@"IOS6FULL state.diff.skipInvalidPeer peer=%lld pts=%d", peerId, pts);
        return [SSignal complete];
    }
    
    int32_t limit = 100;
    int64_t channelId = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    if (channelId == 0 || accessHash != 0)
    {
        TGLog(@"IOS6AUTH skip getChannelDifference peer=%lld channel=%lld accessHash=%lld pts=%d", peerId, channelId, accessHash, pts);
        return [SSignal complete];
    }
    
    TLRPCupdates_getChannelDifference$updates_getChannelDifference *getChannelDifference = [[TLRPCupdates_getChannelDifference$updates_getChannelDifference alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = channelId;
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    TGLog(@"IOS6AUTH getChannelDifference peer=%lld apiChannel=%lld accessHash=%lld pts=%d", peerId, inputChannel.channel_id, accessHash, pts);
    getChannelDifference.channel = inputChannel;
    getChannelDifference.filter = [[TLChannelMessagesFilter$channelMessagesFilterEmpty alloc] init];
    getChannelDifference.pts = pts;
    getChannelDifference.limit = limit;
    
    return [[TGTelegramNetworking instance] requestSignal:getChannelDifference];
}

+ (SSignal *)deleteChannelMessages {
    return [[TGDatabaseInstance() enqueuedDeleteChannelMessages] mapToQueue:^SSignal *(TGQueuedDeleteChannelMessages *queued) {
        TLRPCchannels_deleteMessages$channels_deleteMessages *deleteChannelMessages = [[TLRPCchannels_deleteMessages$channels_deleteMessages alloc] init];
        TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
        inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(queued.peerId, queued.accessHash);
        inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(queued.peerId, queued.accessHash);
        deleteChannelMessages.channel = inputChannel;
        deleteChannelMessages.n_id = queued.messageIds;
        
        return [[[[TGTelegramNetworking instance] requestSignal:deleteChannelMessages] mapToSignal:^SSignal *(TLmessages_AffectedMessages *result) {
            [TGDatabaseInstance() confirmChannelMessagesDeleted:queued];
            [self updateChannelState:queued.peerId pts:result.pts ptsCount:result.pts_count];
            return [SSignal complete];
        }] catch:^SSignal *(__unused id error) {
            [TGDatabaseInstance() confirmChannelMessagesDeleted:queued];
            return [SSignal complete];
        }];
    }];
}

+ (SSignal *)readChannelMessages {
    return [[TGDatabaseInstance() enqueuedReadChannelMessages] mapToQueue:^SSignal *(TGQueuedReadChannelMessages *queued) {
        bool isChannel = TGIOS6ChannelPeerIdIsModernChannel(queued.peerId, queued.accessHash);
        while (false) TGLog(@"IOS6READ rpc.prepare peer=%lld channel=%d maxId=%d unread=%d access=%lld", queued.peerId, isChannel ? 1 : 0, queued.maxId, queued.unread ? 1 : 0, queued.accessHash);
        if (queued.unread) {
            TLRPCmessages_markDialogUnread *markDialogUnread = [[TLRPCmessages_markDialogUnread alloc] init];
            TLInputPeer *inputPeer = [TGTelegraphInstance createInputPeerForConversation:queued.peerId accessHash:queued.accessHash];
            if (inputPeer != nil) {
                TLInputDialogPeer$inputDialogPeer *inputDialogPeer = [[TLInputDialogPeer$inputDialogPeer alloc] init];
                inputDialogPeer.peer = inputPeer;
                markDialogUnread.peer = inputDialogPeer;
            }
            markDialogUnread.flags = (1 << 0);
            
            return [[[[TGTelegramNetworking instance] requestSignal:markDialogUnread] mapToSignal:^SSignal *(id result) {
                while (false) TGLog(@"IOS6READ rpc.markUnread.ok peer=%lld result=%@", queued.peerId, NSStringFromClass([result class]));
                [TGDatabaseInstance() confirmChannelHistoryRead:queued];
                return [SSignal complete];
            }] catch:^SSignal *(id error) {
                while (false) TGLog(@"IOS6READ rpc.markUnread.error peer=%lld error=%@", queued.peerId, error);
                [TGDatabaseInstance() confirmChannelHistoryRead:queued];
                return [SSignal complete];
            }];
        }
        else if (isChannel) {
            TLRPCchannels_readHistory$channels_readHistory *readChannelHistory = [[TLRPCchannels_readHistory$channels_readHistory alloc] init];
            TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
            inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(queued.peerId, queued.accessHash);
            inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(queued.peerId, queued.accessHash);
            readChannelHistory.channel = inputChannel;
            readChannelHistory.max_id = queued.maxId;
            
            return [[[[TGTelegramNetworking instance] requestSignal:readChannelHistory] mapToSignal:^SSignal *(id result) {
                while (false) TGLog(@"IOS6READ rpc.channel.ok peer=%lld maxId=%d result=%@", queued.peerId, queued.maxId, NSStringFromClass([result class]));
                [TGDatabaseInstance() confirmChannelHistoryRead:queued];
                return [SSignal complete];
            }] catch:^SSignal *(id error) {
                while (false) TGLog(@"IOS6READ rpc.channel.error peer=%lld maxId=%d error=%@", queued.peerId, queued.maxId, error);
                [TGDatabaseInstance() confirmChannelHistoryRead:queued];
                return [SSignal complete];
            }];
        } else if (TGPeerIdIsSecretChat(queued.peerId)) {
            NSAssert(false, @"readChannelMessages TGPeerIdIsSecretChat == true");
            return [SSignal complete];
        } else {
            TLRPCmessages_readHistory$messages_readHistory *readHistory = [[TLRPCmessages_readHistory$messages_readHistory alloc] init];
            readHistory.peer = [TGTelegraphInstance createInputPeerForConversation:queued.peerId accessHash:queued.accessHash];
            readHistory.max_id = queued.maxId;
            
            return [[[[TGTelegramNetworking instance] requestSignal:readHistory] mapToSignal:^SSignal *(id result) {
                while (false) TGLog(@"IOS6READ rpc.messages.ok peer=%lld maxId=%d result=%@", queued.peerId, queued.maxId, NSStringFromClass([result class]));
                [TGDatabaseInstance() confirmChannelHistoryRead:queued];
                return [SSignal complete];
            }] catch:^SSignal *(id error) {
                while (false) TGLog(@"IOS6READ rpc.messages.error peer=%lld maxId=%d error=%@", queued.peerId, queued.maxId, error);
                [TGDatabaseInstance() confirmChannelHistoryRead:queued];
                return [SSignal complete];
            }];
        }
    }];
}

+ (SSignal *)leaveChannels {
    return [[TGDatabaseInstance() enqueuedLeaveChannels] mapToQueue:^SSignal *(TGQueuedLeaveChannel *queued) {
        TLRPCchannels_leaveChannel$channels_leaveChannel *leaveChannel = [[TLRPCchannels_leaveChannel$channels_leaveChannel alloc] init];
        TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
        inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(queued.peerId, queued.accessHash);
        inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(queued.peerId, queued.accessHash);
        leaveChannel.channel = inputChannel;
        
        return [[[[TGTelegramNetworking instance] requestSignal:leaveChannel] mapToSignal:^SSignal *(__unused NSNumber *result) {
            [TGDatabaseInstance() confirmChannelLeaved:queued];
            return [SSignal complete];
        }] catch:^SSignal *(__unused id error) {
            [TGDatabaseInstance() confirmChannelLeaved:queued];
            return [SSignal complete];
        }];
    }];
}

+ (void)updateChannelState:(int64_t)peerId pts:(int32_t)pts ptsCount:(int32_t)ptsCount {
    [[TGDatabaseInstance() modifyChannel:peerId block:^id(int32_t currentPts) {
        if (currentPts + ptsCount == pts) {
            [TGDatabaseInstance() addMessagesToChannelAndDispatch:peerId messages:nil deletedMessages:nil holes:nil pts:pts skipFeedUpdate:true];
        } else {
            TLUpdate$updateChannelTooLong *updateChannelTooLong = [[TLUpdate$updateChannelTooLong alloc] init];
            updateChannelTooLong.channel_id = TGChannelIdFromPeerId(peerId);
            [TGChannelStateSignals addChannelUpdates:peerId updates:@[updateChannelTooLong]];
        }
        return nil;
    }] startWithNext:nil];
}

+ (SSignal *)joinTemporaryChannel:(int64_t)peerId {
    return [[[TGDatabaseInstance() existingChannel:peerId] take:1] mapToSignal:^SSignal *(TGConversation *next) {
        TLRPCchannels_joinChannel$channels_joinChannel *joinChannel = [[TLRPCchannels_joinChannel$channels_joinChannel alloc] init];
        TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
        inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, next.accessHash);
        inputChannel.access_hash = next.accessHash;
        joinChannel.channel = inputChannel;

        return [[[TGTelegramNetworking instance] requestSignal:joinChannel] mapToSignal:^SSignal *(TLUpdates *updates) {
            if (updates.chats.count != 0) {
                TGConversation *conversation = [[TGConversation alloc] initWithTelegraphChatDesc:updates.chats[0]];
                if (conversation.conversationId == peerId) {
                    return [[TGDatabaseInstance() modifyChannel:peerId block:^id(__unused int32_t pts) {
                        [TGDatabaseInstance() updateChannels:@[conversation]];
                        return [SSignal complete];
                    }] switchToLatest];
                } else {
                    return [SSignal fail:nil];
                }
            } else {
                return [SSignal fail:nil];
            }
        }];
    }];
}

+ (SSignal *)inviteUsers:(int64_t)peerId accessHash:(int64_t)accessHash users:(NSArray *)users {
    TLRPCchannels_inviteToChannel$channels_inviteToChannel *inviteToChannel = [[TLRPCchannels_inviteToChannel$channels_inviteToChannel alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    inviteToChannel.channel = inputChannel;
    
    NSMutableArray *inputUsers = [[NSMutableArray alloc] init];
    for (TGUser *user in users) {
        TLInputUser$inputUser *inputUser = [[TLInputUser$inputUser alloc] init];
        inputUser.user_id = user.uid;
        inputUser.access_hash = user.phoneNumberHash;
        [inputUsers addObject:inputUser];
    }
    inviteToChannel.users = inputUsers;
    
    return [[[TGTelegramNetworking instance] requestSignal:inviteToChannel] mapToSignal:^SSignal *(TLUpdates *updates) {
        id chat = updates.chats.firstObject;
        TGConversation *conversation = nil;
        if (chat != nil) {
            conversation = [[TGConversation alloc] initWithTelegraphChatDesc:chat];
            if (conversation.conversationId == peerId) {
                [TGDatabaseInstance() updateChannels:@[conversation]];
            }
        }
        [[TGTelegramNetworking instance] addUpdates:updates];
        
        return [SSignal complete];
    }];
}

+ (SSignal *)checkChannelUsername:(int64_t)peerId accessHash:(int64_t)accessHash username:(NSString *)username {
    TLRPCchannels_checkUsername$channels_checkUsername *checkChannelUsername = [[TLRPCchannels_checkUsername$channels_checkUsername alloc] init];
    if (peerId != 0) {
        TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
        inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
        inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
        checkChannelUsername.channel = inputChannel;
    } else {
        checkChannelUsername.channel = [[TLInputChannel$inputChannelEmpty alloc] init];
    }
    checkChannelUsername.username = username;
    return [[[TGTelegramNetworking instance] requestSignal:checkChannelUsername] mapToSignal:^SSignal *(NSNumber *result) {
        if ([result boolValue]) {
            return [SSignal complete];
        } else {
            return [SSignal fail:nil];
        }
    }];
}

+ (SSignal *)updateChannelUsername:(int64_t)peerId accessHash:(int64_t)accessHash username:(NSString *)username {
    TLRPCchannels_updateUsername$channels_updateUsername *updateChannelUsername = [[TLRPCchannels_updateUsername$channels_updateUsername alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    updateChannelUsername.channel = inputChannel;
    updateChannelUsername.username = username;
    return [[[TGTelegramNetworking instance] requestSignal:updateChannelUsername] mapToSignal:^SSignal *(NSNumber *result) {
        if ([result boolValue]) {
            return [[TGDatabaseInstance() modifyChannel:peerId block:^id(__unused int32_t pts) {
                [TGDatabaseInstance() updateChannelUsername:peerId username:username];
                return [SSignal complete];
            }] switchToLatest];
        } else {
            return [SSignal fail:nil];
        }
    }];
}

+ (SSignal *)updateChannelAbout:(int64_t)peerId accessHash:(int64_t)accessHash about:(NSString *)about {
    TLRPCchannels_editAbout$channels_editAbout *editChatAbout = [[TLRPCchannels_editAbout$channels_editAbout alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    editChatAbout.channel = inputChannel;
    editChatAbout.about = about;
    return [[[TGTelegramNetworking instance] requestSignal:editChatAbout] mapToSignal:^SSignal *(NSNumber *result) {
        if ([result boolValue]) {
            return [[TGDatabaseInstance() modifyChannel:peerId block:^id(__unused int32_t pts) {
                [TGDatabaseInstance() updateChannelAbout:peerId about:about];
                return [SSignal complete];
            }] switchToLatest];
        } else {
            return [SSignal fail:nil];
        }
    }];
}

+ (SSignal *)updateChannelPhoto:(int64_t)peerId accessHash:(int64_t)accessHash uploadedFile:(SSignal *)uploadedFile {
    return [uploadedFile mapToSignal:^SSignal *(TLInputFile *inputFile) {
        TLRPCchannels_editPhoto$channels_editPhoto *editPhoto = [[TLRPCchannels_editPhoto$channels_editPhoto alloc] init];
        TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
        inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
        inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
        editPhoto.channel = inputChannel;
        TLInputChatPhoto$inputChatUploadedPhoto *uploadedPhoto = [[TLInputChatPhoto$inputChatUploadedPhoto alloc] init];
        uploadedPhoto.file = inputFile;
        editPhoto.photo = uploadedPhoto;
        
        return [[[TGTelegramNetworking instance] requestSignal:editPhoto] mapToSignal:^SSignal *(TLUpdates *updates) {
            if (updates.chats.count != 0) {
                TGConversation *conversation = [[TGConversation alloc] initWithTelegraphChatDesc:updates.chats[0]];
                if (conversation.conversationId == peerId) {
                    [TGDatabaseInstance() updateChannels:@[conversation]];
                }
            }
            [[TGTelegramNetworking instance] addUpdates:updates];
            
            return [SSignal complete];
        }];
    }];
}

+ (SSignal *)updateChannelStickerPack:(int64_t)peerId accessHash:(int64_t)accessHash stickerPack:(TGStickerPack *)stickerPack {
    TLRPCchannels_setStickers$channels_setStickers *setStickers = [[TLRPCchannels_setStickers$channels_setStickers alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    setStickers.channel = inputChannel;
    
    TLInputStickerSet *stickerSet = [[TLInputStickerSet$inputStickerSetEmpty alloc] init];
    if (stickerPack != nil)
        stickerSet = [TGStickersSignals _inputStickerSetFromPackReference:stickerPack.packReference];
    setStickers.stickerset = stickerSet;
    
    return [[[TGTelegramNetworking instance] requestSignal:setStickers] mapToSignal:^SSignal *(NSNumber *result) {
        if ([result boolValue]) {
            [TGDatabaseInstance() updateChannelCachedData:peerId block:^TGCachedConversationData *(TGCachedConversationData *currentData) {
                if (currentData == nil) {
                    currentData = [[TGCachedConversationData alloc] init];
                }
                return [currentData updateStickerPack:stickerPack.packReference canSetStickerPack:currentData.canSetStickerPack];
            }];
            
            return [SSignal complete];
        } else {
            return [SSignal fail:nil];
        }
    }];

}

+ (SSignal *)updateChannelExtendedInfo:(int64_t)peerId accessHash:(int64_t)accessHash updateUnread:(bool)updateUnread {
    NSData *invalidPeerMarker = [TGDatabaseInstance() conversationCustomPropertySync:peerId name:murMurHash32(@"ios6InvalidPeer")];
    if (invalidPeerMarker.length != 0)
    {
        TGLog(@"IOS6FULL channelExtendedInfo.skipInvalidPeer peer=%lld hash=%lld updateUnread=%d", peerId, accessHash, updateUnread ? 1 : 0);
        return [SSignal complete];
    }
    
    if (TGIOS6ChannelPeerIdIsModernRawChannel(peerId, accessHash)) {
        IOS6Trace(@"IOS6TRACE skip channels.getFullChannel modern peer=%lld channel=%lld hash=%lld updateUnread=%d", peerId, TGIOS6ChannelIdFromPeerId(peerId, accessHash), accessHash, updateUnread ? 1 : 0);
        return [SSignal complete];
    }
    
    TLRPCchannels_getFullChannel$channels_getFullChannel *getFullChat = [[TLRPCchannels_getFullChannel$channels_getFullChannel alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    getFullChat.channel = inputChannel;
    return [[[[TGTelegramNetworking instance] requestSignal:getFullChat] mapToSignal:^SSignal *(TLmessages_ChatFull *result) {
        if ([result.full_chat isKindOfClass:[TLChatFull$channelFull class]]) {
            TLChatFull$channelFull *channelFull = (TLChatFull$channelFull *)result.full_chat;
            
            TGConversation *conversation = nil;
            for (TLChat *chat in result.chats) {
                if ([chat isKindOfClass:[TLChat$channel class]]) {
                    if (((TLChat$channel *)chat).n_id == TGChannelIdFromPeerId(peerId)) {
                        conversation = [[TGConversation alloc] initWithTelegraphChatDesc:chat];
                        break;
                    }
                }
            }
            
            NSString *privateLink = @"";
            if ([channelFull.exported_invite isKindOfClass:[TLExportedChatInvite$chatInviteExported class]]) {
                privateLink = ((TLExportedChatInvite$chatInviteExported *)channelFull.exported_invite).link;
            }
            
            TGConversationMigrationData *migrationData = nil;
            if (channelFull.migrated_from_chat_id != 0) {
                migrationData = [[TGConversationMigrationData alloc] initWithPeerId:TGPeerIdFromGroupId(channelFull.migrated_from_chat_id) maxMessageId:channelFull.migrated_from_max_id];
            }
            
            NSMutableDictionary *botInfos = nil;
            if (channelFull.bot_info != nil) {
                botInfos = [[NSMutableDictionary alloc] init];
                
                for (TLBotInfo *botInfo in channelFull.bot_info) {
                    if ([botInfo isKindOfClass:[TLBotInfo$botInfo class]]) {
                        TGBotInfo *parsedBotInfo = [TGBotSignals botInfoForInfo:botInfo];
                        if (parsedBotInfo != nil) {
                            botInfos[@(((TLBotInfo$botInfo *)botInfo).user_id)] = parsedBotInfo;
                        }
                    }
                }
            }
            
            TGStickerPackIdReference *stickerPack = nil;
            if (channelFull.stickerset != nil) {
                stickerPack = [[TGStickerPackIdReference alloc] initWithPackId:channelFull.stickerset.n_id packAccessHash:channelFull.stickerset.access_hash shortName:channelFull.stickerset.short_name];
            }
            
            return [[TGDatabaseInstance() modifyChannel:peerId block:^id(__unused int32_t pts) {
                if (conversation != nil) {
                    [TGDatabaseInstance() updateChannels:@[conversation]];
                }
                [TGDatabaseInstance() updateChannelAbout:peerId about:channelFull.about];
                if (channelFull.pinned_msg_id >= channelFull.available_min_id) {
                    [TGDatabaseInstance() updateChannelPinnedMessageId:peerId pinnedMessageId:channelFull.pinned_msg_id hidden:nil];
                } else {
                    [TGDatabaseInstance() updateChannelPinnedMessageId:peerId pinnedMessageId:0 hidden:nil];
                }
                
                if (updateUnread) {
                    [TGDatabaseInstance() updateChannelReadState:peerId maxReadId:channelFull.read_inbox_max_id unreadImportantCount:channelFull.unread_count unreadUnimportantCount:0 unreadMentionsCount:-1 topMessageId:-1];
                }
                
                __block int32_t clearMessagesMessageId = 0;
                __block int64_t clearMessagesAssociatedPeerId = 0;
                [TGDatabaseInstance() updateChannelCachedData:peerId block:^TGCachedConversationData *(TGCachedConversationData *currentData) {
                    if (currentData == nil) {
                        currentData = [[TGCachedConversationData alloc] init];
                    }
                    
                    currentData = [currentData updatePrivateLink:privateLink];
                    currentData = [currentData updateMigrationData:migrationData];
                    currentData = [currentData updateBotInfos:botInfos];
                    currentData = [currentData updateStickerPack:stickerPack canSetStickerPack:channelFull.can_set_stickers];
                    if (currentData.minAvailableMessageId < channelFull.available_min_id) {
                        clearMessagesMessageId = channelFull.available_min_id;
                        clearMessagesAssociatedPeerId = migrationData.peerId;
                    }
                    currentData = [currentData updateMinAvailableMessageId:channelFull.available_min_id];
                    currentData = [currentData updatePreHistory:channelFull.flags & (1 << 10)];
                    
                    return [currentData updateManagementCount:channelFull.admins_count blacklistCount:channelFull.kicked_count bannedCount:channelFull.banned_count memberCount:channelFull.participants_count];
                }];
                
                if (clearMessagesMessageId != 0) {
                    NSArray *clearAssociatedPeerIds = nil;
                    if (clearMessagesAssociatedPeerId != 0) {
                        clearAssociatedPeerIds = @[@(clearMessagesAssociatedPeerId)];
                    }
                    [TGDatabaseInstance() transactionAddMessages:nil notifyAddedMessages:false removeMessages:nil updateMessages:nil updatePeerDrafts:nil removeMessagesInteractive:nil keepDates:false removeMessagesInteractiveForEveryone:false updateConversationDatas:nil applyMaxIncomingReadIds:nil applyMaxOutgoingReadIds:nil applyMaxOutgoingReadDates:nil applyUnreadMarks:nil readHistoryForPeerIds:nil resetPeerReadStates:nil resetPeerUnseenMentionsStates:nil clearConversationsWithPeerIds:nil clearConversationsInteractive:false removeConversationsWithPeerIds:nil updatePinnedConversations:nil synchronizePinnedConversations:false forceReplacePinnedConversations:false readMessageContentsInteractive:nil deleteEarlierHistory:@{@(peerId): @(clearMessagesMessageId - 1)} updateFeededChannels:nil newlyJoinedFeedId:nil synchronizeFeededChannels:false calculateUnreadChats:false];
                }
                
                TLPeerNotifySettings *settings = channelFull.notify_settings;
                
                NSNumber *peerSoundId = nil;
                NSNumber *peerMuteUntil = nil;
                NSNumber *peerPreviewText = nil;
                NSNumber *messagesMuted = nil;
                
                if ([settings isKindOfClass:[TLPeerNotifySettings$peerNotifySettings class]])
                {
                    TLPeerNotifySettings$peerNotifySettings *concreteSettings = (TLPeerNotifySettings$peerNotifySettings *)settings;
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
                    if (concreteSettings.flags & (1 << 3))
                    {
                        if (concreteSettings.sound.length == 0)
                            peerSoundId = @(0);
                        else if ([concreteSettings.sound isEqualToString:@"default"])
                            peerSoundId = @(1);
                        else
                            peerSoundId = @([concreteSettings.sound intValue]);
                    }
                }
                
                [TGDatabaseInstance() storePeerNotificationSettings:peerId soundId:peerSoundId muteUntil:peerMuteUntil previewText:peerPreviewText messagesMuted:messagesMuted writeToActionQueue:false completion:^(bool changed)
                {
                    if (changed)
                    {
                        [ActionStageInstance() dispatchOnStageQueue:^
                        {
                            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                            if (peerSoundId != nil)
                                dict[@"soundId"] = peerSoundId;
                            if (peerMuteUntil != nil)
                                dict[@"muteUntil"] = peerMuteUntil;
                            if (peerPreviewText != nil)
                                dict[@"previewText"] = peerPreviewText;
                            if (messagesMuted != nil)
                                dict[@"messagesMuted"] = messagesMuted;
                            
                            [ActionStageInstance() dispatchResource:[NSString stringWithFormat:@"/tg/peerSettings/(%lld)", peerId] resource:[[SGraphObjectNode alloc] initWithObject:dict]];
                        }];
                    }
                }];
                
                return [SSignal complete];
            }] switchToLatest];
        }
        
        return [SSignal complete];
    }] catch:^SSignal *(id error) {
        IOS6Trace(@"IOS6TRACE channelExtendedInfo error peer=%lld channel=%lld hash=%lld updateUnread=%d error=%@", peerId, inputChannel.channel_id, inputChannel.access_hash, updateUnread ? 1 : 0, error);
        NSString *errorType = [[TGTelegramNetworking instance] extractNetworkErrorType:error];
        if ([errorType isEqual:@"CHANNEL_INVALID"] || [errorType isEqual:@"PEER_ID_INVALID"] || [errorType isEqual:@"CHAT_ID_INVALID"]) {
            TGIOS6MarkChannelInvalidPeer(peerId, errorType);
            return [SSignal complete];
        }
        if ([errorType isEqual:@"CHANNEL_PRIVATE"]) {
            TGIOS6MarkChannelInvalidPeer(peerId, errorType);
            return [[TGDatabaseInstance() modify:^id{
                TGConversation *conversation = [[TGDatabaseInstance() loadChannels:@[@(peerId)]][@(peerId)] copy];
                if (conversation != nil && !conversation.kickedFromChat) {
                    conversation.kickedFromChat = true;
                    [TGDatabaseInstance() updateChannels:@[conversation]];
                }
                
                return [SSignal complete];
            }] switchToLatest];
        }
        return [SSignal complete];
    }];
}

+ (SSignal *)updatedPeerMessageViews:(int64_t)peerId accessHash:(int64_t)accessHash messageIds:(NSArray *)messageIds {
    TLRPCmessages_getMessagesViews$messages_getMessagesViews *getMessageViews = [[TLRPCmessages_getMessagesViews$messages_getMessagesViews alloc] init];
    if (TGPeerIdIsChannel(peerId)) {
        TLInputPeer$inputPeerChannel *inputChannel = [[TLInputPeer$inputPeerChannel alloc] init];
        inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
        inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
        getMessageViews.peer = inputChannel;
    } else {
        getMessageViews.peer = [[TLInputPeer$inputPeerEmpty alloc] init];
    }
    getMessageViews.n_id = messageIds;
    
    return [[[TGTelegramNetworking instance] requestSignal:getMessageViews] mapToSignal:^SSignal *(NSArray *viewCounts) {
        NSMutableDictionary *messageIdToViewCount = [[NSMutableDictionary alloc] init];
        NSUInteger count = MIN(messageIds.count, viewCounts.count);
        for (NSUInteger i = 0; i < count; i++) {
            messageIdToViewCount[messageIds[i]] = viewCounts[i];
        }
        return [[TGDatabaseInstance() modify:^id{
            [TGDatabaseInstance() updateMessageViews:peerId messageIdToViews:messageIdToViewCount];
            return [SSignal single:messageIdToViewCount];
        }] switchToLatest];
    }];
}

+ (SSignal *)consumeMessages:(int64_t)peerId accessHash:(int64_t)accessHash messageIds:(NSArray *)messageIds {
    TLRPCmessages_getMessagesViews$messages_getMessagesViews *getMessageViews = [[TLRPCmessages_getMessagesViews$messages_getMessagesViews alloc] init];
    if (TGPeerIdIsChannel(peerId)) {
        TLInputPeer$inputPeerChannel *inputChannel = [[TLInputPeer$inputPeerChannel alloc] init];
        inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
        inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
        getMessageViews.peer = inputChannel;
    } else {
        getMessageViews.peer = [[TLInputPeer$inputPeerEmpty alloc] init];
    }
    getMessageViews.increment = true;
    getMessageViews.n_id = messageIds;
    
    return [[[TGTelegramNetworking instance] requestSignal:getMessageViews] mapToSignal:^SSignal *(NSArray *viewCounts) {
        return [[TGDatabaseInstance() modify:^id{
            NSMutableDictionary *messageIdToViewCount = [[NSMutableDictionary alloc] init];
            NSUInteger count = MIN(messageIds.count, viewCounts.count);
            for (NSUInteger i = 0; i < count; i++) {
                messageIdToViewCount[messageIds[i]] = viewCounts[i];
            }
            [TGDatabaseInstance() updateMessageViews:peerId messageIdToViews:messageIdToViewCount];
            return [SSignal single:messageIdToViewCount];
        }] switchToLatest];
    }];
}

+ (SSignal *)toggleChannelEverybodyCanInviteMembers:(int64_t)peerId accessHash:(int64_t)accessHash enabled:(bool)enabled {
    TLRPCchannels_toggleInvites$channels_toggleInvites *toggleChannelInvites = [[TLRPCchannels_toggleInvites$channels_toggleInvites alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    toggleChannelInvites.channel = inputChannel;
    toggleChannelInvites.enabled = enabled;
    return [[[TGTelegramNetworking instance] requestSignal:toggleChannelInvites] mapToSignal:^SSignal *(TLUpdates *updates) {
        if (updates.chats.count != 0) {
            TGConversation *conversation = [[TGConversation alloc] initWithTelegraphChatDesc:updates.chats[0]];
            if (conversation.conversationId == peerId) {
                [TGDatabaseInstance() updateChannels:@[conversation]];
            }
        }
        
        [[TGTelegramNetworking instance] addUpdates:updates];
        return [SSignal complete];
    }];
}

+ (SSignal *)updateChannelAdminRights:(int64_t)peerId accessHash:(int64_t)accessHash user:(TGUser *)user rights:(TGChannelAdminRights *)rights {
    TLRPCchannels_editAdmin$channels_editAdmin *editAdmin = [[TLRPCchannels_editAdmin$channels_editAdmin alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    editAdmin.channel = inputChannel;
    TLInputUser$inputUser *inputUser = [[TLInputUser$inputUser alloc] init];
    inputUser.user_id = user.uid;
    inputUser.access_hash = user.phoneNumberHash;
    editAdmin.user_id = inputUser;
    editAdmin.admin_rights = [rights tlRights];
    
    return [[[TGTelegramNetworking instance] requestSignal:editAdmin] mapToSignal:^SSignal *(TLUpdates *updates) {
        [[TGTelegramNetworking instance] addUpdates:updates];
        [self channelAdminRightsUpdatedPipe].sink(@(peerId));
        return [SSignal complete];
    }];
}

+ (SSignal *)updateChannelBannedRightsAndGetMembership:(int64_t)peerId accessHash:(int64_t)accessHash user:(TGUser *)user rights:(TGChannelBannedRights *)rights {
    TLRPCchannels_editBanned$channels_editBanned *editBanned = [[TLRPCchannels_editBanned$channels_editBanned alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    editBanned.channel = inputChannel;
    TLInputUser$inputUser *inputUser = [[TLInputUser$inputUser alloc] init];
    inputUser.user_id = user.uid;
    inputUser.access_hash = user.phoneNumberHash;
    editBanned.user_id = inputUser;
    editBanned.banned_rights = [rights tlRights];
    
    SSignal *update = [[[[TGTelegramNetworking instance] requestSignal:editBanned] mapToSignal:^SSignal *(TLUpdates *updates) {
        [[TGTelegramNetworking instance] addUpdates:updates];
        
        return [SSignal complete];
    }] then:[self channelRole:peerId accessHash:accessHash user:user]];
    
    return update;
}

+ (SSignal *)channelRole:(int64_t)peerId accessHash:(int64_t)accessHash user:(TGUser *)user {
    TLRPCchannels_getParticipant$channels_getParticipant *getParticipant = [[TLRPCchannels_getParticipant$channels_getParticipant alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    getParticipant.channel = inputChannel;
    
    TLInputUser$inputUser *inputUser = [[TLInputUser$inputUser alloc] init];
    inputUser.user_id = user.uid;
    inputUser.access_hash = user.phoneNumberHash;
    getParticipant.user_id = inputUser;
    
    return [[[[TGTelegramNetworking instance] requestSignal:getParticipant] map:^id(TLchannels_ChannelParticipant *result) {
        TLChannelParticipant *participant = result.participant;
        int32_t timestamp = 0;
        bool isCreator = false;
        TGChannelAdminRights *adminRights = nil;
        TGChannelBannedRights *bannedRights = nil;
        int32_t inviterId = 0;
        int32_t adminInviterId = 0;
        int32_t kickedById = 0;
        bool adminCanManage = false;
        
        if ([participant isKindOfClass:[TLChannelParticipant$channelParticipant class]]) {
            timestamp = ((TLChannelParticipant$channelParticipant *)participant).date;
        } else if ([participant isKindOfClass:[TLChannelParticipant$channelParticipantCreator class]]) {
            isCreator = true;
            timestamp = 0;
        } else if ([participant isKindOfClass:[TLChannelParticipant$channelParticipantAdmin class]]) {
            adminRights = [[TGChannelAdminRights alloc] initWithTL:((TLChannelParticipant$channelParticipantAdmin *)participant).admin_rights];
            inviterId = ((TLChannelParticipant$channelParticipantAdmin *)participant).inviter_id;
            timestamp = ((TLChannelParticipant$channelParticipantAdmin *)participant).date;
            adminInviterId = ((TLChannelParticipant$channelParticipantAdmin *)participant).promoted_by;
            adminCanManage = ((TLChannelParticipant$channelParticipantAdmin *)participant).flags & (1 << 0);
        } else if ([participant isKindOfClass:[TLChannelParticipant$channelParticipantBanned class]]) {
            bannedRights = [[TGChannelBannedRights alloc] initWithTL:((TLChannelParticipant$channelParticipantBanned *)participant).banned_rights];
            kickedById = ((TLChannelParticipant$channelParticipantBanned *)participant).kicked_by;
            timestamp = ((TLChannelParticipant$channelParticipantBanned *)participant).date;
        }
        
        return [[TGCachedConversationMember alloc] initWithUid:user.uid isCreator:isCreator adminRights:adminRights bannedRights:bannedRights timestamp:timestamp inviterId:inviterId adminInviterId:adminInviterId kickedById:kickedById adminCanManage:adminCanManage];
    }] catch:^SSignal *(__unused id error) {
        return [SSignal single:nil];
    }];
}

+ (SSignal *)channelMembers:(int64_t)peerId accessHash:(int64_t)accessHash filter:(TLChannelParticipantsFilter *)filter offset:(NSUInteger)offset count:(NSUInteger)count {
    return [self channelMembers:peerId accessHash:accessHash filter:filter offset:offset count:count hash:0];
}
    
+ (SSignal *)channelMembers:(int64_t)peerId accessHash:(int64_t)accessHash filter:(TLChannelParticipantsFilter *)filter offset:(NSUInteger)offset count:(NSUInteger)count hash:(int32_t)hash {
    if (TGIOS6ChannelPeerIdIsModernRawChannel(peerId, accessHash)) {
        IOS6Trace(@"IOS6TRACE skip channels.getParticipants modern peer=%lld channel=%lld hash=%lld offset=%d count=%d filter=%@", peerId, TGIOS6ChannelIdFromPeerId(peerId, accessHash), accessHash, (int)offset, (int)count, NSStringFromClass([filter class]));
        return [SSignal single:@{@"memberDatas": @{}, @"users": @[], @"count": @0}];
    }
    
    TLRPCchannels_getParticipants$channels_getParticipants *getParticipants = [[TLRPCchannels_getParticipants$channels_getParticipants alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    getParticipants.channel = inputChannel;
    getParticipants.filter = filter;
    getParticipants.offset = (int32_t)offset;
    getParticipants.limit = (int32_t)count;
    getParticipants.n_hash = hash;
    return [[[TGTelegramNetworking instance] requestSignal:getParticipants] mapToSignal:^SSignal *(TLchannels_ChannelParticipants *intermediateResult) {
        if ([intermediateResult isKindOfClass:[TLchannels_ChannelParticipants$channels_channelParticipants class]]) {
            TLchannels_ChannelParticipants$channels_channelParticipants *result = (TLchannels_ChannelParticipants$channels_channelParticipants *)intermediateResult;
            [TGUserDataRequestBuilder executeUserDataUpdate:result.users];
            
            NSMutableArray *users = [[NSMutableArray alloc] init];
            NSMutableDictionary *memberDatas = [[NSMutableDictionary alloc] init];
            
            for (TLChannelParticipant *participant in result.participants) {
                TGUser *user = [TGDatabaseInstance() loadUser:participant.user_id];
                if (user != nil) {
                    int32_t timestamp = 0;
                    bool isCreator = false;
                    TGChannelAdminRights *adminRights = nil;
                    TGChannelBannedRights *bannedRights = nil;
                    int32_t inviterId = 0;
                    int32_t adminInviterId = 0;
                    int32_t kickedById = 0;
                    bool adminCanManage = false;
                    
                    if ([participant isKindOfClass:[TLChannelParticipant$channelParticipant class]]) {
                        timestamp = ((TLChannelParticipant$channelParticipant *)participant).date;
                    } else if ([participant isKindOfClass:[TLChannelParticipant$channelParticipantCreator class]]) {
                        isCreator = true;
                        timestamp = 0;
                    } else if ([participant isKindOfClass:[TLChannelParticipant$channelParticipantAdmin class]]) {
                        adminRights = [[TGChannelAdminRights alloc] initWithTL:((TLChannelParticipant$channelParticipantAdmin *)participant).admin_rights];
                        inviterId = ((TLChannelParticipant$channelParticipantAdmin *)participant).inviter_id;
                        timestamp = ((TLChannelParticipant$channelParticipantAdmin *)participant).date;
                        adminInviterId = ((TLChannelParticipant$channelParticipantAdmin *)participant).promoted_by;
                        adminCanManage = ((TLChannelParticipant$channelParticipantAdmin *)participant).flags & (1 << 0);
                    } else if ([participant isKindOfClass:[TLChannelParticipant$channelParticipantBanned class]]) {
                        bannedRights = [[TGChannelBannedRights alloc] initWithTL:((TLChannelParticipant$channelParticipantBanned *)participant).banned_rights];
                        timestamp = ((TLChannelParticipant$channelParticipantBanned *)participant).date;
                        kickedById = ((TLChannelParticipant$channelParticipantBanned *)participant).kicked_by;
                    } else if ([participant isKindOfClass:[TLChannelParticipant$channelParticipantSelf class]]) {
                        timestamp = ((TLChannelParticipant$channelParticipantSelf *)participant).date;
                        inviterId = ((TLChannelParticipant$channelParticipantSelf *)participant).inviter_id;
                    }
                    
                    memberDatas[@(user.uid)] = [[TGCachedConversationMember alloc] initWithUid:user.uid isCreator:isCreator adminRights:adminRights bannedRights:bannedRights timestamp:timestamp inviterId:inviterId adminInviterId:adminInviterId kickedById:kickedById adminCanManage:adminCanManage];
                    [users addObject:user];
                }
            }
            
            return [SSignal single:@{@"memberDatas": memberDatas, @"users": users, @"count": @(result.count)}];
        } else {
            return [SSignal single:@{@"notModified": @true}];
        }
    }];
}

+ (SSignal *)channelBlacklistMembers:(int64_t)peerId accessHash:(int64_t)accessHash offset:(NSUInteger)offset count:(NSUInteger)count {
    return [self channelMembers:peerId accessHash:accessHash filter:[[TLChannelParticipantsFilter$channelParticipantsKicked alloc] init] offset:offset count:count];
}

+ (SSignal *)channelBannedMembers:(int64_t)peerId accessHash:(int64_t)accessHash offset:(NSUInteger)offset count:(NSUInteger)count {
    return [self channelMembers:peerId accessHash:accessHash filter:[[TLChannelParticipantsFilter$channelParticipantsBanned alloc] init] offset:offset count:count];
}

+ (SSignal *)channelMembers:(int64_t)peerId accessHash:(int64_t)accessHash offset:(NSUInteger)offset count:(NSUInteger)count {
    return [self channelMembers:peerId accessHash:accessHash filter:[[TLChannelParticipantsFilter$channelParticipantsRecent alloc] init] offset:offset count:count];
}

+ (SSignal *)channelAdmins:(int64_t)peerId accessHash:(int64_t)accessHash offset:(NSUInteger)offset count:(NSUInteger)count {
    return [self channelAdmins:peerId accessHash:accessHash offset:offset count:count hash:0];
}

+ (SSignal *)channelAdmins:(int64_t)peerId accessHash:(int64_t)accessHash offset:(NSUInteger)offset count:(NSUInteger)count hash:(int32_t)hash {
    return [self channelMembers:peerId accessHash:accessHash filter:[[TLChannelParticipantsFilter$channelParticipantsAdmins alloc] init] offset:offset count:count hash:hash];
}

+ (SSignal *)channelInviterUser:(int64_t)peerId accessHash:(int64_t)accessHash {
    TLRPCchannels_getParticipant$channels_getParticipant *getParticipant = [[TLRPCchannels_getParticipant$channels_getParticipant alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    getParticipant.channel = inputChannel;
    getParticipant.user_id = [[TLInputUser$inputUserSelf alloc] init];
    
    SSignal *cachedDataSignal = [[[TGDatabaseInstance() channelCachedData:peerId] take:1] mapToSignal:^SSignal *(TGCachedConversationData *cachedData) {
        if (cachedData == nil || true) {
            return [[[TGChannelManagementSignals updateChannelExtendedInfo:peerId accessHash:accessHash updateUnread:false] then:[[TGDatabaseInstance() channelCachedData:peerId] take:1]] map:^id(TGCachedConversationData *nextCachedData) {
                if (nextCachedData == nil) {
                    IOS6Trace(@"IOS6TRACE channelInviter empty cachedData peer=%lld hash=%lld", peerId, accessHash);
                    return [[TGCachedConversationData alloc] init];
                }
                return nextCachedData;
            }];
        } else {
            return [SSignal single:cachedData];
        }
    }];
    
    SSignal *participantSignal = [[TGTelegramNetworking instance] requestSignal:getParticipant];
    
    return [[[SSignal combineSignals:@[participantSignal, cachedDataSignal]] map:^id(NSArray *combinedData) {
        TLchannels_ChannelParticipant *result = combinedData[0];
        TGCachedConversationData *cachedData = combinedData[1];
        
        [TGUserDataRequestBuilder executeUserDataUpdate:result.users];
        
        TLChannelParticipant *participant = result.participant;
        int32_t inviterUid = 0;
        int32_t timestamp = 0;
        
        if (cachedData.migrationData == nil && [participant isKindOfClass:[TLChannelParticipant$channelParticipantSelf class]]) {
            inviterUid = ((TLChannelParticipant$channelParticipantSelf *)participant).inviter_id;
            timestamp = ((TLChannelParticipant$channelParticipantSelf *)participant).date;
        }
        
        return @{@"userId": @(inviterUid), @"timestamp": @(timestamp)};
    }] catch:^SSignal *(__unused id error) {
        return [SSignal single:nil];
    }];
}

+ (SSignal *)deleteChannel:(int64_t)peerId accessHash:(int64_t)accessHash {
    TLRPCchannels_deleteChannel$channels_deleteChannel *deleteChannel = [[TLRPCchannels_deleteChannel$channels_deleteChannel alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    deleteChannel.channel = inputChannel;
    
    return [[TGTelegramNetworking instance] requestSignal:deleteChannel];
}

+ (SSignal *)canMakePublicChannels {
    return [[[self checkChannelUsername:0 accessHash:0 username:@""] catch:^SSignal *(__unused id error) {
        return [SSignal single:@false];
    }] then:[SSignal single:@true]];
}

+ (SSignal *)updateChannelSignaturesEnabled:(int64_t)peerId accessHash:(int64_t)accessHash enabled:(bool)enabled {
    TLRPCchannels_toggleSignatures$channels_toggleSignatures *toggleSignatures = [[TLRPCchannels_toggleSignatures$channels_toggleSignatures alloc] init];
    
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    toggleSignatures.channel = inputChannel;
    toggleSignatures.enabled = enabled;
    return [[[TGTelegramNetworking instance] requestSignal:toggleSignatures] mapToSignal:^SSignal *(TLUpdates *updates) {
        id chat = updates.chats.firstObject;
        TGConversation *conversation = nil;
        if (chat != nil) {
            conversation = [[TGConversation alloc] initWithTelegraphChatDesc:chat];
            if (conversation.conversationId == peerId) {
                [TGDatabaseInstance() updateChannels:@[conversation]];
            }
        }
        [[TGTelegramNetworking instance] addUpdates:updates];
        
        return [SSignal complete];
    }];
}

+ (SSignal *)messageEditData:(int64_t)peerId accessHash:(int64_t)accessHash messageId:(int32_t)messageId {
    TLRPCmessages_getMessageEditData$messages_getMessageEditData *getMessageEditData = [[TLRPCmessages_getMessageEditData$messages_getMessageEditData alloc] init];
    TLInputPeer$inputPeerChannel *inputPeerChannel = [[TLInputPeer$inputPeerChannel alloc] init];
    inputPeerChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputPeerChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    getMessageEditData.peer = inputPeerChannel;
    getMessageEditData.n_id = messageId;
    return [[TGTelegramNetworking instance] requestSignal:getMessageEditData];
}

+ (SSignal *)updatePinnedMessage:(int64_t)peerId accessHash:(int64_t)accessHash messageId:(int32_t)messageId notify:(bool)notify {
    TLRPCchannels_updatePinnedMessage$channels_updatePinnedMessage *updatePinnedMessage = [[TLRPCchannels_updatePinnedMessage$channels_updatePinnedMessage alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    updatePinnedMessage.channel = inputChannel;
    
    updatePinnedMessage.n_id = messageId;
    if (!notify) {
        updatePinnedMessage.flags |= 1 << 0;
    }
    
    return [[[TGTelegramNetworking instance] requestSignal:updatePinnedMessage] mapToSignal:^SSignal *(TLUpdates *updates) {
        id chat = updates.chats.firstObject;
        TGConversation *conversation = nil;
        if (chat != nil) {
            conversation = [[TGConversation alloc] initWithTelegraphChatDesc:chat];
            if (conversation.conversationId == peerId) {
                [TGDatabaseInstance() updateChannels:@[conversation]];
            }
        }
        [[TGTelegramNetworking instance] addUpdates:updates];
        
        [TGDatabaseInstance() updateChannelPinnedMessageId:peerId pinnedMessageId:messageId hidden:nil];
        
        return [SSignal complete];
    }];
}

+ (SSignal *)removeAllUserMessages:(int64_t)peerId accessHash:(int64_t)accessHash user:(TGUser *)user {
    TLRPCchannels_deleteUserHistory$channels_deleteUserHistory *deleteUserHistory = [[TLRPCchannels_deleteUserHistory$channels_deleteUserHistory alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    deleteUserHistory.channel = inputChannel;
    
    TLInputUser$inputUser *inputUser = [[TLInputUser$inputUser alloc] init];
    inputUser.user_id = user.uid;
    inputUser.access_hash = user.phoneNumberHash;
    deleteUserHistory.user_id = inputUser;
    
    return [[[TGTelegramNetworking instance] requestSignal:deleteUserHistory] mapToSignal:^SSignal *(TLmessages_AffectedHistory *affectedHistory) {
        return [[TGDatabaseInstance() modify:^id{
            [TGDatabaseInstance() addMessagesToChannelAndDispatch:peerId messages:nil deletedMessages:nil holes:nil pts:affectedHistory.pts skipFeedUpdate:true];
            return nil;
        }] then:[TGDatabaseInstance() deleteMessagesInChannel:peerId fromUserId:user.uid]];
    }];
}

+ (SSignal *)reportUserSpam:(int64_t)peerId accessHash:(int64_t)accessHash user:(TGUser *)user messageIds:(NSArray *)messageIds {
    TLRPCchannels_reportSpam$channels_reportSpam *reportSpam = [[TLRPCchannels_reportSpam$channels_reportSpam alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    reportSpam.channel = inputChannel;
    
    TLInputUser$inputUser *inputUser = [[TLInputUser$inputUser alloc] init];
    inputUser.user_id = user.uid;
    inputUser.access_hash = user.phoneNumberHash;
    reportSpam.user_id = inputUser;
    reportSpam.n_id = messageIds;
    
    return [[TGTelegramNetworking instance] requestSignal:reportSpam];
}

+ (SSignal *)resolveChannelWithUsername:(NSString *)username {
    TLRPCcontacts_resolveUsername$contacts_resolveUsername *resolveUsername = [[TLRPCcontacts_resolveUsername$contacts_resolveUsername alloc] init];
    resolveUsername.username = username;

    return [[[TGTelegramNetworking instance] requestSignal:resolveUsername] mapToSignal:^SSignal *(TLcontacts_ResolvedPeer *resolvedPeer) {
        if ([resolvedPeer.peer isKindOfClass:[TLPeer$peerChannel class]] && resolvedPeer.chats.count != 0) {
            TGConversation *conversation = [[TGConversation alloc] initWithTelegraphChatDesc:resolvedPeer.chats[0]];
            conversation.kind = TGConversationKindTemporaryChannel;
            return [[TGChannelManagementSignals addChannel:conversation] takeLast];
        }
        else
        {
            return [SSignal fail:nil];
        }
    }];
}

+ (SSignal *)channelAdminLogEvents:(int64_t)peerId accessHash:(int64_t)accessHash minEntryId:(int64_t)minEntryId count:(int32_t)count filter:(TGChannelEventFilter)filter searchQuery:(NSString *)searchQuery userIds:(NSArray *)userIds {
    TLRPCchannels_getAdminLog *getAdminLog = [[TLRPCchannels_getAdminLog alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    getAdminLog.channel = inputChannel;
    getAdminLog.max_id = minEntryId;
    
    int32_t filterFlags = 0;
    if (filter.join) {
        filterFlags |= (1 << 0);
    }
    if (filter.leave) {
        filterFlags |= (1 << 1);
    }
    if (filter.invite) {
        filterFlags |= (1 << 2);
    }
    if (filter.ban) {
        filterFlags |= (1 << 3);
    }
    if (filter.unban) {
        filterFlags |= (1 << 4);
    }
    if (filter.kick) {
        filterFlags |= (1 << 5);
    }
    if (filter.unkick) {
        filterFlags |= (1 << 6);
    }
    if (filter.promote) {
        filterFlags |= (1 << 7);
    }
    if (filter.demote) {
        filterFlags |= (1 << 8);
    }
    if (filter.info) {
        filterFlags |= (1 << 9);
    }
    if (filter.settings) {
        filterFlags |= (1 << 10);
    }
    if (filter.pinned) {
        filterFlags |= (1 << 11);
    }
    if (filter.edit) {
        filterFlags |= (1 << 12);
    }
    if (filter.del) {
        filterFlags |= (1 << 13);
    }
    
    getAdminLog.flags |= (1 << 0);
    
    TLChannelAdminLogEventsFilter$channelAdminLogEventsFilter *eventsFilter = [[TLChannelAdminLogEventsFilter$channelAdminLogEventsFilter alloc] init];
    eventsFilter.flags = filterFlags;
    getAdminLog.events_filter = eventsFilter;
    
    getAdminLog.q = searchQuery;
    
    if (userIds != nil) {
        NSMutableArray *users = [[NSMutableArray alloc] init];
        for (NSNumber *userId in userIds) {
            TGUser *user = [TGDatabaseInstance() loadUser:[userId intValue]];
            if (user != nil) {
                TLInputUser$inputUser *inputUser = [[TLInputUser$inputUser alloc] init];
                inputUser.user_id = user.uid;
                inputUser.access_hash = user.phoneNumberHash;
                [users addObject:inputUser];
            }
        }
        
        getAdminLog.flags |= (1 << 1);
        getAdminLog.admins = users;
    }
    
    getAdminLog.limit = count;
    
    return [[[TGTelegramNetworking instance] requestSignal:getAdminLog] map:^id(TLchannels_AdminLogResults *results) {
        [TGUserDataRequestBuilder executeUserDataUpdate:results.users];
        NSMutableArray *entries = [[NSMutableArray alloc] init];
        for (TLChannelAdminLogEvent *event in results.events) {
            [entries addObject:[[TGChannelAdminLogEntry alloc] initWithTL:event]];
        }
        return entries;
    }];
}

+ (TGCachedConversationMember *)parseMember:(TLChannelParticipant *)participant {
    int32_t timestamp = 0;
    bool isCreator = false;
    TGChannelAdminRights *adminRights = nil;
    TGChannelBannedRights *bannedRights = nil;
    int32_t inviterId = 0;
    int32_t adminInviterId = 0;
    int32_t kickedById = 0;
    bool adminCanManage = false;
    
    if ([participant isKindOfClass:[TLChannelParticipant$channelParticipant class]]) {
        timestamp = ((TLChannelParticipant$channelParticipant *)participant).date;
    } else if ([participant isKindOfClass:[TLChannelParticipant$channelParticipantCreator class]]) {
        isCreator = true;
        timestamp = 0;
    } else if ([participant isKindOfClass:[TLChannelParticipant$channelParticipantAdmin class]]) {
        adminRights = [[TGChannelAdminRights alloc] initWithTL:((TLChannelParticipant$channelParticipantAdmin *)participant).admin_rights];
        inviterId = ((TLChannelParticipant$channelParticipantAdmin *)participant).inviter_id;
        timestamp = ((TLChannelParticipant$channelParticipantAdmin *)participant).date;
        adminInviterId = ((TLChannelParticipant$channelParticipantAdmin *)participant).promoted_by;
        adminCanManage = ((TLChannelParticipant$channelParticipantAdmin *)participant).flags & (1 << 0);
    } else if ([participant isKindOfClass:[TLChannelParticipant$channelParticipantBanned class]]) {
        bannedRights = [[TGChannelBannedRights alloc] initWithTL:((TLChannelParticipant$channelParticipantBanned *)participant).banned_rights];
        timestamp = ((TLChannelParticipant$channelParticipantBanned *)participant).date;
        kickedById = ((TLChannelParticipant$channelParticipantBanned *)participant).kicked_by;
    } else if ([participant isKindOfClass:[TLChannelParticipant$channelParticipantSelf class]]) {
        timestamp = ((TLChannelParticipant$channelParticipantSelf *)participant).date;
        inviterId = ((TLChannelParticipant$channelParticipantSelf *)participant).inviter_id;
    }
    
    return [[TGCachedConversationMember alloc] initWithUid:participant.user_id isCreator:isCreator adminRights:adminRights bannedRights:bannedRights timestamp:timestamp inviterId:inviterId adminInviterId:adminInviterId kickedById:kickedById adminCanManage:adminCanManage];
}

+ (SSignal *)togglePreHistoryHidden:(int64_t)peerId accessHash:(int64_t)accessHash enabled:(bool)enabled {
    TLRPCchannels_togglePreHistoryHidden$channels_togglePreHistoryHidden *toggleRequest = [[TLRPCchannels_togglePreHistoryHidden$channels_togglePreHistoryHidden alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = TGIOS6ChannelIdFromPeerId(peerId, accessHash);
    inputChannel.access_hash = TGIOS6ChannelAccessHashForPeerId(peerId, accessHash);
    toggleRequest.channel = inputChannel;
    toggleRequest.enabled = enabled;
    return [[[TGTelegramNetworking instance] requestSignal:toggleRequest] mapToSignal:^SSignal *(__unused id result) {
        return [TGDatabaseInstance() modify:^id{
            [TGDatabaseInstance() updateChannelCachedData:peerId block:^TGCachedConversationData *(TGCachedConversationData *data) {
                if (data != nil) {
                    return [data updatePreHistory:enabled];
                }
                return data;
            }];
            return [TGDatabaseInstance() _channelCachedDataSync:peerId];
        }];
    }];
}

static int32_t hashForAdminIds(NSArray *contactIds) {
    uint32_t acc = 0;
    
    for (NSNumber *nUid in contactIds) {
        uint32_t uid = (uint32_t)[nUid intValue];
        acc = (acc * 20261) + uid;
    }
    return acc % 0x7FFFFFFF;
}

+ (SPipe *)channelAdminRightsUpdatedPipe {
    static SPipe *pipe = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pipe = [[SPipe alloc] init];
    });
    return pipe;
}

+ (SSignal *)updatedChannelAdmins:(int64_t)peerId accessHash:(int64_t)accessHash {
    SSignal *currentAdmins = [TGDatabaseInstance() modify:^{
        TGCachedConversationData *data = [TGDatabaseInstance() _channelCachedDataSync:peerId];
        NSMutableSet *adminIds = [[NSMutableSet alloc] init];
        for (TGCachedConversationMember *member in data.managementMembers) {
            [adminIds addObject:@(member.uid)];
        }
        return adminIds;
    }];
    
    SSignal *poll = [[TGDatabaseInstance() modify:^{
        TGCachedConversationData *data = [TGDatabaseInstance() _channelCachedDataSync:peerId];
        NSMutableArray *adminIds = [[NSMutableArray alloc] init];
        for (TGCachedConversationMember *member in data.managementMembers) {
            [adminIds addObject:@(member.uid)];
        }
        [adminIds sortUsingSelector:@selector(compare:)];
        
        return [[self channelAdmins:peerId accessHash:accessHash offset:0 count:100 hash:hashForAdminIds(adminIds)] mapToSignal:^SSignal *(NSDictionary *dict) {
            if ([dict[@"notModified"] boolValue]) {
                return [SSignal complete];
            } else {
                return [TGDatabaseInstance() modify:^id{
                    [TGDatabaseInstance() updateChannelCachedData:peerId block:^TGCachedConversationData *(TGCachedConversationData *current) {
                        return [current updateManagementMembers:[dict[@"memberDatas"] allValues]];
                    }];
                    
                    NSMutableSet *adminIds = [[NSMutableSet alloc] init];
                    for (TGCachedConversationMember *member in [dict[@"memberDatas"] allValues]) {
                        [adminIds addObject:@(member.uid)];
                    }
                    return adminIds;
                }];
            }
        }];
    }] switchToLatest];
    
    SSignal *reset = [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber) {
        [subscriber putNext:@true];
        return [[[self channelAdminRightsUpdatedPipe].signalProducer() filter:^bool(NSNumber *updatePeerId) {
            return [updatePeerId longLongValue] == peerId;
        }] startWithNext:^(__unused id next) {
            [subscriber putNext:@true];
        }];
    }];
    
    SSignal *repeatedPoll = [reset mapToSignal:^SSignal *(__unused id next) {
        return [[poll then:[[SSignal complete] delay:60.0 onQueue:[SQueue concurrentDefaultQueue]]] restart];
    }];
    
    return [currentAdmins then:repeatedPoll];
}

+ (SSignal *)pollQueuedChannels {
    return [[TGDatabaseInstance() enqueuedChannelPolls] mapToSignal:^SSignal *(TGQueuedPeerPoll *poll) {
        return [[TGChannelStateSignals pollOnce:poll.peerId] mapToSignal:^SSignal *(__unused id result) {
            [TGDatabaseInstance() confirmPeerPoll:poll];
            return [SSignal complete];
        }];
    }];
}

@end
