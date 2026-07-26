#import "TGApplyUpdatesActor.h"
#import "IOS6NotificationProbe.h"
#import "IOS6FeatureProbe.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGTimer.h"

#import "../submodules/LegacyComponents/LegacyComponents/ActionStage.h"
#import "../submodules/LegacyComponents/LegacyComponents/SGraphObjectNode.h"

#import "TGDatabase.h"
#import "TGTelegraph.h"
#import "TGTelegramNetworking.h"
#import "TGAppDelegate.h"

#import "TGUser+Telegraph.h"
#import "TGMessage+Telegraph.h"
#import "TGConversation+Telegraph.h"
#import "TGUserDataRequestBuilder.h"

#import "TGUser+Telegraph.h"

#import "TGTimelineItem.h"

#import "TGConversationAddMessagesActor.h"
#import "TGApplyStateRequestBuilder.h"

#import "TGUpdateStateRequestBuilder.h"

#import "TGUpdate.h"
#import "TGDatabaseUpdateMessage.h"

#import "TLUpdate$updateChangePts.h"

#import "TGUpdatesWithSeq.h"
#import "TGUpdatesWithPts.h"
#import "TGUpdatesWithQts.h"
#import "TGUpdatesWithDate.h"

#import "TLMessage$modernMessage.h"
#import "TLMessage$modernMessageService.h"

#import "TLUser$modernUser.h"
#import "TLUpdates+TG.h"

#import "TLMessageFwdHeader$messageFwdHeader.h"

#import "TGCurrencyFormatter.h"

#import <set>
#import <map>

@protocol TGSyntheticUpdateWithPts <NSObject>

- (int32_t)pts;
- (int32_t)pts_count;

@end

@protocol TGSyntheticUpdateWithQts <NSObject>

- (int32_t)qts;

@end

@interface TGWrappedUpdate : NSObject

@property (nonatomic, strong, readonly) id update;
@property (nonatomic, readonly) int32_t date;

@end

@implementation TGWrappedUpdate

- (instancetype)initWithUpdate:(id)update date:(int32_t)date
{
    self = [super init];
    if (self != nil)
    {
        _update = update;
        _date = date;
    }
    return self;
}

@end

static inline void maybeProcessUser(TLUser *user, std::map<int, TLUser *> &processedUsers)
{
    if (((TLUser$modernUser *)user).n_id != 0)
        processedUsers[((TLUser$modernUser *)user).n_id] = user;
}

static inline void maybeProcessChat(TLChat *chat, std::map<int, TLChat *> &processedChats)
{
    if (chat.n_id != 0)
        processedChats[chat.n_id] = chat;
}

static int64_t TGIOS6PeerIdFromFolderPeer(TLPeer *peer)
{
    if ([peer isKindOfClass:[TLPeer$peerUser class]])
        return ((TLPeer$peerUser *)peer).user_id;
    if ([peer isKindOfClass:[TLPeer$peerChat class]])
        return TGPeerIdFromGroupId(((TLPeer$peerChat *)peer).chat_id);
    if ([peer isKindOfClass:[TLPeer$peerChannel class]])
        return TGPeerIdFromChannelId(((TLPeer$peerChannel *)peer).channel_id);
    return 0;
}

static NSMutableArray *delayedNotifications()
{
    static NSMutableArray *array = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        array = [[NSMutableArray alloc] init];
    });
    return array;
}

// iOS 6 can stall SpringBoard when a large update burst makes us build many
// local notifications at once.  Limit the expensive notification path before
// TGMessage/user/chat objects and alert text are created.  This does not drop
// Telegram messages; it only suppresses excess local alerts for this burst.
static bool TGIOS6ConsumeLocalNotificationBudget(NSUInteger batchCount)
{
    if ([[UIDevice currentDevice].systemVersion intValue] > 6)
        return true;

    // Keep a few candidates so a muted first message does not hide an eligible
    // message later in the same batch. Presentation itself is aggregated below.
    (void)batchCount;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();

    static CFAbsoluteTime windowStart = 0.0;
    static NSUInteger consumedInWindow = 0;

    if (windowStart == 0.0 || now - windowStart >= 10.0)
    {
        windowStart = now;
        consumedInWindow = 0;
    }

    if (consumedInWindow >= 5)
        return false;

    consumedInWindow++;
    return true;
}

static NSString *TGIOS6AggregateNotificationText(NSUInteger count)
{
    NSString *language = [NSLocale preferredLanguages].count == 0 ? @"en" : [NSLocale preferredLanguages][0];
    if ([language hasPrefix:@"ru"])
        return [NSString stringWithFormat:@"%lu новых сообщений", (unsigned long)count];
    if ([language hasPrefix:@"uk"])
        return [NSString stringWithFormat:@"%lu нових повідомлень", (unsigned long)count];
    if ([language hasPrefix:@"de"])
        return [NSString stringWithFormat:@"%lu neue Nachrichten", (unsigned long)count];
    return [NSString stringWithFormat:@"%lu new messages", (unsigned long)count];
}

static bool TGIOS6ShouldRequestStateUpdateNow()
{
    if ([[UIDevice currentDevice].systemVersion intValue] > 6 ||
        [UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        return true;
    }

    static NSTimeInterval lastBackgroundStateUpdate = 0.0;
    NSTimeInterval now = CFAbsoluteTimeGetCurrent();
    @synchronized([TGApplyUpdatesActor class])
    {
        if (lastBackgroundStateUpdate != 0.0 && now - lastBackgroundStateUpdate < 60.0)
            return false;
        lastBackgroundStateUpdate = now;
    }
    return true;
}

@interface TGApplyUpdatesActor ()

@property (nonatomic, strong) NSMutableArray *updateList;

@property (nonatomic) bool waitingForApplyUpdates;
@property (nonatomic, strong) NSMutableArray *waitingForApplyUpdatesQueue;

@property (nonatomic, strong) TGTimer *timeoutTimer;
@property (nonatomic) NSTimeInterval overallTimeout;

@property (nonatomic) NSMutableSet *notifiedGroups;

@end

@implementation TGApplyUpdatesActor

+ (NSString *)genericPath
{
    return @"/tg/service/tryupdates/@";
}

+ (void)clearState
{
    [TGApplyUpdatesActor clearDelayedNotifications];
}

+ (void)clearDelayedNotifications
{
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        [delayedNotifications() removeAllObjects];
    }];
}

// iOS 6 hands alertBody to SpringBoard as UTF-16.  Never pass malformed
// surrogate pairs, bidi/control characters or an unbounded string across that
// process boundary: a single hostile message can otherwise stall the device UI.
+ (NSString *)safeNotificationText:(NSString *)text
{
    if (![text isKindOfClass:[NSString class]] || text.length == 0)
        return nil;

    const NSUInteger maxLength = 160;
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:MIN(text.length, maxLength)];
    bool previousWasSpace = false;
    bool truncated = false;

    for (NSUInteger i = 0; i < text.length; i++)
    {
        unichar ch = [text characterAtIndex:i];

        if (ch >= 0xd800 && ch <= 0xdbff)
        {
            if (i + 1 >= text.length)
                continue;
            unichar low = [text characterAtIndex:i + 1];
            if (low < 0xdc00 || low > 0xdfff)
                continue;
            if (result.length + 2 > maxLength - 1)
            {
                truncated = true;
                break;
            }
            [result appendFormat:@"%C%C", ch, low];
            i++;
            previousWasSpace = false;
            continue;
        }
        if (ch >= 0xdc00 && ch <= 0xdfff)
            continue;

        bool isWhitespace = ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r';
        bool isControl = ch < 0x20 || (ch >= 0x7f && ch <= 0x9f);
        bool isDirectionalControl = (ch >= 0x200b && ch <= 0x200f) ||
            (ch >= 0x202a && ch <= 0x202e) || (ch >= 0x2060 && ch <= 0x206f);
        bool isInvalid = ch == 0xfffc || ch == 0xfffe || ch == 0xffff || ch == 0xfeff;

        if (isWhitespace)
        {
            if (!previousWasSpace && result.length != 0)
                [result appendString:@" "];
            previousWasSpace = true;
            continue;
        }
        if (isControl || isDirectionalControl || isInvalid)
            continue;
        if (result.length + 1 > maxLength - 1)
        {
            truncated = true;
            break;
        }

        [result appendFormat:@"%C", ch];
        previousWasSpace = false;
    }

    NSString *clean = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (clean.length == 0)
        return nil;
    if (truncated || text.length > maxLength)
        clean = [clean stringByAppendingString:@"\u2026"];
    return clean;
}

+ (void)presentSafeLocalNotification:(UILocalNotification *)notification text:(NSString *)text
{
    if (notification == nil || !TGIOS6BackgroundNotificationsEnabled())
        return;

    NSString *safeText = [self safeNotificationText:text];
    if (safeText.length == 0)
        return;

    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    static CFAbsoluteTime lastPresentationTime = 0.0;
    static CFAbsoluteTime lastSoundTime = 0.0;
    static CFAbsoluteTime aggregateBlockUntil = 0.0;
    bool shouldPresent = false;
    bool isAggregate = [notification.userInfo[@"ios6Aggregate"] boolValue];

    @synchronized(self)
    {
        // No timers and no polling: the first message wins, all messages in the
        // following one-second burst are silently folded into it.
        if (now >= aggregateBlockUntil && (lastPresentationTime == 0.0 || now - lastPresentationTime >= 1.0))
        {
            lastPresentationTime = now;
            if (isAggregate)
                aggregateBlockUntil = now + 10.0;
            shouldPresent = true;

            // Long message storms may last for minutes.  Keep banners useful,
            // but let SpringBoard play at most one sound every three seconds.
            if (notification.soundName.length != 0)
            {
                if (lastSoundTime != 0.0 && now - lastSoundTime < 3.0)
                    notification.soundName = nil;
                else
                    lastSoundTime = now;
            }
        }
    }

    if (!shouldPresent)
        return;

    notification.alertBody = safeText;
    dispatch_async(dispatch_get_main_queue(), ^
    {
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    });
}

