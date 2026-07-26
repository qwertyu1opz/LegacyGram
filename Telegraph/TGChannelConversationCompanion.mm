#import "TGChannelConversationCompanion.h"
#import "IOS6Trace.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGLegacyComponentsContext.h"


#import "TGCommon.h"

#import "TGAppDelegate.h"
#import "../submodules/LegacyComponents/LegacyComponents/ActionStage.h"
#import "TGDatabase.h"
#import "TGTelegraph.h"
#import "TGAppDelegate.h"
#import "TGDialogListCompanion.h"

#import "TGChannelManagementSignals.h"
#import "TGChannelStateSignals.h"

#import "TGModernConversationController.h"
#import "TGMessageModernConversationItem.h"

#import "TGModernConversationGroupTitlePanel.h"
#import "TGUpdateStateRequestBuilder.h"

#import "TGChannelInfoController.h"
#import "TGChannelGroupInfoController.h"

#import "TGModernViewContext.h"

#import "TGModernConversationActionInputPanel.h"

#import "TGTelegramNetworking.h"

#import "TGCustomAlertView.h"

#import "TGModernConversationTitleIcon.h"

#import "TGModernConversationTitleView.h"

#import <libkern/OSAtomic.h>

#import "TGMigratedChannelConversationHeaderView.h"

#import "TGGroupedUserOnlineSignals.h"

#import "TGDownloadMessagesSignal.h"

#import "TGPinnedMessageTitlePanel.h"
#import "TGLiveLocationTitlePanel.h"

#import "TLRPCmessages_search.h"
#import "TGMessage+Telegraph.h"
#import "TGUserDataRequestBuilder.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGProgressWindow.h"

#import "TGAccountSignals.h"

#import "TGModernConversationContactLinkTitlePanel.h"
#import "TGModernConversationRestrictedInputPanel.h"

#import "TGServiceSignals.h"
#import "TGRecentContextBotsSignal.h"
#import "TGCustomActionSheet.h"

#import "TGReportPeerOtherTextController.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGModernGalleryController.h"
#import "TGGroupAvatarGalleryModel.h"

#import "TGGroupManagementSignals.h"

#import "TGChannelBanController.h"

#import "TGPresentation.h"

@interface TGIOS6ChannelPinnedMessagesFilter : TLMessagesFilter
@end

@implementation TGIOS6ChannelPinnedMessagesFilter

- (int32_t)TLconstructorSignature
{
    return (int32_t)0x1bb00451;
}

- (int32_t)TLconstructorName
{
    return -1;
}

- (void)TLserialize:(NSOutputStream *)__unused os
{
}

@end

@interface TGChannelConversationCompanion () <TGModernConversationContactLinkTitlePanelDelegate> {
    NSDictionary *_initialUserActivities;
    
    TGConversation *_conversation;
    int32_t _displayVariant;
    int32_t _kind;
    bool _isCreator;
    TGChannelAdminRights *_adminRights;
    TGChannelBannedRights *_bannedRights;
    bool _isGroup;
    bool _isMuted;
    bool _isForbidden;
    
    NSMutableDictionary *_defaultNotificationSettings;
    NSMutableDictionary *_groupNotificationSettings;
    
    NSSet *_adminIds;
    int32_t _memberCount;
    
    bool _enableVisibleMessagesProcessing;
    
    SMetaDisposable *_requestingHoleDisposable;
    SMetaDisposable *_managedState;
    SMetaDisposable *_extendedDataDisposable;
    SMetaDisposable *_cachedDataDisposable;
    SMetaDisposable *_updatedAdminsDisposable;
    
    TGVisibleMessageHole *_requestingHole;
    bool _loadingHistoryAbove;
    bool _loadingHistoryBelow;
    NSUInteger _ios6RemoteGapGeneration;
    
    bool _historyAbove;
    bool _historyBelow;
    
    NSArray *_visibleHoles;
    
    TGModernConversationActionInputPanel *_joinChannelPanel; // Main Thread
    TGModernConversationActionInputPanel *_mutePanel; // Main Thread
    TGModernConversationActionInputPanel *_deletePanel; // Main Thread
    TGModernConversationRestrictedInputPanel *_restrictedPanel; // Main Thread
    SMetaDisposable *_joinChannelDisposable;
    
    TGMessageGroup *_lastExpandedGroup;
    
    NSTimeInterval _lastTypingActivity;
    NSTimeInterval _ios6LastReadHistoryScheduleTime;
    
    TGMigratedChannelConversationHeaderView *_migratedChannelHeaderView;
    
    TGConversationMigrationData *_migrationData;
    bool _migrationHistoryAbove;
    
    bool _hasBots;
    
    SVariable *_pinnedMessage;
    int32_t _immediatePinnedMessage;
    SVariable *_pinnedMessagesVariable;
    NSArray *_pinnedMessages;
    id<SDisposable> _pinnedMessagesDisposable;
    int32_t _hiddenPinnedMessageId;
    
    int32_t _invalidatedPts;
    bool _needsToValidatePts;
    id<SDisposable> _invalidatedPtsDisposable;
    
    bool _updatingInvalidatedMessages;
    SMetaDisposable *_updatingInvalidatedMessagesDisposable;
    
    SDisposableSet *_genericInfoDisposables;
    NSNumber *_messagesMuted;
    bool _shouldNotifyMembers;
    
    bool _signaturesEnabled;
    
    SMetaDisposable *_groupedUserStatusesDisposable;
    
    TGGroupedUserOnlineInfo *_groupedOnlineInfo;

    id<SDisposable> _updatedPeerSettingsDisposable;
    
    TGModernConversationContactLinkTitlePanel *_reportSpamPanel;
    TGPinnedMessageTitlePanel *_pinnedMessagePanel;
    TGLiveLocationTitlePanel *_locationPanel;
    
    SVariable *_primaryPanel;
}

@end

@implementation TGChannelConversationCompanion

- (void)_ios6ScheduleReadHistoryFromChannelAppear:(NSString *)reason
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (_ios6LastReadHistoryScheduleTime > 0.0 && now - _ios6LastReadHistoryScheduleTime < 1.0)
        return;
    _ios6LastReadHistoryScheduleTime = now;
    
    TGModernConversationController *controller = self.controller;
    while (false) TGLog(@"IOS6READ channel.appearSchedule reason=%@ peer=%lld group=%d preview=%d canRead=%d unread=%d serviceUnread=%d maxRead=%d maxKnown=%d display=%d",
        reason, _conversationId, _isGroup ? 1 : 0, self.previewMode ? 1 : 0, [controller canReadHistory] ? 1 : 0, _conversation.unreadCount, _conversation.serviceUnreadCount, _conversation.maxReadMessageId, _conversation.maxKnownMessageId, _displayVariant);
    [self scheduleReadHistory];
}

- (void)_controllerWillAppearAnimated:(bool)animated firstTime:(bool)firstTime
{
    [super _controllerWillAppearAnimated:animated firstTime:firstTime];
    [self _ios6ScheduleReadHistoryFromChannelAppear:firstTime ? @"firstWillAppear" : @"willAppear"];
}

- (void)updateBroadcasting
{
    bool shouldNotify = false;
    if (_messagesMuted != nil)
        shouldNotify = !(_messagesMuted.boolValue);
    else
        shouldNotify = !([_defaultNotificationSettings[@"messagesMuted"] boolValue]);
    
    _shouldNotifyMembers = shouldNotify;
    [self.controller setIsBroadcasting:shouldNotify];
}

- (TGMessage *)_pinnedMessageFromServiceMessage:(TGMessage *)message
{
    bool isPinnedMessageAction = false;
    TGMessage *replyMessage = nil;
    for (id attachment in message.mediaAttachments)
    {
        if ([attachment isKindOfClass:[TGActionMediaAttachment class]] && ((TGActionMediaAttachment *)attachment).actionType == TGMessageActionPinnedMessage)
            isPinnedMessageAction = true;
        else if ([attachment isKindOfClass:[TGReplyMessageMediaAttachment class]])
            replyMessage = ((TGReplyMessageMediaAttachment *)attachment).replyMessage;
    }
    return isPinnedMessageAction ? replyMessage : nil;
}

- (NSArray *)_pinnedMessagesFromMessages:(NSArray *)messages
{
    NSArray *sortedMessages = [messages sortedArrayUsingComparator:^NSComparisonResult(TGMessage *message1, TGMessage *message2)
    {
        int32_t date1 = [message1 actualDate];
        int32_t date2 = [message2 actualDate];
        if (date1 == date2)
            return message1.mid > message2.mid ? NSOrderedAscending : NSOrderedDescending;
        return date1 > date2 ? NSOrderedAscending : NSOrderedDescending;
    }];

    for (TGMessage *message in sortedMessages)
    {
        TGMessage *pinnedMessage = [self _pinnedMessageFromServiceMessage:message];
        if (pinnedMessage != nil && pinnedMessage.mid != 0)
            return @[pinnedMessage];
    }
    return @[];
}

- (void)_mergePinnedMessages:(NSArray *)messages
{
    if (messages.count == 0)
        return;

    TGDispatchOnMainThread(^
    {
        int32_t previousFirstMessageId = ((TGMessage *)_pinnedMessages.firstObject).mid;
        NSMutableArray *mergedMessages = [[NSMutableArray alloc] init];
        NSMutableSet *messageIds = [[NSMutableSet alloc] init];
        for (TGMessage *message in messages)
        {
            if (message.mid != 0 && ![messageIds containsObject:@(message.mid)])
            {
                [messageIds addObject:@(message.mid)];
                [mergedMessages addObject:message];
            }
        }
        for (TGMessage *message in _pinnedMessages)
        {
            if (message.mid != 0 && ![messageIds containsObject:@(message.mid)])
            {
                [messageIds addObject:@(message.mid)];
                [mergedMessages addObject:message];
            }
        }
        _pinnedMessages = mergedMessages;
        if (((TGMessage *)_pinnedMessages.firstObject).mid != previousFirstMessageId)
            _hiddenPinnedMessageId = 0;
        [_pinnedMessagesVariable set:[SSignal single:_pinnedMessages]];
    });
}

- (void)_replacePinnedMessagesFromServer:(NSArray *)messages
{
    TGDispatchOnMainThread(^
    {
        int32_t previousFirstMessageId = ((TGMessage *)_pinnedMessages.firstObject).mid;
        TGMessage *preferredMessage = _pinnedMessages.firstObject;
        NSMutableArray *result = [[NSMutableArray alloc] init];
        NSMutableSet *messageIds = [[NSMutableSet alloc] init];
        if (preferredMessage != nil)
        {
            for (TGMessage *message in messages)
            {
                if (message.mid == preferredMessage.mid)
                {
                    [result addObject:message];
                    [messageIds addObject:@(message.mid)];
                    break;
                }
            }
        }
        for (TGMessage *message in messages)
        {
            if (message.mid != 0 && ![messageIds containsObject:@(message.mid)])
            {
                [messageIds addObject:@(message.mid)];
                [result addObject:message];
            }
        }
        _pinnedMessages = result;
        if (((TGMessage *)_pinnedMessages.firstObject).mid != previousFirstMessageId)
            _hiddenPinnedMessageId = 0;
        [_pinnedMessagesVariable set:[SSignal single:_pinnedMessages]];
    });
}

