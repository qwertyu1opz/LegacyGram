#import "TGChannelStateSignals.h"
#import "IOS6Trace.h"
#import "IOS6NotificationProbe.h"
#import "IOS6FeatureProbe.h"

#import <UIKit/UIKit.h>

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGDatabase.h"
#import "TGTelegramNetworking.h"

#import "TL/TLMetaScheme.h"
#import "TLUpdates_ChannelDifference_manual.h"

#import "TGConversation+Telegraph.h"
#import "TGMessage+Telegraph.h"
#import "TGUserDataRequestBuilder.h"
#import "TGUpdateStateRequestBuilder.h"
#import "TGApplyUpdatesActor.h"
#import "TGTelegraph.h"

#import "TGDownloadMessagesSignal.h"
#import "TGConversationAddMessagesActor.h"

#import "TGChannelManagementSignals.h"

#import "TGModernSendCommonMessageActor.h"

#import "TGPreparedMessage.h"

#import "TLUpdate$updateChannelTooLong.h"
#import "TLchannelDifferenceTooLong.h"

static dispatch_block_t recursiveBlock(void (^block)(dispatch_block_t recurse)) {
    return ^ {
        block(recursiveBlock(block));
    };
}

static inline bool TGIOS6StatePeerIdIsModernRawChannel(int64_t peerId, int64_t accessHash)
{
    int64_t channelId = -peerId - 4294967296LL;
    return accessHash != 0 && channelId > 0 && channelId <= UINT32_MAX;
}

static NSMutableDictionary *TGIOS6InvalidChannelDifferenceUntil()
{
    static NSMutableDictionary *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        dict = [[NSMutableDictionary alloc] init];
    });
    return dict;
}

static NSString *TGIOS6InvalidChannelDifferenceKey(int64_t peerId, int64_t channelId, int64_t accessHash)
{
    return [[NSString alloc] initWithFormat:@"%lld:%lld:%lld", peerId, channelId, accessHash];
}

static inline int64_t TGIOS6StateChannelIdFromPeerId(int64_t peerId, int64_t accessHash)
{
    NSData *apiIdData = [TGDatabaseInstance() conversationCustomPropertySync:peerId name:murMurHash32(@"ios6ApiChannelId")];
    int64_t apiChannelId = 0;
    if (apiIdData.length == sizeof(int64_t))
        [apiIdData getBytes:&apiChannelId length:sizeof(apiChannelId)];
    if (apiChannelId > 0)
        return apiChannelId;

    if (TGIOS6StatePeerIdIsModernRawChannel(peerId, accessHash))
        return -peerId - 4294967296LL;

    int32_t channelId = TGChannelIdFromPeerId(peerId);
    if (channelId != 0)
        return channelId < 0 ? (int64_t)(uint32_t)channelId : (int64_t)channelId;

    return 0;
}

static int64_t TGIOS6RememberedMinChannelAccessHash(int64_t peerId)
{
    NSData *data = [TGDatabaseInstance() conversationCustomPropertySync:peerId name:murMurHash32(@"ios6MinChannelAccessHash")];
    if (data.length == sizeof(int64_t)) {
        int64_t accessHash = 0;
        [data getBytes:&accessHash length:sizeof(accessHash)];
        return accessHash;
    }
    return 0;
}

static SAtomic *TGIOS6SeededModernChannelTails()
{
    static SAtomic *value = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [[SAtomic alloc] initWithValue:[[NSMutableSet alloc] init]];
    });
    return value;
}

static const int64_t TGIOS6DebugAutoSeedChannelPeerId = -8167248297LL;

@interface TGManagedChannelState : NSObject {
    int64_t _peerId;
    
    SPipe *_updatesPipe;
    SPipe *_pollsPipe;
    id<SDisposable> _disposable;
    SAtomic *_timer;
    
    SAtomic *_keepPollingBag;
    id<SDisposable> _inviterId;
}

@end

@implementation TGManagedChannelState

- (instancetype)initWithPeerId:(int64_t)peerId {
    self = [super init];
    if (self != nil) {
        _peerId = peerId;
        
        _updatesPipe = [[SPipe alloc] init];
        _pollsPipe = [[SPipe alloc] init];
        
        _keepPollingBag = [[SAtomic alloc] initWithValue:[[SBag alloc] init]];
        
        __weak TGManagedChannelState *weakSelf = self;
        
        SSignal *pollsSignal = [_pollsPipe.signalProducer() mapToQueue:^SSignal *(__unused id tick) {
            __strong TGManagedChannelState *strongSelf = weakSelf;
            if (strongSelf != nil) {
                if ([[UIDevice currentDevice].systemVersion intValue] <= 6 &&
                    [UIApplication sharedApplication].applicationState != UIApplicationStateActive)
                {
                    // mapToQueue expects the returned signal to complete without
                    // forwarding a plain value into SSignalQueueState. Schedule
                    // the next lightweight check here, then emit completion only.
                    return [[SSignal single:@(120.0)] mapToSignal:^SSignal *(NSNumber *nextTimeout) {
                        __strong TGManagedChannelState *strongSelf = weakSelf;
                        if (strongSelf != nil) {
                            STimer *nextTimer = [[STimer alloc] initWithTimeout:[nextTimeout doubleValue] repeat:false completion:^{
                                __strong TGManagedChannelState *strongSelf = weakSelf;
                                if (strongSelf != nil) {
                                    if ([[strongSelf->_keepPollingBag with:^id(SBag *bag) {
                                        return @(![bag isEmpty]);
                                    }] boolValue]) {
                                        strongSelf->_pollsPipe.sink(@true);
                                    }
                                }
                            } queue:[SQueue concurrentDefaultQueue]];
                            STimer *previousTimer = [strongSelf->_timer swap:nextTimer];
                            [previousTimer invalidate];
                            [nextTimer start];
                        }
                        return [SSignal complete];
                    }];
                }
                return [[TGChannelStateSignals pollOnce:peerId] mapToSignal:^SSignal *(NSNumber *nextTimeout) {
                    __strong TGManagedChannelState *strongSelf = weakSelf;
                    if (strongSelf != nil) {
                        STimer *nextTimer = [[STimer alloc] initWithTimeout:[nextTimeout doubleValue] repeat:false completion:^{
                            __strong TGManagedChannelState *strongSelf = weakSelf;
                            if (strongSelf != nil) {
                                if ([[strongSelf->_keepPollingBag with:^id(SBag *bag) {
                                    return @(![bag isEmpty]);
                                }] boolValue]) {
                                    strongSelf->_pollsPipe.sink(@true);
                                }
                            }
                        } queue:[SQueue concurrentDefaultQueue]];
                        STimer *previousTimer = [strongSelf->_timer swap:nextTimer];
                        [previousTimer invalidate];
                        [nextTimer start];
                    }
                    return [SSignal complete];
                }];
            } else {
                return [SSignal complete];
            }
        }];
        
        SSignal *updatesSignal = [_updatesPipe.signalProducer() mapToSignal:^SSignal *(NSArray *updates) {
            __strong TGManagedChannelState *strongSelf = weakSelf;
            if (strongSelf != nil) {
                return [[strongSelf applyUpdates:updates] catch:^SSignal *(__unused id error) {
                    __strong TGManagedChannelState *strongSelf = weakSelf;
                    if (strongSelf != nil) {
                        strongSelf->_pollsPipe.sink(@true);
                    }
                    
                    return [SSignal complete];
                }];
            } else {
                return [SSignal complete];
            }
        }];
        SSignal *process = [[SSignal mergeSignals:@[updatesSignal, pollsSignal]] queue];
        
        _disposable = [process startWithNext:nil];
        
        _inviterId = [[[[[TGDatabaseInstance() existingChannel:peerId] filter:^bool(TGConversation *conversation) {
            return conversation.kind == TGConversationKindPersistentChannel;
        }] take:1] mapToSignal:^SSignal *(TGConversation *conversation) {
            return [TGChannelStateSignals addInviterMessage:peerId accessHash:conversation.accessHash];
        }] startWithNext:nil];
    }
    return self;
}

- (void)dealloc {
    [_disposable dispose];
    STimer *timer = [_timer swap:nil];
    [timer invalidate];
    [_inviterId dispose];
}