+ (void)presentLocalNotificationsForMessageDescriptions:(NSArray *)messageDescriptions
{
    // UILocalNotification remains available through iOS 10.  The iOS 6
    // background transport is separate, but newer systems should still show
    // locally generated notifications while the process is alive in background.
    if (!TGIOS6BackgroundNotificationsEnabled() ||
        [[UIDevice currentDevice].systemVersion intValue] > 10 ||
        [UIApplication sharedApplication].applicationState == UIApplicationStateActive ||
        messageDescriptions.count == 0)
    {
        return;
    }

    [ActionStageInstance() dispatchOnStageQueue:^
    {
        static NSMutableSet *recentNotificationKeys = nil;
        static NSMutableArray *recentNotificationKeyOrder = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            recentNotificationKeys = [[NSMutableSet alloc] init];
            recentNotificationKeyOrder = [[NSMutableArray alloc] init];
        });

        NSMutableArray *acceptedDescriptions = [[NSMutableArray alloc] init];
        NSMutableArray *mids = [[NSMutableArray alloc] init];
        NSMutableSet *midsWithoutSound = [[NSMutableSet alloc] init];
        int32_t maxMid = 0;

        for (id messageDescription in messageDescriptions)
        {
            if (![messageDescription isKindOfClass:[TLMessage class]])
                continue;

            TGMessage *message = [[TGMessage alloc] initWithTelegraphMessageDesc:messageDescription];
            if (message.mid == 0 || message.cid == 0 || message.outgoing) {
                IOS6NotificationProbe(@"NOTIFY_SKIP", @"reason=invalid peer=%lld mid=%d outgoing=%d", message.cid, message.mid, message.outgoing ? 1 : 0);
                continue;
            }

            NSString *key = [[NSString alloc] initWithFormat:@"%lld:%d", message.cid, message.mid];
            if ([recentNotificationKeys containsObject:key]) {
                IOS6NotificationProbe(@"NOTIFY_SKIP", @"reason=duplicate peer=%lld mid=%d", message.cid, message.mid);
                continue;
            }

            [recentNotificationKeys addObject:key];
            [recentNotificationKeyOrder addObject:key];
            while (recentNotificationKeyOrder.count > 256)
            {
                NSString *oldestKey = recentNotificationKeyOrder[0];
                [recentNotificationKeys removeObject:oldestKey];
                [recentNotificationKeyOrder removeObjectAtIndex:0];
            }

            [acceptedDescriptions addObject:messageDescription];
            [mids addObject:@(message.mid)];
            if (message.isSilent)
                [midsWithoutSound addObject:@(message.mid)];
            maxMid = MAX(maxMid, message.mid);
        }

        if (acceptedDescriptions.count != 0)
        {
            [delayedNotifications() addObjectsFromArray:acceptedDescriptions];
            [TGApplyUpdatesActor applyDelayedNotifications:maxMid mids:mids midsWithoutSound:midsWithoutSound maxQts:0 randomIds:nil];
        }
    }];
}

- (id)initWithPath:(NSString *)path
{
    self = [super initWithPath:path];
    if (self != nil)
    {
        _updateList = [[NSMutableArray alloc] init];
        _waitingForApplyUpdatesQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self cancelTimeoutTimer];
}

- (void)prepare:(NSDictionary *)__unused options
{
    bool messagesQueue = false;
    
    if ([self.path isEqualToString:@"/tg/service/tryupdates/(withPts)"])
        messagesQueue = true;
    else if ([self.path isEqualToString:@"/tg/service/tryupdates/(withSeq)"])
        messagesQueue = true;
    else if ([self.path isEqualToString:@"/tg/service/tryupdates/(withQts)"])
        messagesQueue = true;
    else if ([self.path isEqualToString:@"/tg/service/tryupdates/(withDate)"])
        messagesQueue = false;
    else
        NSAssert(false, ([NSString stringWithFormat:@"Invalid actor path %@", self.path]));
    
    if (messagesQueue)
        self.requestQueueName = @"messages";
}

- (void)execute:(NSDictionary *)options
{
    [self dumpUpdates:[options objectForKey:@"updates"]];
    
    [_updateList addObjectsFromArray:[options objectForKey:@"updates"]];
    
    if ([self.path isEqualToString:@"/tg/service/tryupdates/(withPts)"])
        [self checkPtsUpdates];
    else if ([self.path isEqualToString:@"/tg/service/tryupdates/(withSeq)"])
        [self checkSeqUpdates];
    else if ([self.path isEqualToString:@"/tg/service/tryupdates/(withQts)"])
        [self checkQtsUpdates];
    else
    {
        NSArray *sortedDateUpdates = [_updateList sortedArrayUsingComparator:^NSComparisonResult(TGUpdatesWithDate *updates1, TGUpdatesWithDate *updates2)
        {
            return updates1.date < updates2.date ? NSOrderedAscending : NSOrderedDescending;
        }];
        NSMutableArray *users = [[NSMutableArray alloc] init];
        NSMutableArray *chats = [[NSMutableArray alloc] init];
        NSMutableArray *wrappedUpdates = [[NSMutableArray alloc] init];
        
        for (TGUpdatesWithDate *updates in sortedDateUpdates)
        {
            for (id update in updates.updates)
            {
                [wrappedUpdates addObject:[[TGWrappedUpdate alloc] initWithUpdate:update date:updates.date]];
            }
            [users addObjectsFromArray:updates.users];
            [chats addObjectsFromArray:updates.chats];
        }
        if (wrappedUpdates.count != 0)
        {
            [self _tryApplyingUpdates:wrappedUpdates users:users chats:chats optionalFinalSeq:0 optionalFinalDate:0 completion:^(bool)
            {
            }];
        }
        
        [self completeAction];
    }
}

- (void)completeAction
{
    [ActionStageInstance() actionCompleted:self.path result:nil];
}

- (void)dumpUpdates:(NSArray *)updateList
{
    for (id updates in updateList)
    {
        if ([updates isKindOfClass:[TGUpdatesWithPts class]])
        {
            for (id<TGSyntheticUpdateWithPts> update in ((TGUpdatesWithPts *)updates).updates)
                while (false) TGLog(@"enqueued update with pts: %d [+%d]", [update pts], [update pts_count]);
        }
        else if ([updates isKindOfClass:[TGUpdatesWithSeq class]])
        {
            while (false) TGLog(@"enqueued updates with seq: %d..%d", ((TGUpdatesWithSeq *)updates).seqStart, ((TGUpdatesWithSeq *)updates).seqEnd);
        }
        else if ([updates isKindOfClass:[TGUpdatesWithQts class]])
        {
            for (id<TGSyntheticUpdateWithQts> update in ((TGUpdatesWithQts *)updates).updates)
                while (false) TGLog(@"enqueued update with qts: %d", [update qts]);
        }
    }
}

- (void)watcherJoined:(ASHandle *)watcherHandle options:(NSDictionary *)options waitingInActorQueue:(bool)waitingInActorQueue
{
    [self dumpUpdates:[options objectForKey:@"updates"]];
    
    if (_waitingForApplyUpdates)
        [_waitingForApplyUpdatesQueue addObjectsFromArray:[options objectForKey:@"updates"]];
    else
        [_updateList addObjectsFromArray:[options objectForKey:@"updates"]];
    
    if ([self.path isEqualToString:@"/tg/service/tryupdates/(withPts)"])
    {
        if (!waitingInActorQueue && !_waitingForApplyUpdates)
            [self checkPtsUpdates];
    }
    else if ([self.path isEqualToString:@"/tg/service/tryupdates/(withSeq)"])
    {
        if (!waitingInActorQueue && !_waitingForApplyUpdates)
            [self checkSeqUpdates];
    }
    else if ([self.path isEqualToString:@"/tg/service/tryupdates/(withQts)"])
    {
        if (!waitingInActorQueue && !_waitingForApplyUpdates)
            [self checkQtsUpdates];
    }
    else
    {
        [_updateList removeAllObjects];
        
        NSArray *sortedDateUpdates = [_updateList sortedArrayUsingComparator:^NSComparisonResult(TGUpdatesWithDate *updates1, TGUpdatesWithDate *updates2)
        {
            return updates1.date < updates2.date ? NSOrderedAscending : NSOrderedDescending;
        }];
        NSMutableArray *users = [[NSMutableArray alloc] init];
        NSMutableArray *chats = [[NSMutableArray alloc] init];
        NSMutableArray *wrappedUpdates = [[NSMutableArray alloc] init];
        
        for (TGUpdatesWithDate *updates in sortedDateUpdates)
        {
            for (id update in updates.updates)
            {
                [wrappedUpdates addObject:[[TGWrappedUpdate alloc] initWithUpdate:update date:updates.date]];
            }
            [users addObjectsFromArray:updates.users];
            [chats addObjectsFromArray:updates.chats];
        }
        if (wrappedUpdates.count != 0)
        {
            [self _tryApplyingUpdates:wrappedUpdates users:users chats:chats optionalFinalSeq:0 optionalFinalDate:((TGWrappedUpdate *)wrappedUpdates.lastObject).date completion:^(bool)
            {
            }];
        }
    }
    
    [super watcherJoined:watcherHandle options:options waitingInActorQueue:waitingInActorQueue];
}

- (void)cancelTimeoutTimer
{
    if (_timeoutTimer != nil)
    {
        [_timeoutTimer invalidate];
        _timeoutTimer = nil;
    }
}

- (void)startTimeoutTimer
{
    _overallTimeout += [_timeoutTimer remainingTime];
    
    [self cancelTimeoutTimer];
    
    __weak TGApplyUpdatesActor *weakSelf = self;
    NSTimeInterval timeout = MAX(0.0, MIN(2.0, 5.0 - _overallTimeout));
    _timeoutTimer = [[TGTimer alloc] initWithTimeout:timeout repeat:false completion:^
    {
        __strong TGApplyUpdatesActor *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            strongSelf->_timeoutTimer = nil;
            while (false) TGLog(@"update timeout timer fired at %f", timeout);
            [strongSelf timeoutReached];
        }
    } queue:[ActionStageInstance() globalStageDispatchQueue]];
    [_timeoutTimer start];
}

- (void)timeoutReached
{
    if ([self.path isEqualToString:@"/tg/service/tryupdates/(withPts)"])
        [self _failPts];
    else if ([self.path isEqualToString:@"/tg/service/tryupdates/(withSeq)"])
        [self _failSeq];
    else if ([self.path isEqualToString:@"/tg/service/tryupdates/(withQts)"])
        [self _failQts];
}