- (NSString *)_menuTitleForPinnedMessage:(TGMessage *)message
{
    NSString *text = message.text.length != 0 ? message.text : message.caption;
    text = [[text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    while ([text rangeOfString:@"  "].location != NSNotFound)
        text = [text stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0)
        text = TGLocalized(@"Conversation.PinnedMessage");
    return text;
}

- (void)_navigateToPinnedMessage:(TGMessage *)message
{
    if (message.mid == 0)
        return;
    TGModernConversationController *controller = self.controller;
    if ([[controller visibleMessageIds] containsObject:@(message.mid)])
        [self navigateToMessageId:message.mid scrollBackMessageId:0 forceUnseenMention:false animated:true];
    else
        [self navigateToMessageId:message.mid scrollBackMessageId:0 forceUnseenMention:false animated:true forceLoad:true];
}

- (void)_setPinnedMessagesMenuItemsForController:(TGMenuSheetController *)controller offset:(NSUInteger)offset animated:(bool)animated
{
    bool classicIOS6Style = [TGPresentation classicIOS6Style];
    const NSUInteger pageSize = classicIOS6Style ? 5 : 8;
    NSUInteger messageCount = _pinnedMessages.count;
    if (messageCount == 0)
    {
        [controller dismissAnimated:true];
        return;
    }

    NSUInteger maximumOffset = ((messageCount - 1) / pageSize) * pageSize;
    offset = MIN(offset, maximumOffset);
    NSUInteger endIndex = MIN(offset + pageSize, messageCount);

    NSMutableArray *items = [[NSMutableArray alloc] init];
    if (!classicIOS6Style)
        [items addObject:[[TGPinnedMessagesMenuHeaderItemView alloc] initWithMessageCount:messageCount]];

    __weak TGChannelConversationCompanion *weakSelf = self;
    __weak TGMenuSheetController *weakController = controller;
    for (NSUInteger index = offset; index < endIndex; index++)
    {
        TGMessage *message = _pinnedMessages[index];
        NSString *title = [self _menuTitleForPinnedMessage:message];
        void (^action)(void) = ^
        {
            __strong TGMenuSheetController *strongController = weakController;
            [strongController dismissAnimated:true];
            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
            [strongSelf _navigateToPinnedMessage:message];
        };

        if (classicIOS6Style)
        {
            NSString *buttonTitle = [NSString stringWithFormat:@"%d. %@", (int)index + 1, title];
            // UIActionSheet scales long labels down independently.  Keep every
            // pinned-message button short enough to preserve one font size.
            if (buttonTitle.length > 24)
            {
                NSRange range = [buttonTitle rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, 23)];
                buttonTitle = [[buttonTitle substringWithRange:range] stringByAppendingString:@"\u2026"];
            }
            [items addObject:[[TGMenuSheetButtonItemView alloc] initWithTitle:buttonTitle type:TGMenuSheetButtonTypeDefault action:action]];
        }
        else
        {
            [items addObject:[[TGPinnedMessageMenuItemView alloc] initWithTitle:title index:index action:action]];
        }
    }

    if (offset > 0)
    {
        NSUInteger previousOffset = offset >= pageSize ? offset - pageSize : 0;
        NSUInteger previousEnd = MIN(previousOffset + pageSize, messageCount);
        NSString *title = [NSString stringWithFormat:@"\u2039 %d\u2013%d", (int)previousOffset + 1, (int)previousEnd];
        [items addObject:[[TGMenuSheetButtonItemView alloc] initWithTitle:title type:TGMenuSheetButtonTypeDefault action:^
        {
            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
            __strong TGMenuSheetController *strongController = weakController;
            [strongSelf _setPinnedMessagesMenuItemsForController:strongController offset:previousOffset animated:true];
        }]];
    }

    if (endIndex < messageCount)
    {
        NSUInteger nextOffset = endIndex;
        NSUInteger nextEnd = MIN(nextOffset + pageSize, messageCount);
        NSString *title = [NSString stringWithFormat:@"%d\u2013%d \u203a", (int)nextOffset + 1, (int)nextEnd];
        [items addObject:[[TGMenuSheetButtonItemView alloc] initWithTitle:title type:TGMenuSheetButtonTypeDefault action:^
        {
            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
            __strong TGMenuSheetController *strongController = weakController;
            [strongSelf _setPinnedMessagesMenuItemsForController:strongController offset:nextOffset animated:true];
        }]];
    }

    if (animated)
        [controller setItemViews:items animated:true];
    else
        [controller setItemViews:items];
}

- (void)_presentPinnedMessagesMenuFromPanel:(TGPinnedMessageTitlePanel *)panel
{
    if (_pinnedMessages.count == 0)
        return;

    [self.controller endEditing];
    TGMenuSheetController *controller = [[TGMenuSheetController alloc] initWithContext:[TGLegacyComponentsContext shared] dark:false];
    controller.dismissesByOutsideTap = true;
    controller.narrowInLandscape = true;
    controller.maxHeight = MIN(420.0f, self.controller.view.bounds.size.height - 44.0f);

    __weak TGChannelConversationCompanion *weakSelf = self;
    [self _setPinnedMessagesMenuItemsForController:controller offset:0 animated:false];
    __weak TGPinnedMessageTitlePanel *weakPanel = panel;
    controller.sourceRect = ^CGRect
    {
        __strong TGChannelConversationCompanion *strongSelf = weakSelf;
        __strong TGPinnedMessageTitlePanel *strongPanel = weakPanel;
        if (strongSelf == nil || strongPanel == nil)
            return CGRectZero;
        return [strongPanel convertRect:strongPanel.bounds toView:strongSelf.controller.view];
    };
    controller.permittedArrowDirections = UIPopoverArrowDirectionUp;
    [controller presentInViewController:self.controller sourceView:self.controller.view animated:true];
}

- (SSignal *)_requestPinnedMessages
{
    TLRPCmessages_search *search = [[TLRPCmessages_search alloc] init];
    search.peer = [TGTelegraphInstance createInputPeerForConversation:_conversationId accessHash:_accessHash];
    search.q = @"";
    search.filter = [[TGIOS6ChannelPinnedMessagesFilter alloc] init];
    search.min_date = 0;
    search.max_date = 0;
    search.offset = 0;
    search.max_id = 0;
    search.limit = 50;
    search.flags = 0;

    int64_t peerId = _conversationId;
    return [[[[TGTelegramNetworking instance] requestSignal:search] map:^id(TLmessages_Messages *result)
    {
        [TGUserDataRequestBuilder executeUserDataUpdate:result.users];
        NSMutableArray *messages = [[NSMutableArray alloc] init];
        for (TLMessage *messageDesc in result.messages)
        {
            TGMessage *message = [[TGMessage alloc] initWithTelegraphMessageDesc:messageDesc];
            if (message.mid != 0)
                [messages addObject:message];
        }
        return messages;
    }] catch:^SSignal *(id error)
    {
        TGLog(@"IOS6TRACE pinned.search.error peer=%lld filter=inputMessagesFilterPinned scope=channel error=%@", peerId, error);
        return [SSignal single:[NSNull null]];
    }];
}

- (void)_refreshPinnedMessages
{
    [_pinnedMessagesDisposable dispose];
    __weak TGChannelConversationCompanion *weakSelf = self;
    _pinnedMessagesDisposable = [[[self _requestPinnedMessages] deliverOn:[SQueue mainQueue]] startWithNext:^(id next)
    {
        __strong TGChannelConversationCompanion *strongSelf = weakSelf;
        if (strongSelf != nil && [next isKindOfClass:[NSArray class]])
            [strongSelf _replacePinnedMessagesFromServer:next];
    }];
}

- (void)_updatePinnedMessagesFromConversationItems
{
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    for (TGMessageModernConversationItem *item in [self.controller _items])
    {
        if ([item isKindOfClass:[TGMessageModernConversationItem class]])
            [messages addObject:item->_message];
    }
    [self _mergePinnedMessages:[self _pinnedMessagesFromMessages:messages]];
}

- (instancetype)initWithConversation:(TGConversation *)conversation userActivities:(NSDictionary *)userActivities {
    if (self != nil) {
        _primaryPanel = [[SVariable alloc] init];
        [_primaryPanel set:[SSignal single:nil]];
        _pinnedMessagesVariable = [[SVariable alloc] init];
        [_pinnedMessagesVariable set:[SSignal single:[NSNull null]]];
    }
    
    self = [super initWithConversation:conversation mayHaveUnreadMessages:false];
    if (self != nil) {
        IOS6Trace(@"IOS6FULL channel.init peer=%lld title=%@ access=%lld rawChannel=%d group=%d min=%d kind=%d role=%d unread=%d serviceUnread=%d pts=%d", conversation.conversationId, conversation.chatTitle, conversation.accessHash, (int)TGChannelIdFromPeerId(conversation.conversationId), conversation.isChannelGroup ? 1 : 0, conversation.isMin ? 1 : 0, (int)conversation.kind, (int)conversation.channelRole, conversation.unreadCount, conversation.serviceUnreadCount, conversation.pts);
        _genericInfoDisposables = [[SDisposableSet alloc] init];
        
        _conversation = conversation;
        _pinnedMessages = @[];
        
        _accessHash = conversation.accessHash;
        _isGroup = conversation.isChannelGroup;
        _displayVariant = conversation.displayVariant;
        _kind = conversation.kind;
        _isCreator = conversation.channelRole == TGChannelRoleCreator;
        _adminRights = conversation.channelAdminRights;
        _bannedRights = conversation.channelBannedRights;
        if (!_isGroup) {
            _displayVariant = TGChannelDisplayVariantImportant;
        } else {
            _displayVariant = TGChannelDisplayVariantAll;
        }
        
        _isForbidden = conversation.kickedFromChat;
        _signaturesEnabled = conversation.signaturesEnabled;
        
        __weak TGChannelConversationCompanion *weakSelf = self;
        _cachedDataDisposable = [[[TGDatabaseInstance() channelCachedData:_conversationId] deliverOn:[SQueue mainQueue]] startWithNext:^(TGCachedConversationData *data) {
            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
            if (strongSelf != nil) {
                [strongSelf setMemberCount:data.memberCount];
                [strongSelf setMigrationData:data.migrationData];
                [strongSelf setHasBots:data.botInfos.count != 0];
            }
        }];
        
        _updatedAdminsDisposable = [[SMetaDisposable alloc] init];
        if (_isGroup) {
            [_updatedAdminsDisposable setDisposable:[[[TGChannelManagementSignals updatedChannelAdmins:_conversationId accessHash:_accessHash] deliverOn:[SQueue mainQueue]] startWithNext:^(NSSet *adminIds) {
                __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    [strongSelf setAdminIds:adminIds];
                }
            }]];
        }
        
        _manualMessageManagement = true;
        _everyMessageNeedsAuthor = true;
        
        _initialUserActivities = userActivities;
        
        [_genericInfoDisposables add:[[[TGDatabaseInstance() channelShouldMuteMembers:_conversationId] deliverOn:[SQueue mainQueue]] startWithNext:^(NSNumber *next) {
            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
            if (strongSelf != nil) {
                strongSelf->_messagesMuted = next;
                if (!strongSelf->_isGroup && (strongSelf->_isCreator || strongSelf->_adminRights.canPostMessages)) {
                    TGModernConversationController *controller = strongSelf.controller;
                    [controller setCanBroadcast:true];
                    [strongSelf updateBroadcasting];
                    [controller setIsAlwaysBroadcasting:false];
                }
            }
        }]];
        
        if (_isGroup) {
            _groupedUserStatusesDisposable = [[SMetaDisposable alloc] init];
            
            int64_t conversationId = _conversationId;
            int64_t accessHash = _accessHash;
            
            SSignal *changedPrecondition = [[[TGDatabaseInstance() channelCachedData:conversationId] map:^id(TGCachedConversationData *cachedData) {
                return @(cachedData.memberCount != 0 && cachedData.memberCount <= 200);
            }] ignoreRepeated];
            
            
            SSignal *users = [changedPrecondition mapToSignal:^SSignal *(NSNumber *shouldCountOnlines) {
                if ([shouldCountOnlines boolValue]) {
                    SSignal *cachedUsers = [[[TGDatabaseInstance() channelCachedData:conversationId] map:^id (TGCachedConversationData *cachedData) {
                        NSMutableArray *users = [[NSMutableArray alloc] init];
                        for (TGCachedConversationMember *member in cachedData.generalMembers) {
                            TGUser *user = [TGDatabaseInstance() loadUser:member.uid];
                            if (user != nil) {
                                [users addObject:user];
                            }
                        }
                        return users;
                    }] take:1];
                    
                    return [cachedUsers then:[[TGChannelManagementSignals channelMembers:conversationId accessHash:accessHash offset:0 count:200] map:^id(NSDictionary *dict) {
                        [TGDatabaseInstance() updateChannelCachedData:conversation.conversationId block:^TGCachedConversationData *(TGCachedConversationData *data) {
                            if (data == nil) {
                                data = [[TGCachedConversationData alloc] init];
                            }
                            
                            NSMutableArray *sortedMemberDatas = [[NSMutableArray alloc] init];
                            NSDictionary *memberDatas = dict[@"memberDatas"];
                            for (TGUser *user in dict[@"users"]) {
                                TGCachedConversationMember *member = memberDatas[@(user.uid)];
                                if (member != nil) {
                                    [sortedMemberDatas addObject:member];
                                }
                            }
                            
                            return [data updateGeneralMembers:sortedMemberDatas];
                        }];
                        
                        return dict[@"users"];
                    }]];
                } else {
                    return [SSignal single:@[]];
                }
            }];
            
            SSignal *groupedInfo = [TGGroupedUserOnlineSignals groupedOnlineInfoForUserList:users];
            [_groupedUserStatusesDisposable setDisposable:[[groupedInfo deliverOn:[SQueue mainQueue]] startWithNext:^(TGGroupedUserOnlineInfo *groupedOnlineInfo) {
                __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    strongSelf->_groupedOnlineInfo = groupedOnlineInfo;
                    [strongSelf updateStatus];
                }
            }]];
        }
        
        _pinnedMessage = [[SVariable alloc] init];
        int64_t conversationId = _conversationId;
        int64_t accessHash = _accessHash;
        
        _initialMayHaveUnreadMessages = _conversation.kind == TGConversationKindPersistentChannel && (_conversation.unreadCount != 0 || (_displayVariant == TGChannelDisplayVariantAll && _conversation.serviceUnreadCount != 0));
        
        SSignal *pinnedId = [[[TGDatabaseInstance() existingChannel:_conversationId] map:^id(TGConversation *conversation) {
            return @(conversation.pinnedMessageHidden ? 0 : conversation.pinnedMessageId);
        }] ignoreRepeated];
        
        [_pinnedMessage set:[pinnedId mapToSignal:^SSignal *(NSNumber *nPinnedMessageId) {
            int32_t pinnedMessageId = [nPinnedMessageId intValue];
            return [[TGDatabaseInstance() modify:^id{
                if (pinnedMessageId == 0) {
                    return [SSignal single:[NSNull null]];
                } else {
                    TGMessage *message = [TGDatabaseInstance() loadMessageWithMid:pinnedMessageId peerId:conversationId];
                    if (message != nil) {
                        return [SSignal single:message];
                    } else {
                        return [[TGDownloadMessagesSignal downloadMessages:@[[[TGDownloadMessage alloc] initWithPeerId:conversationId accessHash:accessHash messageId:pinnedMessageId]]] mapToSignal:^SSignal *(NSArray *messages) {
                            return [TGDatabaseInstance() modify:^id{
                                for (TGMessage *message in messages) {
                                    if (message.mid == pinnedMessageId) {
                                        [TGDatabaseInstance() addMessagesToChannel:conversationId messages:@[message] deleteMessages:nil unimportantGroups:nil addedHoles:nil removedHoles:nil removedUnimportantHoles:nil updatedMessageSortKeys:nil returnGroups:false keepUnreadCounters:false skipFeedUpdate:true changedMessages:nil];
                                        return message;
                                    }
                                }
                                return [NSNull null];
                            }];
                        }];
                    }
                }
            }] switchToLatest];
        }]];

        SSignal *effectivePinnedMessage = [[SSignal combineSignals:@[_pinnedMessage.signal, _pinnedMessagesVariable.signal]
                                                       withInitialStates:@[[NSNull null], [NSNull null]]] map:^id(NSArray *values)
        {
            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
            if (strongSelf == nil)
                return [NSNull null];
            id pinnedMessagesState = values[1];
            if ([pinnedMessagesState isKindOfClass:[NSArray class]])
            {
                TGMessage *message = [(NSArray *)pinnedMessagesState firstObject];
                if (message.mid != 0 && message.mid == strongSelf->_hiddenPinnedMessageId)
                    return [NSNull null];
                return message == nil ? [NSNull null] : message;
            }
            TGMessage *message = [values[0] isKindOfClass:[TGMessage class]] ? values[0] : nil;
            if (message.mid != 0 && message.mid == strongSelf->_hiddenPinnedMessageId)
                return [NSNull null];
            return message == nil ? [NSNull null] : message;
        }];

        SSignal *combinedPinnedMessageAndShouldReportSpam = [SSignal combineSignals:@
         [
          effectivePinnedMessage,
          [[TGDatabaseInstance() shouldReportSpamForPeerId:_conversationId] ignoreRepeated],
          [self liveLocationSignal]
        ] withInitialStates:@[[NSNull null], @false, @[]]];
        
        SSignal *panelSignal = [[combinedPinnedMessageAndShouldReportSpam deliverOn:[SQueue mainQueue]] map:^id(NSArray *pinnedMessageAndReportSpam) {
            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
            TGModernConversationTitlePanel *resultPanel = nil;
            if (strongSelf != nil) {
                if ([pinnedMessageAndReportSpam[1] boolValue]) {
                    if (strongSelf->_reportSpamPanel == nil) {
                        TGModernConversationContactLinkTitlePanel *panel = [[TGModernConversationContactLinkTitlePanel alloc] init];
                        panel.delegate = strongSelf;
                        [panel setShareContact:false addContact:false reportSpam:true];
                        strongSelf->_reportSpamPanel = panel;
                    }
                    resultPanel = strongSelf->_reportSpamPanel;
                } else {
                    NSArray *liveLocations = (NSArray *)pinnedMessageAndReportSpam[2];
                    TGLiveLocation *ownLiveLocation = nil;
                    for (TGLiveLocation *liveLocation in liveLocations)
                    {
                        if (liveLocation.hasOwnSession)
                        {
                            ownLiveLocation = liveLocation;
                            break;
                        }
                    }
                    
                    if (!strongSelf->_isGroup && ownLiveLocation != nil)
                        liveLocations = @[ownLiveLocation];
                    
                    TGMessage *pinnedMessage = pinnedMessageAndReportSpam[0];
                    bool pinnedMessageIsLiveLocation = false;
                    if ([pinnedMessage isKindOfClass:[TGMessage class]])
                    {
                        int32_t currentTime = (int32_t)[[TGTelegramNetworking instance] globalTime];
                        TGLocationMediaAttachment *location = pinnedMessage.locationAttachment;
                        if (location.period > 0 && currentTime < pinnedMessage.date + location.period)
                            pinnedMessageIsLiveLocation = true;
                    }
                    
                    if (ownLiveLocation != nil || pinnedMessageIsLiveLocation)
                    {
                        if (strongSelf->_locationPanel == nil)
                            strongSelf->_locationPanel = [[TGLiveLocationTitlePanel alloc] init];
                        
                        __weak TGLiveLocationTitlePanel *weakPanel = strongSelf->_locationPanel;
                        strongSelf->_locationPanel.tapped = ^
                        {
                            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                            if (strongSelf == nil)
                                return;
                            
                            TGLiveLocation *liveLocationToOpen = nil;
                            int32_t latestLiveLocationDate = 0;
                            for (TGLiveLocation *liveLocation in liveLocations)
                            {
                                if (liveLocation.hasOwnSession)
                                {
                                    liveLocationToOpen = liveLocation;
                                    break;
                                }
                                
                                if ([liveLocation.message actualDate] > latestLiveLocationDate)
                                {
                                    liveLocationToOpen = liveLocation;
                                    latestLiveLocationDate = [liveLocation.message actualDate];
                                }
                            }
                            
                            [strongSelf.controller openLocationFromMessage:pinnedMessageIsLiveLocation ? pinnedMessage : liveLocationToOpen.message previewMode:false zoomToFitAll:liveLocations.count > 0];
                        };
                        strongSelf->_locationPanel.closed = ^
                        {
                            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                            if (strongSelf == nil)
                                return;
                            
                            [strongSelf.controller endEditing];
                            
                            bool hasOwn = false;
                            for (TGLiveLocation *liveLocation in liveLocations)
                            {
                                if (liveLocation.hasOwnSession)
                                {
                                    hasOwn = true;
                                    break;
                                }
                            }
                            
                            if (hasOwn)
                            {
                                TGMenuSheetController *controller = [[TGMenuSheetController alloc] initWithContext:[TGLegacyComponentsContext shared] dark:false];
                                controller.dismissesByOutsideTap = true;
                                controller.narrowInLandscape = true;
                                
                                __weak TGMenuSheetController *weakController = controller;
                                NSArray *items = @
                                [
                                 [[TGMenuSheetButtonItemView alloc] initWithTitle:TGLocalized(@"Map.StopLiveLocation") type:TGMenuSheetButtonTypeDestructive action:^
                                  {
                                      __strong TGMenuSheetController *strongController = weakController;
                                      if (strongController == nil)
                                          return;
                                      
                                      [strongController dismissAnimated:true];
                                      [TGTelegraphInstance.liveLocationManager stopWithPeerId:strongSelf.conversationId];
                                  }],
                                 [[TGMenuSheetButtonItemView alloc] initWithTitle:TGLocalized(@"Common.Cancel") type:TGMenuSheetButtonTypeCancel action:^
                                  {
                                      __strong TGMenuSheetController *strongController = weakController;
                                      if (strongController != nil)
                                          [strongController dismissAnimated:true];
                                  }]
                                 ];
                                
                                [controller setItemViews:items];
                                controller.sourceRect = ^CGRect
                                {
                                    __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                                    if (strongSelf == nil)
                                        return CGRectZero;
                                    
                                    __strong TGLiveLocationTitlePanel *strongPanel = weakPanel;
                                    if (strongPanel == nil)
                                        return CGRectZero;
                                    
                                    return [strongPanel convertRect:strongPanel.bounds toView:strongSelf.controller.view];
                                };
                                controller.permittedArrowDirections = UIPopoverArrowDirectionUp;
                                [controller presentInViewController:strongSelf.controller sourceView:strongSelf.controller.view animated:true];
                            }
                            else
                            {
                                [TGDatabaseInstance() updateChannelPinnedMessageId:conversationId pinnedMessageId:pinnedMessage.mid hidden:@(true)];
                            }
                        };
                        
                        [strongSelf->_locationPanel setLiveLocations:liveLocations];
                        resultPanel = strongSelf->_locationPanel;
                    }
                    else
                    {
                        TGMessage *message = [pinnedMessageAndReportSpam[0] isKindOfClass:[TGMessage class]] ? pinnedMessageAndReportSpam[0] : nil;
                        
                        strongSelf->_immediatePinnedMessage = message.mid;
                        TGModernConversationController *controller = strongSelf.controller;
                        if (message == nil) {
                            [controller setSecondaryTitlePanel:nil animated:true];
                        } else {
                            if (strongSelf->_pinnedMessagePanel.message == message)
                            {
                                [strongSelf->_pinnedMessagePanel setMessageCount:MAX((NSUInteger)1, strongSelf->_pinnedMessages.count)];
                                resultPanel = strongSelf->_pinnedMessagePanel;
                            }
                            else
                            {
                                TGPinnedMessageTitlePanel *panel = [[TGPinnedMessageTitlePanel alloc] initWithMessage:message];
                                strongSelf->_pinnedMessagePanel = panel;
                                [panel setMessageCount:MAX((NSUInteger)1, strongSelf->_pinnedMessages.count)];
                                
                                panel.dismiss = ^{
                                    __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                                    if (strongSelf != nil) {
                                        if ([strongSelf canPinMessage:message]) {
                                            [[[[strongSelf updatePinnedMessage:0] deliverOn:[SQueue mainQueue]] onDispose:^{
                                            }] startWithNext:nil error:^(__unused id error) {
                                                NSString *errorText = TGLocalized(@"Login.UnknownError");
                                                [TGCustomAlertView presentAlertWithTitle:nil message:errorText cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
                                            } completed:^{
                                            }];
                                        } else {
                                            strongSelf->_hiddenPinnedMessageId = message.mid;
                                            [strongSelf->_pinnedMessagesVariable set:[SSignal single:strongSelf->_pinnedMessages]];
                                            [TGDatabaseInstance() updateChannelPinnedMessageId:conversationId pinnedMessageId:message.mid hidden:@(true)];
                                        }
                                    }
                                };
                                panel.tapped = ^{
                                    __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                                    if (strongSelf != nil) {
                                        if (strongSelf->_pinnedMessages.count > 1)
                                            [strongSelf _presentPinnedMessagesMenuFromPanel:strongSelf->_pinnedMessagePanel];
                                        else
                                            [strongSelf _navigateToPinnedMessage:message];
                                    }
                                };
                                strongSelf->_pinnedMessagePanel = panel;
                                resultPanel = panel;
                            }
                        }
                    }
                }
                
                return resultPanel;
            } else {
                return nil;
            }
        }];
        
        [_primaryPanel set:panelSignal];
        
        _updatedPeerSettingsDisposable = [[TGAccountSignals updatedShouldReportSpamForPeer:_conversationId accessHash:_accessHash] startWithNext:nil];
    }
    return self;
}

- (void)dealloc {
    [_requestingHoleDisposable dispose];
    [_managedState dispose];
    [_extendedDataDisposable dispose];
    [_cachedDataDisposable dispose];
    [_updatedAdminsDisposable dispose];
    [_updatingInvalidatedMessagesDisposable dispose];
    [_genericInfoDisposables dispose];
    [_groupedUserStatusesDisposable dispose];
    [_updatedPeerSettingsDisposable dispose];
    [_pinnedMessagesDisposable dispose];
}

- (void)setMemberCount:(int32_t)memberCount {
    if (_memberCount != memberCount) {
        _memberCount = memberCount;
        [self updateStatus];
    }
}

- (void)setMigrationData:(TGConversationMigrationData *)migrationData {
    [TGModernConversationCompanion dispatchOnMessageQueue:^{
        _migrationData = migrationData;
        _attachedConversationId = _migrationData.peerId;
        
        if (_migrationData != nil && !_migrationHistoryAbove) {
            _migrationHistoryAbove = true;
            if (!_loadingHistoryAbove) {
                TGDispatchOnMainThread(^{
                    [self loadMoreMessagesAbove];
                });
            }
        }
    }];
}

- (void)setHasBots:(bool)hasBots {
    hasBots = _isGroup && hasBots;
    TGDispatchOnMainThread(^{
        if (_hasBots != hasBots) {
            _hasBots = hasBots;
            
            self.viewContext.commandsEnabled = hasBots;
            TGModernConversationController *controller = self.controller;
            [controller setHasBots:_hasBots];
        }
    });
}