+ (SSignal *)_channelDifference:(int64_t)peerId accessHash:(int64_t)accessHash pts:(int32_t)pts {
    int32_t limit = 10;
    
#ifdef DEBUG
    limit = 2;
#endif

    int64_t channelId = TGIOS6StateChannelIdFromPeerId(peerId, accessHash);
    if (channelId == 0)
    {
        TGLog(@"IOS6AUTH skip state getChannelDifference peer=%lld channel=%lld accessHash=%lld pts=%d", peerId, channelId == 0 ? 0LL : (int64_t)(uint32_t)channelId, accessHash, pts);
        IOS6Trace(@"IOS6FULL state.diff.skip peer=%lld channel=%lld accessHash=%lld pts=%d", peerId, channelId == 0 ? 0LL : (int64_t)(uint32_t)channelId, accessHash, pts);
        if (channelId != 0 && accessHash != 0 && peerId == TGIOS6DebugAutoSeedChannelPeerId)
        {
            NSNumber *key = @(peerId);
            bool shouldSeedTail = [[TGIOS6SeededModernChannelTails() with:^id(NSMutableSet *set) {
                if ([set containsObject:key])
                    return @false;
                [set addObject:key];
                return @true;
            }] boolValue];
            if (shouldSeedTail)
            {
                TGLog(@"IOS6TRACE seed modern channel tail peer=%lld channel=%lld hash=%lld", peerId, (int64_t)(uint32_t)channelId, accessHash);
                [[[TGChannelManagementSignals preloadedHistoryTailForPeerId:peerId accessHash:accessHash] catch:^SSignal *(id error) {
                    TGLog(@"IOS6TRACE seed modern channel tail error peer=%lld channel=%lld hash=%lld error=%@", peerId, (int64_t)(uint32_t)channelId, accessHash, error);
                    return [SSignal complete];
                }] startWithNext:^(NSDictionary *dict) {
                    [[TGDatabaseInstance() modify:^id{
                        NSArray *removedImportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                        NSArray *removedUnimportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                        [TGDatabaseInstance() addMessagesToChannel:peerId messages:dict[@"messages"] deleteMessages:nil unimportantGroups:dict[@"unimportantGroups"] addedHoles:nil removedHoles:removedImportantHoles removedUnimportantHoles:removedUnimportantHoles updatedMessageSortKeys:nil returnGroups:false keepUnreadCounters:false skipFeedUpdate:true changedMessages:nil];
                        return [SSignal complete];
                    }] startWithNext:nil];
                }];
            }
        }
        TLUpdates_ChannelDifference$empty *empty = [[TLUpdates_ChannelDifference$empty alloc] init];
        empty.pts = MAX(pts, 1);
        empty.flags = 1;
        empty.timeout = 5;
        return [SSignal single:empty];
    }
    
    NSString *invalidChannelKey = TGIOS6InvalidChannelDifferenceKey(peerId, channelId, accessHash);
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSNumber *invalidUntil = nil;
    @synchronized(TGIOS6InvalidChannelDifferenceUntil())
    {
        invalidUntil = TGIOS6InvalidChannelDifferenceUntil()[invalidChannelKey];
        if (invalidUntil != nil && invalidUntil.doubleValue <= now)
        {
            [TGIOS6InvalidChannelDifferenceUntil() removeObjectForKey:invalidChannelKey];
            invalidUntil = nil;
        }
    }
    if (invalidUntil != nil)
    {
        TGLog(@"IOS6TRACE state getChannelDifference suppressed invalid peer=%lld channel=%lld hash=%lld until=%.0f", peerId, channelId, accessHash, invalidUntil.doubleValue);
        IOS6Trace(@"IOS6FULL state.diff.suppressed peer=%lld channel=%lld hash=%lld until=%.0f", peerId, channelId, accessHash, invalidUntil.doubleValue);
        TLUpdates_ChannelDifference$empty *empty = [[TLUpdates_ChannelDifference$empty alloc] init];
        empty.pts = MAX(pts, 1);
        empty.flags = 3;
        empty.timeout = (int32_t)MAX(60, invalidUntil.doubleValue - now);
        return [SSignal single:empty];
    }
    
    TLRPCupdates_getChannelDifference$updates_getChannelDifference *getChannelDifference = [[TLRPCupdates_getChannelDifference$updates_getChannelDifference alloc] init];
    TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
    inputChannel.channel_id = channelId;
    inputChannel.access_hash = accessHash;
    getChannelDifference.channel = inputChannel;
    getChannelDifference.filter = [[TLChannelMessagesFilter$channelMessagesFilterEmpty alloc] init];
    getChannelDifference.pts = MAX(pts, 1);
    getChannelDifference.limit = limit;
    
    IOS6Trace(@"IOS6FULL state.diff.request peer=%lld channel=%lld hash=%lld pts=%d limit=%d", peerId, inputChannel.channel_id, inputChannel.access_hash, getChannelDifference.pts, getChannelDifference.limit);
    
    return [[[TGTelegramNetworking instance] requestSignal:getChannelDifference] catch:^SSignal *(id error) {
        TGLog(@"IOS6TRACE state getChannelDifference error peer=%lld channel=%lld hash=%lld error=%@", peerId, inputChannel.channel_id, inputChannel.access_hash, error);
        IOS6Trace(@"IOS6FULL state.diff.error peer=%lld channel=%lld hash=%lld error=%@", peerId, inputChannel.channel_id, inputChannel.access_hash, error);
        TLUpdates_ChannelDifference$empty *empty = [[TLUpdates_ChannelDifference$empty alloc] init];
        empty.pts = MAX(pts, 1);
        NSString *errorDescription = [[error description] uppercaseString];
        if ([errorDescription rangeOfString:@"CHANNEL_INVALID"].location != NSNotFound || [errorDescription rangeOfString:@"PEER_ID_INVALID"].location != NSNotFound || [errorDescription rangeOfString:@"CHANNEL_PRIVATE"].location != NSNotFound)
        {
            empty.flags = 3;
            empty.timeout = [errorDescription rangeOfString:@"CHANNEL_PRIVATE"].location != NSNotFound ? 60 : 3600;
            @synchronized(TGIOS6InvalidChannelDifferenceUntil())
            {
                TGIOS6InvalidChannelDifferenceUntil()[invalidChannelKey] = @([[NSDate date] timeIntervalSince1970] + (empty.timeout == 60 ? 60.0 : 3600.0));
            }
        }
        else
        {
            empty.flags = 3;
            empty.timeout = 5;
        }
        return [SSignal single:empty];
    }];
}