- (void)checkPtsUpdates
{
    if (_updateList.count == 0)
    {
        [self completeAction];
    }
    else
    {
        NSMutableArray *ptsUpdates = [[NSMutableArray alloc] init];
        for (TGUpdatesWithPts *update in _updateList)
        {
            [ptsUpdates addObjectsFromArray:update.updates];
        }
        
        [ptsUpdates sortUsingComparator:^NSComparisonResult(id<TGSyntheticUpdateWithPts> update1, id<TGSyntheticUpdateWithPts> update2)
        {
            if ([update1 pts] == [update2 pts])
                return [update1 pts_count] > [update2 pts_count] ? NSOrderedAscending : NSOrderedDescending;
            return [update1 pts] < [update2 pts] ? NSOrderedAscending : NSOrderedDescending;
        }];
        
        int32_t databasePts = [[TGDatabase instance] databaseState].pts;
        int32_t currentPts = databasePts;
        
        NSMutableArray *inOrderUpdates = [[NSMutableArray alloc] init];
        NSMutableArray *expiredUpdates = [[NSMutableArray alloc] init];
        
        for (id<TGSyntheticUpdateWithPts> update in ptsUpdates)
        {
            if ([update pts] <= databasePts)
                [expiredUpdates addObject:update];
            else
            {
                if (currentPts + [update pts_count] == [update pts])
                {
                    [inOrderUpdates addObject:update];
                    
                    currentPts = [update pts];
                }
                else
                {
                    TGLog(@"***** Missing updates: %d + %d != %d", (int)currentPts, (int)[update pts_count], (int)[update pts]);
                    [self startTimeoutTimer];
                    break;
                }
            }
        }
        
        if (expiredUpdates.count != 0)
        {
            NSMutableArray *affectedGroups = [[NSMutableArray alloc] init];
            
            for (TGUpdatesWithPts *updates in _updateList)
            {
                for (id update in expiredUpdates)
                {
                    if ([updates.updates containsObject:update])
                    {
                        if (![affectedGroups containsObject:updates])
                            [affectedGroups addObject:updates];
                    }
                }
            }
            
            for (TGUpdatesWithPts *updates in affectedGroups)
            {
                NSMutableArray *filteredUpdates = [[NSMutableArray alloc] initWithArray:updates.updates];
                for (id update in expiredUpdates)
                {
                    [filteredUpdates removeObject:update];
                }
                
                if (filteredUpdates.count == 0)
                    [_updateList removeObject:updates];
            }
        }
        
        if (inOrderUpdates.count != 0)
        {
            NSMutableArray *affectedGroups = [[NSMutableArray alloc] init];
            
            for (TGUpdatesWithPts *updates in _updateList)
            {
                for (id update in inOrderUpdates)
                {
                    if ([updates.updates containsObject:update])
                    {
                        if (![affectedGroups containsObject:updates])
                            [affectedGroups addObject:updates];
                    }
                }
            }
            
            NSMutableArray *users = [[NSMutableArray alloc] init];
            NSMutableArray *chats = [[NSMutableArray alloc] init];
            for (TGUpdatesWithPts *updates in affectedGroups)
            {
                [users addObjectsFromArray:updates.users];
                [chats addObjectsFromArray:updates.chats];
                
                NSMutableArray *filteredUpdates = [[NSMutableArray alloc] initWithArray:updates.updates];
                for (id update in inOrderUpdates)
                {
                    [filteredUpdates removeObject:update];
                }
                
                if (filteredUpdates.count == 0)
                    [_updateList removeObject:updates];
            }
            
            NSMutableArray *wrappedUpdates = [[NSMutableArray alloc] init];
            for (id update in inOrderUpdates)
            {
                [wrappedUpdates addObject:[[TGWrappedUpdate alloc] initWithUpdate:update date:0]];
            }
            
            [self _tryApplyingUpdates:wrappedUpdates users:users chats:chats optionalFinalSeq:0 optionalFinalDate:0 completion:^(bool success)
            {
                if (!success)
                    [self _failPts];
                else
                    [self checkPtsUpdates];
            }];
        }
        else
        {
            if (_updateList.count == 0)
                [self completeAction];
        }
    }
}

- (void)checkQtsUpdates
{
    if (_updateList.count == 0)
    {
        [self completeAction];
    }
    else
    {
        NSMutableArray *qtsUpdates = [[NSMutableArray alloc] init];
        for (TGUpdatesWithQts *update in _updateList)
        {
            [qtsUpdates addObjectsFromArray:update.updates];
        }
        
        [qtsUpdates sortUsingComparator:^NSComparisonResult(id<TGSyntheticUpdateWithQts> update1, id<TGSyntheticUpdateWithQts> update2)
        {
            return [update1 qts] < [update2 qts] ? NSOrderedAscending : NSOrderedDescending;
        }];
        
        int32_t databaseQts = [[TGDatabase instance] databaseState].qts;
        int32_t currentQts = databaseQts;
        
        NSMutableArray *inOrderUpdates = [[NSMutableArray alloc] init];
        NSMutableArray *expiredUpdates = [[NSMutableArray alloc] init];
        
        for (id<TGSyntheticUpdateWithQts> update in qtsUpdates)
        {
            if ([update qts] <= databaseQts)
                [expiredUpdates addObject:update];
            else
            {
                if (currentQts + 1 == [update qts])
                {
                    [inOrderUpdates addObject:update];
                    
                    currentQts = [update qts];
                }
                else
                {
                    TGLog(@"***** Missing updates: qts %d + 1 != %d", (int)currentQts, (int)[update qts]);
                    [self startTimeoutTimer];
                    break;
                }
            }
        }
        
        if (expiredUpdates.count != 0)
        {
            NSMutableArray *affectedGroups = [[NSMutableArray alloc] init];
            
            for (TGUpdatesWithQts *updates in _updateList)
            {
                for (id update in expiredUpdates)
                {
                    if ([updates.updates containsObject:update])
                    {
                        if (![affectedGroups containsObject:updates])
                            [affectedGroups addObject:updates];
                    }
                }
            }
            
            for (TGUpdatesWithQts *updates in affectedGroups)
            {
                NSMutableArray *filteredUpdates = [[NSMutableArray alloc] initWithArray:updates.updates];
                for (id update in expiredUpdates)
                {
                    [filteredUpdates removeObject:update];
                }
                
                if (filteredUpdates.count == 0)
                    [_updateList removeObject:updates];
            }
        }
        
        if (inOrderUpdates.count != 0)
        {
            NSMutableArray *affectedGroups = [[NSMutableArray alloc] init];
            
            for (TGUpdatesWithQts *updates in _updateList)
            {
                for (id update in inOrderUpdates)
                {
                    if ([updates.updates containsObject:update])
                    {
                        if (![affectedGroups containsObject:updates])
                            [affectedGroups addObject:updates];
                    }
                }
            }
            
            NSMutableArray *users = [[NSMutableArray alloc] init];
            NSMutableArray *chats = [[NSMutableArray alloc] init];
            for (TGUpdatesWithQts *updates in affectedGroups)
            {
                [users addObjectsFromArray:updates.users];
                [chats addObjectsFromArray:updates.chats];
                
                NSMutableArray *filteredUpdates = [[NSMutableArray alloc] initWithArray:updates.updates];
                for (id update in inOrderUpdates)
                {
                    [filteredUpdates removeObject:update];
                }
                
                if (filteredUpdates.count == 0)
                    [_updateList removeObject:updates];
            }
            
            NSMutableArray *wrappedUpdates = [[NSMutableArray alloc] init];
            for (id update in inOrderUpdates)
            {
                [wrappedUpdates addObject:[[TGWrappedUpdate alloc] initWithUpdate:update date:0]];
            }
            
            [self _tryApplyingUpdates:wrappedUpdates users:users chats:chats optionalFinalSeq:0 optionalFinalDate:0 completion:^(bool success)
            {
                if (!success)
                    [self _failQts];
                else
                    [self checkQtsUpdates];
            }];
        }
        else
        {
            if (_updateList.count == 0)
                [self completeAction];
        }
    }
}

- (void)checkSeqUpdates
{
    if (_updateList.count == 0)
    {
        [self completeAction];
    }
    else
    {
        NSArray *seqUpdates = [_updateList sortedArrayUsingComparator:^NSComparisonResult(TGUpdatesWithSeq *updates1, TGUpdatesWithSeq *updates2)
        {
            return updates1.seqEnd < updates2.seqEnd ? NSOrderedAscending : NSOrderedDescending;
        }];
        
        int32_t currentSeq = [[TGDatabase instance] databaseState].seq;
        
        NSMutableArray *inOrderUpdates = [[NSMutableArray alloc] init];
        for (TGUpdatesWithSeq *updates in seqUpdates)
        {
            if (updates.seqStart == currentSeq + 1)
            {
                [inOrderUpdates addObject:updates];
                currentSeq = updates.seqEnd;
            }
            else
            {
                TGLog(@"***** Missing updates: seq %d", (int)currentSeq + 1);
                [self startTimeoutTimer];
            }
        }
        
        if (inOrderUpdates.count != 0)
        {
            NSMutableArray *wrappedUpdates = [[NSMutableArray alloc] init];
            NSMutableArray *users = [[NSMutableArray alloc] init];
            NSMutableArray *chats = [[NSMutableArray alloc] init];
            
            for (TGUpdatesWithSeq *updates in inOrderUpdates)
            {
                for (id update in updates.updates)
                {
                    [wrappedUpdates addObject:[[TGWrappedUpdate alloc] initWithUpdate:update date:updates.date]];
                }
                [users addObjectsFromArray:updates.users];
                [chats addObjectsFromArray:updates.chats];
                
                [_updateList removeObject:updates];
            }
            
            [self _tryApplyingUpdates:wrappedUpdates users:users chats:chats optionalFinalSeq:((TGUpdatesWithSeq *)inOrderUpdates.lastObject).seqEnd optionalFinalDate:((TGWrappedUpdate *)wrappedUpdates.lastObject).date completion:^(bool success)
            {
                if (!success)
                    [self _failSeq];
                else
                    [self checkSeqUpdates];
            }];
        }
        else if (_updateList.count == 0)
        {
            [self completeAction];
        }
    }
}

- (void)_failPts
{
    TGLog(@"***** Inconsistent state by (pts, pts_count)! Synchronization required.");
    
    [self cancelTimeoutTimer];
    
    if (TGIOS6ShouldRequestStateUpdateNow())
        [TGTelegraphInstance stateUpdateRequired];
    
    [self completeAction];
}

- (void)_failSeq
{
    TGLog(@"***** Inconsistent state by seq! Synchronization required.");
    
    [self cancelTimeoutTimer];
    
    if (TGIOS6ShouldRequestStateUpdateNow())
        [TGTelegraphInstance stateUpdateRequired];
    
    [self completeAction];
}

- (void)_failQts
{
    TGLog(@"***** Inconsistent state by qts! Synchronization required.");
    
    [self cancelTimeoutTimer];
    
    if (TGIOS6ShouldRequestStateUpdateNow())
        [TGTelegraphInstance stateUpdateRequired];
    
    [self completeAction];
}

template<typename T>
static int64_t extractMessageConversationId(T concreteMessage, int &outFromUid)
{
    int64_t fromUid = concreteMessage.from_id;
    bool outgoing = concreteMessage.flags & 2;
    
    if (!outgoing)
        outFromUid = (int)fromUid;
    
    if ([concreteMessage.to_id isKindOfClass:[TLPeer$peerUser class]])
    {
        TLPeer$peerUser *toUser = (TLPeer$peerUser *)concreteMessage.to_id;
        int64_t toUid = toUser.user_id;
        if (toUid == fromUid && !outgoing)
            outgoing = true;
        return outgoing ? toUid : fromUid;
    }
    else if ([concreteMessage.to_id isKindOfClass:[TLPeer$peerChat class]])
    {
        TLPeer$peerChat *toChat = (TLPeer$peerChat *)concreteMessage.to_id;
        int64_t toUid = -toChat.chat_id;
        return toUid;
    }
    else if ([concreteMessage.to_id isKindOfClass:[TLPeer$peerChannel class]])
    {
        TLPeer$peerChannel *toChannel = (TLPeer$peerChannel *)concreteMessage.to_id;
        int64_t toUid = TGPeerIdFromChannelId(toChannel.channel_id);
        return toUid;
    }
    
    return 0;
}