- (void)setAdminIds:(NSSet *)adminIds {
    if (![_adminIds isEqualToSet:adminIds]) {
        _adminIds = adminIds;
        
        [TGModernConversationCompanion dispatchOnMessageQueue:^
         {
             self.viewContext.adminIds = adminIds;
             
             NSMutableArray *updatedItems = [[NSMutableArray alloc] init];
             NSMutableArray *updatedIndices = [[NSMutableArray alloc] init];
             
             for (NSUInteger i = 0; i < _items.count; i++)
             {
                 TGMessageModernConversationItem *item = _items[i];
                 
                 bool byAdmin = [self.viewContext isByAdmin:item->_message];
                 if (item->_byAdmin != byAdmin)
                 {
                     item = [item copy];
                     [updatedItems addObject:item];
                     [updatedIndices addObject:@(i)];
                 }
             }
          
             if (updatedItems.count != 0)
             {
                 TGDispatchOnMainThread(^
                 {
                     TGModernConversationController *controller = self.controller;
                     int index = -1;
                     for (NSNumber *nIndex in updatedIndices)
                     {
                         index++;
                         [controller updateItemAtIndex:[nIndex intValue] toItem:updatedItems[index] delayAvailability:false animated:true animateTransition:false force:true];
                     }
                 });
             }
         }];
    }
}

- (void)_controllerDidAppear:(bool)firstTime {
    [super _controllerDidAppear:firstTime];
    [self _ios6ScheduleReadHistoryFromChannelAppear:firstTime ? @"firstAppear" : @"appear"];
    [self _updatePinnedMessagesFromConversationItems];
    [self _refreshPinnedMessages];
    
    if (firstTime) {
        _managedState = [[TGChannelStateSignals updatedChannel:_conversationId] startWithNext:nil];
        
        _enableVisibleMessagesProcessing = true;
        
        _extendedDataDisposable = [[TGChannelManagementSignals updateChannelExtendedInfo:_conversationId accessHash:_accessHash updateUnread:false] startWithNext:nil];
        
        if (!_isGroup && _isForbidden) {
            [TGCustomAlertView presentAlertWithTitle:nil message:[NSString stringWithFormat:TGLocalized(@"ChannelInfo.ChannelForbidden"), _conversation.chatTitle] cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
        }
        
        if (_invalidatedPtsDisposable == nil) {
            __weak TGChannelConversationCompanion *weakSelf = self;
            _invalidatedPtsDisposable = [[TGDatabaseInstance() channelHistoryPtsForPeerId:_conversationId] startWithNext:^(NSNumber *nInvalidatedPts) {
                [TGModernConversationCompanion dispatchOnMessageQueue:^{
                    __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                    if (strongSelf != nil) {
                        [strongSelf setInvalidatedPts:[nInvalidatedPts intValue]];
                    }
                }];
            }];
        }
        
        [TGModernConversationCompanion dispatchOnMessageQueue:^{
            [self _updateVisibleHoles];
        }];
    }
}

- (void)_controllerAvatarPressed
{
    TGModernConversationController *controller = self.controller;
    TGCollectionMenuController *groupInfoController = nil;
    if (_isGroup) {
        groupInfoController = [[TGChannelGroupInfoController alloc] initWithPeerId:_conversationId];
    } else {
        groupInfoController = [[TGChannelInfoController alloc] initWithPeerId:_conversationId];
    }
    
    if (controller.currentSizeClass == UIUserInterfaceSizeClassCompact) {
        [controller.navigationController pushViewController:groupInfoController animated:true];
    }
    else
    {
        if (controller != nil)
        {
            TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[groupInfoController] navigationBarClass:[TGWhiteNavigationBar class]];
            navigationController.presentationStyle = TGNavigationControllerPresentationStyleRootInPopover;
            TGPopoverController *popoverController = [[TGPopoverController alloc] initWithContentViewController:navigationController];
            navigationController.parentPopoverController = popoverController;
            navigationController.detachFromPresentingControllerInCompactMode = true;
            [popoverController setContentSize:CGSizeMake(320.0f, 528.0f)];
            
            controller.associatedPopoverController = popoverController;
            [popoverController presentPopoverFromBarButtonItem:controller.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:true];
            groupInfoController.collectionView.contentOffset = CGPointMake(0.0f, -groupInfoController.collectionView.contentInset.top);
        }
    }
}

- (void)_createOrUpdatePrimaryTitlePanel:(bool)__unused createIfNeeded
{
    TGModernConversationController *controller = self.controller;
    
    TGModernConversationGroupTitlePanel *groupTitlePanel = nil;
    if ([[controller primaryTitlePanel] isKindOfClass:[TGModernConversationGroupTitlePanel class]])
        groupTitlePanel = (TGModernConversationGroupTitlePanel *)[controller primaryTitlePanel];
    else
    {
        if (createIfNeeded)
        {
            groupTitlePanel = [[TGModernConversationGroupTitlePanel alloc] init];
            groupTitlePanel.companionHandle = self.actionHandle;
        }
        else
            return;
    }
    
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    TGPresentation *presentation = self.controller.presentation;
    [actions addObject:@{@"title": TGLocalized(@"Conversation.Search"), @"icon": presentation.images.chatTitleSearchIcon, @"action": @"search"}];
    if (_isGroup && _conversation.username.length != 0) {
        [actions addObject:@{@"title": TGLocalized(@"ReportPeer.Report"), @"icon": presentation.images.chatTitleReportIcon, @"action": @"report"}];
    }
    if (_isMuted)
        [actions addObject:@{@"title": TGLocalized(@"Conversation.Unmute"), @"icon": presentation.images.chatTitleUnmuteIcon, @"action": @"unmute"}];
    else
        [actions addObject:@{@"title": TGLocalized(@"Conversation.Mute"), @"icon": presentation.images.chatTitleMuteIcon, @"action": @"mute"}];
    [actions addObject:@{@"title": TGLocalized(@"Conversation.Info"), @"icon": presentation.images.chatTitleInfoIcon, @"action": @"info"}];
    [groupTitlePanel setPresentation:presentation];
    [groupTitlePanel setButtonsWithTitlesAndActions:actions];
    
    [controller setPrimaryTitlePanel:groupTitlePanel];
}

- (void)_loadControllerPrimaryTitlePanel {
    [self _createOrUpdatePrimaryTitlePanel:true];
}

- (TGModernConversationInputPanel *)_conversationGenericInputPanel {
    TGPresentation *presentation = self.controller.presentation;
    if (_bannedRights != nil && _bannedRights.banSendMessages) {
        if (_restrictedPanel == nil) {
            _restrictedPanel = [[TGModernConversationRestrictedInputPanel alloc] init];
        }
        [_restrictedPanel setTimeout:_bannedRights.timeout];
        return _restrictedPanel;
    } else if (_isForbidden) {
        if (_deletePanel == nil) {
            TGModernConversationController *controller = self.controller;
            _deletePanel = [[TGModernConversationActionInputPanel alloc] init];
            [_deletePanel setActionWithTitle:TGLocalized(@"DialogList.DeleteConversationConfirmation") action:@"delete" color:presentation.pallete.accentColor icon:TGModernConversationActionInputPanelIconNone];
            _deletePanel.companionHandle = self.actionHandle;
            _deletePanel.delegate = controller;
        }
        return _deletePanel;
    } else if (_kind != TGConversationKindPersistentChannel)
    {
        if (_joinChannelPanel == nil)
        {
            TGModernConversationController *controller = self.controller;
            _joinChannelPanel = [[TGModernConversationActionInputPanel alloc] init];
            [_joinChannelPanel setActionWithTitle:TGLocalized(@"Channel.JoinChannel") action:@"joinchannel" color:presentation.pallete.accentColor icon:TGModernConversationActionInputPanelIconJoin];
            _joinChannelPanel.companionHandle = self.actionHandle;
            _joinChannelPanel.delegate = controller;
        }
        return _joinChannelPanel;
    } else if (![self canPostMessages]) {
        if (_mutePanel == nil) {
            TGModernConversationController *controller = self.controller;
            _mutePanel = [[TGModernConversationActionInputPanel alloc] init];
            [_mutePanel setActionWithTitle:!_isMuted ? TGLocalized(@"Conversation.Mute") : TGLocalized(@"Conversation.Unmute") action:@"toggleMute" color:presentation.pallete.accentColor icon:TGModernConversationActionInputPanelIconNone];
            _mutePanel.companionHandle = self.actionHandle;
            _mutePanel.delegate = controller;
        }
        return _mutePanel;
    }
    
    return nil;
}
               
- (bool)canPostMessages {
    if (_isGroup) {
        return true;
    } else {
        return _isCreator || _adminRights.canPostMessages;
    }
}

- (void)_updateJoinPanel {
    TGModernConversationController *controller = self.controller;
    [controller setDefaultInputPanel:[self _conversationGenericInputPanel]];
}

- (void)actionStageActionRequested:(NSString *)action options:(id)options {
    if ([action isEqualToString:@"titlePanelAction"]) {
        NSString *panelAction = options[@"action"];
        
        if ([panelAction isEqualToString:@"switchMode"]) {
            [self _toggleTitleMode];
        } else if ([panelAction isEqualToString:@"mute"]) {
            [self _commitEnableNotifications:false];
        } else if ([panelAction isEqualToString:@"unmute"]) {
            [self _commitEnableNotifications:true];
        } else if ([panelAction isEqualToString:@"edit"]) {
            [self.controller enterEditingMode];
        } else if ([panelAction isEqualToString:@"report"]) {
            [self reportChannelPressed];
        } else if ([panelAction isEqualToString:@"info"]) {
            [self _controllerAvatarPressed];
        } else if ([panelAction isEqualToString:@"search"]) {
            [self navigateToMessageSearch];
        }
    } else if ([action isEqualToString:@"openMessageGroup"]) {
    } else if ([action isEqualToString:@"actionPanelAction"]) {
        NSString *panelAction = options[@"action"];
        if ([panelAction isEqualToString:@"joinchannel"]) {
            [self requestJoinChannel];
            
            [TGAppDelegateInstance.rootController.dialogListController maybeDismissSearchResults];
        } else if ([panelAction isEqualToString:@"toggleMute"]) {
            [self _commitEnableNotifications:_isMuted];
        } else if ([panelAction isEqualToString:@"delete"]) {
            TGModernConversationController *controller = self.controller;
            
            [TGAppDelegateInstance.rootController.dialogListController.dialogListCompanion deleteItem:[[TGConversation alloc] initWithConversationId:_conversationId unreadCount:0 serviceUnreadCount:0] animated:false];
            
            if (controller.popoverController != nil) {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [controller.popoverController dismissPopoverAnimated:true];
                });
            }
            else {
                [controller.navigationController popToRootViewControllerAnimated:true];
            }
        }
    }

    [super actionStageActionRequested:action options:options];
}

- (void)_commitEnableNotifications:(bool)enable
{
    if (_isMuted != !enable) {
        _isMuted = !enable;
        
        [_mutePanel setActionWithTitle:!_isMuted ? TGLocalized(@"Conversation.Mute") : TGLocalized(@"Conversation.Unmute") action:@"toggleMute" color:self.controller.presentation.pallete.accentColor icon:TGModernConversationActionInputPanelIconNone];
        
        NSNumber *muteUntil = enable ? @0: @(INT32_MAX);
        _groupNotificationSettings[@"muteUntil"] = muteUntil;
        
        static int actionId = 0;
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/changePeerSettings/(%" PRId64 ")/(channelControllerMute%d)", _conversationId, actionId++] options:@{@"peerId": @(_conversationId), @"accessHash": @(_accessHash), @"muteUntil": muteUntil} watcher:TGTelegraphInstance];
        
        [self _updateNotifcationSettings];
    }
}

- (void)_updateChannelMute
{
    TGDispatchOnMainThread(^
    {
        if (_isMuted)
        {
            TGModernConversationTitleIcon *muteIcon = [[TGModernConversationTitleIcon alloc] init];
            muteIcon.bounds = CGRectMake(0.0f, 0.0f, 16, 16);
            muteIcon.offsetWeight = 0.5f;
            muteIcon.imageOffset = CGPointMake(4.0f, 7.0f);
            
            muteIcon.image = self.controller.presentation.images.chatTitleMutedIcon;
            muteIcon.iconPosition = TGModernConversationTitleIconPositionAfterTitle;
            [self _setTitleIcons:@[muteIcon]];
        }
        else
            [self _setTitleIcons:nil];
        
        [self _createOrUpdatePrimaryTitlePanel:false];
    });
}

- (NSString *)title
{
    return [self titleForConversation:_conversation];
}