- (SSignal *)applyUpdates:(NSArray *)updates {
    int64_t peerId = _peerId;
    IOS6Trace(@"IOS6FULL state.applyUpdates peer=%lld count=%d", peerId, (int)updates.count);
    
    return [[[TGDatabaseInstance() existingChannel:peerId] take:1] mapToSignal:^SSignal *(TGConversation *conversation) {
        IOS6Trace(@"IOS6FULL state.applyUpdates.conversation peer=%lld title=%@ pts=%d access=%lld kind=%d", peerId, conversation.chatTitle, conversation.pts, conversation.accessHash, (int)conversation.kind);
        IOS6NotificationProbe(@"GROUP", @"apply peer=%lld title=%@ count=%d pts=%d", peerId, conversation.chatTitle ?: @"", (int)updates.count, conversation.pts);
        NSMutableArray *ptsUpdates = [[NSMutableArray alloc] init];
        NSMutableSet *skipMessageIds = [[NSMutableSet alloc] init];
        NSMutableSet *readContentsMessageIds = [[NSMutableSet alloc] init];
        int32_t maxReadId = 0;
        int32_t maxReadOutgoingId = 0;
        NSNumber *pinnedMessageId = nil;
        __block bool failed = false;
        bool hasMessageIdUpdates = false;
        int32_t maxAvailableMessageId = 0;
        
        for (id update in updates) {
            IOS6Trace(@"IOS6FULL state.applyUpdates.item peer=%lld class=%@", peerId, NSStringFromClass([update class]));
            if ([update isKindOfClass:[TLUpdate$updateNewChannelMessage class]]) {
                [ptsUpdates addObject:update];
            } else if ([update isKindOfClass:[TLUpdate$updateEditChannelMessage class]]) {
                [ptsUpdates addObject:update];
            } else if ([update isKindOfClass:[TLUpdate$updateReadChannelInbox class]]) {
                maxReadId = MAX(maxReadId, ((TLUpdate$updateReadChannelInbox *)update).max_id);
            } else if ([update isKindOfClass:[TLUpdate$updateReadChannelOutbox class]]) {
                maxReadOutgoingId = MAX(maxReadOutgoingId, ((TLUpdate$updateReadChannelOutbox *)update).max_id);
            } else if ([update isKindOfClass:[TLUpdate$updateDeleteChannelMessages class]]) {
                [ptsUpdates addObject:update];
            } else if ([update isKindOfClass:[TLUpdate$updateChannelWebPage class]]) {
                [ptsUpdates addObject:update];
            } else if ([update isKindOfClass:[TLUpdate$updateChannelTooLong class]]) {
                failed = true;
            } else if ([update isKindOfClass:[TLUpdate$updateMessageID class]]) {
                hasMessageIdUpdates = true;
            } else if ([update isKindOfClass:[TLUpdate$updateChannelPinnedMessage class]]) {
                pinnedMessageId = @(((TLUpdate$updateChannelPinnedMessage *)update).n_id);
            } else if ([update isKindOfClass:[TLUpdate$updateChannelReadMessagesContents class]]) {
                [readContentsMessageIds addObjectsFromArray:((TLUpdate$updateChannelReadMessagesContents *)update).messages];
            } else if ([update isKindOfClass:[TLUpdate$updateChannelAvailableMessages class]]) {
                maxAvailableMessageId = MAX(maxAvailableMessageId, ((TLUpdate$updateChannelAvailableMessages *)update).available_min_id + 1);
            }
        }
        
        SSignal *removeMessagesInProgressSignal = nil;
        
        if (hasMessageIdUpdates) {
            NSMutableDictionary *randomIdToMessageId = [[NSMutableDictionary alloc] init];
            
            for (id update in updates) {
                if ([update isKindOfClass:[TLUpdate$updateMessageID class]]) {
                    int64_t randomId = ((TLUpdate$updateMessageID *)update).random_id;
                    int32_t messageId = ((TLUpdate$updateMessageID *)update).n_id;
                    randomIdToMessageId[@(randomId)] = @(messageId);
                }
            }
            
            removeMessagesInProgressSignal = [[SSignal defer:^SSignal *{
                for (TGModernSendCommonMessageActor *actor in [ActionStageInstance() executingActorsWithPathPrefix:[[NSString alloc] initWithFormat:@"/tg/sendCommonMessage/(%" PRId64 ")/", peerId]]) {
                    if (actor.preparedMessage.randomId != 0) {
                        NSNumber *nMessageId = randomIdToMessageId[@(actor.preparedMessage.randomId)];
                        if (nMessageId != nil) {
                            [skipMessageIds addObject:nMessageId];
                        }
                    }
                }
                
                return [SSignal complete];
            }] startOn:[SQueue wrapConcurrentNativeQueue:[ActionStageInstance() globalStageDispatchQueue]]];
        } else {
            removeMessagesInProgressSignal = [SSignal complete];
        }
        
        return [removeMessagesInProgressSignal then:[SSignal defer:^SSignal *{
            int32_t updatedPts = conversation.pts;
            
            [ptsUpdates sortUsingComparator:^NSComparisonResult(id lhs, id rhs) {
                int32_t lhsPts = 0;
                int32_t rhsPts = 0;
                if ([lhs isKindOfClass:[TLUpdate$updateNewChannelMessage class]]) {
                    lhsPts = ((TLUpdate$updateNewChannelMessage *)lhs).pts;
                } else if ([lhs isKindOfClass:[TLUpdate$updateEditChannelMessage class]]) {
                    lhsPts = ((TLUpdate$updateEditChannelMessage *)lhs).pts;
                } else if ([lhs isKindOfClass:[TLUpdate$updateDeleteChannelMessages class]]) {
                    lhsPts = ((TLUpdate$updateDeleteChannelMessages *)lhs).pts;
                } else if ([lhs isKindOfClass:[TLUpdate$updateChannelWebPage class]]) {
                    lhsPts = ((TLUpdate$updateChannelWebPage *)lhs).pts;
                }
                if ([rhs isKindOfClass:[TLUpdate$updateNewChannelMessage class]]) {
                    rhsPts = ((TLUpdate$updateNewChannelMessage *)rhs).pts;
                }  else if ([rhs isKindOfClass:[TLUpdate$updateEditChannelMessage class]]) {
                    rhsPts = ((TLUpdate$updateEditChannelMessage *)rhs).pts;
                } else if ([rhs isKindOfClass:[TLUpdate$updateDeleteChannelMessages class]]) {
                    rhsPts = ((TLUpdate$updateDeleteChannelMessages *)rhs).pts;
                } else if ([rhs isKindOfClass:[TLUpdate$updateChannelWebPage class]]) {
                    rhsPts = ((TLUpdate$updateChannelWebPage *)rhs).pts;
                }
                return lhsPts < rhsPts ? NSOrderedAscending : NSOrderedDescending;
            }];
            
            NSMutableArray *addedMessages = [[NSMutableArray alloc] init];
            NSMutableArray *notificationMessageDescriptions = [[NSMutableArray alloc] init];
            NSMutableArray *updatedMessages = [[NSMutableArray alloc] init];
            NSMutableArray *deletedMessageIds = [[NSMutableArray alloc] init];
            
            while (false) TGLog(@"IOS6STATE channel.batch peer=%lld basePts=%d ptsUpdates=%d readIn=%d readOut=%d contents=%d", peerId, updatedPts, (int)ptsUpdates.count, maxReadId, maxReadOutgoingId, (int)readContentsMessageIds.count);

            for (id update in ptsUpdates) {
                if ([update isKindOfClass:[TLUpdate$updateNewChannelMessage class]]) {
                    TLUpdate$updateNewChannelMessage *updateNewChannelMessage = update;
                    TGMessage *message = [[TGMessage alloc] initWithTelegraphMessageDesc:updateNewChannelMessage.message];
                    message.pts = updateNewChannelMessage.pts;
                    
                    if (updateNewChannelMessage.pts <= updatedPts) {
                        IOS6Trace(@"IOS6FULL state.apply.newChannel.skipOld peer=%lld mid=%d pts=%d updatedPts=%d", peerId, message.mid, updateNewChannelMessage.pts, updatedPts);
                        IOS6NotificationProbe(@"GROUP_SKIP", @"reason=old peer=%lld title=%@ mid=%d pts=%d base=%d", peerId, conversation.chatTitle ?: @"", message.mid, updateNewChannelMessage.pts, updatedPts);
                        continue;
                    }
                    else if (updatedPts + updateNewChannelMessage.pts_count == updateNewChannelMessage.pts) {
                        if (message.mid != 0) {
                            if ([skipMessageIds containsObject:@(message.mid)]) {
                                TGLog(@"(Channel State %lld Skipped message %d", (long long)peerId, message.mid);
                            } else {
                                [addedMessages addObject:message];
                                [notificationMessageDescriptions addObject:updateNewChannelMessage.message];
                            }
                        }
                        IOS6Trace(@"IOS6FULL state.apply.newChannel.accept peer=%lld mid=%d pts=%d ptsCount=%d added=%d skipped=%d", peerId, message.mid, updateNewChannelMessage.pts, updateNewChannelMessage.pts_count, (int)addedMessages.count, [skipMessageIds containsObject:@(message.mid)] ? 1 : 0);
                        IOS6NotificationProbe(@"GROUP_ACCEPT", @"peer=%lld title=%@ mid=%d pts=%d count=%d queued=%d", peerId, conversation.chatTitle ?: @"", message.mid, updateNewChannelMessage.pts, updateNewChannelMessage.pts_count, (int)notificationMessageDescriptions.count);
                        updatedPts = updateNewChannelMessage.pts;
                    } else {
                        IOS6Trace(@"IOS6FULL state.apply.newChannel.gap peer=%lld mid=%d oldPts=%d newPts=%d ptsCount=%d", peerId, message.mid, updatedPts, updateNewChannelMessage.pts, updateNewChannelMessage.pts_count);
                        IOS6NotificationProbe(@"GROUP_SKIP", @"reason=pts_gap peer=%lld title=%@ mid=%d base=%d pts=%d count=%d", peerId, conversation.chatTitle ?: @"", message.mid, updatedPts, updateNewChannelMessage.pts, updateNewChannelMessage.pts_count);
                        failed = true;
                    }
                } else if ([update isKindOfClass:[TLUpdate$updateEditChannelMessage class]]) {
                    TLUpdate$updateEditChannelMessage *updateEditMessage = update;
                    TGMessage *message = [[TGMessage alloc] initWithTelegraphMessageDesc:updateEditMessage.message];
                    message.pts = updateEditMessage.pts;
                    
                    if (updateEditMessage.pts <= updatedPts) {
                        TGLog(@"IOS6STATE channel.edit.skipOld peer=%lld mid=%d pts=%d base=%d", peerId, message.mid, updateEditMessage.pts, updatedPts);
                        continue;
                    }
                    else if (updatedPts + updateEditMessage.pts_count == updateEditMessage.pts) {
                        if (message.mid != 0) {
                            if ([skipMessageIds containsObject:@(message.mid)]) {
                                TGLog(@"(Channel State %lld Skipped updated message %d", (long long)peerId, message.mid);
                            } else {
                                [updatedMessages addObject:message];
                            }
                        }
                        updatedPts = updateEditMessage.pts;
                    } else {
                        TGLog(@"IOS6STATE channel.edit.gap peer=%lld mid=%d base=%d pts=%d ptsCount=%d", peerId, message.mid, updatedPts, updateEditMessage.pts, updateEditMessage.pts_count);
                        failed = true;
                    }
                } else if ([update isKindOfClass:[TLUpdate$updateDeleteChannelMessages class]]) {
                    TLUpdate$updateDeleteChannelMessages *updateDeleteChannelMessages = update;
                    
                    if (updateDeleteChannelMessages.pts <= updatedPts) {
                        TGLog(@"IOS6STATE channel.delete.skipOld peer=%lld count=%d pts=%d base=%d", peerId, (int)updateDeleteChannelMessages.messages.count, updateDeleteChannelMessages.pts, updatedPts);
                        continue;
                    } else if (updatedPts + updateDeleteChannelMessages.pts_count == updateDeleteChannelMessages.pts) {
                        [deletedMessageIds addObjectsFromArray:updateDeleteChannelMessages.messages];
                        TGLog(@"IOS6STATE channel.delete.accept peer=%lld count=%d pts=%d ptsCount=%d", peerId, (int)updateDeleteChannelMessages.messages.count, updateDeleteChannelMessages.pts, updateDeleteChannelMessages.pts_count);
                        updatedPts = updateDeleteChannelMessages.pts;
                    } else {
                        TGLog(@"IOS6STATE channel.delete.gap peer=%lld count=%d base=%d pts=%d ptsCount=%d", peerId, (int)updateDeleteChannelMessages.messages.count, updatedPts, updateDeleteChannelMessages.pts, updateDeleteChannelMessages.pts_count);
                        failed = true;
                    }
                } else if ([update isKindOfClass:[TLUpdate$updateChannelWebPage class]]) {
                    TLUpdate$updateChannelWebPage *updateWebPage = (TLUpdate$updateChannelWebPage *)update;
                    
                    if (updateWebPage.pts <= updatedPts) {
                        continue;
                    } else if (updatedPts + updateWebPage.pts_count == updateWebPage.pts) {
                        updatedPts = updateWebPage.pts;
                    } else {
                        failed = true;
                    }
                }
            }
            
            NSMutableArray *downloadMessages = [[NSMutableArray alloc] init];
            
            NSMutableDictionary *addedMessageIdToMessage = [[NSMutableDictionary alloc] init];
            for (TGMessage *message in addedMessages) {
                addedMessageIdToMessage[@(message.mid)] = message;
            }
            
            for (TGMessage *message in [addedMessages arrayByAddingObjectsFromArray:updatedMessages])
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
                                    [downloadMessages addObject:[[TGDownloadMessage alloc] initWithPeerId:conversation.conversationId accessHash:conversation.accessHash messageId:replyAttachment.replyMessageId]];
                                }
                            }
                        }
                    }
                }
            }
            
            if (readContentsMessageIds.count != 0) {
                [ActionStageInstance() dispatchResource:[NSString stringWithFormat:@"/tg/conversation/(%lld)/readmessageContents", peerId] resource:@{@"messageIds": readContentsMessageIds}];
            }
            
            if (downloadMessages.count != 0) {
                return [[TGDownloadMessagesSignal downloadMessages:downloadMessages] mapToSignal:^SSignal *(NSArray *messages) {
                    return [[TGDatabaseInstance() modify:^id {
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
                        
                        for (TGMessage *message in updatedMessages)
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
                        
                        NSMutableArray *messageUpdates = [[NSMutableArray alloc] init];
                        
                        if (readContentsMessageIds.count != 0) {
                            for (NSNumber *nMid in readContentsMessageIds) {
                                [messageUpdates addObject:[[TGDatabaseUpdateContentsRead alloc] initWithPeerId:peerId messageId:[nMid intValue]]];
                            }
                        }

                        if (updatedMessages.count != 0) {
                            for (TGMessage *message in updatedMessages) {
                                int64_t updatePeerId = message.cid == 0 ? peerId : message.cid;
                                if (updatePeerId != peerId)
                                    TGLog(@"IOS6STATE channel.edit.peerMismatch peer=%lld msgPeer=%lld mid=%d", peerId, message.cid, message.mid);
                                [messageUpdates addObject:[[TGDatabaseUpdateMessageWithMessage alloc] initWithPeerId:updatePeerId messageId:message.mid message:message dispatchEdited:true]];
                            }
                        }
                        
                        if (messageUpdates.count != 0) {
                            [TGDatabaseInstance() transactionUpdateMessages:messageUpdates updateConversationDatas:nil];
                        }
                        
                        if (updatedPts != conversation.pts) {
                            IOS6Trace(@"IOS6FULL state.apply.commit peer=%lld added=%d updated=%d deleted=%d readIn=%d readOut=%d pinned=%@ available=%d failed=%d pts=%d oldPts=%d downloadedReplies=%d",
                                peerId, (int)addedMessages.count, (int)updatedMessages.count, (int)deletedMessageIds.count, maxReadId, maxReadOutgoingId, pinnedMessageId, maxAvailableMessageId, failed ? 1 : 0, updatedPts, conversation.pts, (int)downloadMessages.count);
                            [TGDatabaseInstance() addMessagesToChannelAndDispatch:peerId messages:addedMessages deletedMessages:deletedMessageIds holes:nil pts:updatedPts skipFeedUpdate:false];
                        }
                        
                        if (conversation.kind == TGConversationKindPersistentChannel && addedMessages.count != 0) {
                            [TGDatabaseInstance() _addedNewMessages:addedMessages];
                        }

                        IOS6NotificationProbe(@"GROUP_NOTIFY", @"peer=%lld title=%@ count=%d", peerId, conversation.chatTitle ?: @"", (int)notificationMessageDescriptions.count);
                        [TGApplyUpdatesActor presentLocalNotificationsForMessageDescriptions:notificationMessageDescriptions];
                        
                        if (maxReadId != 0) {
                            [TGDatabaseInstance() updateChannelRead:peerId maxReadId:maxReadId maxReadOutgoingId:0];
                        }
                        
                        if (maxReadOutgoingId != 0) {
                            [TGDatabaseInstance() transactionApplyMaxOutgoingReadIds:@{@(peerId): @(maxReadOutgoingId)}];
                        }
                        
                        if (pinnedMessageId != nil) {
                            if ([pinnedMessageId intValue] >= [TGDatabaseInstance() _channelCachedDataSync:peerId].minAvailableMessageId) {
                                [TGDatabaseInstance() updateChannelPinnedMessageId:peerId pinnedMessageId:[pinnedMessageId intValue] hidden:nil];
                            } else {
                                [TGDatabaseInstance() updateChannelPinnedMessageId:peerId pinnedMessageId:0 hidden:nil];
                            }
                        }
                        
                        if (maxAvailableMessageId != 0) {
                            [TGDatabaseInstance() transactionAddMessages:nil notifyAddedMessages:false removeMessages:nil updateMessages:nil updatePeerDrafts:nil removeMessagesInteractive:nil keepDates:false removeMessagesInteractiveForEveryone:false updateConversationDatas:nil applyMaxIncomingReadIds:nil applyMaxOutgoingReadIds:nil applyMaxOutgoingReadDates:nil applyUnreadMarks:nil readHistoryForPeerIds:nil resetPeerReadStates:nil resetPeerUnseenMentionsStates:nil clearConversationsWithPeerIds:nil clearConversationsInteractive:false removeConversationsWithPeerIds:nil updatePinnedConversations:nil synchronizePinnedConversations:false forceReplacePinnedConversations:false readMessageContentsInteractive:nil deleteEarlierHistory:@{@(peerId): @(maxAvailableMessageId)} updateFeededChannels:nil newlyJoinedFeedId:nil synchronizeFeededChannels:false calculateUnreadChats:false];
                        }
                        
                        if (failed) {
                            return [SSignal fail:nil];
                        } else {
                            return [SSignal complete];
                        }
                    }] switchToLatest];
                }];
            } else {
                NSMutableArray *messageUpdates = [[NSMutableArray alloc] init];
                
                if (readContentsMessageIds.count != 0) {
                    for (NSNumber *nMid in readContentsMessageIds) {
                        [messageUpdates addObject:[[TGDatabaseUpdateContentsRead alloc] initWithPeerId:peerId messageId:[nMid intValue]]];
                    }
                }
                
                if (updatedMessages.count != 0) {
                    for (TGMessage *message in updatedMessages) {
                        int64_t updatePeerId = message.cid == 0 ? peerId : message.cid;
                        if (updatePeerId != peerId)
                            TGLog(@"IOS6STATE channel.edit.peerMismatch peer=%lld msgPeer=%lld mid=%d", peerId, message.cid, message.mid);
                        [messageUpdates addObject:[[TGDatabaseUpdateMessageWithMessage alloc] initWithPeerId:updatePeerId messageId:message.mid message:message dispatchEdited:true]];
                    }
                }
                if (messageUpdates.count != 0) {
                    [TGDatabaseInstance() transactionUpdateMessages:messageUpdates updateConversationDatas:nil];
                }
                
                if (updatedPts != conversation.pts) {
                    IOS6Trace(@"IOS6FULL state.apply.commit peer=%lld added=%d updated=%d deleted=%d readIn=%d readOut=%d pinned=%@ available=%d failed=%d pts=%d oldPts=%d downloadedReplies=0",
                        peerId, (int)addedMessages.count, (int)updatedMessages.count, (int)deletedMessageIds.count, maxReadId, maxReadOutgoingId, pinnedMessageId, maxAvailableMessageId, failed ? 1 : 0, updatedPts, conversation.pts);
                    [TGDatabaseInstance() addMessagesToChannelAndDispatch:peerId messages:addedMessages deletedMessages:deletedMessageIds holes:nil pts:updatedPts skipFeedUpdate:false];
                }
                
                if (conversation.kind == TGConversationKindPersistentChannel && addedMessages.count != 0) {
                    [TGDatabaseInstance() _addedNewMessages:addedMessages];
                }

                IOS6NotificationProbe(@"GROUP_NOTIFY", @"peer=%lld title=%@ count=%d", peerId, conversation.chatTitle ?: @"", (int)notificationMessageDescriptions.count);
                [TGApplyUpdatesActor presentLocalNotificationsForMessageDescriptions:notificationMessageDescriptions];
                
                if (maxReadId != 0) {
                    [TGDatabaseInstance() updateChannelRead:peerId maxReadId:maxReadId maxReadOutgoingId:0];
                }
                
                if (maxReadOutgoingId != 0) {
                    [TGDatabaseInstance() transactionApplyMaxOutgoingReadIds:@{@(peerId): @(maxReadOutgoingId)}];
                }
                
                if (pinnedMessageId != nil) {
                    if ([pinnedMessageId intValue] >= [TGDatabaseInstance() _channelCachedDataSync:peerId].minAvailableMessageId) {
                        [TGDatabaseInstance() updateChannelPinnedMessageId:peerId pinnedMessageId:[pinnedMessageId intValue] hidden:nil];
                    } else {
                        [TGDatabaseInstance() updateChannelPinnedMessageId:peerId pinnedMessageId:0 hidden:nil];
                    }
                }
                
                if (maxAvailableMessageId != 0) {
                    [TGDatabaseInstance() transactionAddMessages:nil notifyAddedMessages:false removeMessages:nil updateMessages:nil updatePeerDrafts:nil removeMessagesInteractive:nil keepDates:false removeMessagesInteractiveForEveryone:false updateConversationDatas:nil applyMaxIncomingReadIds:nil applyMaxOutgoingReadIds:nil applyMaxOutgoingReadDates:nil applyUnreadMarks:nil readHistoryForPeerIds:nil resetPeerReadStates:nil resetPeerUnseenMentionsStates:nil clearConversationsWithPeerIds:nil clearConversationsInteractive:false removeConversationsWithPeerIds:nil updatePinnedConversations:nil synchronizePinnedConversations:false forceReplacePinnedConversations:false readMessageContentsInteractive:nil deleteEarlierHistory:@{@(peerId): @(maxAvailableMessageId)} updateFeededChannels:nil newlyJoinedFeedId:nil synchronizeFeededChannels:false calculateUnreadChats:false];
                }
                
                if (failed) {
                    return [SSignal fail:nil];
                } else {
                    return [SSignal complete];
                }
            }
        }]];
    }];
};