- (bool)_tryApplyingUpdates:(NSArray *)updates users:(NSArray *)users chats:(NSArray *)chats optionalFinalSeq:(int32_t)optionalFinalSeq optionalFinalDate:(int32_t)optionalFinalDate completion:(void (^)(bool))completion
{
    static Class updateNewMessageClass = nil;
    static Class updateNewEncryptedMessageClass = nil;
    static Class updateDeleteMessagesClass = nil;
    static Class updateRestoreMessagesClass = nil;
    static Class updateChangePtsClass = nil;
    static Class updateUserTypingClass = nil;
    static Class updateChatUserTypingClass = nil;
    static Class updateChatParticipantsClass = nil;
    static Class updateChatParticipantAddClass = nil;
    static Class updateChatParticipantDeleteClass = nil;
    static Class updateContactLocatedClass = nil;
    
    static Class messageClass = nil;
    static Class messageServiceClass = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        updateNewMessageClass = [TLUpdate$updateNewMessage class];
        updateNewEncryptedMessageClass = [TLUpdate$updateNewEncryptedMessage class];
        updateDeleteMessagesClass = [TLUpdate$updateDeleteMessages class];
        updateRestoreMessagesClass = [TLUpdate$updateRestoreMessages class];
        updateChangePtsClass = [TLUpdate$updateChangePts class];
        updateUserTypingClass = [TLUpdate$updateUserTyping class];
        updateChatUserTypingClass = [TLUpdate$updateChatUserTyping class];
        updateChatParticipantsClass = [TLUpdate$updateChatParticipants class];
        updateChatParticipantAddClass = [TLUpdate$updateChatParticipantAdd class];
        updateChatParticipantDeleteClass = [TLUpdate$updateChatParticipantDelete class];
        updateContactLocatedClass = [TLUpdate$updateContactLocated class];
        
        messageClass = [TLMessage$modernMessage class];
        messageServiceClass = [TLMessage$modernMessageService class];
    });
    
    int32_t statePts = 0;
    int32_t stateQts = 0;
    
    TGDatabaseState databaseState = [[TGDatabase instance] databaseState];
    
    for (TGWrappedUpdate *update in updates)
    {
        if ([update.update hasPts])
            statePts = MAX(statePts, [(id<TGSyntheticUpdateWithPts>)update.update pts]);
        if ([update.update respondsToSelector:@selector(qts)])
            stateQts = MAX(stateQts, [(id<TGSyntheticUpdateWithQts>)update.update qts]);
    }
    
    std::map<int, TLUser *> processedUsers;
    std::map<int, TLChat *> processedChats;
    
    NSMutableArray *updatesWithDates = [[NSMutableArray alloc] init];
    
    std::set<int> knownUsers;
    std::set<int64_t> knownChats;
    
    NSMutableArray *addedMessages = [[NSMutableArray alloc] init];
    NSMutableArray *messagesForLocalNotification = [[NSMutableArray alloc] init];
    
    NSMutableArray *allUpdates = [[NSMutableArray alloc] init];
    NSMutableArray *reactionMessageUpdates = [[NSMutableArray alloc] init];
    NSMutableSet *updatedArchivePeerIds = nil;
    bool archivePeerIdsChanged = false;
    
    int currentTime = (int)[[TGTelegramNetworking instance] globalTime];
    
    bool failedProcessing = false;
    bool updatesTooLong = false;
    
    for (TLUser *userDesc in users)
    {
        maybeProcessUser(userDesc, processedUsers);
    }
    
    for (TLChat *chatDesc in chats)
    {
        maybeProcessChat(chatDesc, processedChats);
    }
    
    std::map<int64_t, int32_t> maxInboxReadMessageIdByPeerId;
    std::map<int64_t, int32_t> maxOutboxReadMessageIdByPeerId;

    for (TGWrappedUpdate *wrappedUpdate in updates)
    {
        if ([wrappedUpdate.update isKindOfClass:[TLUpdate$updateReadHistoryInbox class]])
        {
            TLUpdate$updateReadHistoryInbox *concreteUpdate = wrappedUpdate.update;
            
            int64_t peerId = 0;
            if ([concreteUpdate.peer isKindOfClass:[TLPeer$peerUser class]])
                peerId = ((TLPeer$peerUser *)concreteUpdate.peer).user_id;
            else if ([concreteUpdate.peer isKindOfClass:[TLPeer$peerChat class]])
                peerId = -((TLPeer$peerChat *)concreteUpdate.peer).chat_id;
            else if ([concreteUpdate.peer isKindOfClass:[TLPeer$peerChannel class]])
                peerId = TGPeerIdFromChannelId(((TLPeer$peerChannel *)concreteUpdate.peer).channel_id);
            
            auto it = maxInboxReadMessageIdByPeerId.find(peerId);
            if (it == maxInboxReadMessageIdByPeerId.end())
                maxInboxReadMessageIdByPeerId[peerId] = concreteUpdate.max_id;
            else
                maxInboxReadMessageIdByPeerId[peerId] = MAX(it->second, concreteUpdate.max_id);
        }
        else if ([wrappedUpdate.update isKindOfClass:[TLUpdate$updateReadHistoryOutbox class]])
        {
            TLUpdate$updateReadHistoryOutbox *concreteUpdate = wrappedUpdate.update;
            
            int64_t peerId = 0;
            if ([concreteUpdate.peer isKindOfClass:[TLPeer$peerUser class]])
                peerId = ((TLPeer$peerUser *)concreteUpdate.peer).user_id;
            else if ([concreteUpdate.peer isKindOfClass:[TLPeer$peerChat class]])
                peerId = -((TLPeer$peerChat *)concreteUpdate.peer).chat_id;
            else if ([concreteUpdate.peer isKindOfClass:[TLPeer$peerChannel class]])
                peerId = TGPeerIdFromChannelId(((TLPeer$peerChannel *)concreteUpdate.peer).channel_id);
            
            auto it = maxOutboxReadMessageIdByPeerId.find(peerId);
            if (it == maxOutboxReadMessageIdByPeerId.end())
                maxOutboxReadMessageIdByPeerId[peerId] = concreteUpdate.max_id;
            else
                maxOutboxReadMessageIdByPeerId[peerId] = MAX(it->second, concreteUpdate.max_id);
        }
    }
    
    for (TGWrappedUpdate *wrappedUpdate in updates)
    {
        id update = wrappedUpdate.update;
        int32_t date = wrappedUpdate.date;
        
        if ([update isKindOfClass:[TLUpdate$updateMessageReactionsCodex class]])
        {
            TLUpdate$updateMessageReactionsCodex *reactionUpdate = (TLUpdate$updateMessageReactionsCodex *)update;
            int64_t peerId = TGIOS6PeerIdFromFolderPeer(reactionUpdate.peer);
            if (peerId != 0 && reactionUpdate.msg_id != 0)
            {
                TGMessage *storedMessage = [TGDatabaseInstance() loadMessageWithMid:reactionUpdate.msg_id peerId:peerId];
                if (storedMessage != nil)
                {
                    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:storedMessage.contentProperties ?: @{}];
                    if (reactionUpdate.reactionSummary.length != 0)
                        properties[@"ios6ReactionSummary"] = [[TGMessageReactionSummaryContentProperty alloc] initWithSummary:reactionUpdate.reactionSummary chosenReaction:reactionUpdate.chosenReaction];
                    else
                        [properties removeObjectForKey:@"ios6ReactionSummary"];
                    storedMessage.contentProperties = properties;
                    [reactionMessageUpdates addObject:[[TGDatabaseUpdateMessageWithMessage alloc] initWithPeerId:peerId messageId:reactionUpdate.msg_id message:storedMessage dispatchEdited:true]];
                    IOS6FeatureProbe(@"REACTION global.apply peer=%lld mid=%d summary=%@ queued=1", peerId, reactionUpdate.msg_id, reactionUpdate.reactionSummary);
                }
                else
                    IOS6FeatureProbe(@"REACTION global.apply peer=%lld mid=%d summary=%@ missingMessage=1", peerId, reactionUpdate.msg_id, reactionUpdate.reactionSummary);
            }
        }
        else if ([update isKindOfClass:[TLUpdate$updateFolderPeers class]])
        {
            if (updatedArchivePeerIds == nil)
            {
                NSData *data = [TGDatabaseInstance() customProperty:@"ios6ArchivePeerIds"];
                NSArray *storedPeerIds = nil;
                if (data.length != 0)
                {
                    @try
                    {
                        storedPeerIds = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                    }
                    @catch (__unused NSException *exception)
                    {
                    }
                }
                updatedArchivePeerIds = [[NSMutableSet alloc] initWithArray:[storedPeerIds isKindOfClass:[NSArray class]] ? storedPeerIds : @[]];
            }
            
            TLUpdate$updateFolderPeers *folderUpdate = (TLUpdate$updateFolderPeers *)update;
            for (TLCodexFolderPeer *folderPeer in folderUpdate.folder_peers)
            {
                if (![folderPeer isKindOfClass:[TLCodexFolderPeer class]])
                    continue;
                int64_t peerId = TGIOS6PeerIdFromFolderPeer(folderPeer.peer);
                if (peerId == 0)
                    continue;
                NSNumber *nPeerId = @(peerId);
                bool archived = folderPeer.folder_id == 1;
                if (archived)
                    [updatedArchivePeerIds addObject:nPeerId];
                else
                    [updatedArchivePeerIds removeObject:nPeerId];
                [TGDatabaseInstance() setConversationArchived:peerId archived:archived];
                archivePeerIdsChanged = true;
            }
        }
        else if ([update isKindOfClass:updateNewMessageClass])
        {
            TLUpdate$updateNewMessage *newMessage = (TLUpdate$updateNewMessage *)update;
            
            TLMessage *message = newMessage.message;
            
            if (([message isKindOfClass:[TLMessage$modernMessage class]] || [message isKindOfClass:[TLMessage$modernMessageService class]]) && !(((TLMessage$modernMessage *)message).flags & 2))
            {
                TGMessage *parsedMessage = [[TGMessage alloc] initWithTelegraphMessageDesc:message];
                if (!parsedMessage.outgoing && !parsedMessage.isSilent)
                {
                    auto maxIt = maxInboxReadMessageIdByPeerId.find(parsedMessage.cid);
                    if (maxIt == maxInboxReadMessageIdByPeerId.end()) {
                        TGConversation *conversation = [TGDatabaseInstance() loadConversationWithId:parsedMessage.cid];
                        maxInboxReadMessageIdByPeerId[parsedMessage.cid] = conversation.maxReadMessageId;
                    }
                    
                    if (!(maxIt != maxInboxReadMessageIdByPeerId.end() && parsedMessage.mid <= maxIt->second))
                        [messagesForLocalNotification addObject:newMessage.message];
                }
                
                TGLog(@"message date: %d", (int32_t)parsedMessage.date);
            }
            else
                TGLog(@"Message %d does not match for local notification", (int)message.n_id);
            
            int64_t conversationId = 0;
            int fromUid = 0;
            
            if ([message isKindOfClass:messageClass])
                conversationId = extractMessageConversationId((TLMessage$message *)message, fromUid);
            else if ([message isKindOfClass:messageServiceClass])
                conversationId = extractMessageConversationId((TLMessage$modernMessageService *)message, fromUid);
            
            if (conversationId != 0)
            {
                if (conversationId < 0)
                {
                    if (knownChats.find(conversationId) == knownChats.end() && processedChats.find(-(int)conversationId) == processedChats.end())
                    {
                        bool contains = [TGDatabaseInstance() containsConversationWithId:conversationId];
                        if (contains)
                            knownChats.insert(conversationId);
                        else
                        {
                            TGLog(@"Unknown chat %" PRId64 "", conversationId);
                            failedProcessing = true;
                        }
                    }
                }
                else
                {
                    if (knownUsers.find((int)conversationId) == knownUsers.end() && processedUsers.find((int)conversationId) == processedUsers.end())
                    {
                        bool contains = [TGDatabaseInstance() loadUser:(int)conversationId];
                        if (contains)
                            knownUsers.insert((int)conversationId);
                        else
                        {
                            TGLog(@"Unknown user %" PRId64 "", conversationId);
                            failedProcessing = true;
                        }
                    }
                }
            }
            
            if (!failedProcessing && fromUid != 0 && fromUid != conversationId)
            {
                if (knownUsers.find(fromUid) == knownUsers.end() && processedUsers.find(fromUid) == processedUsers.end())
                {
                    bool contains = [TGDatabaseInstance() loadUser:fromUid];
                    if (contains)
                        knownUsers.insert(fromUid);
                    else
                    {
                        TGLog(@"Unknown user %" PRId32 "", fromUid);
                        failedProcessing = true;
                    }
                }
            }
            
            if (!failedProcessing)
            {
                if ([message isKindOfClass:[TLMessage$modernMessage class]])
                {
                    TLMessageFwdHeader$messageFwdHeader *fwd_header = (TLMessageFwdHeader$messageFwdHeader *)((TLMessage$modernMessage *)message).fwd_from;
                    if (fwd_header != nil) {
                        if (fwd_header.from_id != 0) {
                            if (knownUsers.find(fwd_header.from_id) == knownUsers.end() && processedUsers.find(fwd_header.from_id) == processedUsers.end())
                            {
                                bool contains = [TGDatabaseInstance() loadUser:fwd_header.from_id];
                                if (contains)
                                    knownUsers.insert(fwd_header.from_id);
                                else
                                {
                                    TGLog(@"Unknown user %" PRId32 "", fwd_header.from_id);
                                    failedProcessing = true;
                                }
                            }
                        }
                        if (fwd_header.channel_id != 0) {
                            int64_t peerId = TGPeerIdFromChannelId(fwd_header.channel_id);
                            if (peerId != 0) {
                                if (knownChats.find(peerId) == knownChats.end() && processedChats.find(TGChannelIdFromPeerId(peerId)) == processedChats.end()) {
                                    bool contains = [TGDatabaseInstance() _channelExists:peerId];
                                    if (contains)
                                        knownChats.insert(TGChannelIdFromPeerId(peerId));
                                    else
                                    {
                                        TGLog(@"Unknown channel %" PRId64 "", peerId);
                                        failedProcessing = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            if (failedProcessing)
                break;
            
            [addedMessages addObject:message];
        }
        else if ([update isKindOfClass:updateUserTypingClass])
        {
            if (date > currentTime - 20)
                [allUpdates addObject:update];
        }
        else if ([update isKindOfClass:updateChatUserTypingClass])
        {
            if (date > currentTime - 20)
                [allUpdates addObject:update];
        }
        else if ([update isKindOfClass:[TLUpdate$updateEncryptedChatTyping class]])
        {
            if (date > currentTime - 20)
                [allUpdates addObject:update];
        }
        else if ([update isKindOfClass:updateContactLocatedClass])
        {   
            if (date > currentTime - 5 * 60)
                [allUpdates addObject:update];
        }
        else if ([update isKindOfClass:updateChatParticipantsClass])
        {
            TLUpdate$updateChatParticipants *updateChatParticipants = (TLUpdate$updateChatParticipants *)update;
            
            int64_t conversationId = -updateChatParticipants.participants.chat_id;
            
            if (conversationId < 0)
            {
                if (knownChats.find(conversationId) == knownChats.end() && processedChats.find(-(int)conversationId) == processedChats.end())
                {
                    bool contains = [TGDatabaseInstance() containsConversationWithId:conversationId];
                    if (contains)
                        knownChats.insert(conversationId);
                    else
                        failedProcessing = true;
                }
            }
            
            [allUpdates addObject:update];
        }
        else if ([update isKindOfClass:updateChatParticipantAddClass] || [update isKindOfClass:updateChatParticipantDeleteClass])
        {
            int64_t conversationId = 0;
            int32_t userId = 0;
            if ([update isKindOfClass:updateChatParticipantAddClass])
            {
                conversationId = -((TLUpdate$updateChatParticipantAdd *)update).chat_id;
                userId = ((TLUpdate$updateChatParticipantAdd *)update).user_id;
            }
            if ([update isKindOfClass:updateChatParticipantDeleteClass])
            {
                conversationId = -((TLUpdate$updateChatParticipantDelete *)update).chat_id;
                userId = ((TLUpdate$updateChatParticipantDelete *)update).user_id;
            }
            
            if (conversationId < 0)
            {
                if (knownChats.find(conversationId) == knownChats.end() && processedChats.find(-(int)conversationId) == processedChats.end())
                {
                    bool contains = [TGDatabaseInstance() containsConversationWithId:conversationId];
                    if (contains)
                        knownChats.insert(conversationId);
                    else
                        failedProcessing = true;
                }
            }
            
            if (userId != 0)
            {
                if (knownUsers.find(userId) == knownUsers.end() && processedUsers.find(userId) == processedUsers.end())
                {
                    bool contains = [TGDatabaseInstance() loadUser:userId];
                    if (contains)
                        knownUsers.insert(userId);
                    else
                    {
                        TGLog(@"Unknown user %" PRId32 "", userId);
                        failedProcessing = true;
                    }
                }
            }
            
            [updatesWithDates addObject:@[update, @(date)]];
            [allUpdates addObject:update];
        }
        else if ([update isKindOfClass:[TLUpdate$updateEncryption class]])
        {
            TLUpdate$updateEncryption *updateEncryption = (TLUpdate$updateEncryption *)update;
            
            TGConversation *conversation = [[TGConversation alloc] initWithTelegraphEncryptedChatDesc:updateEncryption.chat];
            
            if (conversation.conversationId != 0)
            {
                if (conversation.chatParticipants.chatParticipantUids.count != 0)
                {
                    int userId = [conversation.chatParticipants.chatParticipantUids[0] intValue];
                    if ([TGDatabaseInstance() loadUser:userId] != nil)
                        [allUpdates addObject:update];
                    else
                        failedProcessing = true;
                }
                else
                    failedProcessing = true;
            }
            else
                failedProcessing = true;
        }
        else if ([update isKindOfClass:updateNewEncryptedMessageClass])
        {
            TLUpdate$updateNewEncryptedMessage *updateNewEncryptedMessage = (TLUpdate$updateNewEncryptedMessage *)update;
            
            if (![updateNewEncryptedMessage.message isKindOfClass:[TLEncryptedMessage$encryptedMessageService class]] && updateNewEncryptedMessage.message != nil && stateQts != 0)
            {
                [messagesForLocalNotification addObject:@{@"message": updateNewEncryptedMessage.message, @"qts": @(stateQts)}];
            }
            
            [allUpdates addObject:update];
        }
        else if ([update isKindOfClass:[TLUpdates$updatesTooLong class]])
        {
            failedProcessing = true;
            updatesTooLong = true;
            
            break;
        }
        else
        {
            [allUpdates addObject:update];
        }
    }

    
    if (archivePeerIdsChanged)
    {
        NSArray *archivePeerIds = [updatedArchivePeerIds allObjects];
        [TGDatabaseInstance() setCustomProperty:@"ios6ArchivePeerIds" value:[NSKeyedArchiver archivedDataWithRootObject:archivePeerIds]];
        TGDispatchOnMainThread(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TGIOS6ArchivePeerIdsUpdated" object:nil];
        });
    }
    
    if (!failedProcessing)
    {
        NSMutableArray *usersToProcess = [[NSMutableArray alloc] initWithCapacity:processedUsers.size()];
        
        for (std::map<int, TLUser *>::iterator it = processedUsers.begin(); it != processedUsers.end(); it++)
        {
            [usersToProcess addObject:it->second];
        }
        
        NSMutableArray *chatsToProcess = [[NSMutableArray alloc] initWithCapacity:processedChats.size()];
        
        for (std::map<int, TLChat *>::iterator it = processedChats.begin(); it != processedChats.end(); it++)
        {
            [chatsToProcess addObject:it->second];
        }
        
        _waitingForApplyUpdates = true;
        [TGUpdateStateRequestBuilder applyUpdates:addedMessages otherUpdates:allUpdates usersDesc:usersToProcess chatsDesc:chatsToProcess chatParticipantsDesc:nil updatesWithDates:updatesWithDates addedEncryptedActionsByPeerId:nil addedEncryptedUnparsedActionsByPeerId:nil completion:^(__unused bool applied)
        {
            if (reactionMessageUpdates.count != 0)
            {
                IOS6FeatureProbe(@"REACTION global.commit count=%d", (int)reactionMessageUpdates.count);
                [TGDatabaseInstance() transactionUpdateMessages:reactionMessageUpdates updateConversationDatas:nil];
            }
            _waitingForApplyUpdates = false;
            [_updateList addObjectsFromArray:_waitingForApplyUpdatesQueue];
            [_waitingForApplyUpdatesQueue removeAllObjects];
            
            [delayedNotifications() addObjectsFromArray:messagesForLocalNotification];

            if ([[UIDevice currentDevice].systemVersion intValue] <= 6 &&
                [UIApplication sharedApplication].applicationState != UIApplicationStateActive &&
                messagesForLocalNotification.count != 0)
            {
                NSMutableArray *directMids = [[NSMutableArray alloc] init];
                int32_t directMaxMid = 0;
                for (id notificationDesc in messagesForLocalNotification)
                {
                    if ([notificationDesc isKindOfClass:[TLMessage class]])
                    {
                        int32_t mid = ((TLMessage *)notificationDesc).n_id;
                        if (mid != 0)
                        {
                            [directMids addObject:@(mid)];
                            directMaxMid = MAX(directMaxMid, mid);
                        }
                    }
                }

                if (directMids.count != 0)
                {
                    [TGApplyUpdatesActor applyDelayedNotifications:directMaxMid mids:directMids midsWithoutSound:[NSSet set] maxQts:stateQts randomIds:nil];
                }
            }
            
            if (stateQts != 0)
            {
                [TGDatabaseInstance() updateLatestQts:stateQts applied:false completion:^(int greaterQtsForSynchronization)
                 {
                     if (greaterQtsForSynchronization > 0)
                     {
                         [ActionStageInstance() requestActor:[[NSString alloc] initWithFormat:@"/tg/messages/reportDelivery/(qts)"] options:[[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInt:stateQts], @"qts", nil] watcher:TGTelegraphInstance];
                     }
                 }];
            }
            
            if ([self.path isEqualToString:@"/tg/service/tryupdates/(withPts)"] || [self.path isEqualToString:@"/tg/service/tryupdates/(withSeq)"] || [self.path isEqualToString:@"/tg/service/tryupdates/(withQts)"])
            {
                if (statePts != 0)
                    TGLog(@"=== pts: %d", statePts);
                if (optionalFinalSeq != 0)
                    TGLog(@"=== seq: %d", optionalFinalSeq);
                if (stateQts != 0)
                    TGLog(@"=== qts: %d", stateQts);
                
                [[TGDatabase instance] applyPts:statePts date:optionalFinalDate seq:optionalFinalSeq qts:stateQts unreadCount:-1];
            }
            else if (optionalFinalDate > databaseState.date)
            {
                [[TGDatabase instance] applyPts:0 date:optionalFinalDate seq:0 qts:0 unreadCount:-1];
            }
            
            if (completion)
                completion(true);
        }];
    }
    else
    {
        if (updatesTooLong)
            TGLog(@"===== Updates too long, requesting complete difference");
        else
            TGLog(@"***** Unknown chat or user found, requesting complete difference");
        
        if (completion)
            completion(false);
    }
    
    return !failedProcessing;
}

- (void)cancel
{
    [self cancelTimeoutTimer];
    
    [super cancel];
}

+ (void)applyDelayedNotifications:(int)maxMid mids:(NSArray *)mids midsWithoutSound:(NSSet *)midsWithoutSound maxQts:(int)maxQts randomIds:(NSArray *)randomIds
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        UIApplicationState applicationState = [UIApplication sharedApplication].applicationState;
        if ([UIApplication sharedApplication] == nil)
            applicationState = UIApplicationStateBackground;
        
        [ActionStageInstance() dispatchOnStageQueue:^
        {
            if (applicationState != UIApplicationStateActive)
            {
                NSNumber *globalMessageSoundIdVal = nil;
                NSNumber *globalMessagePreviewTextVal = nil;
                NSNumber *globalMessageMuteUntilVal = nil;
                
                int globalMessageSoundId = 1;
                bool globalMessagePreviewText = true;
                int globalMessageMuteUntil = 0;
                bool notFound = false;
                [TGDatabaseInstance() loadPeerNotificationSettings:INT_MAX - 1 soundId:&globalMessageSoundIdVal muteUntil:&globalMessageMuteUntilVal previewText:&globalMessagePreviewTextVal messagesMuted:NULL notFound:&notFound];
                if (notFound) {
                    globalMessageSoundId = 1;
                    globalMessagePreviewText = true;
                }
                else {
                    globalMessageSoundId = globalMessageSoundIdVal ? globalMessageSoundIdVal.intValue : 1;
                    globalMessagePreviewText = globalMessagePreviewTextVal ? globalMessagePreviewTextVal.boolValue : true;
                    globalMessageMuteUntil = globalMessageMuteUntilVal ? globalMessageMuteUntilVal.intValue : 0;
                }
                
                NSNumber *globalGroupSoundIdVal = nil;
                NSNumber *globalGroupPreviewTextVal = nil;
                NSNumber *globalGroupMuteUntilVal = nil;
                
                int globalGroupSoundId = 1;
                bool globalGroupPreviewText = true;
                int globalGroupMuteUntil = 0;
                notFound = false;
                [TGDatabaseInstance() loadPeerNotificationSettings:INT_MAX - 2 soundId:&globalGroupSoundIdVal muteUntil:&globalGroupMuteUntilVal previewText:&globalGroupPreviewTextVal messagesMuted:NULL notFound:&notFound];
                if (notFound) {
                    globalGroupSoundId = 1;
                    globalGroupPreviewText = true;
                } else {
                    globalGroupSoundId = globalGroupSoundIdVal ? globalGroupSoundIdVal.intValue : 1;
                    globalGroupPreviewText = globalGroupPreviewTextVal ? globalGroupPreviewTextVal.boolValue : true;
                    globalGroupMuteUntil = globalGroupMuteUntilVal ? globalGroupMuteUntilVal.intValue : 0;
                }
                
                @try
                {
                    std::set<int> midsSet;
                    for (NSNumber *nMid in mids)
                    {
                        midsSet.insert([nMid intValue]);
                    }
                    
                    std::set<int> processedMidsSet;
                    
                    std::set<int64_t> randomIdsSet;
                    for (NSNumber *nRandomId in randomIds)
                    {
                        randomIdsSet.insert([nRandomId longLongValue]);
                    }
                    
                    int count = (int)delayedNotifications().count;
                    for (int i = 0; i < count; i++)
                    {
                        TGMessage *message = nil;
                        NSUInteger multiforwardCount = 0;
                        
                        int messageQts = 0;
                        
                        id abstractDesc = delayedNotifications()[i];
                        if ([abstractDesc respondsToSelector:@selector(allKeys)])
                        {
                            messageQts = [abstractDesc[@"qts"] intValue];
                            abstractDesc = abstractDesc[@"message"];
                        }
                        
                        if ([abstractDesc isKindOfClass:[TLMessage class]])
                        {
                            if (mids == nil)
                                continue;
                            
                            TLMessage *messageDesc = abstractDesc;
                            int mid = messageDesc.n_id;
                            
                            if (mid == 0 || mid > maxMid)
                                continue;
                            
                            [delayedNotifications() removeObjectAtIndex:i];
                            i--;
                            count--;
                            
                            if (midsSet.find(mid) == midsSet.end())
                                continue;
                            
                            if (processedMidsSet.find(mid) != processedMidsSet.end())
                                continue;
                            processedMidsSet.insert(mid);

                            NSUInteger notificationBatchCount = mids.count != 0 ? mids.count : randomIds.count;
                            if (!TGIOS6ConsumeLocalNotificationBudget(notificationBatchCount))
                                continue;
                            
                            message = [[TGMessage alloc] initWithTelegraphMessageDesc:messageDesc];
                            bool foundForward = false;
                            
                            for (id media in message.mediaAttachments)
                            {
                                if ([media isKindOfClass:[TGForwardedMessageMediaAttachment class]])
                                {
                                    foundForward = true;
                                    break;
                                }
                            }
                            
                            if (foundForward)
                            {
                                for (int j = i + 1; j >= 0 && j < count; j++)
                                {
                                    if ([delayedNotifications()[j] isKindOfClass:[TLMessage class]])
                                    {
                                        TGMessage *nextMessage = [[TGMessage alloc] initWithTelegraphMessageDesc:delayedNotifications()[j]];
                                        
                                        if (processedMidsSet.find(nextMessage.mid) != processedMidsSet.end())
                                            continue;
                                        processedMidsSet.insert(nextMessage.mid);
                                        
                                        bool nextIsForward = false;
                                        for (id media in nextMessage.mediaAttachments)
                                        {
                                            if ([media isKindOfClass:[TGForwardedMessageMediaAttachment class]])
                                            {
                                                nextIsForward = true;
                                                break;
                                            }
                                        }
                                        
                                        if (nextIsForward)
                                        {
                                            if (multiforwardCount == 0)
                                                multiforwardCount = 1;
                                            multiforwardCount++;
                                            [delayedNotifications() removeObjectAtIndex:j];
                                            j--;
                                            count--;
                                        }
                                    }
                                }
                            }
                        }
                        else if ([abstractDesc isKindOfClass:[TLEncryptedMessage class]])
                        {
                            if (randomIds == nil)
                                continue;
                            
                            TLEncryptedMessage *encryptedMessage = abstractDesc;
                            
                            if (messageQts > maxQts)
                                continue;
                            
                            [delayedNotifications() removeObjectAtIndex:i];
                            i--;
                            count--;
                            
                            if (randomIdsSet.find(encryptedMessage.random_id) == randomIdsSet.end())
                                continue;

                            NSUInteger notificationBatchCount = mids.count != 0 ? mids.count : randomIds.count;
                            if (!TGIOS6ConsumeLocalNotificationBudget(notificationBatchCount))
                                continue;
                            
                            message = [[TGMessage alloc] init];
                            message.randomId = encryptedMessage.random_id;
                            message.cid = [TGDatabaseInstance() peerIdForEncryptedConversationId:encryptedMessage.chat_id];
                        }
                        else
                        {
                            TGLog(@"***** unknown notification message type %@", abstractDesc);
                            continue;
                        }
                        
                        bool messageIsChannel = TGPeerIdIsChannel(message.cid);

                        if (message.containsMention)
                        {
                            if ([TGDatabaseInstance() isPeerMuted:message.fromUid]) {
                                IOS6NotificationProbe(@"NOTIFY_SKIP", @"reason=mention_muted peer=%lld from=%lld mid=%d", message.cid, message.fromUid, message.mid);
                                continue;
                            }
                        }
                        else
                        {
                            if ([TGDatabaseInstance() isPeerMuted:message.cid]) {
                                IOS6NotificationProbe(@"NOTIFY_SKIP", @"reason=peer_muted peer=%lld mid=%d", message.cid, message.mid);
                                continue;
                            }
                        }
                        
                        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                        if (localNotification == nil)
                            continue;
                        
                        TGUser *user = nil;
                        NSString *chatName = nil;
                        
                        int64_t notificationPeerId = 0;
                        
                        if (messageIsChannel)
                        {
                            notificationPeerId = message.cid;
                            if (message.fromUid != 0)
                                user = [TGDatabaseInstance() loadUser:(int)message.fromUid];
                            TGConversation *conversation = [TGDatabaseInstance() loadConversationWithIdCached:message.cid];
                            if (conversation != nil)
                                chatName = conversation.chatTitle;
                            else
                                chatName = [TGDatabaseInstance() loadConversationWithId:message.cid].chatTitle;
                        }
                        else if (message.cid <= INT_MIN)
                        {
                            notificationPeerId = [TGDatabaseInstance() encryptedParticipantIdForConversationId:message.cid];
                        }
                        else if (message.cid > 0)
                        {
                            user = [TGDatabaseInstance() loadUser:(int)message.cid];
                            notificationPeerId = message.cid;
                        }
                        else
                        {
                            if (message.containsMention)
                                notificationPeerId = message.fromUid;
                            else
                                notificationPeerId = message.cid;
                            user = [TGDatabaseInstance() loadUser:(int)message.fromUid];
                            TGConversation *conversation = [TGDatabaseInstance() loadConversationWithIdCached:message.cid];
                            if (conversation != nil)
                                chatName = conversation.chatTitle;
                            else
                                chatName = [TGDatabaseInstance() loadConversationWithId:message.cid].chatTitle;
                        }
                        
                        if ([TGDatabaseInstance() isPeerMuted:notificationPeerId]) {
                            IOS6NotificationProbe(@"NOTIFY_SKIP", @"reason=notification_peer_muted peer=%lld title=%@ mid=%d", notificationPeerId, chatName ?: @"", message.mid);
                            continue;
                        }
                        
                        NSNumber *soundIdVal = nil;
                        int soundId = 1;
                        [TGDatabaseInstance() loadPeerNotificationSettings:notificationPeerId soundId:&soundIdVal muteUntil:NULL previewText:NULL messagesMuted:NULL notFound:NULL];
                        
                        if (soundIdVal != nil) {
                            soundId = soundIdVal.intValue;
                        } else {
                            soundId = (message.cid > 0 || (message.cid <= INT_MIN && !messageIsChannel)) ? globalMessageSoundId : globalGroupSoundId;
                        }
                        
                        NSString *text = nil;
                        
                        bool attachmentFound = false;
                        bool migrationFound = false;
                        bool skipMessage = false;
                        bool phoneCall = false;
                        
                        for (TGMediaAttachment *attachment in message.mediaAttachments)
                        {
                            if (attachment.type == TGActionMediaAttachmentType)
                            {
                                TGActionMediaAttachment *actionAttachment = (TGActionMediaAttachment *)attachment;
                                switch (actionAttachment.actionType)
                                {
                                    case TGMessageActionChatEditTitle:
                                    {
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_TITLE_EDITED"), user.displayName, [((TGActionMediaAttachment *)attachment).actionData objectForKey:@"title"]];
                                        attachmentFound = true;
                                        
                                        break;
                                    }
                                    case TGMessageActionChatEditPhoto:
                                    {
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_PHOTO_EDITED"), user.displayName, chatName];
                                        attachmentFound = true;
                                        
                                        break;
                                    }
                                    case TGMessageActionChatAddMember:
                                    {
                                        NSArray *uids = actionAttachment.actionData[@"uids"];
                                        if (uids != nil) {
                                            TGUser *authorUser = user;
                                            NSMutableArray *subjectUsers = [[NSMutableArray alloc] init];
                                            for (NSNumber *nUid in uids) {
                                                TGUser *subjectUser = [TGDatabaseInstance() loadUser:[nUid intValue]];
                                                if (user != nil) {
                                                    [subjectUsers addObject:subjectUser];
                                                }
                                            }
                                            
                                            if (subjectUsers.count == 1 && authorUser.uid == ((TGUser *)subjectUsers[0]).uid) {
                                                text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_RETURNED"), authorUser.displayName, chatName];
                                            } else {
                                                NSMutableString *subjectNames = [[NSMutableString alloc] init];
                                                for (TGUser *subjectUser in subjectUsers) {
                                                    if (subjectNames.length != 0) {
                                                        [subjectNames appendString:@", "];
                                                    }
                                                    [subjectNames appendString:subjectUser.displayName];
                                                }
                                                text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_ADD_MEMBER"), authorUser.displayName, chatName, subjectNames];
                                            }
                                            attachmentFound = true;
                                        } else {
                                            NSNumber *nUid = [actionAttachment.actionData objectForKey:@"uid"];
                                            if (nUid != nil)
                                            {
                                                TGUser *subjectUser = [TGDatabaseInstance() loadUser:[nUid intValue]];
                                                
                                                if (subjectUser.uid == user.uid)
                                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_RETURNED"), user.displayName, chatName];
                                                else if (subjectUser.uid == TGTelegraphInstance.clientUserId)
                                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_ADD_YOU"), user.displayName, chatName];
                                                else
                                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_ADD_MEMBER"), user.displayName, chatName, subjectUser.displayName];
                                                attachmentFound = true;
                                            }
                                        }
                                        
                                        break;
                                    }
                                    case TGMessageActionChatDeleteMember:
                                    {
                                        NSNumber *nUid = [actionAttachment.actionData objectForKey:@"uid"];
                                        if (nUid != nil)
                                        {
                                            TGUser *subjectUser = [TGDatabaseInstance() loadUser:[nUid intValue]];
                                            
                                            if (subjectUser.uid == user.uid)
                                                text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_LEFT"), user.displayName, chatName];
                                            else if (subjectUser.uid == TGTelegraphInstance.clientUserId)
                                                text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_DELETE_YOU"), user.displayName, chatName];
                                            else
                                                text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_DELETE_MEMBER"), user.displayName, chatName, subjectUser.displayName];
                                            attachmentFound = true;
                                        }
                                        
                                        break;
                                    }
                                    case TGMessageActionCreateChat:
                                    {
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_ADD_YOU"), user.displayName, chatName];
                                        attachmentFound = true;
                                        
                                        break;
                                    }
                                    case TGMessageActionChannelCreated:
                                    {
                                        text = @"";
                                        attachmentFound = true;
                                        
                                        break;
                                    }
                                    case TGMessageActionChannelCommentsStatusChanged:
                                    {
                                        text = [actionAttachment.actionData[@"enabled"] boolValue] ? TGLocalized(@"Channel.NotificationCommentsEnabled") : TGLocalized(@"Channel.NotificationCommentsDisabled");
                                        attachmentFound = true;
                                        
                                        break;
                                    }
                                    case TGMessageActionJoinedByLink:
                                    {
                                        NSString *formatString = [actionAttachment.actionData[@"joinedByRequest"] boolValue] ? TGLocalized(@"Notification.JoinedChat") : TGLocalized(@"Notification.JoinedGroupByLink");
                                        text = [[NSString alloc] initWithFormat:formatString, user.displayName];
                                        attachmentFound = true;
                                        
                                        break;
                                    }
                                    case TGMessageActionGroupMigratedTo:
                                    {
                                        migrationFound = true;
                                        break;
                                    }
                                    case TGMessageActionGameScore:
                                    {
                                        TGMessage *replyMessage = nil;
                                        for (id attachment in message.mediaAttachments) {
                                            if ([attachment isKindOfClass:[TGReplyMessageMediaAttachment class]]) {
                                                replyMessage = ((TGReplyMessageMediaAttachment *)attachment).replyMessage;
                                                break;
                                            }
                                        }
                                        
                                        NSString *gameTitle = nil;
                                        for (id attachment in replyMessage.mediaAttachments) {
                                            if ([attachment isKindOfClass:[TGGameMediaAttachment class]]) {
                                                gameTitle = ((TGGameMediaAttachment *)attachment).title;
                                                break;
                                            }
                                        }
                                        
                                        int scoreCount = (int)[actionAttachment.actionData[@"score"] intValue];
                                        
                                        NSString *formatStringBase = @"";
                                        if (gameTitle != nil) {
                                            if (user.uid == TGTelegraphInstance.clientUserId) {
                                                formatStringBase = [TGStringUtils integerValueFormat:@"ServiceMessage.GameScoreSelfExtended_" value:scoreCount];
                                            } else {
                                                formatStringBase = [TGStringUtils integerValueFormat:@"ServiceMessage.GameScoreExtended_" value:scoreCount];
                                            }
                                        } else {
                                            if (user.uid == TGTelegraphInstance.clientUserId) {
                                                formatStringBase = [TGStringUtils integerValueFormat:@"ServiceMessage.GameScoreSelfSimple_" value:scoreCount];
                                            } else {
                                                formatStringBase = [TGStringUtils integerValueFormat:@"ServiceMessage.GameScoreSimple_" value:scoreCount];
                                            }
                                        }
                                        
                                        NSString *baseString = TGLocalized(formatStringBase);
                                        baseString = [baseString stringByReplacingOccurrencesOfString:@"%@" withString:@"{game}"];
                                        
                                        NSMutableString *formatString = [[NSMutableString alloc] initWithString:baseString];
                                        
                                        NSString *authorName = user.displayFirstName;
                                        
                                        for (int i = 0; i < 3; i++) {
                                            NSRange nameRange = [formatString rangeOfString:@"{name}"];
                                            NSRange scoreRange = [formatString rangeOfString:@"{score}"];
                                            NSRange gameTitleRange = [formatString rangeOfString:@"{game}"];
                                            
                                            if (nameRange.location != NSNotFound) {
                                                if (scoreRange.location == NSNotFound || scoreRange.location > nameRange.location) {
                                                    scoreRange.location = NSNotFound;
                                                }
                                                if (gameTitleRange.location == NSNotFound || gameTitleRange.location > nameRange.location) {
                                                    gameTitleRange.location = NSNotFound;
                                                }
                                            }
                                            
                                            if (scoreRange.location != NSNotFound) {
                                                if (nameRange.location == NSNotFound || nameRange.location > scoreRange.location) {
                                                    nameRange.location = NSNotFound;
                                                }
                                                if (gameTitleRange.location == NSNotFound || gameTitleRange.location > scoreRange.location) {
                                                    gameTitleRange.location = NSNotFound;
                                                }
                                            }
                                            
                                            if (gameTitleRange.location != NSNotFound) {
                                                if (scoreRange.location == NSNotFound || scoreRange.location > gameTitleRange.location) {
                                                    scoreRange.location = NSNotFound;
                                                }
                                                if (nameRange.location == NSNotFound || nameRange.location > gameTitleRange.location) {
                                                    nameRange.location = NSNotFound;
                                                }
                                            }
                                            
                                            if (nameRange.location != NSNotFound) {
                                                [formatString replaceCharactersInRange:nameRange withString:authorName];
                                            }
                                            
                                            if (scoreRange.location != NSNotFound) {
                                                [formatString replaceCharactersInRange:scoreRange withString:[NSString stringWithFormat:@"%d", scoreCount]];
                                            }
                                            
                                            if (gameTitleRange.location != NSNotFound) {
                                                [formatString replaceCharactersInRange:gameTitleRange withString:gameTitle];
                                            }
                                        }
                                        
                                        text = formatString;
                                        attachmentFound = true;
                                        
                                        break;
                                    }
                                    case TGMessageActionPhoneCall:
                                    {
                                        TGCallDiscardReason reason = (TGCallDiscardReason)[actionAttachment.actionData[@"reason"] intValue];
                                        if (reason == TGCallDiscardReasonMissed) {
                                            text = [NSString stringWithFormat:TGLocalized(@"PHONE_CALL_MISSED"), user.displayName];
                                            phoneCall = true;
                                        }
                                        else {
                                            skipMessage = true;
                                        }
                                        
                                        attachmentFound = true;
                                        break;
                                    }
                                    case TGMessageActionEncryptedChatMessageScreenshot:
                                    {
                                        text = [NSString stringWithFormat:TGLocalized(@"MESSAGE_SCREENSHOT"), user.displayName];
                                        attachmentFound = true;
                                        
                                        break;
                                    }
                                    default:
                                        break;
                                }
                            }
                            else if (attachment.type == TGImageMediaAttachmentType)
                            {
                                if (((globalMessagePreviewText && TGPeerIdIsUser(message.cid)) || (globalGroupPreviewText && !TGPeerIdIsUser(message.cid))) && ((TGImageMediaAttachment *)attachment).caption.length != 0) {
                                    if (message.cid > 0) {
                                        text = [[NSString alloc] initWithFormat:@"%@: 🖼 %@", user.displayName, ((TGImageMediaAttachment *)attachment).caption];
                                    } else {
                                        text = [[NSString alloc] initWithFormat:@"%@@%@: 🖼 %@", user.displayName, chatName, ((TGImageMediaAttachment *)attachment).caption];
                                    }
                                } else {
                                    if (message.cid > 0) {
                                        if (message.messageLifetime > 0 && message.messageLifetime <= 60) {
                                            text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_PHOTO_SECRET"), user.displayName];
                                        } else {
                                            text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_PHOTO"), user.displayName];
                                        }
                                    }
                                    else
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_PHOTO"), user.displayName, chatName];
                                }
                                
                                attachmentFound = true;
                                
                                break;
                            }
                            else if (attachment.type == TGVideoMediaAttachmentType)
                            {
                                bool isRoundMessage = ((TGVideoMediaAttachment *)attachment).roundMessage;
                                
                                if (((globalMessagePreviewText && TGPeerIdIsUser(message.cid)) || (globalGroupPreviewText && !TGPeerIdIsUser(message.cid))) && ((TGVideoMediaAttachment *)attachment).caption.length != 0) {
                                    if (message.cid > 0) {
                                        text = [[NSString alloc] initWithFormat:@"%@: 📹 %@", user.displayName, ((TGVideoMediaAttachment *)attachment).caption];
                                    } else {
                                        text = [[NSString alloc] initWithFormat:@"%@@%@: 📹 %@", user.displayName, chatName, ((TGVideoMediaAttachment *)attachment).caption];
                                    }
                                } else {
                                    if (isRoundMessage) {
                                        if (message.cid > 0)
                                            text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_ROUND"), user.displayName];
                                        else
                                            text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_ROUND"), user.displayName, chatName];
                                    }
                                    else {
                                        if (message.cid > 0)
                                            if (message.messageLifetime > 0 && message.messageLifetime <= 60) {
                                                text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_VIDEO_SECRET"), user.displayName];
                                            } else {
                                                text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_VIDEO"), user.displayName];
                                            }
                                        else
                                            text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_VIDEO"), user.displayName, chatName];
                                    }
                                }
                                
                                attachmentFound = true;
                                
                                break;
                            }
                            else if (attachment.type == TGLocationMediaAttachmentType)
                            {
                                TGLocationMediaAttachment *attachment = (TGLocationMediaAttachment *)attachment;
                                if (attachment.period > 0)
                                {
                                    if (message.cid > 0)
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_GEOLIVE"), user.displayName];
                                    else
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_GEOLIVE"), user.displayName, chatName];
                                }
                                else
                                {
                                    if (message.cid > 0)
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_GEO"), user.displayName];
                                    else
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_GEO"), user.displayName, chatName];
                                }
                                
                                attachmentFound = true;
                                
                                break;
                            }
                            else if (attachment.type == TGContactMediaAttachmentType)
                            {
                                if (message.cid > 0)
                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_CONTACT"), user.displayName];
                                else
                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_CONTACT"), user.displayName, chatName];
                                
                                attachmentFound = true;
                                
                                break;
                            }
                            else if (attachment.type == TGDocumentMediaAttachmentType)
                            {
                                bool isAnimated = false;
                                bool isVoice = false;
                                CGSize imageSize = CGSizeZero;
                                bool isSticker = false;
                                NSString *stickerRepresentation = @"";
                                for (id attribute in ((TGDocumentMediaAttachment *)attachment).attributes)
                                {
                                    if ([attribute isKindOfClass:[TGDocumentAttributeAnimated class]])
                                    {
                                        isAnimated = true;
                                    }
                                    else if ([attribute isKindOfClass:[TGDocumentAttributeImageSize class]])
                                    {
                                        imageSize = ((TGDocumentAttributeImageSize *)attribute).size;
                                    }
                                    else if ([attribute isKindOfClass:[TGDocumentAttributeVideo class]]) {
                                        imageSize = ((TGDocumentAttributeVideo *)attribute).size;
                                    }
                                    else if ([attribute isKindOfClass:[TGDocumentAttributeSticker class]])
                                    {
                                        isSticker = true;
                                        stickerRepresentation = [((TGDocumentAttributeSticker *)attribute).alt stringByAppendingString:@" "];
                                    }
                                    else if ([attribute isKindOfClass:[TGDocumentAttributeAudio class]]) {
                                        isVoice = ((TGDocumentAttributeAudio *)attribute).isVoice;
                                    }
                                }
                                
                                if (isSticker)
                                {
                                    if (message.cid > 0) {
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_STICKER"), user.displayName, stickerRepresentation];
                                    } else {
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_STICKER"), user.displayName, chatName, stickerRepresentation];
                                    }
                                }
                                else if (isAnimated) {
                                    if (message.cid > 0)
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_GIF"), user.displayName];
                                    else
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_GIF"), user.displayName, chatName];
                                }
                                else if (isVoice) {
                                    if (message.cid > 0)
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_AUDIO"), user.displayName];
                                    else
                                        text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_AUDIO"), user.displayName, chatName];
                                }
                                else
                                {
                                    if (globalMessagePreviewText && ((TGDocumentMediaAttachment *)attachment).caption.length != 0) {
                                        if (message.cid > 0) {
                                            text = [[NSString alloc] initWithFormat:@"%@: 📎 %@", user.displayName, ((TGDocumentMediaAttachment *)attachment).caption];
                                        } else {
                                            text = [[NSString alloc] initWithFormat:@"%@@%@: 📎 %@", user.displayName, chatName, ((TGDocumentMediaAttachment *)attachment).caption];
                                        }
                                    } else {
                                        if (message.cid > 0)
                                            text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_DOC"), user.displayName];
                                        else
                                            text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_DOC"), user.displayName, chatName];
                                    }
                                }
                                
                                attachmentFound = true;
                                
                                break;
                            }
                            else if (attachment.type == TGAudioMediaAttachmentType)
                            {
                                if (message.cid > 0)
                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_AUDIO"), user.displayName];
                                else
                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_AUDIO"), user.displayName, chatName];
                                
                                attachmentFound = true;
                                
                                break;
                            }
                            else if (attachment.type == TGGameAttachmentType) {
                                NSString *gameTitle = ((TGGameMediaAttachment *)attachment).title;
                                
                                if (message.cid > 0) {
                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_GAME"), user.displayName, gameTitle];
                                } else {
                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_GAME"), user.displayName, chatName, gameTitle];
                                }
                                
                                attachmentFound = true;
                                break;
                            }
                            else if (attachment.type == TGInvoiceMediaAttachmentType) {
                                TGInvoiceMediaAttachment *invoice = (TGInvoiceMediaAttachment *)attachment;
                                
                                NSString *priceString = [[TGCurrencyFormatter shared] formatAmount:invoice.totalAmount currency:invoice.currency];
                                
                                if (message.cid > 0) {
                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_INVOICE"), user.displayName, priceString];
                                } else {
                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_INVOICE"), user.displayName, chatName, priceString];
                                }
                                
                                attachmentFound = true;
                                break;
                            }
                        }
                        
                        if (migrationFound || skipMessage) {
                            continue;
                        }
                        
                        bool notificationWithoutSound = [midsWithoutSound containsObject:@(message.mid)];
                        if ([[UIDevice currentDevice].systemVersion intValue] <= 6 && !notificationWithoutSound)
                        {
                            // Legacy sound ids can be missing/zero after modern TL
                            // notification settings are mapped into this old client.
                            // The peer mute checks above are authoritative, so use the
                            // bundled CAF for an otherwise audible iOS 6 notification.
                            localNotification.soundName = @"notification.caf";
                        }
                        else if (soundId > 0 && !notificationWithoutSound)
                        {
                            localNotification.soundName = [[NSString alloc] initWithFormat:@"%d.m4a", soundId];

                        }

                        if (multiforwardCount != 0)
                        {
                            if (message.cid > 0)
                            {
                                text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_FWDS"), user.displayName, [[NSString alloc] initWithFormat:@"%d", (int)multiforwardCount]];
                            }
                            else
                            {
                                text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_FWDS"), user.displayName, chatName, [[NSString alloc] initWithFormat:@"%d", (int)multiforwardCount]];
                            }
                        }
                        else
                        {
                            if (messageIsChannel)
                            {
                                if (globalGroupPreviewText && !attachmentFound)
                                {
                                    if (user.displayName.length != 0)
                                        text = [[NSString alloc] initWithFormat:@"%@@%@: %@", user.displayName, chatName, message.text];
                                    else
                                        text = [[NSString alloc] initWithFormat:@"%@: %@", chatName, message.text];
                                }
                                else if (!attachmentFound)
                                {
                                    text = [[NSString alloc] initWithFormat:@"%@", chatName];
                                }
                            }
                            else if (message.cid <= INT_MIN)
                            {
                                text = [[NSString alloc] initWithFormat:TGLocalized(@"ENCRYPTED_MESSAGE"), @""];
                            }
                            else if (message.cid > 0)
                            {
                                if (globalMessagePreviewText && !attachmentFound)
                                    text = [[NSString alloc] initWithFormat:@"%@: %@", user.displayName, message.text];
                                else if (!attachmentFound)
                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"MESSAGE_NOTEXT"), user.displayName];
                            }
                            else
                            {
                                if (globalGroupPreviewText && !attachmentFound)
                                    text = [[NSString alloc] initWithFormat:@"%@@%@: %@", user.displayName, chatName, message.text];
                                else if (!attachmentFound)
                                    text = [[NSString alloc] initWithFormat:TGLocalized(@"CHAT_MESSAGE_NOTEXT"), user.displayName, chatName];
                            }
                        }
                        
                        // Some legacy iOS 6 build configurations expose an older
                        // TGAppDelegate runtime without this selector.  Calling it
                        // unconditionally aborts the whole notification batch before
                        // presentLocalNotificationNow: is reached.
                        bool isLocked = false;
                        if ([TGAppDelegateInstance respondsToSelector:@selector(isCurrentlyLocked)])
                            isLocked = [TGAppDelegateInstance isCurrentlyLocked];
                        if (isLocked)
                        {
                            text = [[NSString alloc] initWithFormat:TGLocalized(@"LOCKED_MESSAGE"), @""];
                        }
                        
                        localNotification.userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithLongLong:message.cid], @"cid", @(message.mid), @"mid", nil];

                        // iOS 8+ exposes a separate notification title.  Keep this
                        // runtime-only so the same binary remains safe with the iOS 6 SDK.
                        NSString *notificationTitle = chatName;
                        if (notificationTitle.length == 0)
                            notificationTitle = user.displayName;
                        SEL setAlertTitleSelector = NSSelectorFromString(@"setAlertTitle:");
                        if (notificationTitle.length != 0 && [localNotification respondsToSelector:setAlertTitleSelector])
                            [localNotification setValue:notificationTitle forKey:@"alertTitle"];
                        
                        if (iosMajorVersion() >= 8 && !isLocked)
                        {
                            if (phoneCall)
                                localNotification.category = @"p";
                            else if (TGPeerIdIsGroup(message.cid))
                                localNotification.category = @"m";
                            else if (TGPeerIdIsChannel(message.cid))
                                localNotification.category = @"c";
                            else if (message.cid > INT_MIN)
                                localNotification.category = @"r";
                        }
                        
                        NSUInteger notificationBatchCount = mids.count != 0 ? mids.count : randomIds.count;
                        if ([[UIDevice currentDevice].systemVersion intValue] <= 6 && notificationBatchCount >= 5)
                        {
                            text = TGIOS6AggregateNotificationText(notificationBatchCount);
                            NSMutableDictionary *aggregateInfo = [localNotification.userInfo mutableCopy];
                            aggregateInfo[@"ios6Aggregate"] = @true;
                            localNotification.userInfo = aggregateInfo;
                        }
                        IOS6NotificationProbe(@"NOTIFY_READY", @"peer=%lld title=%@ mid=%d batch=%d", message.cid, chatName ?: @"", message.mid, (int)notificationBatchCount);
                        [TGApplyUpdatesActor presentSafeLocalNotification:localNotification text:text];
                    }
                }
                @catch (NSException *e)
                {
                    TGLog(@"%@", e);
                }
            }
            else
            {
                TGLog(@"Not showing local notifications (applicationState = %d)", (int)applicationState);
                [TGApplyUpdatesActor clearDelayedNotifications];
            }
        }];
    });
}

@end
