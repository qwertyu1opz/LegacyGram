#import "TGConversationHistoryRequestActor.h"
#import "IOS6Trace.h"

#import "../submodules/LegacyComponents/LegacyComponents/ActionStage.h"

#import "TGTelegraph.h"
#import "TGMessage+Telegraph.h"
#import "TGConversation+Telegraph.h"

#import "TGDatabase.h"

#import "TGSchema.h"

#import "TGUserDataRequestBuilder.h"

@interface TGConversationHistoryRequestActor ()
{
}

@property (nonatomic) bool loadUnread;
@property (nonatomic) int loadAtMessageId;

@end

@implementation TGConversationHistoryRequestActor

+ (NSString *)genericPath
{
    return @"/tg/conversations/@/history/@";
}


- (id)initWithPath:(NSString *)path
{
    self = [super initWithPath:path];
    if (self != nil)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:false];
    }
    return self;
}

- (void)dealloc
{
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

- (void)execute:(NSDictionary *)options
{
    NSRange range;
    range.location = [@"/tg/conversations/(" length];
    range.length = self.path.length - [@")/history" length] - range.location;
    int64_t conversationId = [[self.path substringWithRange:range] longLongValue];
    
    int maxMid = [options[@"maxMid"] intValue];
    
    int limit = 70;
    if ([options objectForKey:@"limit"] != nil)
        limit = [TGSchema intFromObject:[options objectForKey:@"limit"]];
    
    int maxDate = 0;
    if ([options objectForKey:@"maxDate"] != nil)
        maxDate = [TGSchema intFromObject:[options objectForKey:@"maxDate"]];
    
    int maxLocalMid = 0;
    if ([options objectForKey:@"maxLocalMid"] != nil)
        maxLocalMid = [TGSchema intFromObject:[options objectForKey:@"maxLocalMid"]];
    
    int offset = 0;
    if ([options objectForKey:@"offset"] != nil)
        offset = [[options objectForKey:@"offset"] intValue];
    
    bool clearExisting = [options[@"clearExisting"] boolValue];
    
    _loadUnread = [[options objectForKey:@"loadUnread"] boolValue];
    
    _loadAtMessageId = [options[@"loadAtMessageId"] intValue];
    if (_loadAtMessageId)
        _loadUnread = false;
    
    bool extraUnread = _loadUnread && _loadAtMessageId == 0 && [self.path hasSuffix:@"/(up0)"];
    
    IOS6Trace(@"IOS6FULL history.execute path=%@ peer=%lld maxMid=%d maxDate=%d maxLocal=%d offset=%d limit=%d down=%d unread=%d at=%d encrypted=%d broadcast=%d clear=%d options=%@",
        self.path, conversationId, maxMid, maxDate, maxLocalMid, offset, limit, [options[@"downwards"] boolValue] ? 1 : 0, _loadUnread ? 1 : 0, _loadAtMessageId, [options[@"isEncrypted"] boolValue] ? 1 : 0, [options[@"isBroadcast"] boolValue] ? 1 : 0, clearExisting ? 1 : 0, options);
    if ([options[@"downwards"] boolValue])
    {
        [TGDatabaseInstance() loadMessagesFromConversationDownwards:conversationId minMid:maxMid minLocalMid:maxLocalMid minDate:maxDate limit:limit completion:^(NSArray *messages)
        {
            int minMessageId = INT_MAX;
            int maxMessageId = 0;
            for (TGMessage *message in messages)
            {
                if (message.mid < TGMessageLocalMidBaseline)
                {
                    minMessageId = MIN(minMessageId, message.mid);
                    maxMessageId = MAX(maxMessageId, message.mid);
                }
            }
            
            bool sequenceContainsHoles = minMessageId >= maxMid && [TGDatabaseInstance() conversationContainsHole:conversationId minMessageId:maxMid maxMessageId:maxMessageId];
            
            if (sequenceContainsHoles)
            {
                NSMutableDictionary *newOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
                newOptions[@"down"] = @true;
                [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversations/(%lld)/asyncHistory/(%d,down)", conversationId, maxMid] options:newOptions watcher:self];
            }
            else
            {
                [ActionStageInstance() actionCompleted:self.path result:[[NSDictionary alloc] initWithObjectsAndKeys:messages, @"messages", [[NSNumber alloc] initWithBool:true], @"downwards", nil]];
            }
        }];
    }
    else
    {
        int requestMaxMid = (maxMid == 0 ? INT_MAX : maxMid);
        bool isEncrypted = [options[@"isEncrypted"] boolValue];
        bool isBroadcast = [options[@"isBroadcast"] boolValue];
        bool isNegativeModernUser = false;
        if (conversationId < 0)
        {
            TGUser *user = [TGDatabaseInstance() loadUser:(int)conversationId];
            isNegativeModernUser = user != nil && user.phoneNumberHash != 0;
        }
        bool isTopRefreshRequest = offset == 0 && (maxMid == 0 || maxMid == INT_MAX);
        bool isUserPeerTopRefresh = (conversationId > 0 || isNegativeModernUser) && isTopRefreshRequest && _loadAtMessageId == 0 && ![options[@"downwards"] boolValue] && !isEncrypted && !isBroadcast;
        bool forceRemoteTopRefresh = isUserPeerTopRefresh || (offset == 0 && maxDate == 0 && _loadAtMessageId == 0 && ![options[@"downwards"] boolValue] && !isEncrypted && !isBroadcast);
        
        [[TGDatabase instance] loadMessagesFromConversation:conversationId maxMid:requestMaxMid maxDate:(maxDate == 0 ? INT_MAX : maxDate) maxLocalMid:(maxLocalMid == 0 ? INT_MAX : maxLocalMid) atMessageId:_loadAtMessageId limit:limit extraUnread:extraUnread completion:^(NSArray *messages, bool historyExistsBelow)
        {
            int peerMinMid = [TGDatabaseInstance() loadPeerMinMid:conversationId];
            [ActionStageInstance() dispatchOnStageQueue:^
            {
                int minMessageId = INT_MAX;
                int maxMessageId = 0;
                for (TGMessage *message in messages)
                {
                    if (message.mid < TGMessageLocalMidBaseline)
                    {
                        minMessageId = MIN(minMessageId, message.mid);
                        maxMessageId = MAX(maxMessageId, message.mid);
                    }
                }
                
                bool sequenceContainsHoles = minMessageId <= requestMaxMid && [TGDatabaseInstance() conversationContainsHole:conversationId minMessageId:minMessageId maxMessageId:requestMaxMid];
                bool suspiciousStaleHistoryEnd = peerMinMid == 1 && messages.count <= 1 && conversationId < 0 && !isEncrypted && !isBroadcast;
                IOS6Trace(@"IOS6TRACE localHistory peer=%lld maxMid=%d requestMax=%d count=%d min=%d max=%d holes=%d forceTop=%d userTop=%d negativeUserTop=%d offset=%d down=%d peerMin=%d staleEnd=%d", conversationId, maxMid, requestMaxMid, (int)messages.count, minMessageId == INT_MAX ? 0 : minMessageId, maxMessageId, sequenceContainsHoles ? 1 : 0, forceRemoteTopRefresh ? 1 : 0, isUserPeerTopRefresh ? 1 : 0, isNegativeModernUser ? 1 : 0, offset, [options[@"downwards"] boolValue] ? 1 : 0, peerMinMid, suspiciousStaleHistoryEnd ? 1 : 0);
                IOS6Trace(@"IOS6FULL history.local peer=%lld maxMid=%d requestMax=%d count=%d min=%d max=%d holes=%d forceTop=%d userTop=%d negativeUserTop=%d offset=%d down=%d peerMin=%d staleEnd=%d existsBelow=%d",
                    conversationId, maxMid, requestMaxMid, (int)messages.count, minMessageId == INT_MAX ? 0 : minMessageId, maxMessageId, sequenceContainsHoles ? 1 : 0, forceRemoteTopRefresh ? 1 : 0, isUserPeerTopRefresh ? 1 : 0, isNegativeModernUser ? 1 : 0, offset, [options[@"downwards"] boolValue] ? 1 : 0, peerMinMid, suspiciousStaleHistoryEnd ? 1 : 0, historyExistsBelow ? 1 : 0);
                if (((messages.count != 0 && !suspiciousStaleHistoryEnd) || (peerMinMid != 0 && !suspiciousStaleHistoryEnd) || [options[@"isEncrypted"] boolValue] || [options[@"isBroadcast"] boolValue]) && !sequenceContainsHoles && !forceRemoteTopRefresh)
                {
                    /*bool loadedUnread = _loadUnread;
                    if (loadedUnread && !historyExistsBelow)
                    {
                        bool hasRead = false;
                        for (TGMessage *message in messages)
                        {
                            if (!message.outgoing || !message.unread)
                            {
                                hasRead = true;
                                break;
                            }
                        }
                        
                        if (!hasRead)
                            loadedUnread = false;
                    }*/
                    
                    [ActionStageInstance() actionCompleted:self.path result:@{
                        @"messages": messages,
                        @"historyExistsBelow": @(historyExistsBelow),
                        @"clearExisting": @(clearExisting)
                     }];
                }
                else
                {
                    int remoteMaxMid = forceRemoteTopRefresh ? 0 : maxMid;
                    NSString *remoteFetchReason = forceRemoteTopRefresh ? @"forceTopLatest" : (sequenceContainsHoles ? @"holes" : @"empty");
                    if (messages.count == 0 && conversationId < 0 && !isEncrypted && !isBroadcast && !isNegativeModernUser)
                    {
                        remoteMaxMid = 0;
                        remoteFetchReason = @"emptyBasicChatLatest";
                    }
                    IOS6Trace(@"IOS6TRACE localHistory remoteFetch peer=%lld maxMid=%d remoteMaxMid=%d reason=%@", conversationId, maxMid, remoteMaxMid, remoteFetchReason);
                    IOS6Trace(@"IOS6FULL history.remoteFetch peer=%lld maxMid=%d remoteMaxMid=%d reason=%@", conversationId, maxMid, remoteMaxMid, remoteFetchReason);
                    [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversations/(%lld)/asyncHistory/(%d)", conversationId, remoteMaxMid] options:options watcher:self];
                }
            }];
        }];
    }
}

- (void)actorCompleted:(int)resultCode path:(NSString *)path result:(id)result
{
    if ([path hasPrefix:@"/tg/conversations/"])
    {
        IOS6Trace(@"IOS6FULL history.actorCompleted ownPath=%@ childPath=%@ status=%d result=%@", self.path, path, resultCode, NSStringFromClass([result class]));
        if (resultCode == ASStatusSuccess)
            [ActionStageInstance() actionCompleted:self.path result:[[NSDictionary alloc] initWithObjectsAndKeys:result, @"messages", [[NSNumber alloc] initWithBool:false], @"remote", nil]];
        else
            [ActionStageInstance() nodeRetrieveFailed:self.path];
    }
}

- (void)cancel
{
    [ActionStageInstance() removeWatcher:self];
    
    [super cancel];
}

@end