- (void)addUpdates:(NSArray *)updates {
    _updatesPipe.sink(updates);
}

- (SSignal *)keepPolling {
    __weak TGManagedChannelState *weakSelf = self;
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(__unused SSubscriber *subscriber) {
        __strong TGManagedChannelState *strongSelf = weakSelf;
        if (strongSelf != nil) {
            __block NSInteger index = -1;
            bool start = [[strongSelf->_keepPollingBag with:^id(SBag *bag) {
                bool shouldStart = [bag isEmpty];
                index = [bag addItem:@true];
                
                return @(shouldStart);
            }] boolValue];
            
            if (start) {
                _pollsPipe.sink(@true);
            }
            
            return [[SBlockDisposable alloc] initWithBlock:^{
                __strong TGManagedChannelState *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    [strongSelf->_keepPollingBag with:^id(SBag *bag) {
                        [bag removeItem:index];
                        return nil;
                    }];
                }
            }];
        }
        
        return nil;
    }];
}

@end

@implementation TGChannelStateSignals

+ (SAtomic *)channelStates {
    static SAtomic *value = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [[SAtomic alloc] initWithValue:[[NSMutableDictionary alloc] init]];
    });
    return value;
}

+ (void)clearChannelStates {
    [[self channelStates] swap:[[NSMutableDictionary alloc] init]];
}