- (void)loadInitialState {
    [super loadInitialState:false];
    
    TGModernConversationController *controller = self.controller;
    if (!_isGroup) {
        [controller setIsChannel:true];
    }
    
    [controller setConversationHeader:[self _conversationHeader]];
    
    self.viewContext.isPublicGroup = _conversation.isChannelGroup && _conversation.username.length != 0;
    
    if (!_isGroup) {
        if (_isCreator || _adminRights.canPostMessages) {
            [controller setCanBroadcast:true];
            [self updateBroadcasting];
            [controller setIsAlwaysBroadcasting:false];
        } else {
            [controller setCanBroadcast:false];
            [controller setIsBroadcasting:false];
            [controller setIsAlwaysBroadcasting:true];
        }
    }
    
    [controller setBannedStickers:_bannedRights.banSendStickers];
    [controller setBannedMedia:_bannedRights.banSendMedia];
    
    self.viewContext.conversation = _conversation;
    
    __block NSArray *topMessages = nil;
    __block NSArray *topMigrationMessages = nil;
    __block TGConversationMigrationData *migrationData = nil;
    __block int32_t missingPreloadedAreaAtMessageId = 0;
    __block int32_t messageIdForVisibleHoleDirection = 0;
    __block int32_t earliestUnreadMessageId = 0;
    NSUInteger initialChannelMessageCount = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? 20 : 28;
    
    [TGDatabaseInstance() dispatchOnDatabaseThread:^{
        __block TGMessageTransparentSortKey maxSortKey = TGMessageTransparentSortKeyUpperBound(_conversationId);
        
        bool canBeUnread = _conversation.kind == TGConversationKindPersistentChannel && (_conversation.unreadCount != 0 || (_displayVariant == TGChannelDisplayVariantAll && _conversation.serviceUnreadCount != 0));
        
        if (_preferredInitialPositionedMessageId != 0) {
            [TGDatabaseInstance() channelMessageExists:_conversationId messageId:_preferredInitialPositionedMessageId completion:^(bool exists, TGMessageSortKey key) {
                if (exists) {
                    if (TGMessageSortKeySpace(key) == TGMessageSpaceUnimportant) {
                        _displayVariant = TGChannelDisplayVariantAll;
                    }
                    maxSortKey = TGMessageTransparentSortKeyMake(_conversationId, TGMessageSortKeyTimestamp(key), TGMessageSortKeyMid(key), TGMessageSortKeySpace(key));
                    if (_initialScrollState == nil || _initialScrollState.messageId == 0) {
                        [self setInitialMessagePositioning:TGMessageSortKeyMid(key) initialPositionedPeerId:0 position:TGInitialScrollPositionCenter offset:0.0f];
                    }
                    messageIdForVisibleHoleDirection = TGMessageSortKeyMid(key);
                }
            }];
        } else if (canBeUnread) {
            if ([TGChannelManagementSignals _containsPreloadedHistoryForPeerId:_conversationId aroundMessageId:_conversation.maxReadMessageId]) {
                [TGDatabaseInstance() nextChannelIncomingMessageKey:_conversationId messageId:_conversation.maxReadMessageId + 1 completion:^(bool exists, TGMessageSortKey key) {
                    if (exists) {
                        maxSortKey = TGMessageTransparentSortKeyMake(_conversationId, TGMessageSortKeyTimestamp(key), TGMessageSortKeyMid(key), TGMessageSortKeySpace(key));
                        [self setInitialMessagePositioning:TGMessageSortKeyMid(key) initialPositionedPeerId:0 position:TGInitialScrollPositionTop offset:[self.controller initialUnreadOffset]];
                        
                        TGMessageRange unreadRange = TGMessageRangeEmpty();
                        
                        unreadRange.firstDate = TGMessageSortKeyTimestamp(key);
                        unreadRange.lastDate = INT32_MAX;
                        unreadRange.firstMessageId = TGMessageSortKeyMid(key);
                        unreadRange.lastMessageId = INT32_MAX;
                        
                        self.unreadMessageRange = unreadRange;
                        
                        messageIdForVisibleHoleDirection = TGMessageSortKeyMid(key);
                    }
                }];
            } else {
                missingPreloadedAreaAtMessageId = _conversation.maxReadMessageId;
            }
        }
        
        TGCachedConversationData *cachedData = [TGDatabaseInstance() _channelCachedDataSync:_conversationId];
        migrationData = cachedData.migrationData;
        _hasBots = _isGroup && cachedData.botInfos.count != 0;
        
        if (missingPreloadedAreaAtMessageId != 0) {
        } else {
            [TGDatabaseInstance() channelMessages:_conversationId maxTransparentSortKey:maxSortKey count:(int)initialChannelMessageCount important:_displayVariant == TGChannelDisplayVariantImportant mode:TGChannelHistoryRequestAround completion:^(NSArray *messages, bool hasLater) {
                topMessages = messages;
                _historyBelow = hasLater;
            }];
            
            
            if (topMessages.count < initialChannelMessageCount && migrationData != nil) {
                [TGDatabaseInstance() loadMessagesFromConversation:migrationData.peerId maxMid:migrationData.maxMessageId maxDate:TGMessageTransparentSortKeyTimestamp(maxSortKey) maxLocalMid:0 atMessageId:0 limit:(int)initialChannelMessageCount extraUnread:false completion:^(NSArray *messages, __unused bool historyExistsBelow) {
                    NSMutableArray *updatedMessages = [[NSMutableArray alloc] init];
                    
                    for (TGMessage *message in messages) {
                        if (message.mid < TGMessageLocalMidBaseline) {
                            message.mid += migratedMessageIdOffset;
                            [updatedMessages addObject:message];
                        }
                    }
                    
                    topMigrationMessages = updatedMessages;
                }];
            }
        }
    } synchronous:true];
    _historyAbove = topMessages.count != 0;
    _migrationData = migrationData;
    _attachedConversationId = _migrationData.peerId;
    _migrationHistoryAbove = topMigrationMessages.count != 0;
    self.viewContext.commandsEnabled = _hasBots;
    
    if (missingPreloadedAreaAtMessageId == 0) {
        [self _replaceMessages:[topMessages arrayByAddingObjectsFromArray:topMigrationMessages] atMessageId:0 peerId:0 expandFrom:0 jump:false top:false messageIdForVisibleHoleDirection:messageIdForVisibleHoleDirection scrollBackMessageId:0 animated:false];
        if (earliestUnreadMessageId != 0) {
            [controller pushEarliestUnreadMessageId:earliestUnreadMessageId];
        }
        
        if (topMessages.count < initialChannelMessageCount) {
            int64_t conversationId = _conversationId;
            int64_t accessHash = _accessHash;
            bool important = _displayVariant == TGChannelDisplayVariantImportant;
            __weak TGChannelConversationCompanion *weakSelf = self;
            
            IOS6Trace(@"IOS6FULL channel.coldTailPreload.start peer=%lld access=%lld local=%d important=%d", conversationId, accessHash, (int)topMessages.count, important ? 1 : 0);
            [controller setLoadingMessages:true];
            
            [[[TGChannelManagementSignals preloadedHistoryTailForPeerId:conversationId accessHash:accessHash] deliverOn:[SQueue mainQueue]] startWithNext:^(NSDictionary *dict) {
                __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                if (strongSelf == nil) {
                    return;
                }
                
                NSArray *remoteMessages = dict[@"messages"];
                IOS6Trace(@"IOS6FULL channel.coldTailPreload.result peer=%lld remote=%d", conversationId, (int)remoteMessages.count);
                if (remoteMessages.count == 0) {
                    [strongSelf.controller setLoadingMessages:false];
                    return;
                }
                
                NSArray *removedImportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                NSArray *removedUnimportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                
                [TGDatabaseInstance() addMessagesToChannel:conversationId messages:remoteMessages deleteMessages:nil unimportantGroups:dict[@"unimportantGroups"] addedHoles:nil removedHoles:removedImportantHoles removedUnimportantHoles:removedUnimportantHoles updatedMessageSortKeys:nil returnGroups:false keepUnreadCounters:false skipFeedUpdate:true changedMessages:^(__unused NSArray *addedMessages, __unused NSArray *removedMessages, __unused NSDictionary *updatedMessages, __unused NSArray *addedUnimportantHoles, __unused NSArray *removedUnimportantHoles) {
                    [TGModernConversationCompanion dispatchOnMessageQueue:^{
                        __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                        if (strongSelf == nil) {
                            return;
                        }
                        
                        strongSelf->_historyAbove = true;
                        [strongSelf reloadVariantAtSortKey:TGMessageTransparentSortKeyUpperBound(conversationId) group:nil jump:false top:false messageIdForVisibleHoleDirection:0 scrollBackMessageId:0 animated:false];
                    }];
                }];
            } error:^(__unused id error) {
                __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                IOS6Trace(@"IOS6FULL channel.coldTailPreload.error peer=%lld error=%@", conversationId, error);
                [strongSelf.controller setLoadingMessages:false];
            } completed:nil];
        }
        
        if (_accessHash != 0 && _conversationId < -4294967296LL && topMessages.count != 0) {
            int64_t conversationId = _conversationId;
            int64_t accessHash = _accessHash;
            NSArray *localTopMessages = [topMessages copy];
            __weak TGChannelConversationCompanion *weakSelf = self;
            
            SMetaDisposable *tailRefreshDisposable = [[SMetaDisposable alloc] init];
            [TGTelegraphInstance.disposeOnLogout add:tailRefreshDisposable];
            __weak SMetaDisposable *weakTailRefreshDisposable = tailRefreshDisposable;
            
            [tailRefreshDisposable setDisposable:[[TGChannelManagementSignals preloadedHistoryTailForPeerId:conversationId accessHash:accessHash] startWithNext:^(NSDictionary *dict) {
                NSArray *remoteMessages = dict[@"messages"];
                if (remoteMessages.count == 0) {
                    return;
                }
                
                NSMutableSet *remoteMessageIds = [[NSMutableSet alloc] init];
                int32_t minRemoteMessageId = 0;
                for (TGMessage *message in remoteMessages) {
                    if (message.mid != 0) {
                        [remoteMessageIds addObject:@(message.mid)];
                        if (minRemoteMessageId == 0 || minRemoteMessageId > message.mid) {
                            minRemoteMessageId = message.mid;
                        }
                    }
                }
                
                if (minRemoteMessageId == 0) {
                    return;
                }
                
                NSMutableArray *deletedMessageIds = [[NSMutableArray alloc] init];
                for (TGMessage *message in localTopMessages) {
                    if (message.mid >= minRemoteMessageId && ![remoteMessageIds containsObject:@(message.mid)]) {
                        [deletedMessageIds addObject:@(message.mid)];
                    }
                }
                
                if (deletedMessageIds.count == 0) {
                    IOS6Trace(@"IOS6TRACE channelTailReconcile peer=%lld remote=%d local=%d delete=0", conversationId, (int)remoteMessages.count, (int)localTopMessages.count);
                    return;
                }
                
                IOS6Trace(@"IOS6TRACE channelTailReconcile peer=%lld remote=%d local=%d minRemote=%d delete=%@", conversationId, (int)remoteMessages.count, (int)localTopMessages.count, minRemoteMessageId, deletedMessageIds);
                
                [TGDatabaseInstance() dispatchOnDatabaseThread:^{
                    [TGDatabaseInstance() addMessagesToChannel:conversationId messages:remoteMessages deleteMessages:deletedMessageIds unimportantGroups:nil addedHoles:nil removedHoles:nil removedUnimportantHoles:nil updatedMessageSortKeys:nil returnGroups:false keepUnreadCounters:false skipFeedUpdate:false changedMessages:^(__unused NSArray *addedMessages, NSArray *removedMessages, NSDictionary *updatedMessages, __unused NSArray *addedUnimportantHoles, __unused NSArray *removedUnimportantHoles) {
                        __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                        if (strongSelf == nil) {
                            return;
                        }
                        
                        NSMutableArray *removedImportantMessages = [[NSMutableArray alloc] initWithArray:removedMessages];
                        NSMutableArray *removedUnimportantMessages = [[NSMutableArray alloc] initWithArray:removedMessages];
                        
                        [ActionStageInstance() dispatchResource:[NSString stringWithFormat:@"/tg/conversation/(%lld)/importantMessages", conversationId] resource:@{@"removed": removedImportantMessages, @"added": @[], @"updated": updatedMessages == nil ? @{} : updatedMessages}];
                        [ActionStageInstance() dispatchResource:[NSString stringWithFormat:@"/tg/conversation/(%lld)/unimportantMessages", conversationId] resource:@{@"removed": removedUnimportantMessages, @"added": @[], @"updated": updatedMessages == nil ? @{} : updatedMessages}];
                    }];
                } synchronous:false];
            } error:^(__unused id error) {
                __strong SMetaDisposable *strongTailRefreshDisposable = weakTailRefreshDisposable;
                if (strongTailRefreshDisposable != nil) {
                    [TGTelegraphInstance.disposeOnLogout remove:strongTailRefreshDisposable];
                }
            } completed:^{
                __strong SMetaDisposable *strongTailRefreshDisposable = weakTailRefreshDisposable;
                if (strongTailRefreshDisposable != nil) {
                    [TGTelegraphInstance.disposeOnLogout remove:strongTailRefreshDisposable];
                }
            }]];
        }
    } else {
        self.useInitialSnapshot = false;
    }
    
    [self _setTitle:[self titleForConversation:_conversation] andStatus:_isGroup ? TGLocalized(@"Group.Status") : TGLocalized(@"Channel.Status") accentColored:false allowAnimatioon:false toggleMode:[self currentToggleMode]];
    [self _setAvatarConversationId:_conversationId title:_conversation.chatTitle icon:nil];
    [self _setAvatarUrl:_conversation.chatPhotoFullSmall];
    
    if (_initialUserActivities.count != 0) {
        [self _setTypingStatus:[self stringForUserActivities:_initialUserActivities] activity:[self activityTypeForActivities:_initialUserActivities]];
    }
    
    [controller setHasBots:_hasBots];
    
    if (missingPreloadedAreaAtMessageId != 0) {
        [controller setLoadingMessages:true];
        
        if (_requestingHoleDisposable == nil) {
            _requestingHoleDisposable = [[SMetaDisposable alloc] init];
        }
        
        __weak TGChannelConversationCompanion *weakSelf = self;
        [_requestingHoleDisposable setDisposable:[[TGChannelManagementSignals preloadedHistoryForPeerId:_conversationId accessHash:_accessHash aroundMessageId:missingPreloadedAreaAtMessageId] startWithNext:^(NSDictionary *dict) {
            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
            if (strongSelf != nil) {
                NSArray *removedImportantHoles = nil;
                NSArray *removedUnimportantHoles = nil;
                
                removedImportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                removedUnimportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                
                [TGDatabaseInstance() addMessagesToChannel:strongSelf->_conversationId messages:dict[@"messages"] deleteMessages:nil unimportantGroups:dict[@"unimportantGroups"] addedHoles:nil removedHoles:removedImportantHoles removedUnimportantHoles:removedUnimportantHoles updatedMessageSortKeys:nil returnGroups:false keepUnreadCounters:false skipFeedUpdate:true changedMessages:^(__unused NSArray *addedMessages, __unused NSArray *removedMessages, __unused NSDictionary *updatedMessages, __unused NSArray *addedUnimportantHoles, __unused NSArray *removedUnimportantHoles) {
                    __block TGMessageTransparentSortKey messageKey = TGMessageTransparentSortKeyUpperBound(strongSelf->_conversationId);
                    [TGDatabaseInstance() dispatchOnDatabaseThread:^{
                        [TGDatabaseInstance() channelMessageExists:strongSelf->_conversationId messageId:missingPreloadedAreaAtMessageId completion:^(bool exists, TGMessageSortKey key) {
                            if (exists) {
                                messageKey = TGMessageTransparentSortKeyMake(TGMessageSortKeyPeerId(key), TGMessageSortKeyTimestamp(key), TGMessageSortKeyMid(key), TGMessageSortKeySpace(key));
                            }
                        }];
                    } synchronous:true];
                    
                    [TGModernConversationCompanion dispatchOnMessageQueue:^{
                        __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                        if (strongSelf != nil) {
                            /*strongSelf->_displayVariant = TGChannelDisplayVariantImportant;
                            [TGDatabaseInstance() updateChannelDisplayExpanded:strongSelf->_conversationId displayExpanded:true];*/
                            
                            TGDispatchOnMainThread(^{
                                TGMessageRange unreadRange = TGMessageRangeEmpty();
                                
                                unreadRange.firstDate = TGMessageTransparentSortKeyTimestamp(messageKey);
                                unreadRange.lastDate = INT32_MAX;
                                unreadRange.firstMessageId = TGMessageTransparentSortKeyMid(messageKey) + 1;
                                unreadRange.lastMessageId = INT32_MAX;
                                
                                strongSelf.unreadMessageRange = unreadRange;
                                
                                messageIdForVisibleHoleDirection = TGMessageTransparentSortKeyMid(messageKey) + 1;
                                
                                TGModernConversationController *controller = strongSelf.controller;
                                if (earliestUnreadMessageId != 0) {
                                    [controller pushEarliestUnreadMessageId:earliestUnreadMessageId];
                                }
                            });
                            
                            [strongSelf reloadVariantAtSortKey:messageKey group:nil jump:false top:true messageIdForVisibleHoleDirection:messageIdForVisibleHoleDirection scrollBackMessageId:0 animated:false];
                        }
                    }];
                }];
            }
        }]];
    }
}

- (TGModernConversationControllerTitleToggle)currentToggleMode {
    return TGModernConversationControllerTitleToggleNone;
}

- (void)updateStatus {
    NSString *text = _isGroup ? TGLocalized(@"Group.Status") : TGLocalized(@"Channel.Status");
    if (_isForbidden) {
        text = _isGroup ? TGLocalized(@"Conversation.StatusKickedFromGroup") : TGLocalized(@"Conversation.StatusKickedFromChannel");
    } else if (_isGroup && _groupedOnlineInfo != nil) {
        text = [self stringForMemberCount:_memberCount onlineCount:(int)_groupedOnlineInfo.onlineCount];
    } else if (_memberCount != 0) {
        text = _isGroup ? [self stringForMemberCount:_memberCount] : [self stringForSubscriberCount:_memberCount];
    }
    
    [self _setStatus:text accentColored:false allowAnimation:false toggleMode:[self currentToggleMode]];
}

- (id)stringForMemberCount:(int)memberCount onlineCount:(int)onlineCount
{
    if (onlineCount <= 1)
        return [self stringForMemberCount:memberCount];
    else
    {
        NSString *firstPart = [[NSString alloc] initWithFormat:@"%@, ", [self stringForMemberCount:memberCount]];
        NSString *secondPart = [self stringForOnlineCount:onlineCount];
        NSString *combinedString = [firstPart stringByAppendingString:secondPart];
        
        //NSRange range1 = NSMakeRange(firstPart.length, secondPart.length);
        //NSRange range2 = [combinedString rangeOfString:secondPart];
        
        return combinedString;
        
        /*NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[firstPart stringByAppendingString:secondPart]];
         [attributedString addAttribute:NSForegroundColorAttributeName value:TGAccentColor() range:NSMakeRange(firstPart.length, secondPart.length)];
         return attributedString;*/
    }
}

- (NSString *)stringForOnlineCount:(int)onlineCount
{
    return [effectiveLocalization() getPluralized:@"Conversation.StatusOnline" count:(int32_t)onlineCount];
}

- (NSString *)stringForMemberCount:(int)memberCount
{
    return [effectiveLocalization() getPluralized:@"Conversation.StatusMembers" count:(int32_t)memberCount];
}

- (NSString *)stringForSubscriberCount:(int)subscriberCount
{
    return [effectiveLocalization() getPluralized:@"Conversation.StatusSubscribers" count:(int32_t)subscriberCount];
}

- (void)reloadVariantAtSortKey:(TGMessageTransparentSortKey)sortKey group:(TGMessageGroup *)group jump:(bool)jump top:(bool)top messageIdForVisibleHoleDirection:(int32_t)messageIdForVisibleHoleDirection scrollBackMessageId:(int32_t)scrollBackMessageId animated:(bool)animated {
    TGDispatchOnMainThread(^{
        [self updateStatus];
    });
    
    [TGModernConversationCompanion dispatchOnMessageQueue:^{
        _enableVisibleMessagesProcessing = true;
        _visibleHoles = nil;
        [_requestingHoleDisposable setDisposable:nil];
        _requestingHole = nil;
        _loadingHistoryAbove = false;
        _historyAbove = false;
        _loadingHistoryBelow = false;
        _historyBelow = false;
        _migrationHistoryAbove = false;
        
        [self _updateControllerHistoryRequestsFlags];
        
        [TGDatabaseInstance() dispatchOnDatabaseThread:^{
            __block TGMessageTransparentSortKey updatedSortKey = sortKey;
            
            if (group != nil) {
                [TGDatabaseInstance() channelEarlierMessage:_conversationId messageId:group.maxId timestamp:group.maxTimestamp important:true completion:^(bool exists, TGMessageSortKey key) {
                    if (exists) {
                        updatedSortKey = TGMessageTransparentSortKeyMake(_conversationId, TGMessageSortKeyTimestamp(key), TGMessageSortKeyMid(key), TGMessageSortKeySpace(key));
                    }
                }];
            } else if (_displayVariant == TGChannelDisplayVariantImportant && TGMessageTransparentSortKeySpace(sortKey) == TGMessageSpaceUnimportant) {
                [TGDatabaseInstance() channelEarlierMessage:_conversationId messageId:TGMessageTransparentSortKeyMid(sortKey) timestamp:TGMessageTransparentSortKeyTimestamp(sortKey) important:true completion:^(bool exists, TGMessageSortKey key) {
                    if (exists) {
                        updatedSortKey = TGMessageTransparentSortKeyMake(_conversationId, TGMessageSortKeyTimestamp(key), TGMessageSortKeyMid(key), TGMessageSortKeySpace(key));
                    }
                }];
            }
            
            [TGDatabaseInstance() channelMessages:_conversationId maxTransparentSortKey:updatedSortKey count:60 important:_displayVariant == TGChannelDisplayVariantImportant mode:TGChannelHistoryRequestAround completion:^(NSArray *messages, bool hasLater) {
                [TGModernConversationCompanion dispatchOnMessageQueue:^{
                    _historyAbove = messages.count != 0;
                    _historyBelow = hasLater;
                    _migrationHistoryAbove = _migrationData.peerId != 0;
                    
                    int32_t atMessageId = 0;
                    for (TGMessage *message in messages) {
                        if (TGMessageTransparentSortKeyCompare(message.transparentSortKey, updatedSortKey) <= 0) {
                            atMessageId = message.mid;
                            break;
                        }
                    }
                    
                    if (atMessageId != 0) {
                        TGLog(@"Reloading at %d", atMessageId);
                    }
                    [self _replaceMessages:messages atMessageId:atMessageId peerId:0 expandFrom:-group.maxId jump:jump top:top messageIdForVisibleHoleDirection:messageIdForVisibleHoleDirection scrollBackMessageId:scrollBackMessageId animated:animated];
                    [self _updateControllerHistoryRequestsFlags];
                    
                    TGDispatchOnMainThread(^{
                        TGModernConversationController *controller = self.controller;
                        [controller setLoadingMessages:false];
                    });
                }];
            }];
        } synchronous:false];
    }];
}

- (bool)imageDownloadsShouldAutosavePhotos
{
    TGAutoDownloadMode mode = _isGroup ? TGAutoDownloadModeCellularGroups: TGAutoDownloadModeCellularChannels;
    return (TGAppDelegateInstance.autoSavePhotosMode & mode) != 0;
}

- (bool)shouldAutomaticallyDownloadPhotos
{
    TGAutoDownloadChat chat = _isGroup ? TGAutoDownloadChatGroup : TGAutoDownloadChatChannel;
    return [TGAppDelegateInstance.autoDownloadPreferences shouldDownloadPhotoInChat:chat networkType:TGTelegraphInstance.networkTypeManager.networkType];
}

- (bool)shouldAutomaticallyDownloadAnimations
{
    return TGAppDelegateInstance.autoPlayAnimations;
}
- (bool)shouldAutomaticallyDownloadAudios
{
    TGAutoDownloadChat chat = _isGroup ? TGAutoDownloadChatGroup : TGAutoDownloadChatChannel;
    return [TGAppDelegateInstance.autoDownloadPreferences shouldDownloadVoiceMessageInChat:chat networkType:TGTelegraphInstance.networkTypeManager.networkType];
}

- (bool)shouldAutomaticallyDownloadVideoMessages
{
    TGAutoDownloadChat chat = _isGroup ? TGAutoDownloadChatGroup : TGAutoDownloadChatChannel;
    return [TGAppDelegateInstance.autoDownloadPreferences shouldDownloadVideoMessageInChat:chat networkType:TGTelegraphInstance.networkTypeManager.networkType];
}

- (bool)shouldAutomaticallyDownloadVideos
{
    TGAutoDownloadChat chat = _isGroup ? TGAutoDownloadChatGroup : TGAutoDownloadChatChannel;
    return [TGAppDelegateInstance.autoDownloadPreferences shouldDownloadVideoInChat:chat networkType:TGTelegraphInstance.networkTypeManager.networkType];
}

- (bool)shouldAutomaticallyDownloadDocuments
{
    TGAutoDownloadChat chat = _isGroup ? TGAutoDownloadChatGroup : TGAutoDownloadChatChannel;
    return [TGAppDelegateInstance.autoDownloadPreferences shouldDownloadDocumentInChat:chat networkType:TGTelegraphInstance.networkTypeManager.networkType];
}

- (NSString *)_sendMessagePathForMessageId:(int32_t)mid {
    return [[NSString alloc] initWithFormat:@"/tg/sendCommonMessage/(%@)/(%d)", [self _conversationIdPathComponent], mid];
}

- (NSString *)_sendMessagePathPrefix {
    return [[NSString alloc] initWithFormat:@"/tg/sendCommonMessage/(%@)/", [self _conversationIdPathComponent]];
}