+ (TGManagedChannelState *)channelState:(int64_t)peerId {
    return [[self channelStates] with:^id(NSMutableDictionary *dict) {
        TGManagedChannelState *state = dict[@(peerId)];
        if (state == nil) {
            state = [[TGManagedChannelState alloc] initWithPeerId:peerId];
            dict[@(peerId)] = state;
        }
        return state;
    }];
}

+ (SSignal *)addInviterMessage:(int64_t)peerId accessHash:(int64_t)accessHash {
    return [[TGDatabaseInstance() modify:^id {
        NSData *stored = [TGDatabaseInstance() conversationCustomPropertySync:peerId name:murMurHash32(@"inviterStored")];
        if (stored.length == 0) {
            TGConversation *conversation = [TGDatabaseInstance() loadChannels:@[@(peerId)]][@(peerId)];
            if (accessHash == 0 || (conversation != nil && !conversation.isChannelGroup)) {
                uint8_t one = 1;
                [TGDatabaseInstance() setConversationCustomProperty:peerId name:murMurHash32(@"inviterStored") value:[NSData dataWithBytes:&one length:1]];
                IOS6Trace(@"IOS6FULL channelInviter.skip peer=%lld access=%lld group=%d", peerId, accessHash, conversation.isChannelGroup ? 1 : 0);
                return @(true);
            }
            return @(false);
        } else {
            return @(true);
        }
    }] mapToSignal:^SSignal *(NSNumber *alreadyStored) {
        if ([alreadyStored boolValue]) {
            return [SSignal complete];
        } else {
            return [[[TGChannelManagementSignals channelInviterUser:peerId accessHash:accessHash] onNext:^(NSDictionary *dict) {
                [TGDatabaseInstance() dispatchOnDatabaseThread:^{
                    NSData *stored = [TGDatabaseInstance() conversationCustomPropertySync:peerId name:murMurHash32(@"inviterStored")];
                    if (stored.length == 0) {
                        if ([dict[@"userId"] intValue] != 0) {
                            TGMessage *message = [[TGMessage alloc] init];
                            message.mid = [[TGDatabaseInstance() generateLocalMids:1].firstObject intValue];
                            message.date = [dict[@"timestamp"] intValue];
                            TGActionMediaAttachment *attachment = [[TGActionMediaAttachment alloc] init];
                            attachment.actionType = TGMessageActionChannelInviter;
                            attachment.actionData = @{@"uid": dict[@"userId"]};
                            message.mediaAttachments = @[attachment];
                            message.sortKey = TGMessageSortKeyMake(peerId, TGMessageSpaceImportant, (int32_t)message.date, message.mid);
                            message.fromUid = TGTelegraphInstance.clientUserId;
                            message.toUid = peerId;
                            
                            [TGDatabaseInstance() addMessagesToChannelAndDispatch:peerId messages:@[message] deletedMessages:nil holes:nil pts:0 skipFeedUpdate:true];
                        }
                        
                        uint8_t one = 1;
                        [TGDatabaseInstance() setConversationCustomProperty:peerId name:murMurHash32(@"inviterStored") value:[NSData dataWithBytes:&one length:1]];
                    }
                } synchronous:false];
            }] mapToSignal:^SSignal *(__unused id next) {
                return [SSignal complete];
            }];
        }
    }];
}

+ (SSignal *)validateMessageRanges:(int64_t)peerId pts:(int32_t)pts validPts:(int32_t)validPts messageRanges:(NSArray *)messageRanges {
    return [[[TGDatabaseInstance() existingChannel:peerId] take:1] mapToSignal:^SSignal *(TGConversation *conversation) {
        int64_t channelId = TGIOS6StateChannelIdFromPeerId(peerId, conversation.accessHash);
        if (channelId == 0 || conversation.accessHash != 0)
        {
            return [[TGDatabaseInstance() modify:^id{
                [TGDatabaseInstance() updateMessageRangesPts:peerId messageRanges:messageRanges pts:validPts];
                return nil;
            }] mapToSignal:^SSignal *(__unused id next) {
                return [SSignal complete];
            }];
        }
        
        TLRPCupdates_getChannelDifference$updates_getChannelDifference *getChannelDifference = [[TLRPCupdates_getChannelDifference$updates_getChannelDifference alloc] init];
        TLChannelMessagesFilter$channelMessagesFilter *filter = [[TLChannelMessagesFilter$channelMessagesFilter alloc] init];
        filter.flags = 1 << 1;
        filter.ranges = messageRanges;
        getChannelDifference.filter = filter;
        getChannelDifference.pts = pts;
        getChannelDifference.limit = 1000;
        TLInputChannel$inputChannel *inputChannel = [[TLInputChannel$inputChannel alloc] init];
        inputChannel.channel_id = channelId;
        inputChannel.access_hash = conversation.accessHash;
        getChannelDifference.channel = inputChannel;
        
        return [[[TGTelegramNetworking instance] requestSignal:getChannelDifference] mapToSignal:^SSignal *(TLupdates_ChannelDifference *result) {
            NSMutableArray *deletedMessageIds = [[NSMutableArray alloc] init];
            
            if ([result isKindOfClass:[TLUpdates_ChannelDifference$channelDifference class]]) {
                for (id update in ((TLUpdates_ChannelDifference$channelDifference *)result).other_updates) {
                    if ([update isKindOfClass:[TLUpdate$updateDeleteChannelMessages class]]) {
                        [deletedMessageIds addObjectsFromArray:((TLUpdate$updateDeleteChannelMessages *)update).messages];
                    }
                }
            } else if ([result isKindOfClass:[TLUpdates_ChannelDifference$empty class]]) {
                
            } else if ([result isKindOfClass:[TLchannelDifferenceTooLong class]]) {
                
            }
            
            return [[TGDatabaseInstance() modify:^id{
                if (deletedMessageIds.count != 0) {
                    [TGDatabaseInstance() addMessagesToChannel:peerId messages:nil deleteMessages:deletedMessageIds unimportantGroups:nil addedHoles:nil removedHoles:nil removedUnimportantHoles:nil updatedMessageSortKeys:nil returnGroups:false keepUnreadCounters:false skipFeedUpdate:false changedMessages:^(NSArray *addedMessages, NSArray *removedMessages, NSDictionary *updatedMessages, NSArray *addedUnimportantHoles, NSArray *removedUnimportantHoles) {
                        NSMutableArray *addedImportantMessages = [[NSMutableArray alloc] init];
                        NSMutableArray *addedUnimportantMessages = [[NSMutableArray alloc] init];
                        for (TGMessage *message in addedMessages) {
                            if (message.hole != nil) {
                                [addedImportantMessages addObject:message];
                                [addedUnimportantMessages addObject:message];
                            }
                            else if (message.group != nil) {
                                [addedImportantMessages addObject:message];
                            } else if (TGMessageSortKeySpace(message.sortKey) == TGMessageSpaceImportant) {
                                [addedImportantMessages addObject:message];
                                [addedUnimportantMessages addObject:message];
                            } else {
                                [addedUnimportantMessages addObject:message];
                            }
                        }
                        
                        [addedUnimportantMessages addObjectsFromArray:addedUnimportantHoles];
                        
                        NSMutableArray *removedImportantMessages = [[NSMutableArray alloc] init];
                        NSMutableArray *removedUnimportantMessages = [[NSMutableArray alloc] init];
                        
                        NSMutableDictionary *updatedImportantMessages = [[NSMutableDictionary alloc] init];
                        NSMutableDictionary *updatedUnimportantMessages = [[NSMutableDictionary alloc] init];
                        
                        [updatedImportantMessages addEntriesFromDictionary:updatedMessages];
                        [updatedUnimportantMessages addEntriesFromDictionary:updatedMessages];
                        
                        [removedImportantMessages addObjectsFromArray:removedMessages];
                        [removedUnimportantMessages addObjectsFromArray:removedMessages];
                        [removedUnimportantMessages addObjectsFromArray:removedUnimportantHoles];
                        
                        [ActionStageInstance() dispatchResource:[NSString stringWithFormat:@"/tg/conversation/(%lld)/importantMessages", peerId] resource:@{@"removed": removedImportantMessages, @"added": addedImportantMessages, @"updated": updatedImportantMessages}];
                        [ActionStageInstance() dispatchResource:[NSString stringWithFormat:@"/tg/conversation/(%lld)/unimportantMessages", peerId] resource:@{@"removed": removedUnimportantMessages, @"added": addedUnimportantMessages, @"updated": updatedUnimportantMessages}];
                    }];
                }
                
                [TGDatabaseInstance() updateMessageRangesPts:peerId messageRanges:messageRanges pts:validPts];
                
                return [SSignal complete];
            }] switchToLatest];
        }];
    }];
}