- (NSDictionary *)_optionsForMessageActions {
    bool postAsChannel = !_isGroup;//[self messageAuthorPeerId] == _conversationId;
    return @{@"conversationId": @(_conversationId), @"accessHash": @(_accessHash), @"asChannel": @(postAsChannel), @"sendActivity": @(_isGroup), @"notifyMembers": @(_shouldNotifyMembers)};
}

- (void)_setupOutgoingMessage:(TGMessage *)message {
    [super _setupOutgoingMessage:message];
    
    if (_isGroup/* || !_postAsChannel*/) {
        message.sortKey = TGMessageSortKeyMake(_conversationId, TGMessageSpaceUnimportant, (int32_t)message.date, message.mid);
    }
    
    if (!_isGroup && (_adminRights.canPostMessages)/* && _postAsChannel*/) {
        if (message.viewCount == nil) {
            message.viewCount = [[TGMessageViewCountContentProperty alloc] initWithViewCount:1];
        }
    }
}

- (void)subscribeToUpdates
{
    [ActionStageInstance() watchForPaths:@[
        [[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/typing", _conversationId],
        [[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/conversation", _conversationId],
        [[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/importantMessages", _conversationId],
        [[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/unimportantMessages", _conversationId],
        [[NSString alloc] initWithFormat:@"/tg/peerSettings/(%lld)", _conversationId],
        [[NSString alloc] initWithFormat:@"/tg/peerSettings/(%" PRId32 ")", INT_MAX - 2]
    ] watcher:self];
    
    [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/peerSettings/(%" PRId64 ",cachedOnly)", _conversationId] options:@{@"peerId": @(_conversationId), @"accessHash": @(_accessHash)} watcher:self];
    [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/peerSettings/(%d,cachedOnly)", INT_MAX - 2] options:[NSDictionary dictionaryWithObject:[NSNumber numberWithLongLong:INT_MAX - 2] forKey:@"peerId"] watcher:self];

    [super subscribeToUpdates];
}

- (void)_controllerDidUpdateVisibleHoles:(NSArray *)holes {
    [TGModernConversationCompanion dispatchOnMessageQueue:^{
        _visibleHoles = holes;
        
        [self _updateVisibleHoles];
    }];
}

- (void)_updateVisibleHoles {
    if (_enableVisibleMessagesProcessing && _visibleHoles.count != 0 && _requestingHole == nil) {
        TGVisibleMessageHole *maxHole = _visibleHoles[0];
        
        [self _requestHole:maxHole];
    }
}

- (void)loadMoreMessagesAbove {
    int count = 100;
    IOS6Trace(@"IOS6FULL channel.loadMoreAbove.call peer=%lld access=%lld historyAbove=%d loading=%d migration=%d migrationAbove=%d items=%d display=%d", _conversationId, _accessHash, _historyAbove ? 1 : 0, _loadingHistoryAbove ? 1 : 0, _migrationData != nil ? 1 : 0, _migrationHistoryAbove ? 1 : 0, (int)_items.count, (int)_displayVariant);
    
    TGModernConversationController *controller = self.controller;
    [controller setEnableAboveHistoryRequests:false];
    
    [TGModernConversationCompanion dispatchOnMessageQueue:^{
        if (!_loadingHistoryAbove) {
            if (_historyAbove) {
                TGMessageTransparentSortKey maxKey = TGMessageTransparentSortKeyUpperBound(_conversationId);
                bool migratedFound = false;
                bool messagesFound = false;
                int32_t oldestMessageId = 0;
                int32_t oldestMessageDate = 0;
                for (TGMessageModernConversationItem *item in _items) {
                    if (item->_message.cid == _conversationId) {
                        TGMessageTransparentSortKey itemKey = item->_message.transparentSortKey;
                        itemKey = TGMessageTransparentSortKeyMake(TGMessageTransparentSortKeyPeerId(itemKey), TGMessageTransparentSortKeyTimestamp(itemKey), TGMessageTransparentSortKeyMid(itemKey) - 1, TGMessageTransparentSortKeySpace(itemKey));
                        if (TGMessageTransparentSortKeyCompare(maxKey, itemKey) > 0) {
                            maxKey = itemKey;
                        }
                        if (item->_message.mid > 0 && (oldestMessageId == 0 || item->_message.mid < oldestMessageId)) {
                            oldestMessageId = item->_message.mid;
                            oldestMessageDate = (int32_t)item->_message.date;
                        }
                        messagesFound = true;
                    } else {
                        migratedFound = item->_message.cid != 0;
                    }
                }
                
                if (!messagesFound && migratedFound) {
                    self->_loadingHistoryAbove = false;
                    self->_historyAbove = false;
                    [self _updateControllerHistoryRequestsFlags];
                } else {
                    __weak TGChannelConversationCompanion *weakSelf = self;
                    _loadingHistoryAbove = true;
                    [TGDatabaseInstance() channelMessages:_conversationId maxTransparentSortKey:maxKey count:count important:_displayVariant == TGChannelDisplayVariantImportant mode:TGChannelHistoryRequestEarlier completion:^(NSArray *messages, __unused bool hasLater) {
                        IOS6Trace(@"IOS6FULL channel.loadMoreAbove.cacheResult peer=%lld count=%d", _conversationId, (int)messages.count);
                        [TGModernConversationCompanion dispatchOnMessageQueue:^{
                            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                            if (strongSelf != nil) {
                                if (messages.count == 0) {
                                    if (oldestMessageId > 1) {
                                        IOS6Trace(@"IOS6FULL channel.loadMoreAbove.remoteGap peer=%lld oldestMid=%d oldestDate=%d", strongSelf->_conversationId, oldestMessageId, oldestMessageDate);
                                        TGMessageHole *remoteHole = [[TGMessageHole alloc] initWithMinId:1 minTimestamp:1 maxId:oldestMessageId - 1 maxTimestamp:oldestMessageDate];
                                        if (strongSelf->_requestingHoleDisposable == nil) {
                                            strongSelf->_requestingHoleDisposable = [[SMetaDisposable alloc] init];
                                        }
                                        int64_t conversationId = strongSelf->_conversationId;
                                        int32_t displayVariant = strongSelf->_displayVariant;
                                        int64_t accessHash = strongSelf->_accessHash;
                                        NSUInteger remoteGapGeneration = ++strongSelf->_ios6RemoteGapGeneration;
                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                            [TGModernConversationCompanion dispatchOnMessageQueue:^{
                                                __strong TGChannelConversationCompanion *timeoutStrongSelf = weakSelf;
                                                if (timeoutStrongSelf != nil && timeoutStrongSelf->_ios6RemoteGapGeneration == remoteGapGeneration && timeoutStrongSelf->_loadingHistoryAbove) {
                                                    IOS6Trace(@"IOS6FULL channel.loadMoreAbove.remoteGapTimeout peer=%lld oldestMid=%d generation=%d", conversationId, oldestMessageId, (int)remoteGapGeneration);
                                                    [timeoutStrongSelf->_requestingHoleDisposable setDisposable:nil];
                                                    timeoutStrongSelf->_requestingHoleDisposable = nil;
                                                    timeoutStrongSelf->_loadingHistoryAbove = false;
                                                    timeoutStrongSelf->_historyAbove = false;
                                                    [timeoutStrongSelf _updateControllerHistoryRequestsFlags];
                                                }
                                            }];
                                        });
                                        [strongSelf->_requestingHoleDisposable setDisposable:[[TGChannelManagementSignals channelMessageHoleForPeerId:conversationId accessHash:accessHash hole:remoteHole direction:TGChannelHistoryHoleDirectionEarlier important:displayVariant == TGChannelDisplayVariantImportant] startWithNext:^(NSDictionary *dict) {
                                            IOS6Trace(@"IOS6FULL channel.loadMoreAbove.remoteGapResult peer=%lld messages=%d unimportantGroups=%d hole=%@", conversationId, (int)((NSArray *)dict[@"messages"]).count, (int)((NSArray *)dict[@"unimportantGroups"]).count, dict[@"hole"]);
                                            NSArray *removedImportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                                            NSArray *removedUnimportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                                            
                                            [TGDatabaseInstance() addMessagesToChannel:conversationId messages:dict[@"messages"] deleteMessages:nil unimportantGroups:dict[@"unimportantGroups"] addedHoles:nil removedHoles:removedImportantHoles removedUnimportantHoles:removedUnimportantHoles updatedMessageSortKeys:nil returnGroups:displayVariant == TGChannelDisplayVariantImportant keepUnreadCounters:false skipFeedUpdate:false changedMessages:^(NSArray *addedMessages, NSArray *removedMessages, NSDictionary *updatedMessages, NSArray *addedUnimportantHoles, NSArray *removedUnimportantHoles) {
                                                [TGModernConversationCompanion dispatchOnMessageQueue:^{
                                                    __strong TGChannelConversationCompanion *remoteStrongSelf = weakSelf;
                                                    if (remoteStrongSelf != nil) {
                                                        if (remoteStrongSelf->_ios6RemoteGapGeneration != remoteGapGeneration) {
                                                            IOS6Trace(@"IOS6FULL channel.loadMoreAbove.remoteGapStale peer=%lld generation=%d current=%d", conversationId, (int)remoteGapGeneration, (int)remoteStrongSelf->_ios6RemoteGapGeneration);
                                                            return;
                                                        }
                                                        remoteStrongSelf->_requestingHoleDisposable = nil;
                                                        NSMutableArray *resultRemovedMessages = [[NSMutableArray alloc] init];
                                                        [resultRemovedMessages addObjectsFromArray:removedMessages];
                                                        if (remoteStrongSelf->_displayVariant == TGChannelDisplayVariantAll) {
                                                            [resultRemovedMessages addObjectsFromArray:removedUnimportantHoles];
                                                        }
                                                        
                                                        NSMutableArray *resultAddedMessages = [[NSMutableArray alloc] init];
                                                        [resultAddedMessages addObjectsFromArray:addedMessages];
                                                        if (remoteStrongSelf->_displayVariant == TGChannelDisplayVariantAll) {
                                                            [resultAddedMessages addObjectsFromArray:addedUnimportantHoles];
                                                        }
                                                        
                                                        remoteStrongSelf->_loadingHistoryAbove = false;
                                                        remoteStrongSelf->_historyAbove = resultAddedMessages.count != 0;
                                                        if (resultAddedMessages.count != 0 || resultRemovedMessages.count != 0) {
                                                            [remoteStrongSelf _addMessages:resultAddedMessages animated:false intent:TGModernConversationAddMessageIntentLoadMoreMessagesAbove deletedMessages:resultRemovedMessages];
                                                        }
                                                        [remoteStrongSelf _updateMessages:updatedMessages];
                                                        [remoteStrongSelf _updateControllerHistoryRequestsFlags];
                                                    }
                                                }];
                                            }];
                                        } error:^(__unused id error) {
                                            IOS6Trace(@"IOS6FULL channel.loadMoreAbove.remoteGapError peer=%lld error=%@", conversationId, error);
                                            [TGModernConversationCompanion dispatchOnMessageQueue:^{
                                                __strong TGChannelConversationCompanion *remoteStrongSelf = weakSelf;
                                                if (remoteStrongSelf != nil) {
                                                    if (remoteStrongSelf->_ios6RemoteGapGeneration != remoteGapGeneration) {
                                                        IOS6Trace(@"IOS6FULL channel.loadMoreAbove.remoteGapErrorStale peer=%lld generation=%d current=%d", conversationId, (int)remoteGapGeneration, (int)remoteStrongSelf->_ios6RemoteGapGeneration);
                                                        return;
                                                    }
                                                    remoteStrongSelf->_requestingHoleDisposable = nil;
                                                    remoteStrongSelf->_loadingHistoryAbove = false;
                                                    remoteStrongSelf->_historyAbove = false;
                                                    [remoteStrongSelf _updateControllerHistoryRequestsFlags];
                                                }
                                            }];
                                        } completed:nil]];
                                        return;
                                    } else {
                                        strongSelf->_loadingHistoryAbove = false;
                                        strongSelf->_historyAbove = false;
                                    }
                                } else {
                                    strongSelf->_loadingHistoryAbove = false;
                                    strongSelf->_historyAbove = true;
                                }
                                if (messages.count != 0) {
                                    [strongSelf _addMessages:messages animated:false intent:TGModernConversationAddMessageIntentLoadMoreMessagesAbove];
                                }
                                [strongSelf _updateControllerHistoryRequestsFlags];
                            }
                        }];
                    }];
                }
            } else if (_migrationData != nil && _migrationHistoryAbove) {
                __weak TGChannelConversationCompanion *weakSelf = self;
                _loadingHistoryAbove = true;
                
                int32_t maxTimestamp = INT32_MAX;
                int32_t maxMid = _migrationData.maxMessageId;
                
                for (TGMessageModernConversationItem *item in _items) {
                    maxTimestamp = MIN(maxTimestamp, (int32_t)item->_message.date);
                    if (item->_message.cid == _conversationId || item->_message.cid == 0) {
                    } else {
                        maxMid = MIN(maxMid, item->_message.mid - migratedMessageIdOffset);
                    }
                }
                
                [TGDatabaseInstance() loadMessagesFromConversation:_migrationData.peerId maxMid:maxMid maxDate:maxTimestamp maxLocalMid:0 atMessageId:0 limit:count extraUnread:false completion:^(NSArray *messages, __unused bool historyExistsBelow) {
                    int peerMinMid = [TGDatabaseInstance() loadPeerMinMid:_migrationData.peerId];
                    
                    [TGModernConversationCompanion dispatchOnMessageQueue:^{
                        __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                        if (strongSelf != nil) {
                            bool cachedMessagesAbove = false;
                            if (messages.count != 0) {
                                cachedMessagesAbove = true;
                            }
                            
                            NSMutableArray *updatedMessages = [[NSMutableArray alloc] init];
                            
                            for (TGMessage *message in messages) {
                                if (message.mid < TGMessageLocalMidBaseline) {
                                    message.mid += migratedMessageIdOffset;
                                    [updatedMessages addObject:message];
                                }
                            }
                            
                            if (messages.count != 0) {
                                [strongSelf _addMessages:updatedMessages animated:false intent:TGModernConversationAddMessageIntentLoadMoreMessagesAbove];
                            }
                            
                            if (cachedMessagesAbove || peerMinMid != 0) {
                                strongSelf->_loadingHistoryAbove = false;
                                strongSelf->_migrationHistoryAbove = cachedMessagesAbove;
                                
                                [strongSelf _updateControllerHistoryRequestsFlags];
                            } else {
                                NSMutableDictionary *options = [[NSMutableDictionary alloc] initWithDictionary:@{@"maxMid": @(maxMid), @"offset": @(0)}];
                                
                                options[@"conversationId"] = @(_migrationData.peerId);
                                
                                [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversations/(%lld)/asyncHistory/(%d)", _migrationData.peerId, maxMid] options:options watcher:strongSelf];
                                IOS6Trace(@"IOS6FULL channel.loadMoreAbove.migrationRemote peer=%lld migrationPeer=%lld maxMid=%d", strongSelf->_conversationId, strongSelf->_migrationData.peerId, maxMid);
                            }
                        }
                    }];
                }];
            }
        } else {
            IOS6Trace(@"IOS6FULL channel.loadMoreAbove.skip peer=%lld loading=%d historyAbove=%d", _conversationId, _loadingHistoryAbove ? 1 : 0, _historyAbove ? 1 : 0);
            [self _updateControllerHistoryRequestsFlags];
        }
    }];
}

- (void)loadMoreMessagesBelow {
    int count = 100;
#ifdef DEBUG
    count = 10;
#endif
    IOS6Trace(@"IOS6FULL channel.loadMoreBelow.call peer=%lld access=%lld historyBelow=%d loading=%d items=%d display=%d", _conversationId, _accessHash, _historyBelow ? 1 : 0, _loadingHistoryBelow ? 1 : 0, (int)_items.count, (int)_displayVariant);
    
    TGModernConversationController *controller = self.controller;
    [controller setEnableBelowHistoryRequests:false];
    
    [TGModernConversationCompanion dispatchOnMessageQueue:^{
        if (!_loadingHistoryBelow) {
            if (_historyBelow) {
                TGMessageTransparentSortKey minKey = TGMessageTransparentSortKeyLowerBound(_conversationId);
                for (TGMessageModernConversationItem *item in _items) {
                    TGMessageTransparentSortKey itemKey = item->_message.transparentSortKey;
                    if (TGMessageTransparentSortKeyCompare(minKey, itemKey) < 0) {
                        minKey = itemKey;
                    }
                }
                
                __weak TGChannelConversationCompanion *weakSelf = self;
                _loadingHistoryBelow = true;
                [TGDatabaseInstance() channelMessages:_conversationId maxTransparentSortKey:minKey count:count important:_displayVariant == TGChannelDisplayVariantImportant mode:TGChannelHistoryRequestLater completion:^(NSArray *messages, __unused bool hasLater) {
                    IOS6Trace(@"IOS6FULL channel.loadMoreBelow.cacheResult peer=%lld count=%d", _conversationId, (int)messages.count);
                    [TGModernConversationCompanion dispatchOnMessageQueue:^{
                        __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                        if (strongSelf != nil) {
                            strongSelf->_loadingHistoryBelow = false;
                            if (messages.count == 0) {
                                strongSelf->_historyBelow = false;
                            } else {
                                strongSelf->_historyBelow = true;
                            }
                            if (messages.count != 0) {
                                [strongSelf _addMessages:messages animated:false intent:TGModernConversationAddMessageIntentLoadMoreMessagesBelow];
                            }
                            [strongSelf _updateControllerHistoryRequestsFlags];
                        }
                    }];
                }];
            }
        } else {
            IOS6Trace(@"IOS6FULL channel.loadMoreBelow.skip peer=%lld loading=%d historyBelow=%d", _conversationId, _loadingHistoryBelow ? 1 : 0, _historyBelow ? 1 : 0);
            [self _updateControllerHistoryRequestsFlags];
        }
    }];
}

- (void)_requestHole:(TGVisibleMessageHole *)hole {
    _requestingHole = hole;
    if (_requestingHoleDisposable == nil) {
        _requestingHoleDisposable = [[SMetaDisposable alloc] init];
    }

    int64_t conversationId = _conversationId;
    int32_t displayVariant = _displayVariant;
    
    TGLog(@"request hole %d ... %d, %s", hole.hole.minId, hole.hole.maxId, hole.direction == TGVisibleMessageHoleDirectionEarlier ? "earlier" : "later");
    IOS6Trace(@"IOS6FULL channel.hole.request peer=%lld access=%lld min=%d max=%d dir=%@ important=%d", _conversationId, _accessHash, hole.hole.minId, hole.hole.maxId, hole.direction == TGVisibleMessageHoleDirectionEarlier ? @"earlier" : @"later", _displayVariant == TGChannelDisplayVariantImportant ? 1 : 0);
    
    __weak TGChannelConversationCompanion *weakSelf = self;
    [_requestingHoleDisposable setDisposable:[[TGChannelManagementSignals channelMessageHoleForPeerId:_conversationId accessHash:_accessHash hole:hole.hole direction:hole.direction == TGVisibleMessageHoleDirectionEarlier ? TGChannelHistoryHoleDirectionEarlier : TGChannelHistoryHoleDirectionLater important:_displayVariant == TGChannelDisplayVariantImportant] startWithNext:^(NSDictionary *dict) {
        IOS6Trace(@"IOS6FULL channel.hole.result peer=%lld messages=%d unimportantGroups=%d hole=%@", conversationId, (int)((NSArray *)dict[@"messages"]).count, (int)((NSArray *)dict[@"unimportantGroups"]).count, dict[@"hole"]);
        
        NSArray *removedImportantHoles = nil;
        NSArray *removedUnimportantHoles = nil;
        
        removedImportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
        removedUnimportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
        
        [TGDatabaseInstance() addMessagesToChannel:conversationId messages:dict[@"messages"] deleteMessages:nil unimportantGroups:dict[@"unimportantGroups"] addedHoles:nil removedHoles:removedImportantHoles removedUnimportantHoles:removedUnimportantHoles updatedMessageSortKeys:nil returnGroups:displayVariant == TGChannelDisplayVariantImportant keepUnreadCounters:false skipFeedUpdate:false changedMessages:^(NSArray *addedMessages, NSArray *removedMessages, NSDictionary *updatedMessages, NSArray *addedUnimportantHoles, NSArray *removedUnimportantHoles) {
                [TGModernConversationCompanion dispatchOnMessageQueue:^{
                    __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                    if (strongSelf != nil) {
                        
                        NSMutableArray *resultRemovedMessages = [[NSMutableArray alloc] init];
                        [resultRemovedMessages addObjectsFromArray:removedMessages];
                        if (strongSelf->_displayVariant == TGChannelDisplayVariantAll) {
                            [resultRemovedMessages addObjectsFromArray:removedUnimportantHoles];
                        }
                        
                        NSMutableArray *resultAddedMessages = [[NSMutableArray alloc] init];
                        [resultAddedMessages addObjectsFromArray:addedMessages];
                        if (strongSelf->_displayVariant == TGChannelDisplayVariantAll) {
                            [resultAddedMessages addObjectsFromArray:addedUnimportantHoles];
                        }
                        
                        [strongSelf _addMessages:resultAddedMessages animated:false intent:hole.direction == TGVisibleMessageHoleDirectionEarlier ? TGModernConversationAddMessageIntentLoadMoreMessagesAbove : TGModernConversationAddMessageIntentLoadMoreMessagesBelow deletedMessages:resultRemovedMessages];
                        
                        [strongSelf _updateMessages:updatedMessages];
                        
                        strongSelf->_requestingHole = nil;
                        [strongSelf _updateControllerHistoryRequestsFlags];
                    }
                }];
            }];
    } error:^(__unused id error) {
        
    } completed:nil]];
}

- (void)_updateControllerHistoryRequestsFlags {
    NSAssert([TGModernConversationCompanion isMessageQueue], @"[TGModernConversationCompanion isMessageQueue]");
    
    bool enableAboveRequests = _historyAbove || _migrationHistoryAbove;
    if (_loadingHistoryAbove) {
        enableAboveRequests = false;
    }
    
    bool enableBelowRequests = _historyBelow;
    if (_loadingHistoryBelow) {
        enableBelowRequests = false;
    }
    
    TGDispatchOnMainThread(^{
        TGModernConversationController *controller = self.controller;
        [controller setEnableAboveHistoryRequests:enableAboveRequests];
        [controller setEnableBelowHistoryRequests:enableBelowRequests];
    });
}

- (NSString *)titleForConversation:(TGConversation *)conversation {
    return conversation.chatTitle;
}

- (NSString *)stringForActivity:(NSString *)activity
{
    if ([activity isEqualToString:@"recordingAudio"])
        return TGLocalized(@"Activity.RecordingAudio");
    else if ([activity isEqualToString:@"recordingVideoMessage"])
        return TGLocalized(@"Activity.RecordingVideoMessage");
    else if ([activity isEqualToString:@"uploadingPhoto"])
        return TGLocalized(@"Activity.UploadingPhoto");
    else if ([activity isEqualToString:@"uploadingVideo"])
        return TGLocalized(@"Activity.UploadingVideo");
    else if ([activity isEqualToString:@"uploadingDocument"])
        return TGLocalized(@"Activity.UploadingDocument");
    else if ([activity isEqualToString:@"pickingLocation"])
        return nil;
    else if ([activity isEqualToString:@"playingGame"])
        return TGLocalized(@"Activity.PlayingGame");
    
    return TGLocalized(@"Conversation.typing");
}

- (int)activityTypeForActivity:(NSString *)activity
{
    if ([activity isEqualToString:@"recordingAudio"])
        return TGModernConversationTitleViewActivityAudioRecording;
    else if ([activity isEqualToString:@"recordingVideoMessage"])
        return TGModernConversationTitleViewActivityVideoMessageRecording;
    else if ([activity isEqualToString:@"uploadingPhoto"])
        return TGModernConversationTitleViewActivityUploading;
    else if ([activity isEqualToString:@"uploadingVideo"])
        return TGModernConversationTitleViewActivityUploading;
    else if ([activity isEqualToString:@"uploadingDocument"])
        return TGModernConversationTitleViewActivityUploading;
    else if ([activity isEqualToString:@"pickingLocation"])
        return 0;
    else if ([activity isEqualToString:@"playingGame"])
        return TGModernConversationTitleViewActivityPlaying;
    
    return TGModernConversationTitleViewActivityTyping;
}

- (NSString *)stringForUserActivities:(NSDictionary *)activities
{
    if (activities.count != 0)
    {
        NSMutableString *typingString = [[NSMutableString alloc] init];
        
        for (NSNumber *nUid in activities)
        {
            TGUser *user = [TGDatabaseInstance() loadUser:[nUid intValue]];
            if (user != nil)
            {
                if (typingString.length != 0)
                    [typingString appendString:@", "];
                [typingString appendString:user.displayFirstName];
            }
        }
        
        return typingString;
    }
    
    return nil;
}

- (int)activityTypeForActivities:(NSDictionary *)activities
{
    if (activities.count == 1)
    {
        return [self activityTypeForActivity:activities.allValues.firstObject];
    }
    else if (activities.count != 0)
    {
        return TGModernConversationTitleViewActivityTyping;
    }
    
    return 0;
}

- (void)_updateNotifcationSettings
{
    NSNumber *muteUntil = _groupNotificationSettings[@"muteUntil"];
    if (muteUntil == nil)
        muteUntil = _defaultNotificationSettings[@"muteUntil"];
    
    if (muteUntil.intValue <= [[TGTelegramNetworking instance] approximateRemoteTime])
        _isMuted = false;
    else
        _isMuted = true;
    
    [_mutePanel setActionWithTitle:!_isMuted ? TGLocalized(@"Conversation.Mute") : TGLocalized(@"Conversation.Unmute") action:@"toggleMute" color:self.controller.presentation.pallete.accentColor icon:TGModernConversationActionInputPanelIconNone];
    
    [self _updateChannelMute];
}

- (void)actorCompleted:(int)status path:(NSString *)path result:(id)result {
    IOS6Trace(@"IOS6FULL channel.actorCompleted peer=%lld status=%d path=%@ result=%@", _conversationId, status, path, NSStringFromClass([result class]));
    if ([path hasPrefix:[NSString stringWithFormat:@"/tg/peerSettings/(%" PRId32 "", INT_MAX - 2]])
    {
        TGDispatchOnMainThread(^
        {
            _defaultNotificationSettings = [((SGraphObjectNode *)result).object mutableCopy];
            [self _updateNotifcationSettings];
            [self updateBroadcasting];
        });
    }
    else if ([path hasPrefix:@"/tg/peerSettings/"])
    {
        if (status == ASStatusSuccess)
        {
            TGDispatchOnMainThread(^
            {
                _groupNotificationSettings = [((SGraphObjectNode *)result).object mutableCopy];
                [self _updateNotifcationSettings];
            });
        }
    } else if ([path rangeOfString:@"/asyncHistory/"].location != NSNotFound) {
        [TGModernConversationCompanion dispatchOnMessageQueue:^{
            NSArray *messages = result;
            IOS6Trace(@"IOS6FULL channel.actorCompleted.asyncHistory peer=%lld path=%@ messages=%d", _conversationId, path, (int)messages.count);
            
            NSMutableArray *updatedMessages = [[NSMutableArray alloc] init];
            
            for (TGMessage *message in messages) {
                if (message.mid < TGMessageLocalMidBaseline) {
                    
                    TGMessage *updatedMessage = [message copy];
                    updatedMessage.mid += migratedMessageIdOffset;
                    [updatedMessages addObject:updatedMessage];
                }
            }
            
            if (messages.count != 0) {
                [self _addMessages:updatedMessages animated:false intent:TGModernConversationAddMessageIntentLoadMoreMessagesAbove];
            }
            
            _loadingHistoryAbove = false;
            _migrationHistoryAbove = updatedMessages.count != 0;
            
            [self _updateControllerHistoryRequestsFlags];
        }];
        return;
    }
    
    [super actorCompleted:status path:path result:result];
}

- (void)actionStageResourceDispatched:(NSString *)path resource:(id)resource arguments:(id)arguments {
    if ([path rangeOfString:[[NSString alloc] initWithFormat:@"%lld", _conversationId]].location != NSNotFound || [path hasPrefix:@"/tg/peerSettings/"])
        IOS6Trace(@"IOS6FULL channel.resource peer=%lld path=%@ resource=%@ args=%@", _conversationId, path, NSStringFromClass([resource class]), arguments);
    if ([path isEqualToString:[[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/typing", _conversationId]])
    {
        NSDictionary *userActivities = ((SGraphObjectNode *)resource).object;
        if (userActivities.count != 0)
            [self _setTypingStatus:[self stringForUserActivities:userActivities] activity:[self activityTypeForActivities:userActivities]];
        else
            [self _setTypingStatus:nil activity:0];
    }
    else if ([path isEqualToString:[[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/conversation", _conversationId]]) {
        TGConversation *conversation = ((SGraphObjectNode *)resource).object;
        _conversation = conversation;
        _signaturesEnabled = conversation.signaturesEnabled;
        
        TGDispatchOnMainThread(^{
            bool importantFlagsUpdated = !TGObjectCompare(_adminRights, conversation.channelAdminRights) || !TGObjectCompare(_bannedRights, conversation.channelBannedRights) || _kind != conversation.kind || _isForbidden != conversation.kickedFromChat;
            
            _kind = conversation.kind;
            _adminRights = conversation.channelAdminRights;
            _bannedRights = conversation.channelBannedRights;
            
            if (!_isGroup && _isForbidden != conversation.kickedFromChat && conversation.kickedFromChat) {
                [TGCustomAlertView presentAlertWithTitle:nil message:[NSString stringWithFormat:TGLocalized(@"ChannelInfo.ChannelForbidden"), conversation.chatTitle] cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
            }
            
            _isForbidden = conversation.kickedFromChat;
            
            TGModernConversationController *controller = self.controller;
            if (!_isGroup) {
                if (_isCreator || _adminRights.canPostMessages) {
                    [controller setCanBroadcast:true];
                    [self updateBroadcasting];
                    [controller setIsAlwaysBroadcasting:false];
                } else {
                    [controller setCanBroadcast:false];
                    [controller setIsBroadcasting:false];
                    [controller setIsAlwaysBroadcasting:true];
                }
            }
            
            if (importantFlagsUpdated) {
                [self _updateJoinPanel];
                [controller setBannedStickers:_bannedRights.banSendStickers];
                [controller setBannedMedia:_bannedRights.banSendMedia];
            }
            
            [self _setTitle:[self titleForConversation:conversation] andStatus:_isGroup ? TGLocalized(@"Group.Status") : TGLocalized(@"Channel.Status") accentColored:false allowAnimatioon:false toggleMode:[self currentToggleMode]];
            [self updateStatus];
            [self _setAvatarConversationId:_conversationId title:conversation.chatTitle icon:nil];
            [self _setAvatarUrl:conversation.chatPhotoFullSmall];
        });
    } else if ([path isEqualToString:[[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/importantMessages", _conversationId]]) {
        [TGModernConversationCompanion dispatchOnMessageQueue:^{
            if (_displayVariant == TGChannelDisplayVariantImportant) {
                if (((NSArray *)resource[@"removed"]).count != 0) {
                    [self _deleteMessages:resource[@"removed"] animated:true];
                }
                if (((NSArray *)resource[@"added"]).count != 0) {
                    [self _mergePinnedMessages:[self _pinnedMessagesFromMessages:resource[@"added"]]];
                    [super actionStageResourceDispatched:[[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/messages", _conversationId] resource:[[SGraphObjectNode alloc] initWithObject:resource[@"added"]] arguments:@{@"treatIncomingAsUnread": @true}];
                }
                if (((NSDictionary *)resource[@"updated"]).count != 0) {
                    [self _updateMessages:resource[@"updated"]];
                    __block bool hadGroups = false;
                    [(NSDictionary *)resource[@"updated"] enumerateKeysAndObjectsUsingBlock:^(__unused id key, TGMessage *message, BOOL *stop) {
                        if (message.group != nil) {
                            if (stop) {
                                hadGroups = true;
                               *stop = true;
                            }
                        }
                    }];
                    
                    if (hadGroups) {
                        [self scheduleReadHistory];
                    }
                }
            }
        }];
    } else if ([path isEqualToString:[[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/unimportantMessages", _conversationId]]) {
        [TGModernConversationCompanion dispatchOnMessageQueue:^{
            if (_displayVariant == TGChannelDisplayVariantAll) {
                if (((NSArray *)resource[@"removed"]).count != 0) {
                    [self _deleteMessages:resource[@"removed"] animated:true];
                }
                if (((NSArray *)resource[@"added"]).count != 0) {
                    [self _mergePinnedMessages:[self _pinnedMessagesFromMessages:resource[@"added"]]];
                    [super actionStageResourceDispatched:[[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/messages", _conversationId] resource:[[SGraphObjectNode alloc] initWithObject:resource[@"added"]] arguments:@{@"treatIncomingAsUnread": @true}];
                }
                if (((NSDictionary *)resource[@"updated"]).count != 0) {
                    [self _updateMessages:resource[@"updated"]];
                }
            }
        }];
    } else if ([path hasPrefix:@"/tg/peerSettings/"]) {
        [self actorCompleted:ASStatusSuccess path:path result:resource];
    }
    
    [super actionStageResourceDispatched:path resource:resource arguments:arguments];
}

- (void)requestJoinChannel {
    if (_joinChannelDisposable == nil) {
        _joinChannelDisposable = [[SMetaDisposable alloc] init];
    }
    
    [_joinChannelPanel setActivity:true];
    
    __weak TGChannelConversationCompanion *weakSelf = self;
    [_joinChannelDisposable setDisposable:[[[TGChannelManagementSignals joinTemporaryChannel:_conversationId] deliverOn:[SQueue mainQueue]] startWithNext:nil error:^(__unused id error) {
        [TGCustomAlertView presentAlertWithTitle:nil message:TGLocalized(@"GroupInfo.InvitationLinkGroupFull") cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
        
        __strong TGChannelConversationCompanion *strongSelf = weakSelf;
        if (strongSelf != nil)
            [strongSelf->_joinChannelPanel setActivity:false];
    } completed:nil]];
}

- (bool)allowReplies {
    return _kind == TGConversationKindPersistentChannel && (_isGroup || _isCreator || _adminRights.canPostMessages);
}

- (int64_t)messageAuthorPeerId {
    if (_isGroup || _signaturesEnabled) {
        return TGTelegraphInstance.clientUserId;
    }
    
    return _conversationId;
}

- (bool)canDeleteMessage:(TGMessage *)message {
    if (_bannedRights.banSendMessages) {
        return false;
    }
    
    if (!_isGroup) {
        if (TGMessageSortKeySpace(message.sortKey) == TGMessageSpaceImportant) {
            if (_isCreator || _adminRights.canDeleteMessages || message.outgoing) {
                return true;
            } else {
                return false;
            }
        }
    }
    
    if (message.fromUid == _conversationId) {
        return _isCreator || _adminRights.canDeleteMessages;
    } else {
        if (message.outgoing || (_isCreator || _adminRights.canDeleteMessages)) {
            return true;
        }
    }
    return false;
}

- (bool)canModerateMessage:(TGMessage *)message {
    if (message.cid != _conversationId) {
        return false;
    }
    
    if (TGMessageSortKeySpace(message.sortKey) == TGMessageSpaceImportant) {
        return false;
    }
    
    if (message.actionInfo != nil) {
        return false;
    }
    
    if (message.outgoing) {
        return false;
    }
    
    if (message.mid >= TGMessageLocalMidBaseline) {
        return false;
    }
    
    if (_isCreator || _adminRights.canBanUsers) {
        return true;
    }
    
    return false;
}

- (TGUser *)checkedMessageModerateUser {
    NSArray *messageIndices = [self checkedMessageIndices];
    if (messageIndices.count > 20) {
        return nil;
    }
    
    NSNumber *sharedAuthorId = nil;
    
    for (TGMessageIndex *messageIndex in messageIndices) {
        int32_t messageId = messageIndex.messageId;
        TGMessage *message = [TGDatabaseInstance() loadMessageWithMid:messageId peerId:_conversationId];
        if (message == nil || ![self canModerateMessage:message]) {
            return nil;
        }
        
        if (sharedAuthorId == nil) {
            sharedAuthorId = @(message.fromUid);
        } else if ([sharedAuthorId longLongValue] != message.fromUid) {
            return nil;
        }
    }
    
    if (sharedAuthorId != nil) {
        return [TGDatabaseInstance() loadUser:[sharedAuthorId intValue]];
    }
    
    return nil;
}

- (bool)canPinMessage:(TGMessage *)message {
    if (message.mid >= TGMessageLocalMidBaseline) {
        return false;
    }
    
    if (message.actionInfo != nil) {
        return false;
    }
    
    if (message.cid != _conversationId) {
        return false;
    }
    
    if (_isCreator || _adminRights.canPinMessages || (!_conversation.isChannelGroup && _adminRights.canEditMessages)) {
        return true;
    }
    
    return false;
}

- (bool)isMessagePinned:(int32_t)messageId {
    return messageId != 0 && messageId == _immediatePinnedMessage;
}

- (bool)canEditMessage:(TGMessage *)message {
    if (_bannedRights.banSendMessages) {
        return false;
    }
    
    if (_conversation.kind != TGConversationKindPersistentChannel) {
        return false;
    }
    
    if (message.mid >= TGMessageLocalMidBaseline || message.deliveryState == TGMessageDeliveryStateFailed || _uploadingEditMessages[@(message.mid + TGMessageLocalMidEditBaseline)] != nil) {
        return false;
    }
    
    bool editable = true;
    bool hasEditableContent = message.text.length != 0;
    for (id attachment in message.mediaAttachments) {
        if ([attachment isKindOfClass:[TGBotContextResultAttachment class]]) {
            editable = false;
            break;
        } else if ([attachment isKindOfClass:[TGImageMediaAttachment class]]) {
            hasEditableContent = true;
        } else if ([attachment isKindOfClass:[TGVideoMediaAttachment class]] && !((TGVideoMediaAttachment *)attachment).roundMessage) {
            hasEditableContent = true;
        } else if ([attachment isKindOfClass:[TGForwardedMessageMediaAttachment class]]) {
            editable = false;
            break;
        } else if ([attachment isKindOfClass:[TGViaUserAttachment class]]) {
            editable = false;
            break;
        } else if ([attachment isKindOfClass:[TGDocumentMediaAttachment class]]) {
            hasEditableContent = ![((TGDocumentMediaAttachment *)attachment) isSticker];
            break;
        } else if ([attachment isKindOfClass:[TGLocationMediaAttachment class]]) {
            editable = false;
        }
    }
    
    if (!editable || !hasEditableContent) {
        return false;
    }
    
    int32_t maxChannelMessageEditTime = 60 * 60 * 24 * 2;
    NSData *data = [TGDatabaseInstance() customProperty:@"maxChannelMessageEditTime"];
    if (data.length >= 4) {
        [data getBytes:&maxChannelMessageEditTime length:4];
    }
    
    if ([TGTelegramNetworking instance].approximateRemoteTime > message.date + maxChannelMessageEditTime) {
        return false;
    }
    
    if (TGMessageSortKeySpace(message.sortKey) == TGMessageSpaceImportant) {
        if (_isCreator || message.outgoing || _adminRights.canEditMessages) {
            return true;
        }
    } else {
        if (message.outgoing) {
            return true;
        }
    }
    return false;
}

- (bool)canDeleteMessages {
    if (_bannedRights.banSendMessages) {
        return false;
    }
    
    return _isCreator || _adminRights.canDeleteMessages;
}

- (bool)canDeleteAllMessages {
    return _isGroup && _conversation.username.length == 0;
}

- (int64_t)requestPeerId {
    return _conversationId;
}

- (int64_t)requestAccessHash {
    return _accessHash;
}

- (void)_toggleBroadcastMode {
    _shouldNotifyMembers = !_shouldNotifyMembers;
    [TGDatabaseInstance() setChannelShouldMuteMembers:_conversationId value:!_shouldNotifyMembers];
}

- (void)_toggleTitleMode {
    TGMessageTransparentSortKey sortKey = TGMessageTransparentSortKeyUpperBound(_conversationId);
    TGModernConversationController *controller = self.controller;
    TGMessage *maxMessage = [controller latestVisibleMessage];
    if (maxMessage != nil) {
        sortKey = maxMessage.transparentSortKey;
    }
    
    _lastExpandedGroup = nil;
    
    if (_displayVariant != _conversation.displayVariant && _displayVariant == TGChannelDisplayVariantImportant) {
        _conversation = [_conversation copy];
        _conversation.displayVariant = _displayVariant;
        _signaturesEnabled = _conversation.signaturesEnabled;
        [TGDatabaseInstance() updateChannelDisplayVariant:_conversationId displayVariant:_displayVariant];
    }
    
    [self reloadVariantAtSortKey:sortKey group:nil jump:false top:false messageIdForVisibleHoleDirection:0 scrollBackMessageId:0 animated:true];
}

- (void)navigateToMessageId:(int32_t)messageId scrollBackMessageId:(int32_t)scrollBackMessageId forceUnseenMention:(bool)forceUnseenMention animated:(bool)animated {
    [self navigateToMessageId:messageId scrollBackMessageId:scrollBackMessageId forceUnseenMention:forceUnseenMention animated:animated forceLoad:false];
}

- (void)navigateToMessageId:(int32_t)messageId scrollBackMessageId:(int32_t)scrollBackMessageId forceUnseenMention:(bool)forceUnseenMention animated:(bool)animated forceLoad:(bool)forceLoad
{
    __weak TGChannelConversationCompanion *weakSelf = self;
    [TGModernConversationCompanion dispatchOnMessageQueue:^
    {
        if ([self attachedPeerId] != 0 && scrollBackMessageId >= migratedMessageIdOffset) {
            return;
        }
        
        NSMutableArray *updatedIndices = [[NSMutableArray alloc] init];
        NSMutableArray *updatedItems = [[NSMutableArray alloc] init];
        
        bool found = false;
        for (NSUInteger i = 0; i < _items.count; i++)
        {
            TGMessageModernConversationItem *item = _items[i];
            
            if (item->_message.mid == messageId)
            {
                if (forceUnseenMention && !item->_message.containsUnseenMention) {
                    item = [item deepCopy];
                    item->_message.containsUnseenMention = true;
                    ((NSMutableArray *)_items)[i] = item;
                    
                    [updatedIndices addObject:@(i)];
                    [updatedItems addObject:item];
                }
                found = true;
                break;
            }
        }
        
        int32_t sourceMid = scrollBackMessageId;
        
        if (found && !forceLoad)
        {
            TGDispatchOnMainThread(^
            {
                TGModernConversationController *controller = self.controller;
                int index = -1;
                for (NSNumber *nIndex in updatedIndices)
                {
                    index++;
                    [controller updateItemAtIndex:[nIndex intValue] toItem:updatedItems[index] delayAvailability:false];
                }
                [controller scrollToMessage:messageId peerId:0 sourceMessageId:sourceMid animated:animated];
            });
        }
        else
        {
            int64_t conversationId = _conversationId;
            [[TGChannelManagementSignals preloadedHistoryForPeerId:_conversationId accessHash:_accessHash aroundMessageId:messageId] startWithNext:^(NSDictionary *dict) {
                NSArray *removedImportantHoles = nil;
                NSArray *removedUnimportantHoles = nil;
                
                removedImportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                removedUnimportantHoles = dict[@"hole"] == nil ? nil : @[dict[@"hole"]];
                
                __block TGMessageTransparentSortKey sortKey = TGMessageTransparentSortKeyUpperBound(conversationId);
                __block bool keyExists = false;
                
                [TGDatabaseInstance() dispatchOnDatabaseThread:^{
                    [TGDatabaseInstance() channelMessageExists:conversationId messageId:messageId completion:^(bool exists, TGMessageSortKey key) {
                        if (exists) {
                            keyExists = true;
                            sortKey = TGMessageTransparentSortKeyMake(conversationId, TGMessageSortKeyTimestamp(key), TGMessageSortKeyMid(key), TGMessageSortKeySpace(key));
                        }
                    }];
                } synchronous:true];
                
                if (!keyExists) {
                    for (TGMessage *message in dict[@"messages"]) {
                        if (message.mid == messageId) {
                            sortKey = message.transparentSortKey;
                            
                            break;
                        }
                    }
                }
                
                [TGDatabaseInstance() addMessagesToChannel:conversationId messages:dict[@"messages"] deleteMessages:nil unimportantGroups:dict[@"unimportantGroups"] addedHoles:nil removedHoles:removedImportantHoles removedUnimportantHoles:removedUnimportantHoles updatedMessageSortKeys:nil returnGroups:false keepUnreadCounters:false skipFeedUpdate:true changedMessages:^(__unused NSArray *addedMessages, __unused NSArray *removedMessages, __unused NSDictionary *updatedMessages, __unused NSArray *addedUnimportantHoles, __unused NSArray *removedUnimportantHoles) {
                    [TGModernConversationCompanion dispatchOnMessageQueue:^{
                        __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                        if (strongSelf != nil) {
                            if (TGMessageTransparentSortKeySpace(sortKey) == TGMessageSpaceUnimportant && strongSelf->_displayVariant != TGChannelDisplayVariantAll) {
                                /*strongSelf->_displayVariant = TGChannelDisplayVariantAll;
                                [TGDatabaseInstance() updateChannelDisplayExpanded:strongSelf->_conversationId displayExpanded:true];*/
                            }
                            [strongSelf reloadVariantAtSortKey:sortKey group:nil jump:true top:false messageIdForVisibleHoleDirection:TGMessageTransparentSortKeyMid(sortKey) scrollBackMessageId:scrollBackMessageId animated:true];
                        }
                    }];
                }];
            }];
        }
    }];
}

- (void)controllerDidUpdateTypingActivity
{
    if (_isGroup) {
        [ActionStageInstance() dispatchOnStageQueue:^ {
            CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
            if (ABS(currentTime - _lastTypingActivity) >= 4.0) {
                _lastTypingActivity = currentTime;
                [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/conversation/(%lld)/activity/(typing)", _conversationId] options:@{@"accessHash": @(_accessHash)} watcher:self];
            }
        }];
    }
}

- (void)controllerDidCancelTypingActivity
{
}

- (UIView *)_conversationHeader
{
    /*if (_isGroup)
    {
        if (_migratedChannelHeaderView == nil)
        {
            _migratedChannelHeaderView = [[TGMigratedChannelConversationHeaderView alloc] initWithContext:self.viewContext title:_conversation.chatTitle];
            [_migratedChannelHeaderView sizeToFit];
        }
        return _migratedChannelHeaderView;
    }*/
    return nil;
}

- (SSignal *)userListForMention:(NSString *)mention canBeContextBot:(bool)canBeContextBot includeSelf:(bool)includeSelf
{   
    NSMutableArray *visibleUserIds = [[NSMutableArray alloc] init];
    
    TGModernConversationController *controller = self.controller;
    for (TGMessageModernConversationItem *item in [controller _items])
    {
        int32_t uid = (int32_t)(item->_message.fromUid);
        if (![visibleUserIds containsObject:@(uid)]) {
            [visibleUserIds addObject:@(uid)];
        }
    }
    
    SSignal *remoteMembersSignal = [[TGChannelManagementSignals channelMembers:_conversationId accessHash:_accessHash offset:0 count:32] mapToSignal:^SSignal *(NSDictionary *dict) {
        return [[TGDatabaseInstance() modify:^id{
            [TGDatabaseInstance() updateChannelCachedData:_conversationId block:^TGCachedConversationData *(TGCachedConversationData *data) {
                if (data == nil) {
                    data = [[TGCachedConversationData alloc] init];
                }
                
                NSMutableArray *sortedMemberDatas = [[NSMutableArray alloc] init];
                NSDictionary *memberDatas = dict[@"memberDatas"];
                for (TGUser *user in dict[@"users"]) {
                    TGCachedConversationMember *member = memberDatas[@(user.uid)];
                    if (member != nil) {
                        [sortedMemberDatas addObject:member];
                    }
                }
                
                return [data updateGeneralMembers:sortedMemberDatas];
            }];
            
            return [SSignal complete];
        }] switchToLatest];
    }];
    
    //search globally
    
    bool isGroup = _isGroup;
    
    SSignal *recentBotUids = canBeContextBot ? [TGRecentContextBotsSignal recentBots] : [SSignal single:@[]];
    
    return [[[SSignal mergeSignals:@[[SSignal combineSignals:@[[TGDatabaseInstance() channelCachedData:_conversationId], recentBotUids]], remoteMembersSignal]] mapToSignal:^SSignal *(NSArray *combinedResult) {
        
        TGCachedConversationData *cachedData = combinedResult[0];
        
        NSMutableSet *existingUsers = [[NSMutableSet alloc] init];
        if (!includeSelf) {
            [existingUsers addObject:@(TGTelegraphInstance.clientUserId)];
        }
        
        NSMutableArray *contextBots = [[NSMutableArray alloc] init];
        NSString *normalizedMention = [mention lowercaseString];
        for (NSNumber *nUserId in combinedResult[1]) {
            if (![existingUsers containsObject:nUserId]) {
                [existingUsers addObject:nUserId];
                
                TGUser *user = [TGDatabaseInstance() loadUser:[nUserId intValue]];
                if (user != nil && (normalizedMention.length == 0 || [[user.userName lowercaseString] hasPrefix:normalizedMention] || [[user.firstName lowercaseString] hasPrefix:normalizedMention] || [[user.lastName lowercaseString] hasPrefix:normalizedMention])) {
                    if (user.isContextBot) {
                        [contextBots addObject:user];
                    }
                }
            }
        }
        
        NSMutableDictionary *userDict = [[NSMutableDictionary alloc] init];
        for (TGCachedConversationMember *member in cachedData.generalMembers)
        {
            TGUser *user = [TGDatabaseInstance() loadUser:member.uid];
            if (user != nil && (includeSelf || user.uid != TGTelegraphInstance.clientUserId) && (normalizedMention.length == 0 || [[user.userName lowercaseString] hasPrefix:normalizedMention] || [[user.firstName lowercaseString] hasPrefix:normalizedMention] || [[user.lastName lowercaseString] hasPrefix:normalizedMention]))
            {
                if (![existingUsers containsObject:@(user.uid)]) {
                    [existingUsers addObject:@(user.uid)];
                    userDict[@(user.uid)] = user;
                }
            }
        }
        
        NSArray *sortedContextBots = contextBots;
        
        NSMutableArray *sortedUserList = [[NSMutableArray alloc] init];
        
        [sortedUserList addObjectsFromArray:sortedContextBots];
        
        if (isGroup) {
            for (NSNumber *nUid in visibleUserIds)
            {
                int32_t uid = [nUid intValue];
                TGUser *user = userDict[@(uid)];
                if (user == nil) {
                    TGUser *candidateUser = [TGDatabaseInstance() loadUser:uid];
                    if (candidateUser != nil && (includeSelf || candidateUser.uid != TGTelegraphInstance.clientUserId) && (normalizedMention.length == 0 || [[candidateUser.userName lowercaseString] hasPrefix:normalizedMention] || [[candidateUser.firstName lowercaseString] hasPrefix:normalizedMention] || [[candidateUser.lastName lowercaseString] hasPrefix:normalizedMention])) {
                        user = candidateUser;
                    }
                }
                
                if (user != nil && ![existingUsers containsObject:@(user.uid)]) {
                    [existingUsers addObject:@(user.uid)];
                    [sortedUserList addObject:user];
                    [userDict removeObjectForKey:@(uid)];
                    if (userDict.count == 0)
                        break;
                }
            }
            
            NSArray *sortedRemainingUsers = [[userDict allValues] sortedArrayUsingComparator:^NSComparisonResult(TGUser *user1, TGUser *user2) {
                return [user1.displayName compare:user2.displayName];
            }];
            
            [sortedUserList addObjectsFromArray:sortedRemainingUsers];
        }
        
        return [SSignal single:sortedUserList];
    }] deliverOn:[SQueue mainQueue]];
}

- (SSignal *)commandListForCommand:(NSString *)command
{
    return [[[TGDatabaseInstance() channelCachedData:_conversationId] mapToSignal:^SSignal *(TGCachedConversationData *cachedData) {
        if (cachedData.botInfos.count != 0) {
            NSString *normalizedCommand = [command lowercaseString];
            if ([normalizedCommand hasPrefix:@"/"])
                normalizedCommand = [normalizedCommand substringFromIndex:1];
            
            NSMutableArray *botUsers = [[NSMutableArray alloc] init];
            NSMutableArray *botInfoSignals = [[NSMutableArray alloc] init];
            NSMutableArray *initialStates = [[NSMutableArray alloc] init];
            for (NSNumber *nUid in [cachedData.botInfos allKeys])
            {
                TGUser *user = [TGDatabaseInstance() loadUser:[nUid intValue]];
                if (user.kind == TGUserKindBot || user.kind == TGUserKindSmartBot)
                {
                    [botUsers addObject:user];
                    [botInfoSignals addObject:[[SSignal single:cachedData.botInfos[nUid]] map:^id(TGBotInfo *botInfo) {
                        NSMutableArray *commands = [[NSMutableArray alloc] init];
                        for (TGBotComandInfo *commandInfo in botInfo.commandList) {
                            if (normalizedCommand.length == 0 || [[commandInfo.command lowercaseString] hasPrefix:normalizedCommand]) {
                                [commands addObject:commandInfo];
                            }
                        }
                        return commands;
                    }]];
                    [initialStates addObject:@[]];
                }
            }
            
            return [[SSignal combineSignals:botInfoSignals withInitialStates:initialStates] map:^id(NSArray *commandLists) {
                NSMutableArray *commands = [[NSMutableArray alloc] init];
                NSUInteger index = 0;
                for (NSArray *commandList in commandLists) {
                    [commands addObject:@[botUsers[index], commandList]];
                    index++;
                }
                
                return commands;
            }];
        } else {
            return [SSignal single:@[]];
        }
    }] deliverOn:[SQueue mainQueue]];
}

- (int64_t)attachedPeerId {
    return _migrationData.peerId;
}

- (void)setInvalidatedPts:(int32_t)invalidatedPts {
#ifdef DEBUG
    //invalidatedPts = 102;
#endif
    
    [TGModernConversationCompanion dispatchOnMessageQueue:^{
        if (_invalidatedPts != invalidatedPts) {
            _invalidatedPts = invalidatedPts;
            
            [self _validatePts];
        }
    }];
}

- (void)_validatePts {
    if (_invalidatedPts == 0) {
        return;
    }
    
    if (_updatingInvalidatedMessages) {
        _needsToValidatePts = true;
    } else {
        _needsToValidatePts = false;
        
        NSMutableArray *invalidatedMessageRanges = [[NSMutableArray alloc] init];
        int32_t minPts = 1;
        
        for (TGMessageModernConversationItem *item in _items) {
            if (item->_message.cid == _conversationId && item->_message.mid < TGMessageLocalMidBaseline) {
                if (item->_message.hole != nil || item->_message.group != nil) {
                    TLMessageRange$messageRange *lastRange = invalidatedMessageRanges.lastObject;
                    if (lastRange != nil && lastRange.max_id != 0) {
                        TLMessageRange$messageRange *nextRange = [[TLMessageRange$messageRange alloc] init];
                        nextRange.min_id = 0;
                        nextRange.max_id = 0;
                        [invalidatedMessageRanges addObject:nextRange];
                    }
                } else if (item->_message.mid > 0) {
                    if (item->_message.pts < _invalidatedPts) {
                        int32_t messagePts = MAX(1, item->_message.pts);
                        minPts = minPts == 1 ? messagePts : MIN(messagePts, minPts);
                        //TGLog(@"enqueue item %p (mid %d) to pts %d", item, item->_message.mid, item->_message.pts);
                        
                        TLMessageRange$messageRange *lastRange = invalidatedMessageRanges.lastObject;
                        if (lastRange == nil) {
                            lastRange = [[TLMessageRange$messageRange alloc] init];
                            lastRange.min_id = 0;
                            lastRange.max_id = 0;
                            [invalidatedMessageRanges addObject:lastRange];
                        }
                        
                        if (lastRange.max_id == 0) {
                            lastRange.min_id = item->_message.mid;
                            lastRange.max_id = item->_message.mid;
                        } else {
                            lastRange.min_id = MIN(lastRange.min_id, item->_message.mid);
                        }
                    }
                }
            }
        }
        
        if (invalidatedMessageRanges.count != 0) {
            TLMessageRange$messageRange *lastRange = invalidatedMessageRanges.lastObject;
            if (lastRange.max_id == 0) {
                [invalidatedMessageRanges removeLastObject];
            }
        }
        
        if (invalidatedMessageRanges.count != 0) {
            TGLog(@"Will invalidate message ranges to pts %d:", _invalidatedPts);
            for (TLMessageRange *range in invalidatedMessageRanges) {
                TGLog(@"    %d ... %d (pts %d)", range.min_id, range.max_id, minPts);
            }
            
            _updatingInvalidatedMessages = true;
            
            if (_updatingInvalidatedMessagesDisposable == nil) {
                _updatingInvalidatedMessagesDisposable = [[SMetaDisposable alloc] init];
            }
            
            __weak TGChannelConversationCompanion *weakSelf = self;
            int32_t validPts = _invalidatedPts;
            [_updatingInvalidatedMessagesDisposable setDisposable:[[TGChannelStateSignals validateMessageRanges:_conversationId pts:minPts validPts:validPts messageRanges:invalidatedMessageRanges] startWithNext:nil completed:^{
                [TGModernConversationCompanion dispatchOnMessageQueue:^{
                    __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                    if (strongSelf != nil) {
                        [strongSelf _messageRangesValidated:invalidatedMessageRanges pts:validPts];
                        
                        strongSelf->_updatingInvalidatedMessages = false;
                        
                        if (strongSelf->_needsToValidatePts) {
                            [strongSelf _validatePts];
                        }
                    }
                }];
            }]];
        }
    }
}

- (void)_messageRangesValidated:(NSArray *)messageRanges pts:(int32_t)pts {
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
    for (TLMessageRange *range in messageRanges) {
        [indexSet addIndexesInRange:NSMakeRange(range.min_id, range.max_id - range.min_id + 1)];
    }
    for (NSUInteger i = 0; i < _items.count; i++) {
        TGMessageModernConversationItem *item = _items[i];
        
        if ([indexSet containsIndex:item->_message.mid]) {
            item = [item deepCopy];
            item->_message.pts = pts;
            [((NSMutableArray *)_items) replaceObjectAtIndex:i withObject:item];
            //TGLog(@"update %p (mid %d) to pts %d", item, item->_message.mid, pts);
        }
    }
}

- (void)_itemsUpdated {
    [TGModernConversationCompanion dispatchOnMessageQueue:^{
        [super _itemsUpdated];
        
        [self _validatePts];
    }];
}

- (void)_performFastScrollDown:(bool)becauseOfSendTextAction becauseOfNavigation:(bool)becauseOfNavigation
{
    [TGDatabaseInstance() dispatchOnDatabaseThread:^
    {
        [TGDatabaseInstance() channelMessages:_conversationId maxTransparentSortKey:TGMessageTransparentSortKeyUpperBound(_conversationId) count:20 important:_displayVariant == TGChannelDisplayVariantImportant mode:TGChannelHistoryRequestEarlier completion:^(NSArray *messages, bool hasLater) {
            
            _historyBelow = hasLater;
            
            NSMutableArray *sortedTopMessages = [[NSMutableArray alloc] initWithArray:messages];
            [sortedTopMessages sortUsingComparator:^NSComparisonResult(TGMessage *message1, TGMessage *message2)
            {
                NSTimeInterval date1 = message1.date;
                NSTimeInterval date2 = message2.date;
                
                if (ABS(date1 - date2) < DBL_EPSILON)
                {
                    if (message1.mid > message2.mid)
                        return NSOrderedAscending;
                    else
                        return NSOrderedDescending;
                }
                
                return date1 > date2 ? NSOrderedAscending : NSOrderedDescending;
            }];
            
            [TGModernConversationCompanion dispatchOnMessageQueue:^
            {
                _historyBelow = false;
                _historyAbove = true;
                if (_migrationData.peerId != 0) {
                    _migrationHistoryAbove = true;
                }
                
                [self _replaceMessagesWithFastScroll:sortedTopMessages intent:becauseOfNavigation ? TGModernConversationAddMessageIntentGeneric : (becauseOfSendTextAction ? TGModernConversationAddMessageIntentSendTextMessage : TGModernConversationAddMessageIntentSendOtherMessage) scrollToMessageId:0 peerId:0 scrollBackMessageId:0 animated:!becauseOfNavigation];
            }];
        }];
    } synchronous:false];
}

- (bool)shouldFastScrollDown {
    return _historyBelow;
}

- (bool)canAddNewMessagesToTop {
    return !_historyBelow;
}

- (SSignal *)editingContextForMessageWithId:(int32_t)messageId {
    return [[TGChannelManagementSignals messageEditData:_conversationId accessHash:_accessHash messageId:messageId] catch:^SSignal *(__unused id error) {
        return [SSignal single:nil];
    }];
}

- (SSignal *)saveEditedMessageWithId:(int32_t)messageId text:(NSString *)text entities:(NSArray *)entities disableLinkPreviews:(bool)disableLinkPreviews {
    __weak TGChannelConversationCompanion *weakSelf = self;
    int64_t peerId = _conversationId;
    SSignal *notModified = [[TGDatabaseInstance() modify:^id{
        TGMessage *message = [TGDatabaseInstance() loadMessageWithMid:messageId peerId:peerId];
        NSString *messageText = message.text;
        for (id attachment in message.mediaAttachments) {
            if ([attachment isKindOfClass:[TGImageMediaAttachment class]]) {
                messageText = ((TGImageMediaAttachment *)attachment).caption;
            } else if ([attachment isKindOfClass:[TGVideoMediaAttachment class]]) {
                messageText = ((TGVideoMediaAttachment *)attachment).caption;
            } else if ([attachment isKindOfClass:[TGDocumentMediaAttachment class]]) {
                messageText = ((TGDocumentMediaAttachment *)attachment).caption;
            }
        }
        
        if (TGStringCompare(text, messageText) && !disableLinkPreviews) {
            return [SSignal complete];
        } else {
            return [SSignal fail:nil];
        }
    }] switchToLatest];
    
    notModified = [SSignal fail:nil];
    
    return [notModified catch:^SSignal *(__unused id error) {
        return [[[[TGGroupManagementSignals editMessage:_conversationId accessHash:_accessHash messageId:messageId text:text entities:entities disableLinksPreview:disableLinkPreviews media:nil] mapToSignal:^SSignal *(TGMessage *updatedMessage) {
            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
            if (strongSelf != nil) {
                TGMessage *message = updatedMessage;
                if (message == nil) {
                    return [SSignal fail:nil];
                } else {
                    return [SSignal single:message];
                }
            }
            
            return [SSignal complete];
        }] deliverOn:[TGModernConversationCompanion messageQueue]] onNext:^(TGMessage *message) {
            __strong TGChannelConversationCompanion *strongSelf = weakSelf;
            if (strongSelf != nil) {
                [strongSelf updateMessagesLive:@{@(message.mid): message} animated:false];
            }
        }];
    }];
}

- (SSignal *)updatePinnedMessage:(int32_t)messageId {
    SSignal *askSignal = [SSignal single:@true];
    bool isChannelGroup = _isGroup;
    
    if (messageId == 0) {
        askSignal = [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber) {
            [TGCustomAlertView presentAlertWithTitle:nil message:TGLocalized(@"Conversation.UnpinMessageAlert") cancelButtonTitle:TGLocalized(@"Common.No") okButtonTitle:TGLocalized(@"Common.Yes") completionBlock:^(bool okButtonPressed) {
                [subscriber putNext:@(okButtonPressed)];
                [subscriber putCompletion];
            }];
            
            return [[SBlockDisposable alloc] initWithBlock:^{
            }];
        }];
    } else {
        askSignal = [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber) {
            if (_isGroup)
            {
                TGCustomAlertView *alertView = [TGCustomAlertView presentAlertWithTitle:nil message:isChannelGroup ? TGLocalized(@"Conversation.PinMessageAlertGroup") : TGLocalized(@"Conversation.PinMessageAlertGroup") cancelButtonTitle:TGLocalized(@"Conversation.PinMessageAlert.OnlyPin") okButtonTitle:TGLocalized(@"Common.OK") completionBlock:^(bool okButtonPressed) {
                    [subscriber putNext:@(okButtonPressed)];
                    [subscriber putCompletion];
                }];
                alertView.noActionOnDimTap = true;
            }
            else
            {
                [subscriber putNext:@(true)];
                [subscriber putCompletion];
            }
            
            return [[SBlockDisposable alloc] initWithBlock:^{
            }];
        }];
    }
    
    return [[askSignal deliverOn:[SQueue mainQueue]] mapToSignal:^SSignal *(NSNumber *update) {
        if ([update boolValue] || messageId != 0) {
            return [SSignal defer:^SSignal *{
                TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
                [progressWindow showWithDelay:0.2];
                
                return [[[[TGChannelManagementSignals updatePinnedMessage:_conversationId accessHash:_accessHash messageId:messageId notify:[update boolValue]] catch:^SSignal *(id error) {
                    NSString *errorType = [[TGTelegramNetworking instance] extractNetworkErrorType:error];
                    if ([errorType isEqualToString:@"CHAT_NOT_MODIFIED"]) {
                        return [SSignal complete];
                    }
                    return [SSignal fail:nil];
                }] timeout:5.0 onQueue:[SQueue concurrentDefaultQueue] orSignal:[SSignal fail:@"timeout"]] onDispose:^{
                    TGDispatchOnMainThread(^{
                        [progressWindow dismiss:true];
                    });
                }];
            }];
        } else {
            return [SSignal complete];
        }
    }];
}

- (bool)canCreateLinksToMessages {
    return _conversation.username.length != 0;
}

- (SSignal *)applyModerateMessageActions:(NSSet *)actions messageIds:(NSArray *)messageIds {
    if (messageIds.count == 0)
        return [SSignal fail:nil];
    
    NSMutableArray *signals = [[NSMutableArray alloc] init];
    
    TGMessage *anyMessage = [TGDatabaseInstance() loadMessageWithMid:[messageIds[0] intValue] peerId:_conversationId];
    if (anyMessage == nil) {
        return [SSignal fail:nil];
    }
    
    if ([actions containsObject:@(TGMessageModerateActionDeleteAll)]) {
        TGUser *user = [TGDatabaseInstance() loadUser:(int32_t)anyMessage.fromUid];
        if (user != nil) {
            [signals addObject:[[TGChannelManagementSignals removeAllUserMessages:_conversationId accessHash:_accessHash user:user] catch:^SSignal *(__unused id error) {
                return [SSignal complete];
            }]];
        }
    } else if ([actions containsObject:@(TGMessageModerateActionDelete)]) {
        SSignal *signal = [SSignal defer:^SSignal *{
            [self _deleteMessages:messageIds animated:true];
            [self controllerDeletedMessages:messageIds forEveryone:false completion:nil];
            return [SSignal complete];
        }];
        [signals addObject:signal];
    }
    
    if ([actions containsObject:@(TGMessageModerateActionReport)]) {
        TGUser *user = [TGDatabaseInstance() loadUser:(int32_t)anyMessage.fromUid];
        if (user != nil) {
            SSignal *signal = [[TGChannelManagementSignals reportUserSpam:_conversationId accessHash:_accessHash user:user messageIds:messageIds] catch:^SSignal *(__unused id error) {
                return [SSignal complete];
            }];
            [signals addObject:signal];
        }
    }
    
    if ([actions containsObject:@(TGMessageModerateActionBan)]) {
        TGUser *user = [TGDatabaseInstance() loadUser:(int32_t)anyMessage.fromUid];
        if (user != nil) {
            TGChannelBannedRights *rights = [[TGChannelBannedRights alloc] initWithBanReadMessages:true banSendMessages:true banSendMedia:true banSendStickers:true banSendGifs:false banSendGames:false banSendInline:false banEmbedLinks:true timeout:INT32_MAX];
            SSignal *signal = [[[TGChannelManagementSignals updateChannelBannedRightsAndGetMembership:_conversationId accessHash:_accessHash user:user rights:rights] onNext:^(TGCachedConversationMember *resultMember) {
                [TGDatabaseInstance() updateChannelCachedData:_conversationId block:^TGCachedConversationData *(TGCachedConversationData *data) {
                    if (data == nil) {
                        data = [[TGCachedConversationData alloc] init];
                    }
                    
                    return [data updateMemberBannedRights:user.uid rights:rights timestamp:resultMember != nil ? resultMember.timestamp : (int32_t)[[TGTelegramNetworking instance] approximateRemoteTime] isMember:resultMember != nil kickedById:TGTelegraphInstance.clientUserId];
                }];
            }] catch:^SSignal *(__unused id error) {
                return [SSignal complete];
            }];
            [signals addObject:signal];
        }
    }
    
    return [SSignal combineSignals:signals];
}

- (bool)canReportMessage:(TGMessage *)message {
    if (message.cid != _conversationId) {
        return false;
    }
    
    if (message.actionInfo != nil) {
        return false;
    }
    
    if (!message.outgoing) {
        return true;
    }
    return false;
}

- (void)contactLinkTitlePanelBlockContactPressed:(TGModernConversationContactLinkTitlePanel *)__unused panel {
    SMetaDisposable *metaDisposable = [[SMetaDisposable alloc] init];
    id<SDisposable> disposable = [[[TGServiceSignals reportSpam:_conversationId accessHash:_accessHash] onDispose:^{
        [TGTelegraphInstance.disposeOnLogout remove:metaDisposable];
    }] startWithNext:nil];
    [metaDisposable setDisposable:disposable];
    [TGTelegraphInstance.disposeOnLogout add:metaDisposable];
    
    [TGAppDelegateInstance.rootController.dialogListController.dialogListCompanion deleteItem:[[TGConversation alloc] initWithConversationId:_conversationId unreadCount:0 serviceUnreadCount:0] animated:false];
    
    TGModernConversationController *controller = self.controller;
    [controller.navigationController popToRootViewControllerAnimated:true];
}

- (void)contactLinkTitlePanelDismissed:(TGModernConversationContactLinkTitlePanel *)__unused panel {
    [TGDatabaseInstance() hideReportSpamForPeerId:_conversationId];
}

- (void)reportChannelPressed {
    TGModernConversationController *controller = self.controller;
    __weak TGChannelConversationCompanion *weakSelf = self;
    [[[TGCustomActionSheet alloc] initWithTitle:nil actions:@[
    [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"ReportPeer.ReasonSpam") action:@"spam"],
    [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"ReportPeer.ReasonViolence") action:@"violence"],
    [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"ReportPeer.ReasonPornography") action:@"pornography"],
    [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"ReportPeer.ReasonCopyright") action:@"copyright"],
    [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"ReportPeer.ReasonOther") action:@"other"],
    [[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]] actionBlock:^(__unused id target, NSString *action) {
        __strong TGChannelConversationCompanion *strongSelf = weakSelf;
        if (strongSelf != nil) {
            if (![action isEqualToString:@"cancel"]) {
                TGReportPeerReason reason = TGReportPeerReasonSpam;
                if ([action isEqualToString:@"spam"]) {
                    reason = TGReportPeerReasonSpam;
                } else if ([action isEqualToString:@"violence"]) {
                    reason = TGReportPeerReasonViolence;
                } else if ([action isEqualToString:@"pornography"]) {
                    reason = TGReportPeerReasonPornography;
                } else if ([action isEqualToString:@"copyright"]) {
                    reason = TGReportPeerReasonCopyright;
                } else if ([action isEqualToString:@"other"]) {
                    reason = TGReportPeerReasonOther;
                }
                
                void (^reportBlock)(NSString *) = ^(NSString *otherText) {
                    TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
                    [progressWindow showWithDelay:0.1];
                    
                    [[[[TGAccountSignals reportPeer:strongSelf->_conversation.conversationId accessHash:strongSelf->_conversation.accessHash reason:reason otherText:otherText] deliverOn:[SQueue mainQueue]] onDispose:^{
                        TGDispatchOnMainThread(^{
                            [progressWindow dismiss:true];
                        });
                    }] startWithNext:nil error:^(__unused id error) {
                        [TGCustomAlertView presentAlertWithTitle:nil message:TGLocalized(@"Login.UnknownError") cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
                    } completed:^{
                        __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                        if (strongSelf != nil) {
                            TGModernConversationController *controller = strongSelf.controller;
                            [controller dismissViewControllerAnimated:true completion:nil];
                        }
                        
                        [TGCustomAlertView presentAlertWithTitle:nil message:TGLocalized(@"ReportPeer.AlertSuccess") cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil];
                    }];
                };
                
                if (reason == TGReportPeerReasonOther) {
                    TGReportPeerOtherTextController *controller = [[TGReportPeerOtherTextController alloc] initWithCompletion:^(NSString *text) {
                        if (text.length != 0) {
                            reportBlock(text);
                        }
                    }];
                    __strong TGChannelConversationCompanion *strongSelf = weakSelf;
                    if (strongSelf != nil) {
                        TGModernConversationController *myController = strongSelf.controller;
                        [myController presentViewController:[TGNavigationController navigationControllerWithControllers:@[controller]] animated:true completion:nil];
                    }
                } else {
                    reportBlock(nil);
                }
            }
        }
    } target:self] showInView:controller.view];
}

- (void)updateMessagesLive:(NSDictionary *)messageIdToMessage animated:(bool)animated {
    [super updateMessagesLive:messageIdToMessage animated:animated];
    
    TGDispatchOnMainThread(^{
        if (_pinnedMessagePanel != nil && messageIdToMessage[@(_pinnedMessagePanel.message.mid)] != nil){
            TGMessage *message = messageIdToMessage[@(_pinnedMessagePanel.message.mid)];
            [_pinnedMessagePanel updateMessage:message];
        }
    });
}

- (SSignal *)primaryTitlePanel {
    return _primaryPanel.signal;
}

- (TGModernGalleryController *)galleryControllerForAvatar
{
    if (_conversation.chatPhotoFullSmall.length == 0)
        return nil;
    
    TGModernGalleryController *modernGallery = [[TGModernGalleryController alloc] initWithContext:[TGLegacyComponentsContext shared]];
    modernGallery.model = [[TGGroupAvatarGalleryModel alloc] initWithPeerId:_conversationId accessHash:_accessHash messageId:0 legacyThumbnailUrl:_conversation.chatPhotoFullSmall legacyUrl:_conversation.chatPhotoFullBig imageSize:CGSizeMake(640.0f, 640.0f)];
    
    return modernGallery;
}

- (id)acquireAudioRecordingActivityHolder {
    if (_isGroup) {
        return [super acquireAudioRecordingActivityHolder];
    }
    return nil;
}

- (id)acquireVideoMessageRecordingActivityHolder {
    if (_isGroup) {
        return [super acquireVideoMessageRecordingActivityHolder];
    }
    return nil;
}

- (bool)canSendMedia {
    return !_bannedRights.banSendMedia;
}

- (bool)canSendGifs {
    return !_bannedRights.banSendGifs;
}

- (bool)canSendGames {
    return !_bannedRights.banSendGames;
}

- (bool)canSendInline {
    return !_bannedRights.banSendInline;
}

- (bool)canSendStickers {
    return !_bannedRights.banSendStickers;
}

- (bool)canAttachLinkPreviews {
    return !_bannedRights.banEmbedLinks;
}

- (bool)allowLiveLocations {
    return [super allowLiveLocations] && [self canPostMessages];
}

- (bool)useOnlyLocalLiveLocations {
    return !_conversation.isChannelGroup;
}

- (NSNumber *)inlineMediaRestrictionTimeout {
    if (_bannedRights != nil && _bannedRights.banSendInline) {
        return @(_bannedRights.timeout);
    }
    return nil;
}

- (NSNumber *)mediaRestrictionTimeout {
    if (_bannedRights != nil && _bannedRights.banSendMedia) {
        return @(_bannedRights.timeout);
    }
    return nil;
}

- (NSNumber *)stickerRestrictionTimeout {
    if (_bannedRights != nil && _bannedRights.banSendStickers) {
        return @(_bannedRights.timeout);
    }
    return nil;
}

- (bool)messageSearchByUserAvailable {
    return _isGroup;
}

- (bool)suppressesOutgoingUnreadContents {
    return !_isGroup;
}

@end