+ (SSignal *)pollOnce:(int64_t)peerId {
    return [[[TGDatabaseInstance() existingChannel:peerId] take:1] mapToSignal:^SSignal *(TGConversation *conversation) {
        IOS6Trace(@"IOS6FULL state.poll.start peer=%lld title=%@ access=%lld pts=%d", peerId, conversation.chatTitle, conversation.accessHash, conversation.pts);
        return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber) {
            SMetaDisposable *disposable = [[SMetaDisposable alloc] init];
            
            void (^start)() = recursiveBlock(^(dispatch_block_t recurse) {
                [TGDatabaseInstance() channelPts:peerId completion:^(int32_t pts) {                    
                    IOS6Trace(@"IOS6FULL state.poll.pts peer=%lld pts=%d", peerId, pts);
                    int64_t accessHash = conversation.accessHash;
                    TGConversation *freshConversation = [TGDatabaseInstance() loadChannels:@[@(peerId)]][@(peerId)];
                    bool hasStrongAccessHash = false;
                    if (freshConversation != nil && freshConversation.accessHash != 0 && !freshConversation.isMin)
                    {
                        accessHash = freshConversation.accessHash;
                        hasStrongAccessHash = true;
                    }
                    else if (conversation.accessHash != 0 && !conversation.isMin)
                        hasStrongAccessHash = true;
                    int64_t rememberedAccessHash = TGIOS6RememberedMinChannelAccessHash(peerId);
                    if (!hasStrongAccessHash && rememberedAccessHash != 0 && accessHash == 0) {
                        IOS6Trace(@"IOS6FULL state.poll.accessHashRemembered peer=%lld old=%lld remembered=%lld", peerId, accessHash, rememberedAccessHash);
                        accessHash = rememberedAccessHash;
                    }
                    else if (hasStrongAccessHash && rememberedAccessHash != 0 && rememberedAccessHash != accessHash)
                        IOS6Trace(@"IOS6FULL state.poll.accessHashIgnoredMin peer=%lld strong=%lld min=%lld", peerId, accessHash, rememberedAccessHash);
                    if (accessHash != conversation.accessHash)
                        IOS6Trace(@"IOS6FULL state.poll.accessHashRefresh peer=%lld old=%lld fresh=%lld", peerId, conversation.accessHash, accessHash);
                    [disposable setDisposable:[[TGManagedChannelState _channelDifference:peerId accessHash:accessHash pts:pts] startWithNext:^(TLupdates_ChannelDifference *result) {
                        [TGDatabaseInstance() dispatchOnDatabaseThread:^{
                            IOS6Trace(@"IOS6FULL state.poll.diffResult peer=%lld class=%@", peerId, NSStringFromClass([result class]));
                            NSMutableArray *messages = [[NSMutableArray alloc] init];
                            NSMutableArray *notificationMessageDescriptions = [[NSMutableArray alloc] init];
                            NSMutableArray *updatedMessages = [[NSMutableArray alloc] init];
                            NSMutableArray *deletedMessageIds = [[NSMutableArray alloc] init];
                            
                            NSMutableArray *conversations = [[NSMutableArray alloc] init];
                            bool restart = false;
                            NSTimeInterval nextTimeout = 5.0;
                            
                            NSArray *users = nil;
                            void (^addHole)() = nil;
                            void (^addMessages)() = nil;
                            void (^loadHoles)() = nil;
                            
                            SSignal *removeMessagesInProgressSignal = [SSignal complete];
                            NSMutableSet *skipMessageIds = [[NSMutableSet alloc] init];
                            
                            if ([result isKindOfClass:[TLUpdates_ChannelDifference$empty class]]) {
                                TLUpdates_ChannelDifference$empty *concreteDifference = (TLUpdates_ChannelDifference$empty *)result;
                                if (concreteDifference.flags & (1 << 1)) {
                                    nextTimeout = concreteDifference.timeout;
                                }
                            } else if ([result isKindOfClass:[TLchannelDifferenceTooLong class]]) {
                                TLchannelDifferenceTooLong *concreteDifference = (TLchannelDifferenceTooLong *)result;
                                if (concreteDifference.flags & (1 << 1)) {
                                    nextTimeout = concreteDifference.timeout;
                                }
                                
                                TGLog(@"(TGChannelStateSignals ChannelDifference for %lld is tooLong, topMessage: %d)", peerId, concreteDifference.top_message);
                                IOS6Trace(@"IOS6FULL state.poll.tooLong peer=%lld top=%d pts=%d unread=%d mentions=%d messages=%d users=%d chats=%d timeout=%.1f", peerId, concreteDifference.top_message, concreteDifference.pts, concreteDifference.unread_count, concreteDifference.unread_mentions_count, (int)concreteDifference.messages.count, (int)concreteDifference.users.count, (int)concreteDifference.chats.count, nextTimeout);
                                
                                for (id messageDesc in concreteDifference.messages) {
                                    TGMessage *message = [[TGMessage alloc] initWithTelegraphMessageDesc:messageDesc];
                                    message.pts = concreteDifference.pts;
                                    if (message.mid != 0) {
                                        [messages addObject:message];
                                    }
                                }
                                
                                for (id chatDesc in concreteDifference.chats) {
                                    TGConversation *updatedConversation = [[TGConversation alloc] initWithTelegraphChatDesc:chatDesc];
                                    if (updatedConversation.conversationId != 0) {
                                        [conversations addObject:updatedConversation];
                                    }
                                }
                                
                                users = concreteDifference.users;
                                
                                addHole = ^{
                                    int32_t minMessageId = INT32_MAX;
                                    int32_t maxMessageId = 0;
                                    for (TGMessage *message in messages) {
                                        minMessageId = MIN(minMessageId, message.mid);
                                        maxMessageId = MAX(maxMessageId, message.mid);
                                    }
                                    IOS6Trace(@"IOS6FULL state.poll.tooLong.addHole peer=%lld messages=%d min=%d max=%d pts=%d top=%d chats=%d", peerId, (int)messages.count, minMessageId == INT32_MAX ? 0 : minMessageId, maxMessageId, concreteDifference.pts, concreteDifference.top_message, (int)conversations.count);
                                    [TGDatabaseInstance() addTrailingHoleToChannelAndDispatch:peerId messages:messages pts:concreteDifference.pts importantUnreadCount:concreteDifference.unread_count unimportantUnreadCount:0 unreadMentionsCount:concreteDifference.unread_mentions_count maxReadId:concreteDifference.read_inbox_max_id topMessageId:concreteDifference.top_message];
                                    
                                    [TGDatabaseInstance() updateHistoryPtsForPeerId:peerId pts:concreteDifference.pts];
                                };
                                
                                if (concreteDifference.unread_count != 0) {
                                    loadHoles = ^{
                                        SMetaDisposable *metaDisposable = [[SMetaDisposable alloc] init];
                                        __weak SMetaDisposable *weakMetaDisposable = metaDisposable;
                                        id<SDisposable> disposable = [[[TGChannelManagementSignals preloadedHistoryForPeerId:peerId accessHash:conversation.accessHash aroundMessageId:concreteDifference.read_inbox_max_id] mapToSignal:^SSignal *(NSDictionary *dict) {
                                            return [[TGDatabaseInstance() modify:^{
                                                NSArray *removedImportantHoles = nil;
                                                NSArray *removedUnimportantHoles = nil;
                                                IOS6Trace(@"IOS6FULL state.poll.tooLong.preload peer=%lld around=%d messages=%d hole=%@ unimportant=%d", peerId, concreteDifference.read_inbox_max_id, (int)[dict[@"messages"] count], dict[@"hole"], (int)[dict[@"unimportantGroups"] count]);
                                                
                                                removedImportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                                                removedUnimportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                                                
                                                [TGDatabaseInstance() addMessagesToChannel:peerId messages:dict[@"messages"] deleteMessages:nil unimportantGroups:dict[@"unimportantGroups"] addedHoles:nil removedHoles:removedImportantHoles removedUnimportantHoles:removedUnimportantHoles updatedMessageSortKeys:nil returnGroups:false keepUnreadCounters:false skipFeedUpdate:true changedMessages:^(NSArray *addedMessages, NSArray *removedMessages, NSDictionary *updatedMessages, NSArray *addedUnimportantHoles, NSArray *removedUnimportantHoles) {
                                                    NSMutableArray *addedImportantMessages = [[NSMutableArray alloc] init];
                                                    NSMutableArray *addedUnimportantMessages = [[NSMutableArray alloc] init];
                                                    for (TGMessage *message in addedMessages) {
                                                        if (message.hole != nil) {
                                                            [addedImportantMessages addObject:message];
                                                            [addedUnimportantMessages addObject:message];
                                                        }
                                                        else if (message.group != nil) {
                                                            [addedImportantMessages addObject:message];
                                                        } else if (TGMessageSortKeySpace(message.sortKey) == TGMessageSpaceImportant) {
                                                            [addedImportantMessages addObject:message];
                                                            [addedUnimportantMessages addObject:message];
                                                        } else {
                                                            [addedUnimportantMessages addObject:message];
                                                        }
                                                    }
                                                    
                                                    [addedUnimportantMessages addObjectsFromArray:addedUnimportantHoles];
                                                    
                                                    NSMutableArray *removedImportantMessages = [[NSMutableArray alloc] init];
                                                    NSMutableArray *removedUnimportantMessages = [[NSMutableArray alloc] init];
                                                    
                                                    NSMutableDictionary *updatedImportantMessages = [[NSMutableDictionary alloc] init];
                                                    NSMutableDictionary *updatedUnimportantMessages = [[NSMutableDictionary alloc] init];
                                                    
                                                    [updatedImportantMessages addEntriesFromDictionary:updatedMessages];
                                                    [updatedUnimportantMessages addEntriesFromDictionary:updatedMessages];
                                                    
                                                    [removedImportantMessages addObjectsFromArray:removedMessages];
                                                    [removedUnimportantMessages addObjectsFromArray:removedMessages];
                                                    [removedUnimportantMessages addObjectsFromArray:removedUnimportantHoles];
                                                    
                                                    [ActionStageInstance() dispatchResource:[NSString stringWithFormat:@"/tg/conversation/(%lld)/importantMessages", peerId] resource:@{@"removed": removedImportantMessages, @"added": addedImportantMessages, @"updated": updatedImportantMessages}];
                                                    [ActionStageInstance() dispatchResource:[NSString stringWithFormat:@"/tg/conversation/(%lld)/unimportantMessages", peerId] resource:@{@"removed": removedUnimportantMessages, @"added": addedUnimportantMessages, @"updated": updatedUnimportantMessages}];
                                                }];
                                                
                                                return [SSignal complete];
                                            }] switchToLatest];
                                        }] startWithNext:nil error:^(__unused id error) {
                                            __strong SMetaDisposable *strongMetaDisposable = weakMetaDisposable;
                                            if (strongMetaDisposable != nil) {
                                                [TGTelegraphInstance.disposeOnLogout remove:strongMetaDisposable];
                                            }
                                        } completed:^{
                                            __strong SMetaDisposable *strongMetaDisposable = weakMetaDisposable;
                                            if (strongMetaDisposable != nil) {
                                                [TGTelegraphInstance.disposeOnLogout remove:strongMetaDisposable];
                                            }
                                        }];
                                        [metaDisposable setDisposable:disposable];
                                        [TGTelegraphInstance.disposeOnLogout add:metaDisposable];
                                    };
                                }
                            } else if ([result isKindOfClass:[TLUpdates_ChannelDifference$channelDifference class]]) {
                                TLUpdates_ChannelDifference$channelDifference *concreteDifference = (TLUpdates_ChannelDifference$channelDifference *)result;
                                TGLog(@"IOS6STATE diff.channel peer=%lld pts=%d new=%d other=%d users=%d chats=%d flags=%d", peerId, concreteDifference.pts, (int)concreteDifference.n_new_messages.count, (int)concreteDifference.other_updates.count, (int)concreteDifference.users.count, (int)concreteDifference.chats.count, concreteDifference.flags);
                                IOS6Trace(@"IOS6FULL state.poll.channelDifference peer=%lld pts=%d new=%d other=%d users=%d chats=%d flags=%d", peerId, concreteDifference.pts, (int)concreteDifference.n_new_messages.count, (int)concreteDifference.other_updates.count, (int)concreteDifference.users.count, (int)concreteDifference.chats.count, concreteDifference.flags);
                                if (concreteDifference.flags & (1 << 1)) {
                                    nextTimeout = concreteDifference.timeout;
                                } else {
                                    restart = true;
                                }
                                
                                bool hasMessageIdUpdates = false;
                                
                                for (id messageDesc in concreteDifference.n_new_messages) {
                                    TGMessage *message = [[TGMessage alloc] initWithTelegraphMessageDesc:messageDesc];
                                    message.pts = concreteDifference.pts;
                                    if (message.mid != 0 && message.cid == peerId) {
                                        [messages addObject:message];
                                        [notificationMessageDescriptions addObject:messageDesc];
                                    }
                                }
                                
                                for (id update in concreteDifference.other_updates) {
                                    if ([update isKindOfClass:[TLUpdate$updateDeleteChannelMessages class]]) {
                                        TGLog(@"IOS6STATE diff.delete peer=%lld count=%d pts=%d", peerId, (int)((TLUpdate$updateDeleteChannelMessages *)update).messages.count, ((TLUpdate$updateDeleteChannelMessages *)update).pts);
                                        [deletedMessageIds addObjectsFromArray:((TLUpdate$updateDeleteChannelMessages *)update).messages];
                                    } else if ([update isKindOfClass:[TLUpdate$updateMessageID class]]) {
                                        hasMessageIdUpdates = true;
                                    } else if ([update isKindOfClass:[TLUpdate$updateEditChannelMessage class]]) {
                                        TLUpdate$updateEditChannelMessage *updateEditMessage = update;
                                        TGMessage *message = [[TGMessage alloc] initWithTelegraphMessageDesc:updateEditMessage.message];
                                        message.pts = updateEditMessage.pts;
                                        
                                        TGLog(@"IOS6STATE diff.edit peer=%lld mid=%d msgPeer=%lld pts=%d", peerId, message.mid, message.cid, updateEditMessage.pts);
                                        [updatedMessages addObject:message];
                                    } else if ([update isKindOfClass:[TLUpdate$updateMessageReactionsCodex class]]) {
                                        TLUpdate$updateMessageReactionsCodex *reactionUpdate = update;
                                        TGMessage *message = [TGDatabaseInstance() loadMessageWithMid:reactionUpdate.msg_id peerId:peerId];
                                        if (message != nil) {
                                            NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:message.contentProperties ?: @{}];
                                            if (reactionUpdate.reactionSummary.length != 0)
                                                properties[@"ios6ReactionSummary"] = [[TGMessageReactionSummaryContentProperty alloc] initWithSummary:reactionUpdate.reactionSummary chosenReaction:reactionUpdate.chosenReaction];
                                            else
                                                [properties removeObjectForKey:@"ios6ReactionSummary"];
                                            message.contentProperties = properties;
                                            [updatedMessages addObject:message];
                                            IOS6FeatureProbe(@"REACTION channel.apply peer=%lld mid=%d summary=%@ queued=1", peerId, reactionUpdate.msg_id, reactionUpdate.reactionSummary);
                                        } else {
                                            IOS6FeatureProbe(@"REACTION channel.apply peer=%lld mid=%d summary=%@ missingMessage=1", peerId, reactionUpdate.msg_id, reactionUpdate.reactionSummary);
                                        }
                                    }
                                }
                                
                                for (id channelDesc in concreteDifference.chats) {
                                    TGConversation *conversation = [[TGConversation alloc] initWithTelegraphChatDesc:channelDesc];
                                    if (conversation.conversationId != 0) {
                                        [conversations addObject:conversation];
                                    }
                                }
                                
                                SSignal *removeMessagesInProgressSignal = nil;
                                
                                if (hasMessageIdUpdates || true) {
                                    NSMutableDictionary *randomIdToMessageId = [[NSMutableDictionary alloc] init];
                                    
                                    for (id update in concreteDifference.other_updates) {
                                        if ([update isKindOfClass:[TLUpdate$updateMessageID class]]) {
                                            int64_t randomId = ((TLUpdate$updateMessageID *)update).random_id;
                                            int32_t messageId = ((TLUpdate$updateMessageID *)update).n_id;
                                            randomIdToMessageId[@(randomId)] = @(messageId);
                                        }
                                    }
                                    
                                    removeMessagesInProgressSignal = [[SSignal defer:^SSignal *{
                                        for (TGModernSendCommonMessageActor *actor in [ActionStageInstance() executingActorsWithPathPrefix:[[NSString alloc] initWithFormat:@"/tg/sendCommonMessage/(%" PRId64 ")/", peerId]]) {
                                            if (actor.preparedMessage.randomId != 0) {
                                                NSNumber *nMessageId = randomIdToMessageId[@(actor.preparedMessage.randomId)];
                                                if (nMessageId != nil) {
                                                    [skipMessageIds addObject:nMessageId];
                                                }
                                            }
                                        }
                                        
                                        return [SSignal complete];
                                    }] startOn:[SQueue wrapConcurrentNativeQueue:[ActionStageInstance() globalStageDispatchQueue]]];
                                }
                                
                                users = concreteDifference.users;
                                
                                addMessages = ^{
                                    TGLog(@"IOS6STATE diff.apply peer=%lld added=%d updated=%d deleted=%d pts=%d", peerId, (int)messages.count, (int)updatedMessages.count, (int)deletedMessageIds.count, concreteDifference.pts);
                                    [TGDatabaseInstance() addMessagesToChannelAndDispatch:peerId messages:messages deletedMessages:deletedMessageIds holes:nil pts:concreteDifference.pts skipFeedUpdate:false];
                                    
                                    if (updatedMessages.count != 0) {
                                        NSMutableArray *messageUpdates = [[NSMutableArray alloc] init];
                                        for (TGMessage *message in updatedMessages) {
                                            int64_t updatePeerId = message.cid == 0 ? peerId : message.cid;
                                            if (updatePeerId != peerId)
                                                TGLog(@"IOS6STATE diff.edit.peerMismatch peer=%lld msgPeer=%lld mid=%d", peerId, message.cid, message.mid);
                                            TGLog(@"IOS6STATE diff.edit.dbUpdate peer=%lld mid=%d msgPeer=%lld", updatePeerId, message.mid, message.cid);
                                            [messageUpdates addObject:[[TGDatabaseUpdateMessageWithMessage alloc] initWithPeerId:updatePeerId messageId:message.mid message:message dispatchEdited:true]];
                                        }
                                        
                                        [TGDatabaseInstance() transactionUpdateMessages:messageUpdates updateConversationDatas:nil];
                                    }
                                };
                            }
                            
                            NSMutableArray *downloadMessages = [[NSMutableArray alloc] init];
                            
                            NSMutableDictionary *addedMessageIdToMessage = [[NSMutableDictionary alloc] init];
                            for (TGMessage *message in messages) {
                                addedMessageIdToMessage[@(message.mid)] = message;
                            }
                            
                            for (NSInteger i = 0; i < (NSInteger)messages.count; i++)
                            {
                                TGMessage *message = messages[i];
                                if ([skipMessageIds containsObject:@(message.mid)]) {
                                    [messages removeObjectAtIndex:i];
                                    i--;
                                } else {
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
                                                        [downloadMessages addObject:[[TGDownloadMessage alloc] initWithPeerId:conversation.conversationId accessHash:conversation.accessHash messageId:replyAttachment.replyMessageId]];
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            [disposable setDisposable:[[[removeMessagesInProgressSignal then:[TGDownloadMessagesSignal downloadMessages:downloadMessages]] mapToSignal:^SSignal *(NSArray *updatedMessages) {
                                return [TGDatabaseInstance() modify:^id {
                                    for (TGMessage *message in updatedMessages) {
                                        addedMessageIdToMessage[@(message.mid)] = message;
                                    }
                                    
                                    for (TGMessage *message in messages)
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
                                    
                                    [TGUserDataRequestBuilder executeUserDataUpdate:users];
                                    [TGDatabaseInstance() updateChannels:conversations];
                                    
                                    if (addHole) {
                                        addHole();
                                    }
                                    
                                    if (addMessages) {
                                        addMessages();
                                    }

                                    [TGApplyUpdatesActor presentLocalNotificationsForMessageDescriptions:notificationMessageDescriptions];
                                    
                                    if (loadHoles) {
                                        loadHoles();
                                    }
                                    
                                    if (restart) {
                                        recurse();
                                    } else {
                                        [subscriber putNext:@(nextTimeout)];
                                        [subscriber putCompletion];
                                    }
                                    
                                    [TGDatabaseInstance() confirmPeerPoll:[[TGQueuedPeerPoll alloc] initWithPeerId:peerId feedPosition:nil]];
                                    
                                    return nil;
                                }];
                            }] startWithNext:nil]];
                        } synchronous:false];
                    } error:^(__unused id error) {
                    } completed:nil]];
                }];
            });
            
            start();
            
            return disposable;
        }];
    }];
}

+ (void)addChannelUpdates:(int64_t)peerId updates:(NSArray *)updates {
    [[self channelState:peerId] addUpdates:updates];
}

+ (SSignal *)updatedChannel:(int64_t)peerId {
    return [[self channelState:peerId] keepPolling];
}

@end
