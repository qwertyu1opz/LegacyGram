
#ifndef IOS6_NOOP_LOG
#define IOS6_NOOP_LOG(...) do { } while (0)
#endif
#include "TLMetaClassStore.h"
#import <sys/utsname.h>

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "NSData+GZip.h"
#import "NSInputStream+TL.h"

#import "TLCompressedObject.h"
#import "TLMessageContainer.h"
#import "TLRpcResult.h"
#import "TLRPCphone_sendSignalingData.h"

#import "TLResPQ$resPQ_manual.h"
#import "TLMsgsAck$msgs_ack_manual.h"
#import "TLMessage$modernMessage.h"
#import "TLMessage$modernMessageService.h"
#import "TLMessage.h"
#import "TLWebPage_manual.h"
#import "TLWebPage.h"
#import "TLUser$modernUser.h"
#import "TLDcOption$modernDcOption.h"
#import "TLUpdates$modernUpdateShortMessage.h"
#import "TLUpdates$modernUpdateShortChatMessage.h"
#import "TLaccount_PasswordInputSettings_manual.h"
#import "TLmessages_Messages$modernChannelMessages.h"
#import "TLmessages_Messages.h"
#import "TLPeerSettings.h"
#import "TLBotInfo.h"
#import "TLBotCommand.h"
#import "TLReplyMarkup.h"
#import "TLKeyboardButton.h"
#import "TLKeyboardButtonRow.h"
#import "TLchannels_ChannelParticipants.h"
#import "TLChannelParticipant.h"
#import "TLUpdate.h"
#import "TLUpdates.h"
#import "TLUpdates$updateShortSentMessage.h"
#import "TLUpdates_ChannelDifference_manual.h"
#import "TLupdates_ChannelDifference.h"
#import "TLupdates_Difference.h"
#import "TLupdates_State.h"
#import "TLChat$channel.h"
#import "TLChatFull$channelFull.h"
#import "TLChat$chat.h"
#import "TLChatPhoto.h"
#import "TLChatParticipants$chatParticipantsForbidden.h"
#import "TLWebPage$webPageExternal.h"
#import "TLMessages_BotResults$botResults.h"
#import "TLBotInlineMessage$botInlineMessageMediaAuto.h"
#import "TLBotInlineMessage$botInlineMessageText.h"
#import "TLBotInlineResult$botInlineResult.h"
#import "TLDocumentAttribute$documentAttributeAudio.h"
#import "TLDocument.h"
#import "TLDocumentAttribute.h"
#import "TLMessageAction.h"
#import "TLMessageEntity.h"
#import "TLMessageFwdHeader$messageFwdHeader.h"
#import "TLUserFull$userFull.h"
#import "TLUpdate$updateChannelTooLong.h"
#import "TLauth_SentCode$auth_sentCode.h"
#import "TLmessages_BotCallbackAnswer$botCallbackAnswer.h"
#import "TLBotInlineResult$botInlineMediaResult.h"
#import "TLBotInlineMessage$botInlineMessageMediaGeo.h"
#import "TLBotInlineMessage$botInlineMessageMediaVenue.h"
#import "TLBotInlineMessage$botInlineMessageMediaContact.h"
#import "TLDialog$dialog.h"
#import "TLDialog$dialogFeed.h"
#import "TLPeer.h"
#import "TLImportedContact.h"
#import "TLDraftMessage$draftMessage.h"
#import "TLChatInvite$chatInvite.h"
#import "TLConfig$config.h"
#import "TLGame$game.h"
#import "TLPageBlock$pageBlockEmbed.h"
#import "TLPhoneCall.h"
#import "TLPhoneCall$phoneCallWaiting.h"
#import "TLUpdate$updateServiceNotification.h"
#import "TLPhoneCall$phoneCallDiscarded.h"
#import "TLPhoneConnection.h"
#import "TLUpdate$updatePinnedDialogs.h"
#import "TLMessageAction$messageActionPhoneCall.h"
#import "TLInvoice$invoice.h"
#import "TLMessageMedia$messageMediaInvoice.h"
#import "TLpayments_PaymentForm$payments_paymentForm.h"
#import "TLpayments_SavedInfo$payments_savedInfo.h"
#import "TLPaymentRequestedInfo$paymentRequestedInfo.h"
#import "TLPayments_PaymentCeceipt$payments_paymentReceipt.h"
#import "TLpayments_ValidatedRequestedInfo$payments_validatedRequestedInfo.h"
#import "TLLangPackStringPluralized.h"
#import "TLChat$channelForbidden.h"
#import "TLMessageMedia$messageMediaPhoto.h"
#import "TLMessageMedia$messageMediaDocument.h"
#import "TLMessageMedia.h"
#import "TLGeoPoint.h"
#import "TLPhoto.h"
#import "TLPhotoSize.h"
#import "TLContact.h"
#import "TLcontacts_Contacts.h"
#import "TLcontacts_Blocked.h"
#import "TLcontacts_ImportedContacts.h"
#import "TLmessages_Dialogs.h"
#import "TLDialog.h"
#import "TLPopularContact.h"
#import "TLchannelDifferenceTooLong.h"
#import "TLmessages_FeedMessages$messages_feedMessages.h"
#import "TLchannels_FeedSources$channels_feedSources.h"
#import "TLInputSingleMedia$inputSingleMedia.h"
#import "TLStickerSet$stickerSet.h"
#import "TLStickerSetCovered.h"
#import "TLmessages_AllStickers.h"
#import "TLmessages_FavedStickers.h"
#import "TLmessages_FeaturedStickers.h"
#import "TLmessages_FoundStickerSets.h"
#import "TLmessages_RecentStickers.h"
#import "TLmessages_StickerSet.h"
#import "TLmessages_StickerSetInstallResult.h"
#import "TLInputStickerSet.h"
#import "TLStickerPack.h"
#import "TLMaskCoords.h"
#import "TLauth_ExportedAuthorization.h"
#import "TLUpdate$updateReadFeed.h"
#import "TLhelp_ProxyData.h"
#import "TLhelp_TermsOfService$help_termsOfService.h"
#import "TLSecureValue$secureValue.h"
#import "TLInputSecureValue$inputSecureValue.h"
#import "TLaccount_AuthorizationForm$account_authorizationForm.h"
#import "TLPeerNotifySettings$peerNotifySettings.h"
#import "TLhelp_DeepLinkInfo$help_deepLinkInfo.h"
#import "TLhelp_AppUpdate$help_appUpdate.h"
#import "TLaccount_Password$account_password.h"
#import "TLaccount_PasswordSettings$account_passwordSettings.h"
#import "TLUserStatus.h"
#import "TLUserProfilePhoto.h"
#import "TLContactStatus.h"

#import "TLDocumentAttributeSticker.h"

#import "TLBool.h"

#import "TLauth_Authorization$auth_authorization.h"

#include <map>
#include <set>

#include <zlib.h>

struct TLMetaTypeArgumentWithName : public TLMetaTypeArgument
{
    std::vector<char> name;
};

static std::unordered_map<int32_t, NSString *> hashToStringMap;
static TLupdates_State *CodexLastReadUpdatesState = nil;

std::unordered_map<int32_t, std::shared_ptr<TLMetaConstructor> > TLMetaClassStore::constructorsBySignature;
std::unordered_map<int32_t, std::shared_ptr<TLMetaConstructor> > TLMetaClassStore::constructorsByName;
std::unordered_map<int32_t, std::shared_ptr<TLMetaType> > TLMetaClassStore::typesByName;
std::unordered_map<int32_t, TLMetaTypeArgument> TLMetaClassStore::vectorElementTypesByConstructor;

std::unordered_map<int32_t, id<TLObject> > TLMetaClassStore::objectClassesByConstructorNames;
std::unordered_map<int32_t, id<TLVector> > TLMetaClassStore::vectorClassesBySignature;

std::unordered_map<int32_t, id<TLObject> > TLMetaClassStore::manualObjectParsers;
std::unordered_map<int32_t, id<TLObject> > TLMetaClassStore::manualObjectSerializers;

static int32_t CodexCurrentManualSignature = 0;
// Diagnostic only; several parsing queues can update it concurrently.
static __unsafe_unretained NSString *CodexCurrentManualParser = nil;

static void addHashToString(int32_t hash, NSString *string)
{
    hashToStringMap.insert(std::pair<int32_t, NSString *>(hash, string));
}

static NSString *stringForHash(int32_t hash)
{
    std::unordered_map<int32_t, NSString *>::iterator it = hashToStringMap.find(hash);
    if (it == hashToStringMap.end())
        return [NSString stringWithFormat:@"#%.8x", hash];
    return it->second;
}

static NSString *CodexPanicReportEndpoint()
{
    return @"";
}

static NSString *CodexPanicReportSecret()
{
    return @"";
}

static NSString *CodexPanicEscape(NSString *string)
{
    if (string == nil)
        return @"";
    NSString *escaped = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
    return escaped;
}

static NSString *CodexPanicNormalizedMessage(NSString *message)
{
    if (message.length == 0)
        return @"";
    NSError *regexError = nil;
    NSRegularExpression *userInfoRegex = [NSRegularExpression regularExpressionWithPattern:@"UserInfo=0x[0-9a-fA-F]+" options:0 error:&regexError];
    NSString *result = userInfoRegex == nil ? message : [userInfoRegex stringByReplacingMatchesInString:message options:0 range:NSMakeRange(0, message.length) withTemplate:@"UserInfo=0xADDR"];
    NSRegularExpression *longPointerRegex = [NSRegularExpression regularExpressionWithPattern:@"0x[0-9a-fA-F]{9,}" options:0 error:&regexError];
    if (longPointerRegex == nil)
        return result;
    return [longPointerRegex stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:@"0xADDR"];
}

static NSString *CodexPanicDeviceMachine()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    return [[NSString alloc] initWithUTF8String:systemInfo.machine] ?: @"?";
}

static NSString *CodexPanicDeviceMarketingName(NSString *machine)
{
    static NSDictionary *names = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        names = @{
            @"iPhone3,1": @"iPhone 4", @"iPhone3,2": @"iPhone 4", @"iPhone3,3": @"iPhone 4",
            @"iPhone4,1": @"iPhone 4S",
            @"iPhone5,1": @"iPhone 5", @"iPhone5,2": @"iPhone 5",
            @"iPhone5,3": @"iPhone 5c", @"iPhone5,4": @"iPhone 5c",
            @"iPhone6,1": @"iPhone 5s", @"iPhone6,2": @"iPhone 5s",
            @"iPad2,1": @"iPad 2", @"iPad2,2": @"iPad 2", @"iPad2,3": @"iPad 2", @"iPad2,4": @"iPad 2",
            @"iPad2,5": @"iPad mini", @"iPad2,6": @"iPad mini", @"iPad2,7": @"iPad mini",
            @"iPad3,1": @"iPad 3", @"iPad3,2": @"iPad 3", @"iPad3,3": @"iPad 3",
            @"iPad3,4": @"iPad 4", @"iPad3,5": @"iPad 4", @"iPad3,6": @"iPad 4",
            @"iPod5,1": @"iPod touch 5"
        };
    });
    NSString *name = [names objectForKey:machine];
    return name ?: machine ?: @"?";
}

static NSString *CodexPanicDeviceDescription()
{
    NSString *machine = CodexPanicDeviceMachine();
    NSString *name = CodexPanicDeviceMarketingName(machine);
    if ([name isEqualToString:machine])
        return machine;
    return [NSString stringWithFormat:@"%@ (%@)", name, machine];
}

static NSString *CodexPanicReportContext()
{
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?";
    NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"?";
    UIDevice *device = [UIDevice currentDevice];
    NSString *idiom = device.userInterfaceIdiom == UIUserInterfaceIdiomPad ? @"iPad" : @"iPhone";
    return [NSString stringWithFormat:@"version=%@ build=%@ os=%@ %@ idiom=%@ device=%@", version, build, device.systemName, device.systemVersion, idiom, CodexPanicDeviceDescription()];
}

static void CodexReportCritical(NSString *event, NSString *message)
{
    NSString *endpoint = CodexPanicReportEndpoint();
    if (endpoint.length == 0)
        return;
    
    NSString *secret = CodexPanicReportSecret();
    NSString *normalizedMessage = CodexPanicNormalizedMessage(message);
    NSString *key = [NSString stringWithFormat:@"%@:%@", event ?: @"", normalizedMessage ?: @""];
    static NSMutableDictionary *lastReports = nil;
    static NSLock *reportLock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        lastReports = [[NSMutableDictionary alloc] init];
        reportLock = [[NSLock alloc] init];
    });
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    [reportLock lock];
    NSNumber *last = [lastReports objectForKey:key];
    if (last != nil && now - [last doubleValue] < 120.0)
    {
        [reportLock unlock];
        return;
    }
    [lastReports setObject:@(now) forKey:key];
    [reportLock unlock];
    
    NSString *messageWithContext = [NSString stringWithFormat:@"%@\n%@", CodexPanicReportContext(), normalizedMessage ?: @""];
    NSString *bodyString = [NSString stringWithFormat:@"secret=%@&event=%@&message=%@",
        CodexPanicEscape(secret),
        CodexPanicEscape(event),
        CodexPanicEscape(messageWithContext)];
    NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:endpoint];
    if (url == nil || body == nil)
        return;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        NSHTTPURLResponse *httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        NSString *body = data.length == 0 ? @"" : [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        TGLog(@"IOS6PANIC report event=%@ status=%d error=%@ body=%@", event, httpResponse != nil ? (int)httpResponse.statusCode : 0, connectionError, body);
    }];
}

static id<TLObject> CodexReadObject(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t signature = [is readInt32];
    return TLMetaClassStore::constructObject(is, signature, environment, nil, error);
}

static NSArray *CodexReadObjectVector(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error);

static int32_t CodexReadReplyHeaderCompat(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t signature = [is readInt32];
    if (signature == (int32_t)0xafbc09db || signature == (int32_t)0x1b97dd66)
    {
        int32_t flags = [is readInt32];
        int32_t replyToMessageId = 0;
        if (flags & (1 << 4))
            replyToMessageId = [is readInt32];
        if (flags & (1 << 0))
            CodexReadObject(is, environment, error);
        if (flags & (1 << 5))
            CodexReadObject(is, environment, error);
        if (flags & (1 << 8))
            CodexReadObject(is, environment, error);
        if (flags & (1 << 1))
            [is readInt32];
        if (flags & (1 << 6))
            [is readString];
        if (flags & (1 << 7))
            CodexReadObjectVector(is, environment, error);
        if (flags & (1 << 10))
            [is readInt32];
        if (signature == (int32_t)0x1b97dd66 && (flags & (1 << 11)))
            [is readInt32];
        if (signature == (int32_t)0x1b97dd66 && (flags & (1 << 12)))
            [is readBytes];
        TGLog(@"IOS6AUTH skipped replyHeader sig=0x%08x flags=0x%08x", signature, flags);
        return replyToMessageId;
    }
    if (signature > 0 && signature < 10000000)
        return signature;
    TLMetaClassStore::constructObject(is, signature, environment, nil, error);
    return 0;
}

static NSArray *CodexReadObjectVectorWithMarker(NSInputStream *is, int32_t vectorMarker, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error);
static NSArray *CodexReadObjectVectorOrSingleWithMarker(NSInputStream *is, int32_t vectorMarker, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error);

static NSArray *CodexReadObjectVector(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t vectorMarker = [is readInt32];
    return CodexReadObjectVectorWithMarker(is, vectorMarker, environment, error);
}

static NSArray *CodexReadMaybeDoubleObjectVectorWithMarker(NSInputStream *is, int32_t vectorMarker, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    if (vectorMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
    {
        int32_t nextMarker = [is readInt32];
        TGLog(@"IOS6AUTH vector marker followed by 0x%x", nextMarker);
        return CodexReadObjectVectorWithMarker(is, nextMarker, environment, error);
    }
    return CodexReadObjectVectorWithMarker(is, vectorMarker, environment, error);
}

static NSArray *CodexReadObjectVectorWithMarker(NSInputStream *is, int32_t vectorMarker, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t count = 0;
    if (vectorMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
        count = [is readInt32];
    else if (vectorMarker >= 0 && vectorMarker <= 10000)
        count = vectorMarker;
    else
    {
        TGLog(@"IOS6AUTH expected vector/count, got 0x%x manual=0x%08x parser=%@", vectorMarker, CodexCurrentManualSignature, CodexCurrentManualParser);
        id object = TLMetaClassStore::constructObject(is, vectorMarker, environment, nil, error);
        if (error != NULL && *error != nil)
        {
            TGLog(@"IOS6AUTH dropping singleton-vector parse error marker=0x%08x object=%@ error=%@", vectorMarker, object != nil ? NSStringFromClass([object class]) : nil, *error);
            *error = nil;
        }
        else
            TGLog(@"IOS6AUTH dropped singleton where vector expected marker=0x%08x object=%@", vectorMarker, object != nil ? NSStringFromClass([object class]) : nil);
        return @[];
    }
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)MAX(0, count)];
    for (int32_t i = 0; i < count; i++)
    {
        int32_t objectSignature = [is readInt32];
        if (objectSignature == 0 && CodexCurrentManualSignature == (int32_t)0x8fd4c4d8)
        {
            TGLog(@"IOS6AUTH skipping zero document attribute index=%d/%d", i, count);
            continue;
        }
        id object = TLMetaClassStore::constructObject(is, objectSignature, environment, nil, error);
        if (object != nil)
            [array addObject:object];
        if (error != NULL && *error != nil)
        {
            TGLog(@"IOS6AUTH vector failed index=%d/%d sig=0x%08x manual=0x%08x parser=%@ error=%@", i, count, objectSignature, CodexCurrentManualSignature, CodexCurrentManualParser, *error);
            CodexReportCritical(@"tl_vector_failed", [NSString stringWithFormat:@"index=%d/%d sig=0x%08x sigName=%@ manual=0x%08x manualName=%@ parser=%@ error=%@", i, count, objectSignature, stringForHash(objectSignature), CodexCurrentManualSignature, stringForHash(CodexCurrentManualSignature), CodexCurrentManualParser, *error]);
            break;
        }
    }
    return array;
}

static NSArray *CodexReadUpdateVectorSkippingSmallJunk(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t vectorMarker = [is readInt32];
    int32_t count = 0;
    if (vectorMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
        count = [is readInt32];
    else if (vectorMarker >= 0 && vectorMarker <= 10000)
        count = vectorMarker;
    else
    {
        TGLog(@"IOS6AUTH expected update vector/count, got 0x%x manual=0x%08x parser=%@", vectorMarker, CodexCurrentManualSignature, CodexCurrentManualParser);
        id object = TLMetaClassStore::constructObject(is, vectorMarker, environment, nil, error);
        if (error != NULL && *error != nil)
            *error = nil;
        return object == nil ? @[] : @[ object ];
    }
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)MAX(0, count)];
    for (int32_t i = 0; i < count; i++)
    {
        int32_t objectSignature = [is readInt32];
        if (objectSignature > 0 && objectSignature < 0x01000000)
        {
            TGLog(@"IOS6AUTH skipped small junk in update vector index=%d/%d word=0x%08x manual=0x%08x parser=%@", i, count, objectSignature, CodexCurrentManualSignature, CodexCurrentManualParser);
            continue;
        }
        
        id object = TLMetaClassStore::constructObject(is, objectSignature, environment, nil, error);
        if (object != nil)
            [array addObject:object];
        if (error != NULL && *error != nil)
        {
            TGLog(@"IOS6AUTH update vector failed index=%d/%d sig=0x%08x manual=0x%08x parser=%@ error=%@", i, count, objectSignature, CodexCurrentManualSignature, CodexCurrentManualParser, *error);
            CodexReportCritical(@"tl_update_vector_failed", [NSString stringWithFormat:@"index=%d/%d sig=0x%08x sigName=%@ manual=0x%08x manualName=%@ parser=%@ error=%@", i, count, objectSignature, stringForHash(objectSignature), CodexCurrentManualSignature, stringForHash(CodexCurrentManualSignature), CodexCurrentManualParser, *error]);
            break;
        }
    }
    return array;
}

static NSArray *CodexReadObjectVectorOrSingle(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t vectorMarker = [is readInt32];
    return CodexReadObjectVectorOrSingleWithMarker(is, vectorMarker, environment, error);
}

static NSArray *CodexReadObjectVectorOrSingleWithMarker(NSInputStream *is, int32_t vectorMarker, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    if (vectorMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR || (vectorMarker >= 0 && vectorMarker <= 10000))
        return CodexReadObjectVectorWithMarker(is, vectorMarker, environment, error);

    id object = TLMetaClassStore::constructObject(is, vectorMarker, environment, nil, error);
    if (object != nil)
    {
        while (false) TGLog(@"IOS6MEDIA accepted singleton where vector expected sig=0x%08x object=%@", vectorMarker, NSStringFromClass([object class]));
        return @[object];
    }
    return @[];
}

static void CodexSkipStringWithFirstWord(NSInputStream *is, int32_t firstWord)
{
    uint8_t firstByte = (uint8_t)(firstWord & 0xff);
    int32_t length = 0;
    int32_t alreadyConsumedDataBytes = 0;
    
    if (firstByte == 254)
    {
        length = ((firstWord >> 8) & 0xff) | ((firstWord >> 16) & 0xff) << 8 | ((firstWord >> 24) & 0xff) << 16;
        alreadyConsumedDataBytes = 0;
    }
    else
    {
        length = firstByte;
        alreadyConsumedDataBytes = MIN(length, 3);
    }
    
    int32_t remainingBytes = length - alreadyConsumedDataBytes;
    if (remainingBytes > 0)
    {
        uint8_t buffer[256];
        while (remainingBytes > 0)
        {
            int32_t chunk = MIN(remainingBytes, (int32_t)sizeof(buffer));
            [is read:buffer maxLength:(NSUInteger)chunk];
            remainingBytes -= chunk;
        }
    }
    
    int32_t totalPrefixBytes = firstByte == 254 ? 4 : 1;
    int32_t padding = (4 - ((totalPrefixBytes + length) % 4)) % 4;
    if (padding > 0 && (firstByte == 254 || length > 3))
    {
        uint8_t paddingBuffer[4];
        [is read:paddingBuffer maxLength:(NSUInteger)padding];
    }
}

static bool CodexLooksLikeStringFirstWord(int32_t firstWord)
{
    uint8_t firstByte = (uint8_t)(firstWord & 0xff);
    if (firstByte == 254)
        return true;
    if ((((uint32_t)firstWord) & 0xffff0000U) == 0x6a4a0000U)
        return true;
    return firstByte >= 4 && firstByte < 128;
}

static bool CodexLooksLikeTinyBareDocumentTailWord(int32_t word)
{
    return word == 0 || word == 1;
}

static bool CodexSkipBareDocumentAttributeTailWord(NSInputStream *is, int32_t signature)
{
    switch (signature)
    {
        case (int32_t)0x11b58939:
            TGLog(@"IOS6AUTH skipped bare documentAttributeAnimated tail");
            return true;
        case (int32_t)0x9801d2f7:
            TGLog(@"IOS6AUTH skipped bare documentAttributeHasStickers tail");
            return true;
        case (int32_t)0x6c37c15c:
        {
            int32_t w = [is readInt32];
            int32_t h = [is readInt32];
            TGLog(@"IOS6AUTH skipped bare documentAttributeImageSize tail w=%d h=%d", w, h);
            return true;
        }
        case (int32_t)0x15590068:
            [is readString];
            TGLog(@"IOS6AUTH skipped bare documentAttributeFilename tail");
            return true;
        default:
            return false;
    }
}

static NSArray *CodexReadInt64Vector(NSInputStream *is)
{
    int32_t vectorMarker = [is readInt32];
    int32_t count = 0;
    if (vectorMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
        count = [is readInt32];
    else if (vectorMarker >= 0 && vectorMarker <= 10000)
        count = vectorMarker;
    else
    {
        TGLog(@"IOS6AUTH expected long vector/count, got 0x%x", vectorMarker);
        return @[];
    }
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)MAX(0, count)];
    for (int32_t i = 0; i < count; i++)
        [array addObject:[[NSNumber alloc] initWithLongLong:[is readInt64]]];
    return array;
}

static NSArray *CodexReadInt32Vector(NSInputStream *is)
{
    int32_t vectorMarker = [is readInt32];
    int32_t count = 0;
    if (vectorMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
        count = [is readInt32];
    else if (vectorMarker >= 0 && vectorMarker <= 10000)
        count = vectorMarker;
    else
    {
        TGLog(@"IOS6AUTH expected int vector/count, got 0x%x", vectorMarker);
        return @[];
    }
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)MAX(0, count)];
    for (int32_t i = 0; i < count; i++)
        [array addObject:[[NSNumber alloc] initWithInt:[is readInt32]]];
    return array;
}

static void CodexSkipStringVector(NSInputStream *is)
{
    int32_t vectorMarker = [is readInt32];
    int32_t count = 0;
    if (vectorMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
        count = [is readInt32];
    else if (vectorMarker >= 0 && vectorMarker <= 10000)
        count = vectorMarker;
    else
    {
        TGLog(@"IOS6AUTH expected string vector/count, got 0x%x", vectorMarker);
        return;
    }
    for (int32_t i = 0; i < count; i++)
        [is readString];
}

static void CodexSkipBytesVector(NSInputStream *is)
{
    int32_t vectorMarker = [is readInt32];
    int32_t count = 0;
    if (vectorMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
        count = [is readInt32];
    else if (vectorMarker >= 0 && vectorMarker <= 10000)
        count = vectorMarker;
    else
    {
        TGLog(@"IOS6AUTH expected bytes vector/count, got 0x%x", vectorMarker);
        return;
    }
    for (int32_t i = 0; i < count; i++)
        [is readBytes];
}

@interface TLCodexModernPhotoParser : TLPhoto$photo
@end

@implementation TLCodexModernPhotoParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernPhotoParser *result = [[TLCodexModernPhotoParser alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    result.n_id = [is readInt64];
    result.access_hash = [is readInt64];
    result.file_reference = [is readBytes];
    result.date = [is readInt32];
    result.sizes = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    if (flags & (1 << 1))
    {
        CodexReadObjectVector(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    result.dc_id = [is readInt32];
    // High-volume success path; keep parser quiet so system.log does not drop useful error diagnostics.
    return result;
}

@end

@interface TLCodexModernPhotoSizeParser : TLPhotoSize$photoSizeEmpty
@end

@implementation TLCodexModernPhotoSizeParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0xde33b094)
    {
        int32_t flags = [is readInt32];
        NSString *type = [is readString];
        [is readInt32];
        [is readInt32];
        [is readInt32];
        if (flags & (1 << 0))
            [is readDouble];
        
        TLPhotoSize$photoSizeEmpty *result = [[TLPhotoSize$photoSizeEmpty alloc] init];
        result.type = type;
        return result;
    }
    
    if (signature == (int32_t)0xf85c413c)
    {
        [is readInt64];
        CodexReadInt32Vector(is);
        return [[TLPhotoSize$photoSizeEmpty alloc] init];
    }
    
    if (signature == (int32_t)0x0da082fe)
    {
        CodexReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
        [is readInt64];
        CodexReadInt32Vector(is);
        return [[TLPhotoSize$photoSizeEmpty alloc] init];
    }
    
    NSString *type = [is readString];
    switch (signature)
    {
        case (int32_t)0x75c78e60:
        {
            TLPhotoSize$photoSize *result = [[TLPhotoSize$photoSize alloc] init];
            result.type = type;
            result.w = [is readInt32];
            result.h = [is readInt32];
            result.size = [is readInt32];
            // High-volume success path.
            return result;
        }
        case (int32_t)0x021e1ad6:
        {
            TLPhotoSize$photoCachedSize *result = [[TLPhotoSize$photoCachedSize alloc] init];
            result.type = type;
            result.w = [is readInt32];
            result.h = [is readInt32];
            result.bytes = [is readBytes];
            // High-volume success path.
            return result;
        }
        case (int32_t)0xe0b0bc2e:
        case (int32_t)0xd8214d41:
            [is readBytes];
            break;
        case (int32_t)0xfa3efb95:
        {
            TLPhotoSize$photoSize *result = [[TLPhotoSize$photoSize alloc] init];
            result.type = type;
            result.w = [is readInt32];
            result.h = [is readInt32];
            int32_t vectorMarker = [is readInt32];
            int32_t count = 0;
            if (vectorMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
                count = [is readInt32];
            else if (vectorMarker >= 0 && vectorMarker <= 10000)
                count = vectorMarker;
            for (int32_t i = 0; i < count; i++)
                result.size = [is readInt32];
            // High-volume success path.
            return result;
        }
        default:
            break;
    }
    TLPhotoSize$photoSizeEmpty *result = [[TLPhotoSize$photoSizeEmpty alloc] init];
    result.type = type;
    return result;
}

@end

@interface TLCodexModernImportedContactsParser : TLcontacts_ImportedContacts$contacts_importedContacts
@end

@implementation TLCodexModernImportedContactsParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernImportedContactsParser *result = [[TLCodexModernImportedContactsParser alloc] init];
    result.imported = @[];
    result.popular_invites = @[];
    result.retry_contacts = @[];
    result.users = @[];
    if (error != NULL)
        *error = nil;
    return result;
}

@end

@interface TLCodexModernGeoPointSkipParser : NSObject <TLObject>
@end

@implementation TLCodexModernGeoPointSkipParser

- (int32_t)TLconstructorSignature
{
    return (int32_t)0xb2a2f663;
}

- (int32_t)TLconstructorName
{
    return 0;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)__unused metaObject
{
    return nil;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)__unused values
{
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    int32_t flags = [is readInt32];
    TLGeoPoint$geoPoint *result = [[TLGeoPoint$geoPoint alloc] init];
    result.n_long = [is readDouble];
    result.lat = [is readDouble];
    result.access_hash = [is readInt64];
    if (flags & (1 << 0))
        [is readInt32];
    return result;
}

@end

@interface TLCodexRichTextSkipParser : NSObject <TLObject>
@end

@implementation TLCodexRichTextSkipParser

- (int32_t)TLconstructorSignature
{
    return 0;
}

- (int32_t)TLconstructorName
{
    return 0;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)__unused metaObject
{
    return nil;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)__unused values
{
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    IOS6_NOOP_LOG(@"IOS6SKIP parse signature=0x%08x", signature);
    switch (signature)
    {
        case (int32_t)0xdc3d824f:
            break;
        case (int32_t)0x744694e0:
            [is readString];
            break;
        case (int32_t)0x6724abc4:
        case (int32_t)0xd912a59c:
        case (int32_t)0xc12622c4:
        case (int32_t)0x9bf8bb95:
        case (int32_t)0x6c3f19b9:
        case (int32_t)0xed6a8504:
        case (int32_t)0xc7fb5e01:
        case (int32_t)0x034b8621:
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0x3c2884c1:
            CodexReadObject(is, environment, error);
            [is readString];
            [is readInt64];
            break;
        case (int32_t)0xde5a0dd6:
        case (int32_t)0x1ccb966a:
        case (int32_t)0x35553762:
            CodexReadObject(is, environment, error);
            [is readString];
            break;
        case (int32_t)0x7e6260d7:
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0x081ccf4f:
            [is readInt64];
            [is readInt32];
            [is readInt32];
            break;
        default:
            break;
    }
    return nil;
}

@end

@interface TLCodexModernConfigParser : TLConfig$config
@end

@implementation TLCodexModernConfigParser

- (int32_t)TLconstructorSignature
{
    return (int32_t)0xcc1a241e;
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLConfig$config *result = [[TLConfig$config alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    result.date = [is readInt32];
    result.expires = [is readInt32];
    TLBool *testMode = (TLBool *)CodexReadObject(is, environment, error);
    result.test_mode = [testMode respondsToSelector:@selector(boolValue)] ? [testMode boolValue] : false;
    result.this_dc = [is readInt32];
    result.dc_options = CodexReadObjectVector(is, environment, error);
    result.dc_txt_domain_name = [is readString];
    result.chat_size_max = [is readInt32];
    result.megagroup_size_max = [is readInt32];
    result.forwarded_count_max = [is readInt32];
    result.online_update_period_ms = [is readInt32];
    result.offline_blur_timeout_ms = [is readInt32];
    result.offline_idle_timeout_ms = [is readInt32];
    result.online_cloud_timeout_ms = [is readInt32];
    result.notify_cloud_delay_ms = [is readInt32];
    result.notify_default_delay_ms = [is readInt32];
    result.push_chat_period_ms = [is readInt32];
    result.push_chat_limit = [is readInt32];
    result.edit_time_limit = [is readInt32];
    result.revoke_time_limit = [is readInt32];
    result.revoke_pm_time_limit = [is readInt32];
    result.rating_e_decay = [is readInt32];
    result.stickers_recent_limit = [is readInt32];
    result.channels_read_media_period = [is readInt32];
    if (flags & (1 << 0))
        result.tmp_sessions = [is readInt32];
    result.call_receive_timeout_ms = [is readInt32];
    result.call_ring_timeout_ms = [is readInt32];
    result.call_connect_timeout_ms = [is readInt32];
    result.call_packet_timeout_ms = [is readInt32];
    result.me_url_prefix = [is readString];
    if (flags & (1 << 7))
        result.autoupdate_url_prefix = [is readString];
    if (flags & (1 << 9))
        result.gif_search_username = [is readString];
    if (flags & (1 << 10))
        result.venue_search_username = [is readString];
    if (flags & (1 << 11))
        result.img_search_username = [is readString];
    if (flags & (1 << 12))
        result.static_maps_provider = [is readString];
    result.caption_length_max = [is readInt32];
    result.message_length_max = [is readInt32];
    result.webfile_dc_id = [is readInt32];
    if (flags & (1 << 2))
    {
        result.suggested_lang_code = [is readString];
        result.lang_pack_version = [is readInt32];
        [is readInt32];
    }
    if (flags & (1 << 15))
        CodexReadObject(is, environment, error);
    if (flags & (1 << 16))
        [is readString];
    if (error != NULL && *error != nil)
        *error = nil;
    TGLog(@"IOS6AUTH parsed modern config sig=0x%x dc=%d dcOptions=%d flags=%d", signature, result.this_dc, (int)result.dc_options.count, flags);
    return result;
}

@end

@interface TLCodexSkipObjectParser : NSObject <TLObject>
@end

@implementation TLCodexSkipObjectParser

- (int32_t)TLconstructorSignature
{
    return 0;
}

- (int32_t)TLconstructorName
{
    return 0;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)__unused metaObject
{
    return nil;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)__unused values
{
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    switch (signature)
    {
        case (int32_t)0x1cb5c415:
        {
            int32_t count = [is readInt32];
            TGLog(@"IOS6AUTH skipping vector-as-object count=%d manual=0x%08x parser=%@", count, CodexCurrentManualSignature, CodexCurrentManualParser);
            for (int32_t i = 0; i < count; i++)
            {
                @try
                {
                    CodexReadObject(is, environment, error);
                }
                @catch (NSException *exception)
                {
                    NSString *message = [NSString stringWithFormat:@"index=%d/%d manual=0x%08x manualName=%@ parser=%@ exception=%@ reason=%@", i, count, CodexCurrentManualSignature, stringForHash(CodexCurrentManualSignature), CodexCurrentManualParser, exception.name, exception.reason];
                    TGLog(@"IOS6AUTH vector-as-object exception %@", message);
                    CodexReportCritical(@"tl_vector_as_object_exception", message);
                    if (error != NULL)
                    {
                        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                        [userInfo setValue:message forKey:NSLocalizedDescriptionKey];
                        *error = [[NSError alloc] initWithDomain:@"TL" code:-1 userInfo:userInfo];
                    }
                    break;
                }
                if (error != NULL && *error != nil)
                {
                    TGLog(@"IOS6AUTH vector-as-object item failed index=%d/%d manual=0x%08x parser=%@ error=%@", i, count, CodexCurrentManualSignature, CodexCurrentManualParser, *error);
                    break;
                }
            }
            break;
        }
        case (int32_t)0xe8fd8014:
            CodexReadObject(is, environment, error);
            [is readInt32];
            break;
        case (int32_t)0x711d692d:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 1))
                [is readInt32];
            break;
        }
        case (int32_t)0x75b3b798:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0x0ab4a819:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            [is readInt32];
            if (flags & (1 << 4))
                [is readInt32];
            if (flags & (1 << 1))
                [is readInt32];
            if (flags & (1 << 2))
                [is readInt32];
            if (flags & (1 << 3))
                [is readInt32];
            if (flags & (1 << 7))
                [is readInt32];
            if (flags & (1 << 8))
                [is readString];
            break;
        }
        case (int32_t)0xc01e857f:
            [is readInt64];
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0xc32d5b12:
            [is readInt64];
            CodexReadInt32Vector(is);
            [is readInt32];
            [is readInt32];
            break;
        case (int32_t)0x5e1b3cb8:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            CodexReadObject(is, environment, error);
            break;
        }
        case (int32_t)0xd6b19546:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 0))
            {
                [is readInt64];
                [is readInt32];
            }
            break;
        }
        case (int32_t)0xb390dc08:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            if (flags & (1 << 0))
                [is readString];
            if (flags & (1 << 1))
                [is readString];
            if (flags & (1 << 2))
                [is readInt64];
            if (flags & (1 << 3))
                [is readString];
            if (flags & (1 << 4))
                [is readInt32];
            break;
        }
        case (int32_t)0x51e6ee4f:
            [is readInt32];
            break;
        case (int32_t)0x14b24500:
            [is readInt64];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateGroupCall");
            break;
        case (int32_t)0x1bf335b9:
            [is readInt32];
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP updateStoryID");
            break;
        case (int32_t)0xfa0f3ca2:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 1))
                [is readInt32];
            if (flags & (1 << 0))
                CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updatePinnedDialogs flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x7d627683:
            CodexReadObject(is, environment, error);
            [is readInt32];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateSentStoryReaction");
            break;
        case (int32_t)0x1824e40b:
            [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateNewStoryReaction");
            break;
        case (int32_t)0x904dd49c:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateBotChatBoost");
            break;
        case (int32_t)0xac21d3ce:
            CodexReadObject(is, environment, error);
            [is readInt32];
            [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateBotMessageReaction");
            break;
        case (int32_t)0x09cb7759:
            CodexReadObject(is, environment, error);
            [is readInt32];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateBotMessageReactions");
            break;
        case (int32_t)0x8ae5c97a:
            CodexReadObject(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateBotBusinessConnect");
            break;
        case (int32_t)0x9ddb347c:
        case (int32_t)0x07df587c:
        {
            int32_t flags = [is readInt32];
            [is readString];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateBotBusinessMessage sig=0x%08x flags=0x%08x", signature, flags);
            break;
        }
        case (int32_t)0xa02a982e:
            [is readString];
            CodexReadObject(is, environment, error);
            CodexReadInt32Vector(is);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateBotDeleteBusinessMessage");
            break;
        case (int32_t)0x1ea2fda7:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readInt64];
            [is readString];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 2))
                CodexReadObject(is, environment, error);
            [is readInt64];
            if (flags & (1 << 0))
                [is readBytes];
            IOS6_NOOP_LOG(@"IOS6SKIP updateBusinessBotCallbackQuery flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xa584b019:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateStarsRevenueStatus");
            break;
        case (int32_t)0x283bd312:
            [is readInt64];
            [is readString];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateBotPurchasedPaidMedia");
            break;
        case (int32_t)0x8b725fce:
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updatePaidReactionPrivacy");
            break;
        case (int32_t)0x77b0e372:
        case (int32_t)0xa4a79376:
            [is readInt64];
            CodexReadObject(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateReadMonoForum sig=0x%08x", signature);
            break;
        case (int32_t)0x9f812b08:
        {
            [is readInt32];
            [is readInt64];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateMonoForumNoPaidException");
            break;
        }
        case (int32_t)0x683b2c52:
        {
            [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updatePinnedForumTopic");
            break;
        }
        case (int32_t)0xdef143d0:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                CodexReadInt32Vector(is);
            IOS6_NOOP_LOG(@"IOS6SKIP updatePinnedForumTopics flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xfb9c547a:
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateEmojiGameInfo");
            break;
        case (int32_t)0x9e84bc99:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 1))
                [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateReadHistoryInbox flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x2f2f21bf:
            CodexReadObject(is, environment, error);
            [is readInt32];
            [is readInt32];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateReadHistoryOutbox");
            break;
        case (int32_t)0x0bb2d201:
            [is readInt32];
            CodexReadInt64Vector(is);
            IOS6_NOOP_LOG(@"IOS6SKIP updateStickerSetsOrder");
            break;
        case (int32_t)0x31c24808:
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateStickerSets");
            break;
        case (int32_t)0xb23fc698:
            [is readInt64];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateChannelAvailableMessages");
            break;
        case (int32_t)0x9d2216e0:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateGroupCall current flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xbb9bb9a5:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updatePeerHistoryTTL flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x1e297bfa:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateMessageReactions flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xfb4c496c:
        case (int32_t)0x30f443db:
        case (int32_t)0x39c67432:
        case (int32_t)0x8c0f91fb:
            IOS6_NOOP_LOG(@"IOS6SKIP empty update sig=0x%08x", signature);
            break;
        case (int32_t)0x28373599:
            [is readInt64];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateUserEmojiStatus");
            break;
        case (int32_t)0x07b68920:
            [is readInt64];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateChannelViewForumAsMessages");
            break;
        case (int32_t)0xa477288f:
            CodexReadObject(is, environment, error);
            [is readInt32];
            CodexSkipBytesVector(is);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateGroupCallChainBlocks");
            break;
        case (int32_t)0x140502d1:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateWebBrowserException flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x5bb98608:
        {
            [is readInt32];
            [is readInt64];
            CodexReadInt32Vector(is);
            [is readInt32];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updatePinnedChannelMessages");
            break;
        }
        case (int32_t)0x4e80a379:
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateStarsBalance");
            break;
        case (int32_t)0x48e246c2:
            [is readInt64];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateStarGiftAuctionState");
            break;
        case (int32_t)0xdc58f31e:
            [is readInt64];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updateStarGiftAuctionUserState");
            break;
        case (int32_t)0xac072444:
            IOS6_NOOP_LOG(@"IOS6SKIP updateStarGiftCraftFail");
            break;
        case (int32_t)0x50cc03d3:
        {
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP webPageAttributeStickerSet");
            break;
        }
        case (int32_t)0xe46bcee4:
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP chatParticipantCreator");
            break;
        case (int32_t)0xc7b57ce6:
            [is readString];
            [is readString];
            break;
        case (int32_t)0x7533a588:
        case (int32_t)0x4258c205:
            break;
        case (int32_t)0xffadc913:
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            break;
        case (int32_t)0x16a4b93c:
        case (int32_t)0xedf164f1:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 18))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 17))
                CodexReadObject(is, environment, error);
            [is readInt32];
            if (flags & (1 << 0))
                [is readString];
            if (flags & (1 << 1))
                CodexReadObjectVector(is, environment, error);
            CodexReadObject(is, environment, error);
            if (flags & (1 << 14))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 2))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 3))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 15))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 19))
                CodexReadInt32Vector(is);
            if (signature == (int32_t)0x16a4b93c && (flags & (1 << 20)))
                CodexReadObject(is, environment, error);
            break;
        }
        case (int32_t)0x79b26a24:
        {
            int32_t flags = [is readInt32];
            int32_t storyId = [is readInt32];
            [is readInt32]; // date
            if (flags & (1 << 18))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 17))
                CodexReadObject(is, environment, error);
            [is readInt32]; // expire_date
            if (flags & (1 << 0))
                [is readString];
            if (flags & (1 << 1))
                CodexReadObjectVector(is, environment, error);
            CodexReadObject(is, environment, error); // media
            if (flags & (1 << 14))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 2))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 3))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 15))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 19))
                CodexReadInt32Vector(is);
            if (flags & (1 << 20))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP storyItem id=%d flags=0x%08x", storyId, flags);
            break;
        }
        case (int32_t)0x68cb6283:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP messageMediaStory flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x9a35e999:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                [is readInt32];
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP peerStories flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x63c3dd0a:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 0))
                CodexReadInt32Vector(is);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP stories.stories flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x8d595cd6:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            if (flags & (1 << 2))
                [is readInt32];
            if (flags & (1 << 3))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 4))
                [is readInt32];
            if (flags & (1 << 0))
                CodexReadInt64Vector(is);
            IOS6_NOOP_LOG(@"IOS6SKIP storyViews flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xb826e150:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 1))
                [is readString];
            if (flags & (1 << 2))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP storyFwdHeader flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x2e94c3e7:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP webPageAttributeStory flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x54b56617:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP webPageAttributeTheme flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xcf6f6db8:
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP webPageAttributeUniqueStarGift");
            break;
        case (int32_t)0x31cad303:
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP webPageAttributeStarGiftCollection");
            break;
        case (int32_t)0x01c641c2:
            CodexReadObject(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP webPageAttributeStarGiftAuction");
            break;
        case (int32_t)0x7781fe18:
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP webPageAttributeAiComposeTone");
            break;
        case (int32_t)0xbbb6b4a3:
            [is readInt64];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP starsAmount");
            break;
        case (int32_t)0x74aee3e0:
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP starsTonAmount");
            break;
        case (int32_t)0x313a9547:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            CodexReadObject(is, environment, error);
            [is readInt64];
            if (flags & (1 << 0))
            {
                [is readInt32];
                [is readInt32];
            }
            [is readInt64];
            if (flags & (1 << 1))
            {
                [is readInt32];
                [is readInt32];
            }
            if (flags & (1 << 3))
                [is readInt64];
            if (flags & (1 << 4))
                [is readInt64];
            if (flags & (1 << 5))
                [is readString];
            if (flags & (1 << 6))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 8))
            {
                [is readInt32];
                [is readInt32];
            }
            if (flags & (1 << 9))
                [is readInt32];
            if (flags & (1 << 11))
            {
                [is readString];
                [is readInt32];
                [is readInt32];
                [is readInt32];
                [is readInt32];
            }
            if (flags & (1 << 12))
                [is readInt32];
            if (flags & (1 << 13))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP starGift flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x85f0a9cd:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readInt64];
            [is readString];
            [is readString];
            [is readInt32];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 1))
                [is readString];
            if (flags & (1 << 2))
                [is readString];
            CodexReadObjectVector(is, environment, error);
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 3))
                [is readString];
            if (flags & (1 << 4))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 5))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 8))
            {
                [is readInt64];
                [is readString];
                [is readInt64];
            }
            if (flags & (1 << 10))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 11))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 12))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 13))
                [is readInt32];
            if (flags & (1 << 16))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftUnique flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x565251e2:
        {
            int32_t flags = [is readInt32];
            [is readString];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAttributeModel flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x4e7085ea:
            [is readString];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAttributePattern");
            break;
        case (int32_t)0x9f2504e4:
            [is readString];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAttributeBackdrop");
            break;
        case (int32_t)0xe0bff26c:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            [is readInt32];
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAttributeOriginalDetails flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x36437737:
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAttributeRarity");
            break;
        case (int32_t)0xdbce6389:
        case (int32_t)0xf08d516b:
        case (int32_t)0x78fbf3a8:
        case (int32_t)0xcef7e7a8:
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAttributeRarityEmpty sig=0x%08x", signature);
            break;
        case (int32_t)0xaff56398:
            [is readInt32];
            [is readInt32];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftBackground");
            break;
        case (int32_t)0x71f276c4:
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP disallowedGiftsSettings");
            break;
        case (int32_t)0x4d4bd46a:
            IOS6_NOOP_LOG(@"IOS6SKIP profileTabGifts");
            break;
        case (int32_t)0xb98cd696:
        case (int32_t)0x72c64955:
        case (int32_t)0xab339c00:
        case (int32_t)0x9f27d26e:
        case (int32_t)0xe477092e:
        case (int32_t)0xd3656499:
        case (int32_t)0xa2c0f695:
            IOS6_NOOP_LOG(@"IOS6SKIP profileTab sig=0x%08x", signature);
            break;
        case (int32_t)0x3458f9c8:
            CodexReadObject(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP chatThemeUniqueGift");
            break;
        case (int32_t)0xfe333952:
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAuctionStateNotModified");
            break;
        case (int32_t)0x771a4e66:
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt64];
            CodexReadObjectVector(is, environment, error);
            CodexReadInt64Vector(is);
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAuctionState");
            break;
        case (int32_t)0x972dabbf:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt64];
            if (flags & (1 << 0))
                [is readInt32];
            if (flags & (1 << 1))
            {
                [is readInt32];
                [is readString];
            }
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAuctionStateFinished flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x2eeed1c4:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
            {
                [is readInt64];
                [is readInt32];
                [is readInt64];
                CodexReadObject(is, environment, error);
            }
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAuctionUserState flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x3aae0528:
            [is readInt32];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAuctionRound");
            break;
        case (int32_t)0x0aa021e5:
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAuctionRoundExtendable");
            break;
        case (int32_t)0x03d1ea4e:
        {
            [is readDouble];
            [is readDouble];
            [is readDouble];
            [is readDouble];
            [is readDouble];
            IOS6_NOOP_LOG(@"IOS6SKIP mediaAreaCoordinates legacy");
            break;
        }
        case (int32_t)0xcfc9e002:
        {
            int32_t flags = [is readInt32];
            [is readDouble];
            [is readDouble];
            [is readDouble];
            [is readDouble];
            [is readDouble];
            if (flags & (1 << 0))
                [is readDouble];
            IOS6_NOOP_LOG(@"IOS6SKIP mediaAreaCoordinates flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x770416af:
            CodexReadObject(is, environment, error);
            [is readInt64];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP mediaAreaChannelPost");
            break;
        case (int32_t)0xbe82db9c:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            [is readString];
            [is readString];
            [is readString];
            [is readString];
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP mediaAreaVenue");
            break;
        case (int32_t)0xb282217f:
            CodexReadObject(is, environment, error);
            [is readInt64];
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP inputMediaAreaVenue");
            break;
        case (int32_t)0xcad5452d:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP mediaAreaGeoPoint flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x14455871:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP mediaAreaSuggestedReaction flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x2271f2bf:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP inputMediaAreaChannelPost");
            break;
        case (int32_t)0x37381085:
            CodexReadObject(is, environment, error);
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP mediaAreaUrl");
            break;
        case (int32_t)0x49a6549c:
            CodexReadObject(is, environment, error);
            [is readString];
            [is readDouble];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP mediaAreaWeather");
            break;
        case (int32_t)0x5787686d:
            CodexReadObject(is, environment, error);
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP mediaAreaStarGift");
            break;
        case (int32_t)0xdf8b3b22:
        {
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            [is readString];
            [is readString];
            [is readString];
            [is readString];
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP mediaAreaVenue df8b3b22");
            break;
        }
        case (int32_t)0xa5d9abb8:
        {
            [is readString];
            [is readString];
            [is readString];
            [is readString];
            [is readString];
            int32_t tail = [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP geoPointAddress a5d9abb8 strings5 tail=%d", tail);
            break;
        }
        case (int32_t)0xde4c5d93:
        {
            int32_t flags = [is readInt32];
            [is readString];
            if (flags & (1 << 0))
                [is readString];
            if (flags & (1 << 1))
                [is readString];
            if (flags & (1 << 2))
                [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP geoPointAddress flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xb0bdeac5:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readInt32];
            if (flags & (1 << 2))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP storyView flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x9083670b:
        {
            [is readInt32];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP storyViewPublicForward");
            break;
        }
        case (int32_t)0xbd74cf49:
        {
            [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP storyViewPublicRepost");
            break;
        }
        case (int32_t)0x59d78fc5:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 0))
                [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP stories.storyViewsList flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xde9eed1d:
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP stories.storyViews");
            break;
        case (int32_t)0xe87acbc0:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP foundStory");
            break;
        case (int32_t)0xe2de7737:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 0))
                [is readString];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP stories.foundStories flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x6090d6d5:
            CodexReadObject(is, environment, error);
            [is readInt32];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP storyReaction");
            break;
        case (int32_t)0xbbab2643:
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP storyReactionPublicForward");
            break;
        case (int32_t)0xcfcd0f13:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP storyReactionPublicRepost");
            break;
        case (int32_t)0xaa5f789c:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 0))
                [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP stories.storyReactionsList flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xa388a368:
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starGiftsNotModified");
            break;
        case (int32_t)0x2ed82995:
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starGifts");
            break;
        case (int32_t)0x3de1dfed:
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starGiftUpgradePreview");
            break;
        case (int32_t)0x416c56e8:
            CodexReadObject(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.uniqueStarGift");
            break;
        case (int32_t)0x41df43fc:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 2))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 3))
                [is readInt32];
            if (flags & (1 << 11))
                [is readInt64];
            if (flags & (1 << 4))
                [is readInt64];
            if (flags & (1 << 6))
                [is readInt64];
            if (flags & (1 << 7))
                [is readInt32];
            if (flags & (1 << 8))
                [is readInt64];
            if (flags & (1 << 13))
                [is readInt32];
            if (flags & (1 << 14))
                [is readInt32];
            if (flags & (1 << 15))
                CodexReadInt32Vector(is);
            if (flags & (1 << 16))
                [is readString];
            if (flags & (1 << 18))
                [is readInt64];
            if (flags & (1 << 19))
                [is readInt32];
            if (flags & (1 << 20))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP savedStarGift flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x95f389b1:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 0))
                [is readString];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.savedStarGifts flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x69279795:
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP inputSavedStarGiftUser");
            break;
        case (int32_t)0xf101aa7f:
            CodexReadObject(is, environment, error);
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP inputSavedStarGiftChat");
            break;
        case (int32_t)0x2085c238:
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP inputSavedStarGiftSlug");
            break;
        case (int32_t)0x84aa3a9c:
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starGiftWithdrawalUrl");
            break;
        case (int32_t)0x48aaae3c:
        case (int32_t)0x4a162433:
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAttributeIdDocument sig=0x%08x", signature);
            break;
        case (int32_t)0x1f01c757:
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAttributeIdBackdrop");
            break;
        case (int32_t)0x2eb1b658:
            CodexReadObject(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAttributeCounter");
            break;
        case (int32_t)0x947a12df:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 0))
                [is readString];
            if (flags & (1 << 1))
            {
                CodexReadObjectVector(is, environment, error);
                [is readInt64];
            }
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 2))
                CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.resaleStarGifts flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x9d6b13b0:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            [is readString];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            [is readInt32];
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftCollection flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xa0ba4f17:
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starGiftCollectionsNotModified");
            break;
        case (int32_t)0x8a2932f3:
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starGiftCollections");
            break;
        case (int32_t)0x512fe446:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            [is readInt32];
            [is readInt64];
            [is readInt64];
            if (flags & (1 << 0))
            {
                [is readInt32];
                [is readInt64];
            }
            if (flags & (1 << 2))
                [is readInt64];
            if (flags & (1 << 3))
                [is readInt64];
            if (flags & (1 << 4))
                [is readInt32];
            if (flags & (1 << 5))
            {
                [is readInt32];
                [is readString];
            }
            IOS6_NOOP_LOG(@"IOS6SKIP payments.uniqueStarGiftValueInfo flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x99ea331d:
            [is readInt32];
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftUpgradePrice");
            break;
        case (int32_t)0x6b39f4ec:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starGiftAuctionState");
            break;
        case (int32_t)0x42b00348:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            [is readInt64];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 2))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftAuctionAcquiredGift flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x7d5bd1f0:
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starGiftAuctionAcquiredGifts");
            break;
        case (int32_t)0xd31bc45d:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP starGiftActiveAuctionState");
            break;
        case (int32_t)0xdb33dad0:
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starGiftActiveAuctionsNotModified");
            break;
        case (int32_t)0xaef6abbc:
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starGiftActiveAuctions");
            break;
        case (int32_t)0x46c6e36f:
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starGiftUpgradeAttributes");
            break;
        case (int32_t)0x5fb224d5:
            [is readInt32];
            break;
        case (int32_t)0x9f120418:
            [is readInt32];
            [is readInt32];
            break;
        case (int32_t)0xd072acb4:
            [is readString];
            [is readString];
            [is readString];
            break;
        case (int32_t)0xb4073647:
            [is readInt32];
            [is readString];
            break;
        case (int32_t)0xb54b5acf:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            if (flags & (1 << 1))
                [is readInt64];
            break;
        }
        case (int32_t)0xb9c0639a:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readInt64];
            [is readInt64];
            [is readInt32];
            CodexReadInt32Vector(is);
            if (flags & (1 << 0))
                [is readInt32];
            if (flags & (1 << 1))
                CodexReadInt32Vector(is);
            break;
        }
        case (int32_t)0x5da674b7:
            break;
        case (int32_t)0x95fcd1d6:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readInt64];
            [is readString];
            [is readString];
            [is readString];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            [is readInt64];
            break;
        }
        case (int32_t)0x2de11aae:
            break;
        case (int32_t)0xe7ff068a:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            if (flags & (1 << 0))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP emojiStatus flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x7184603b:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readInt64];
            [is readString];
            [is readString];
            [is readInt64];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP emojiStatusCollectible flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x07141dbf:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            if (flags & (1 << 0))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP inputEmojiStatusCollectible flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x929b619d:
            [is readInt64];
            break;
        case (int32_t)0xfa30a8c7:
            [is readInt64];
            [is readInt32];
            break;
        case (int32_t)0xee8c1e86:
            break;
        case (int32_t)0xf35aec28:
            [is readInt64];
            [is readInt64];
            break;
        case (int32_t)0x5b934f9d:
            CodexReadObject(is, environment, error);
            [is readInt32];
            [is readInt64];
            break;
        case (int32_t)0xcdbbcebb:
            [is readInt64];
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0xbe382906:
        {
            [is readInt32];
            [is readInt64];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            int32_t vectorSignature = [is readInt32];
            if (vectorSignature == (int32_t)0x1cb5c415)
            {
                int32_t count = [is readInt32];
                for (int32_t i = 0; i < count; i++)
                    [is readInt64];
            }
            break;
        }
        case (int32_t)0x2cb51097:
            [is readInt64];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0x3b6d152e:
        {
            IOS6_NOOP_LOG(@"IOS6SKIP users.userFull");
            TLUserFull$userFull *fullUser = (TLUserFull$userFull *)CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP users.userFull after full_user error=%@", error != NULL ? *error : nil);
            NSArray *chats = CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP users.userFull after chats error=%@", error != NULL ? *error : nil);
            NSArray *users = CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP users.userFull after users error=%@", error != NULL ? *error : nil);
            if (fullUser.user == nil && users.count != 0)
                fullUser.user = [users objectAtIndex:0];
            IOS6_NOOP_LOG(@"IOS6SKIP users.userFull return fullUser=%@ user=%@ chats=%d users=%d", fullUser, fullUser.user, (int)chats.count, (int)users.count);
            return fullUser;
        }
        case (int32_t)0xb53e8b21:
            CodexReadObject(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP messages.webPagePreview legacy");
            break;
        case (int32_t)0x8c9a88ac:
            CodexReadObject(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP messages.webPagePreview modern");
            break;
        case (int32_t)0xcc997720:
        case (int32_t)0xd2234ea0:
        case (int32_t)0x06cbe645:
        {
            TLUserFull$userFull *result = [[TLUserFull$userFull alloc] init];
            int32_t flags = [is readInt32];
            int32_t flags2 = [is readInt32];
            int64_t userId = [is readInt64];
            result.flags = flags & ((1 << 0) | (1 << 1) | (1 << 2) | (1 << 3));
            IOS6_NOOP_LOG(@"IOS6SKIP userFull flags=0x%08x flags2=0x%08x userId=%lld", flags, flags2, userId);
            if (flags & (1 << 1))
                result.about = [is readString];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP userFull after settings error=%@", error != NULL ? *error : nil);
            if (flags & (1 << 21))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 2))
                result.profile_photo = (TLPhoto *)CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP userFull after profile photos error=%@", error != NULL ? *error : nil);
            if (flags & (1 << 22))
                CodexReadObject(is, environment, error);
            result.notify_settings = (TLPeerNotifySettings *)CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP userFull after notify_settings error=%@", error != NULL ? *error : nil);
            if (flags & (1 << 3))
                result.bot_info = (TLBotInfo *)CodexReadObject(is, environment, error);
            if (flags & (1 << 6))
                result.pinned_msg_id = [is readInt32];
            result.common_chats_count = [is readInt32];
            if (flags & (1 << 11))
                [is readInt32];
            if (flags & (1 << 14))
                [is readInt32];
            if (flags & (1 << 15))
            {
                if (signature == (int32_t)0x06cbe645)
                    CodexReadObject(is, environment, error);
                else
                    [is readString];
            }
            if (flags & (1 << 16))
                [is readString];
            if (flags & (1 << 17))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 18))
                CodexReadObject(is, environment, error);
            if (signature != (int32_t)0x06cbe645 && (flags & (1 << 19)))
                CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP userFull after premium_gifts error=%@", error != NULL ? *error : nil);
            if (flags & (1 << 24))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 25))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 0))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 1))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 2))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 3))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 4))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 5))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 6))
            {
                [is readInt64];
                [is readInt32];
            }
            if (flags2 & (1 << 8))
                [is readInt32];
            if (flags2 & (1 << 11))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 12))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 14))
                [is readInt64];
            if (flags2 & (1 << 15))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 17))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 18))
            {
                CodexReadObject(is, environment, error);
                [is readInt32];
            }
            if (flags2 & (1 << 20))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 21))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 22))
                CodexReadObject(is, environment, error);
            if (flags2 & (1 << 25))
                [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP userFull sig=0x%08x return id=%lld flags2=0x%08x about=%d profile=%@ pinned=%d common=%d", signature, userId, flags2, result.about.length != 0 ? 1 : 0, result.profile_photo, result.pinned_msg_id, result.common_chats_count);
            return result;
        }
        case (int32_t)0x6c8e1e06:
        {
            int32_t flags = [is readInt32];
            int32_t day = [is readInt32];
            int32_t month = [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP birthday flags=0x%08x day=%d month=%d", flags, day, month);
            break;
        }
        case (int32_t)0x120b1ab9:
        {
            int32_t startMinute = [is readInt32];
            int32_t endMinute = [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP businessWeeklyOpen start=%d end=%d", startMinute, endMinute);
            break;
        }
        case (int32_t)0x8c92b098:
        {
            int32_t flags = [is readInt32];
            NSString *timezoneId = [is readString];
            int32_t vectorMarker = [is readInt32];
            int32_t count = 0;
            if (vectorMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
                count = [is readInt32];
            else if (vectorMarker >= 0 && vectorMarker <= 10000)
                count = vectorMarker;
            else
            {
                IOS6_NOOP_LOG(@"IOS6SKIP businessWorkHours expected weekly vector got=0x%08x", vectorMarker);
                break;
            }
            for (int32_t i = 0; i < count; i++)
            {
                int32_t itemSignature = [is readInt32];
                if (itemSignature == (int32_t)0x120b1ab9)
                {
                    [is readInt32];
                    [is readInt32];
                }
                else
                {
                    TLMetaClassStore::constructObject(is, itemSignature, environment, nil, error);
                    if (error != nil && *error != nil)
                        break;
                }
            }
            IOS6_NOOP_LOG(@"IOS6SKIP businessWorkHours flags=0x%08x timezone=%@ weekly=%d", flags, timezoneId, count);
            break;
        }
        case (int32_t)0x5a0a066d:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readString];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP businessIntro flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xac5c1af7:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP businessLocation flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x21108ff7:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 4))
                CodexReadInt64Vector(is);
            IOS6_NOOP_LOG(@"IOS6SKIP businessRecipients flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xe519abab:
            [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP businessGreetingMessage");
            break;
        case (int32_t)0xc9b9e2b9:
        case (int32_t)0xc3f2f501:
            IOS6_NOOP_LOG(@"IOS6SKIP businessAwayMessageScheduleEmpty sig=0x%08x", signature);
            break;
        case (int32_t)0xcc4d9ecc:
            [is readInt32];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP businessAwayMessageScheduleCustom");
            break;
        case (int32_t)0xef156a5c:
        {
            [is readInt32];
            [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP businessAwayMessage");
            break;
        }
        case (int32_t)0x1b0e4f07:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            [is readInt64];
            [is readInt64];
            if (flags & (1 << 0))
                [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP starsRating flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x4b3e14d6:
        {
            int32_t flags = [is readInt32];
            [is readString];
            if (flags & (1 << 0))
                [is readInt64];
            if (flags & (1 << 2))
                [is readInt32];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 4))
                [is readString];
            if (flags & (1 << 5))
                [is readInt32];
            if (flags & (1 << 6))
                [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP boost flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x8f34b2f5:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 2))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP botBusinessConnection flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xfebe5491:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            if (flags & (1 << 1))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP starsRevenueStatus flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x206ad49e:
        case (int32_t)0x1f0c1ad9:
            IOS6_NOOP_LOG(@"IOS6SKIP paidReactionPrivacy sig=0x%08x", signature);
            break;
        case (int32_t)0xdc6cfcf0:
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP paidReactionPrivacyPeer");
            break;
        case (int32_t)0xad628cc8:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
            {
                [is readInt32];
                [is readInt32];
            }
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 2))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP messageExtendedMediaPreview flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xee479c64:
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP messageExtendedMedia");
            break;
        case (int32_t)0xcba9a52f:
            [is readInt32];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP todoItem");
            break;
        case (int32_t)0x49b92a26:
        {
            [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP todoList");
            break;
        }
        case (int32_t)0x221bb5e4:
            [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP todoCompletion");
            break;
        case (int32_t)0xcae68768:
        case (int32_t)0xfd5e12bd:
            CodexReadObject(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP peer/webPage container sig=0x%08x", signature);
            break;
        case (int32_t)0x257e962b:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 0))
                [is readString];
            if (flags & (1 << 1))
                [is readInt32];
            [is readString];
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP premiumGiftCodeOption flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xeb983f8f:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 4))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 3))
                [is readInt32];
            if (flags & (1 << 0))
                [is readInt64];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 1))
                [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.checkedGiftCode flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x4367daa0:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            if (flags & (1 << 1))
                [is readInt32];
            if (flags & (1 << 2))
                [is readInt64];
            if (flags & (1 << 4))
                [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP payments.giveawayInfo flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xe175e66f:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            if (flags & (1 << 3))
                [is readString];
            if (flags & (1 << 4))
                [is readInt64];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 2))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP payments.giveawayInfoResults flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xb2539d54:
            [is readInt64];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP prepaidGiveaway");
            break;
        case (int32_t)0x9a9d77e0:
            [is readInt64];
            [is readInt64];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP prepaidStarsGiveaway");
            break;
        case (int32_t)0x86f8613c:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 0))
                [is readString];
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP premium.boostsList flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xc448415c:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 1))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP myBoost flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x9ae228e2:
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP premium.myBoosts");
            break;
        case (int32_t)0x4959427a:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 4))
                [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            [is readString];
            if (flags & (1 << 3))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 2))
                CodexReadInt32Vector(is);
            IOS6_NOOP_LOG(@"IOS6SKIP premium.boostsStatus flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xe7058e7f:
        case (int32_t)0x8a480e27:
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP postInteractionCounters sig=0x%08x", signature);
            break;
        case (int32_t)0x50cd067c:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP stats.storyStats");
            break;
        case (int32_t)0x1f2bf4a:
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP publicForwardMessage");
            break;
        case (int32_t)0xedf3add0:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP publicForwardStory");
            break;
        case (int32_t)0x93037e20:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 0))
                [is readString];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP stats.publicForwards flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xb8ea86a9:
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP inputPeerColorCollectible");
            break;
        case (int32_t)0x26219a58:
            CodexReadInt32Vector(is);
            IOS6_NOOP_LOG(@"IOS6SKIP help.peerColorSet");
            break;
        case (int32_t)0x767d61eb:
            CodexReadInt32Vector(is);
            CodexReadInt32Vector(is);
            CodexReadInt32Vector(is);
            IOS6_NOOP_LOG(@"IOS6SKIP help.peerColorProfileSet");
            break;
        case (int32_t)0xadec6ebe:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 2))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 3))
                [is readInt32];
            if (flags & (1 << 4))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP help.peerColorOption flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x2ba1f5ce:
            IOS6_NOOP_LOG(@"IOS6SKIP help.peerColorsNotModified");
            break;
        case (int32_t)0x00f8ed08:
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP help.peerColors");
            break;
        case (int32_t)0x64407ea7:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP monoForumDialog flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xf83ae221:
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP messages.savedDialogs");
            break;
        case (int32_t)0x44ba9dd9:
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP messages.savedDialogsSlice");
            break;
        case (int32_t)0xc01f6fe8:
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP messages.savedDialogsNotModified");
            break;
        case (int32_t)0xcb6ff828:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                [is readString];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP savedReactionTag flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x889b59ef:
            IOS6_NOOP_LOG(@"IOS6SKIP messages.savedReactionTagsNotModified");
            break;
        case (int32_t)0x3259950a:
            CodexReadObjectVector(is, environment, error);
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP messages.savedReactionTags");
            break;
        case (int32_t)0x3bb842ac:
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP outboxReadDate");
            break;
        case (int32_t)0x2aee9191:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 1))
                [is readString];
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP smsjobs.status flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x6f8b32aa:
        case (int32_t)0xc4e5921e:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 4))
                CodexReadObjectVector(is, environment, error);
            if (signature == (int32_t)0xc4e5921e && (flags & (1 << 6)))
                CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP inputBusinessRecipients sig=0x%08x flags=0x%08x", signature, flags);
            break;
        }
        case (int32_t)0x0194cb3b:
            [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP inputBusinessGreetingMessage");
            break;
        case (int32_t)0x832175e0:
        {
            [is readInt32];
            [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP inputBusinessAwayMessage");
            break;
        }
        case (int32_t)0x033ed001:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                [is readString];
            if (flags & (1 << 1))
                [is readInt32];
            if (flags & (1 << 2))
                [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP connectedBot flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x17d7f87b:
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP account.connectedBots");
            break;
        case (int32_t)0x09c469cd:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readString];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP inputBusinessIntro flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xb88cf373:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 4))
                CodexReadInt64Vector(is);
            if (flags & (1 << 6))
                CodexReadInt64Vector(is);
            IOS6_NOOP_LOG(@"IOS6SKIP businessBotRecipients flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x1d998733:
            [is readInt64];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP contactBirthday");
            break;
        case (int32_t)0x114ff30d:
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP contacts.contactBirthdays");
            break;
        case (int32_t)0x628c9224:
            [is readInt32];
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP missingInvitee");
            break;
        case (int32_t)0xb4ae666f:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readString];
            if (flags & (1 << 0))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 1))
                [is readString];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP businessChatLink flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xec43a2d1:
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP account.businessChatLinks");
            break;
        case (int32_t)0x9a23af21:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            [is readString];
            if (flags & (1 << 0))
                CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP account.resolvedBusinessChatLinks flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x93c3e27e:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readString];
            if (flags & (1 << 0))
                [is readInt64];
            [is readInt64];
            if (flags & (1 << 1))
                [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP availableEffect flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xd1ed9a5b:
            IOS6_NOOP_LOG(@"IOS6SKIP messages.availableEffectsNotModified");
            break;
        case (int32_t)0xbddb616e:
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP messages.availableEffects");
            break;
        case (int32_t)0xb89bfccf:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 1))
            {
                [is readString];
                CodexReadObject(is, environment, error);
            }
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP factCheck flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x95f2bfe4:
        case (int32_t)0xb457b375:
        case (int32_t)0x7b560a0b:
        case (int32_t)0x250dbaf8:
        case (int32_t)0xe92fd902:
        case (int32_t)0x60682812:
        case (int32_t)0xf9677aad:
            IOS6_NOOP_LOG(@"IOS6SKIP starsTransactionPeer empty sig=0x%08x", signature);
            break;
        case (int32_t)0xd80da15d:
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP starsTransactionPeer");
            break;
        case (int32_t)0x0bd915c0:
        case (int32_t)0x5e0589f1:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            if (flags & (1 << 0))
                [is readString];
            [is readString];
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP starsOption sig=0x%08x flags=0x%08x", signature, flags);
            break;
        }
        case (int32_t)0x13659eb0:
        {
            int32_t flags = [is readInt32];
            [is readString];
            CodexReadObject(is, environment, error);
            [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0)) [is readString];
            if (flags & (1 << 1)) [is readString];
            if (flags & (1 << 2)) CodexReadObject(is, environment, error);
            if (flags & (1 << 5)) { [is readInt32]; [is readString]; }
            if (flags & (1 << 7)) [is readBytes];
            if (flags & (1 << 8)) [is readInt32];
            if (flags & (1 << 9)) CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 12)) [is readInt32];
            if (flags & (1 << 13)) [is readInt32];
            if (flags & (1 << 14)) CodexReadObject(is, environment, error);
            if (flags & (1 << 15)) [is readInt32];
            if (flags & (1 << 16)) [is readInt32];
            if (flags & (1 << 17)) { CodexReadObject(is, environment, error); CodexReadObject(is, environment, error); }
            if (flags & (1 << 19)) [is readInt32];
            if (flags & (1 << 20)) [is readInt32];
            if (flags & (1 << 23)) { [is readInt32]; [is readInt32]; }
            IOS6_NOOP_LOG(@"IOS6SKIP starsTransaction flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x6c9ce8ed:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 1))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 2))
                [is readString];
            if (flags & (1 << 4))
                [is readInt64];
            if (flags & (1 << 3))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 0))
                [is readString];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starsStatus flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x6c207376:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            [is readDouble];
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starsRevenueStats flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x1dab80b7:
        case (int32_t)0x394e7f21:
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP payments.starsRevenueUrl sig=0x%08x", signature);
            break;
        case (int32_t)0x5416d58:
            [is readInt32];
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP starsSubscriptionPricing");
            break;
        case (int32_t)0x2e6eab1a:
        {
            int32_t flags = [is readInt32];
            [is readString];
            CodexReadObject(is, environment, error);
            [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 3)) [is readString];
            if (flags & (1 << 4)) [is readString];
            if (flags & (1 << 5)) CodexReadObject(is, environment, error);
            if (flags & (1 << 6)) [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP starsSubscription flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x94ce852a:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readInt32];
            if (flags & (1 << 2))
                [is readString];
            [is readString];
            [is readInt64];
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP starsGiveawayOption flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x54236209:
            [is readInt32];
            [is readInt32];
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP starsGiveawayWinnersOption");
            break;
        case (int32_t)0xdd0c66f2:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readInt32];
            if (flags & (1 << 0)) [is readInt32];
            if (flags & (1 << 1)) [is readInt32];
            if (flags & (1 << 2)) CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP starRefProgram flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x19a13f71:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt32];
            [is readInt64];
            [is readInt32];
            if (flags & (1 << 0)) [is readInt32];
            [is readInt64];
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP connectedBotStarRef flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x98d5ea1d:
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP payments.connectedStarRefBots");
            break;
        case (int32_t)0xb4d5d859:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 0)) [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP payments.suggestedStarRefBots flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xf93cd45c:
            [is readInt64];
            [is readInt64];
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP botVerification");
            break;
        case (int32_t)0x1e109708:
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP account.paidMessagesRevenue");
            break;
        case (int32_t)0xe581e4e9:
            IOS6_NOOP_LOG(@"IOS6SKIP requirementToContactPremium");
            break;
        case (int32_t)0xb4f67e93:
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP requirementToContactPaidMessages");
            break;
        case (int32_t)0xa0624cf7:
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP businessBotRights");
            break;
        case (int32_t)0xc69708d3:
        {
            int32_t flags = [is readInt32];
            [is readBytes];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0)) [is readString];
            if (flags & (1 << 1)) [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP sponsoredPeer flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xea32b4b1:
            IOS6_NOOP_LOG(@"IOS6SKIP contacts.sponsoredPeersEmpty");
            break;
        case (int32_t)0xeb032884:
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP contacts.sponsoredPeers");
            break;
        case (int32_t)0xc387c04e:
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP stories.canSendStoryCount");
            break;
        case (int32_t)0xe7e82e12:
            [is readString];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP pendingSuggestion");
            break;
        case (int32_t)0x0e8e37e5:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 3))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP suggestedPost flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x9325705a:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            [is readString];
            if (flags & (1 << 0)) CodexReadObject(is, environment, error);
            if (flags & (1 << 1)) CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP storyAlbum flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xc3987a3a:
            [is readInt64];
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP stories.albums");
            break;
        case (int32_t)0x374fa7ad:
            IOS6_NOOP_LOG(@"IOS6SKIP checkCanSendGiftResultOk");
            break;
        case (int32_t)0xd5e58274:
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP checkCanSendGiftResultFail");
            break;
        case (int32_t)0x87e5dfe4:
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP inputChatThemeUniqueGift");
            break;
        case (int32_t)0x1a8afc7e:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0)) [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP groupCallMessage flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xee430c85:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 3))
                CodexReadObject(is, environment, error);
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP groupCallDonor flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x9d1dbd26:
            [is readInt64];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP phone.groupCallStars");
            break;
        case (int32_t)0xda2ad647:
            [is readBytes];
            [is readInt64];
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP messages.emojiGameOutcome");
            break;
        case (int32_t)0x59e65335:
            IOS6_NOOP_LOG(@"IOS6SKIP messages.emojiGameUnavailable");
            break;
        case (int32_t)0x44e56023:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            [is readInt32];
            CodexReadInt32Vector(is);
            if (flags & (1 << 0)) [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP messages.emojiGameDiceInfo flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x90d7adfa:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP messages.composedMessageWithAI flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xcff63ea9:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readInt64];
            [is readString];
            [is readString];
            if (flags & (1 << 1)) [is readInt64];
            if (flags & (1 << 4)) [is readString];
            if (flags & (1 << 2)) [is readInt32];
            if (flags & (1 << 3)) [is readInt64];
            if (flags & (1 << 5)) CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP aiComposeTone flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x9bad6414:
            [is readString];
            [is readInt64];
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP aiComposeToneDefault");
            break;
        case (int32_t)0xc1f46103:
            IOS6_NOOP_LOG(@"IOS6SKIP aicompose.tonesNotModified");
            break;
        case (int32_t)0x6c9d0efe:
            [is readInt64];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP aicompose.tones");
            break;
        case (int32_t)0xf1d628ec:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP aiComposeToneExample");
            break;
        case (int32_t)0x933ca597:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readString];
            [is readString];
            if (flags & (1 << 0)) [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP webDomainException flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x79eb8cb3:
        {
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP account.webBrowserSettings");
            break;
        }
        case (int32_t)0xbaf39d8b:
        {
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP richMessage");
            break;
        }
        case (int32_t)0x7dbf8673:
        {
            int32_t flags = [is readInt32];
            [is readBytes];
            [is readString];
            [is readString];
            [is readString];
            if (flags & (1 << 1)) CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 6)) CodexReadObject(is, environment, error);
            if (flags & (1 << 14)) CodexReadObject(is, environment, error);
            if (flags & (1 << 13)) CodexReadObject(is, environment, error);
            [is readString];
            if (flags & (1 << 7)) [is readString];
            if (flags & (1 << 8)) [is readString];
            if (flags & (1 << 15)) { [is readInt32]; [is readInt32]; }
            IOS6_NOOP_LOG(@"IOS6SKIP sponsoredMessage flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xffda656d:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0)) [is readInt32];
            if (flags & (1 << 1)) [is readInt32];
            if (flags & (1 << 2)) [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP messages.sponsoredMessages flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x1839490f:
            IOS6_NOOP_LOG(@"IOS6SKIP messages.sponsoredMessagesEmpty");
            break;
        case (int32_t)0x31bd492d:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 0)) [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP messages.messageReactionsList flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xc077ec01:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readString];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            if (flags & (1 << 1))
            {
                CodexReadObject(is, environment, error);
                CodexReadObject(is, environment, error);
            }
            IOS6_NOOP_LOG(@"IOS6SKIP availableReaction flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x9f071957:
        case (int32_t)0xb06fdbdf:
        case (int32_t)0xd08ce645:
        case (int32_t)0x481eadfa:
        case (int32_t)0x6fb4ad87:
            IOS6_NOOP_LOG(@"IOS6SKIP notModified/empty list sig=0x%08x", signature);
            break;
        case (int32_t)0x768e3aad:
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP messages.availableReactions");
            break;
        case (int32_t)0x90c467d1:
            [is readInt64];
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP account.emojiStatuses");
            break;
        case (int32_t)0xeafdf716:
            [is readInt64];
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP messages.reactions");
            break;
        case (int32_t)0x5f2d1df2:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 3)) [is readString];
            [is readInt32];
            [is readString];
            [is readInt64];
            [is readString];
            if (flags & (1 << 0)) [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP premiumSubscriptionOption flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xb81c7034:
        {
            [is readInt32];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP sendAsPeer");
            break;
        }
        case (int32_t)0x367617d3:
        {
            [is readInt32];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP messages.forumTopics");
            break;
        }
        case (int32_t)0x43b46b20:
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP defaultHistoryTTL");
            break;
        case (int32_t)0x7a1e11d1:
            [is readInt64];
            CodexReadInt64Vector(is);
            IOS6_NOOP_LOG(@"IOS6SKIP emojiList");
            break;
        case (int32_t)0x7a9abda9:
        case (int32_t)0x80d26cc7:
            [is readString];
            [is readInt64];
            CodexSkipStringVector(is);
            IOS6_NOOP_LOG(@"IOS6SKIP emojiGroup sig=0x%08x", signature);
            break;
        case (int32_t)0x093bcf34:
            [is readString];
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP emojiGroupPremium");
            break;
        case (int32_t)0x881fb94b:
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP messages.emojiGroups");
            break;
        case (int32_t)0xa26156c0:
            [is readInt64];
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP textCustomEmoji");
            break;
        case (int32_t)0xc556a45d:
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP textAutoEmail");
            break;
        case (int32_t)0xd90d8dfe:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readString];
            if (flags & (1 << 3))
                CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP attachMenuBot flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xcfb9d957:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            [is readString];
            if (flags & (1 << 1))
            {
                [is readInt32];
                [is readInt32];
            }
            IOS6_NOOP_LOG(@"IOS6SKIP messages.transcribedAudio flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x5334759c:
            [is readString];
            CodexReadObjectVector(is, environment, error);
            CodexSkipStringVector(is);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP help.premiumPromo");
            break;
        case (int32_t)0x4345be73:
            [is readString];
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP emailVerifyPurposeLoginSetup");
            break;
        case (int32_t)0x527d22eb:
        case (int32_t)0xbbf51685:
            IOS6_NOOP_LOG(@"IOS6SKIP emailVerifyPurpose empty sig=0x%08x", signature);
            break;
        case (int32_t)0x922e55a9:
        case (int32_t)0xdb909ec2:
        case (int32_t)0x96d074fd:
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP emailVerification sig=0x%08x", signature);
            break;
        case (int32_t)0x2b96cd1b:
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP account.emailVerified");
            break;
        case (int32_t)0xe1bb0d61:
            [is readString];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP account.emailVerifiedLogin");
            break;
        case (int32_t)0x3fc9053b:
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP exportedStoryLink");
            break;
        case (int32_t)0x6ebdff91:
            [is readInt32];
            [is readString];
            [is readInt64];
            [is readString];
            [is readInt64];
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP fragment.collectibleInfo");
            break;
        case (int32_t)0xbac3a61a:
        case (int32_t)0x4b9e22a0:
            IOS6_NOOP_LOG(@"IOS6SKIP reactionNotificationsFrom sig=0x%08x", signature);
            break;
        case (int32_t)0x71e4ea58:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0)) CodexReadObject(is, environment, error);
            if (flags & (1 << 1)) CodexReadObject(is, environment, error);
            if (flags & (1 << 2)) CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP reactionsNotifySettings flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x98613ebf:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readString];
            [is readInt32];
            if (flags & (1 << 0)) [is readInt64];
            if (flags & (1 << 1)) [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP passkey flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x0a339f0b:
        {
            int32_t flags = [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP messageReactions flags=0x%08x", flags);
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 1))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 4))
                CodexReadObjectVector(is, environment, error);
            break;
        }
        case (int32_t)0x3e0b5b6a:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 1))
                [is readInt32];
            [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP searchPostsFlood flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xea29055d:
        {
            int32_t flags = [is readInt32];
            int64_t channelId = [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP updateChannelReadMessagesContents flags=0x%08x channelId=%lld", flags, channelId);
            if (flags & (1 << 0))
                [is readInt32];
            CodexReadInt32Vector(is);
            break;
        }
        case (int32_t)0xf8227181:
        {
            int32_t flags = [is readInt32];
            CodexReadInt32Vector(is);
            int32_t pts = [is readInt32];
            int32_t ptsCount = [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateReadMessagesContents flags=0x%08x pts=%d ptsCount=%d", flags, pts, ptsCount);
            break;
        }
        case (int32_t)0xebe07752:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            IOS6_NOOP_LOG(@"IOS6SKIP updatePeerBlocked flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x8951abef:
        {
            int32_t flags = [is readInt32];
            int64_t hash = [is readInt64];
            if (flags & (1 << 0))
            {
                [is readInt32];
                [is readString];
                [is readString];
            }
            IOS6_NOOP_LOG(@"IOS6SKIP updateNewAuthorization flags=0x%08x hash=%lld", flags, hash);
            break;
        }
        case (int32_t)0x20529438:
        {
            int64_t userId = [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP updateUser userId=%lld", userId);
            break;
        }
        case (int32_t)0x635b4c09:
        {
            int64_t channelId = [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP updateChannel channelId=%lld", channelId);
            break;
        }
        case (int32_t)0x922e6e10:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            int64_t channelId = [is readInt64];
            int32_t maxId = [is readInt32];
            int32_t stillUnreadCount = [is readInt32];
            int32_t pts = [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateReadChannelInbox flags=0x%08x channelId=%lld maxId=%d stillUnread=%d pts=%d", flags, channelId, maxId, stillUnreadCount, pts);
            break;
        }
        case (int32_t)0xf74e932b:
        {
            CodexReadObject(is, environment, error);
            int32_t maxId = [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateReadStories maxId=%d", maxId);
            break;
        }
        case (int32_t)0x9c974fdf:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            CodexReadObject(is, environment, error);
            int32_t maxId = [is readInt32];
            int32_t stillUnreadCount = [is readInt32];
            int32_t pts = [is readInt32];
            int32_t ptsCount = [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateReadHistoryInbox flags=0x%08x maxId=%d stillUnread=%d pts=%d ptsCount=%d", flags, maxId, stillUnreadCount, pts, ptsCount);
            break;
        }
        case (int32_t)0xb75f99a9:
        {
            int64_t channelId = [is readInt64];
            int32_t maxId = [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateReadChannelOutbox channelId=%lld maxId=%d", channelId, maxId);
            break;
        }
        case (int32_t)0xf226ac08:
        {
            int64_t channelId = [is readInt64];
            int32_t messageId = [is readInt32];
            int32_t views = [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateChannelMessageViews channelId=%lld id=%d views=%d", channelId, messageId, views);
            break;
        }
        case (int32_t)0x6f7863f4:
            IOS6_NOOP_LOG(@"IOS6SKIP updateRecentReactions");
            break;
        case (int32_t)0x86fccf85:
        {
            int32_t flags = [is readInt32];
            int64_t stickerSetId = [is readInt64];
            IOS6_NOOP_LOG(@"IOS6SKIP updateMoveStickerSetToTop flags=0x%08x stickerSet=%lld", flags, stickerSetId);
            break;
        }
        case (int32_t)0x74c34319:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            [is readString];
            [is readInt64];
            [is readString];
            if (flags & (1 << 0))
                [is readString];
            break;
        }
        case (int32_t)0x50a04e45:
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0x98657f0d:
        {
            int32_t flags = [is readInt32];
            int32_t firstMarker = [is readInt32];
            if (firstMarker != TL_UNIVERSAL_VECTOR_CONSTRUCTOR && (firstMarker < 0 || firstMarker > 10000))
            {
                CodexSkipStringWithFirstWord(is, firstMarker);
                firstMarker = [is readInt32];
            }
            CodexReadObjectVectorWithMarker(is, firstMarker, environment, error);
            CodexReadObjectVector(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 3))
                [is readInt32];
            break;
        }
        case (int32_t)0x1759c560:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
            {
                [is readString];
                [is readInt64];
            }
            break;
        }
        case (int32_t)0x8c88c923:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            if (flags & (1 << 0))
                [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            break;
        }
        case (int32_t)0xb05ac6b1:
            IOS6_NOOP_LOG(@"IOS6SKIP sendMessageChooseStickerAction");
            break;
        case (int32_t)0x7c8fe7b6:
        {
            [is readInt32];
            [is readInt64];
            CodexReadObject(is, environment, error);
            break;
        }
        case (int32_t)0x39f23300:
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0xa8718dc5:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 1))
                [is readString];
            if (flags & (1 << 2))
                [is readString];
            if (flags & (1 << 4))
                [is readInt64];
            if (flags & (1 << 5))
            {
                [is readInt32];
                [is readInt32];
            }
            CodexReadObject(is, environment, error);
            break;
        }
        case (int32_t)0xf259a80b:
            [is readString];
            [is readInt64];
            [is readInt64];
            [is readString];
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0x65a0fa4d:
        case (int32_t)0x031f9590:
            CodexReadObjectVector(is, environment, error);
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0xef1751b5:
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0x804361ea:
            [is readInt64];
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0x1e148390:
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0xbf4dea82:
            [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0x76768bed:
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0x16115a96:
            CodexReadObject(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0xa44f3ef6:
            CodexReadObject(is, environment, error);
            [is readInt32];
            [is readInt32];
            [is readInt32];
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0x25e073fc:
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0xe4e88011:
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0xb92fb6cd:
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0x9a8ae1e1:
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0x5e068047:
            [is readString];
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0x98dd8936:
            [is readString];
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0x6f747657:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0xfffe1bac:
        case (int32_t)0x65427b82:
        case (int32_t)0xf888fa1a:
        case (int32_t)0x8b73e763:
        case (int32_t)0xf7e8d89b:
        case (int32_t)0xece9814b:
            break;
        case (int32_t)0xb8905fb2:
        case (int32_t)0xe4621141:
        case (int32_t)0x6b134e8e:
        case (int32_t)0x41c87565:
            CodexReadInt64Vector(is);
            break;
        case (int32_t)0x2dd14edc:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            [is readInt64];
            [is readInt64];
            [is readString];
            [is readString];
            if (flags & (1 << 4))
            {
                CodexReadObjectVector(is, environment, error);
                [is readInt32];
                [is readInt32];
            }
            if (flags & (1 << 8))
                [is readInt64];
            [is readInt32];
            [is readInt32];
            break;
        }
        case (int32_t)0x4f2b9479:
        {
            int32_t flags = [is readInt32];
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 1))
                CodexReadObjectVector(is, environment, error);
            break;
        }
        case (int32_t)0xa3d1cb80:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            break;
        }
        case (int32_t)0x8c79b63c:
        {
            [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            CodexReadObject(is, environment, error);
            break;
        }
        case (int32_t)0x1b2286b8:
            [is readString];
            break;
        case (int32_t)0x8935fc73:
            [is readInt64];
            break;
        case (int32_t)0x79f5d419:
        case (int32_t)0x523da4eb:
        case (int32_t)0xeafc32bc:
            break;
        case (int32_t)0x52928bca:
            [is readInt32];
            break;
        case (int32_t)0x661d4037:
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0xe9baa668:
            CodexReadObject(is, environment, error);
            [is readInt32];
            break;
        case (int32_t)0x19360dc0:
            CodexReadObjectVector(is, environment, error);
            [is readInt32];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateFolderPeers");
            break;
        case (int32_t)0x695c9e7c:
            [is readInt64];
            [is readInt32];
            [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP updateReadChannelDiscussionOutbox");
            break;
        case (int32_t)0x83d60fc2:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 1))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 0))
                [is readInt64];
            if (flags & (1 << 2))
                [is readInt32];
            if (flags & (1 << 3))
                [is readInt32];
            break;
        }
        case (int32_t)0x85dd99d1:
        {
            int32_t flags = [is readInt32];
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 3))
                [is readString];
            break;
        }
        case (int32_t)0x48a30254:
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0xa03e5b85:
        case (int32_t)0x86b40b08:
        {
            int32_t flags = [is readInt32];
            if (signature == (int32_t)0x86b40b08 && (flags & (1 << 3)))
                [is readString];
            break;
        }
        case (int32_t)0x77608b83:
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0xa2fa4880:
        case (int32_t)0xb16a6c29:
        case (int32_t)0xfc796b3f:
        case (int32_t)0x50f41ccf:
        case (int32_t)0xafd93fbb:
            [is readString];
            break;
        case (int32_t)0x258aff05:
        case (int32_t)0xa0c0505c:
        case (int32_t)0x13767230:
            [is readString];
            [is readString];
            break;
        case (int32_t)0x35bbdb6b:
            [is readInt32];
            [is readString];
            [is readBytes];
            break;
        case (int32_t)0x93b9fbb5:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readString];
            if (flags & (1 << 1))
                CodexReadObjectVector(is, environment, error);
            break;
        }
        case (int32_t)0x10b78d29:
        {
            int32_t flags = [is readInt32];
            [is readString];
            if (flags & (1 << 0))
                [is readString];
            [is readString];
            [is readInt32];
            break;
        }
        case (int32_t)0xd02e7fd4:
        {
            int32_t flags = [is readInt32];
            [is readString];
            if (flags & (1 << 1))
                [is readString];
            [is readString];
            CodexReadObject(is, environment, error);
            break;
        }
        case (int32_t)0xbbc7515d:
            [is readInt32];
            [is readString];
            break;
        case (int32_t)0x308660c1:
            [is readString];
            [is readInt64];
            break;
        case (int32_t)0xe988037b:
            [is readString];
            CodexReadObject(is, environment, error);
            break;
        case (int32_t)0x53d7bfd8:
            [is readString];
            [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            break;
        case (int32_t)0x5f3b8a00:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            break;
        }
        case (int32_t)0xc9f06e1b:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 3))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 4))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 2))
                CodexReadObject(is, environment, error);
            break;
        }
        case (int32_t)0x339bef6c:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 3))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 2))
                CodexReadObject(is, environment, error);
            break;
        }
        case (int32_t)0x3e81e078:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 1))
                [is readString];
            if (flags & (1 << 2))
                [is readString];
            break;
        }
        case (int32_t)0xc9662d05:
            [is readInt32];
            [is readString];
            [is readInt32];
            CodexReadObject(is, environment, error);
            [is readInt32];
            break;
        case (int32_t)0x6c37c15c:
            [is readInt32];
            [is readInt32];
            break;
        case (int32_t)0x11b58939:
        case (int32_t)0x9801d2f7:
            break;
        case (int32_t)0x17399fad:
        {
            int32_t flags = [is readInt32];
            [is readDouble];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 2))
                [is readInt32];
            if (flags & (1 << 4))
                [is readDouble];
            break;
        }
        case (int32_t)0x15590068:
            [is readString];
            break;
        case (int32_t)0xfd149899:
        {
            [is readInt32];
            [is readString];
            CodexReadObject(is, environment, error);
            break;
        }
        case (int32_t)0xd38ff1c2:
        {
            int32_t flags = [is readInt32];
            [is readDouble];
            [is readInt32];
            [is readInt32];
            if (flags & (1 << 2))
                [is readInt32];
            IOS6_NOOP_LOG(@"IOS6SKIP modern documentAttributeVideo sig=0xd38ff1c2 flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xeeca5ce3:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readString];
            [is readString];
            if (flags & (1 << 1))
                [is readString];
            [is readString];
            [is readInt32];
            [is readInt32];
            [is readString];
            IOS6_NOOP_LOG(@"IOS6SKIP modern langPackLanguage sig=0xeeca5ce3 flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x751f3146:
            [is readString];
            CodexReadObjectVector(is, environment, error);
            break;
        case (int32_t)0x58747131:
        {
            [is readInt64];
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 4))
                [is readInt32];
            if (flags & (1 << 5))
                [is readInt32];
            break;
        }
        case (int32_t)0xff16e2ca:
            CodexReadObject(is, environment, error);
            [is readBytes];
            break;
        case (int32_t)0x7adf2420:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 1))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 2))
                [is readInt32];
            if (flags & (1 << 3))
                CodexReadObjectVector(is, environment, error);
            if (flags & (1 << 4))
            {
                [is readString];
                CodexReadObjectVector(is, environment, error);
            }
            break;
        }
        case (int32_t)0x3b6ddad2:
            [is readInt32];
            [is readBytes];
            [is readInt32];
            break;
        case (int32_t)0x6a7e7366:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            break;
        default:
            TGLog(@"IOS6AUTH skip parser has no payload rule for sig=0x%08x", signature);
            break;
    }
    return nil;
}

@end

@interface TLCodexPhoneConnectionParser : NSObject <TLObject>
@end

@implementation TLCodexPhoneConnectionParser

- (int32_t)TLconstructorSignature
{
    return 0;
}

- (int32_t)TLconstructorName
{
    return 0;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)__unused metaObject
{
    return nil;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)__unused values
{
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0x9cc123c7)
    {
        TLPhoneConnection$phoneConnection *result = [[TLPhoneConnection$phoneConnection alloc] init];
        result.flags = [is readInt32];
        result.n_id = [is readInt64];
        result.ip = [is readString];
        result.ipv6 = [is readString];
        result.port = [is readInt32];
        result.peer_tag = [is readBytes];
        if (error != NULL)
            *error = nil;
        TGLog(@"IOS6CALL parse phoneConnection flags=%d id=%lld ip=%@ ipv6=%@ port=%d peerTagLen=%d", result.flags, result.n_id, result.ip, result.ipv6, result.port, (int)result.peer_tag.length);
        return result;
    }
    
    if (signature == (int32_t)0x635fe375)
    {
        TLPhoneConnection$phoneConnectionWebrtc *result = [[TLPhoneConnection$phoneConnectionWebrtc alloc] init];
        result.flags = [is readInt32];
        result.n_id = [is readInt64];
        result.ip = [is readString];
        result.ipv6 = [is readString];
        result.port = [is readInt32];
        result.username = [is readString];
        result.password = [is readString];
        if (error != NULL)
            *error = nil;
        TGLog(@"IOS6CALL parse phoneConnectionWebrtc flags=%d id=%lld ip=%@ ipv6=%@ port=%d user=%@ passLen=%d", result.flags, result.n_id, result.ip, result.ipv6, result.port, result.username, (int)result.password.length);
        return result;
    }
    
    TGLog(@"IOS6CALL parse phoneConnection.unknown sig=0x%08x", signature);
    return nil;
}

@end

@interface TLCodexModernWebPageEmptyParser : TLWebPage$webPageEmpty
@end

@implementation TLCodexModernWebPageEmptyParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLCodexModernWebPageEmptyParser *result = [[TLCodexModernWebPageEmptyParser alloc] init];
    int32_t flags = [is readInt32];
    result.n_id = [is readInt64];
    if (flags & (1 << 0))
        [is readString];
    return result;
}

@end

@interface TLCodexModernWebPageParser : TLWebPage$webPage
@end

@implementation TLCodexModernWebPageParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernWebPageParser *result = [[TLCodexModernWebPageParser alloc] init];
    int32_t flags = [is readInt32];
    [is readInt64];
    [is readString];
    [is readString];
    [is readInt32];
    if (flags & (1 << 0))
        [is readString];
    if (flags & (1 << 1))
        [is readString];
    if (flags & (1 << 2))
        [is readString];
    if (flags & (1 << 3))
        [is readString];
    if (flags & (1 << 4))
        CodexReadObject(is, environment, error);
    if (flags & (1 << 5))
    {
        [is readString];
        [is readString];
    }
    if (flags & (1 << 6))
    {
        [is readInt32];
        [is readInt32];
    }
    if (flags & (1 << 7))
        [is readInt32];
    if (flags & (1 << 8))
        [is readString];
    if (flags & (1 << 9))
        CodexReadObject(is, environment, error);
    if (flags & (1 << 10))
        CodexReadObject(is, environment, error);
    if (flags & (1 << 12))
        CodexReadObjectVector(is, environment, error);
    return result;
}

@end

@interface TLCodexModernMessageMediaUnsupportedParser : TLMessageMedia$messageMediaUnsupported
@end

@implementation TLCodexModernMessageMediaUnsupportedParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    switch (signature)
    {
        case (int32_t)0xf6a548d3:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readString];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 2))
                [is readInt32];
            [is readString];
            [is readInt64];
            [is readString];
            if (flags & (1 << 4))
                CodexReadObject(is, environment, error);
            while (false) TGLog(@"IOS6MEDIA unsupported invoice flags=0x%08x", flags);
            break;
        }
        case (int32_t)0x3ded6320:
        case (int32_t)0x9f84f49e:
            while (false) TGLog(@"IOS6MEDIA unsupported empty sig=0x%08x", signature);
            break;
        case (int32_t)0x56e0d474:
            CodexReadObject(is, environment, error);
            while (false) TGLog(@"IOS6MEDIA unsupported geo");
            break;
        case (int32_t)0x70322949:
            [is readString];
            [is readString];
            [is readString];
            [is readString];
            [is readInt64];
            while (false) TGLog(@"IOS6MEDIA unsupported contact");
            break;
        case (int32_t)0x2ec0533f:
            CodexReadObject(is, environment, error);
            [is readString];
            [is readString];
            [is readString];
            [is readString];
            [is readString];
            while (false) TGLog(@"IOS6MEDIA unsupported venue");
            break;
        case (int32_t)0xfdb19008:
            CodexReadObject(is, environment, error);
            while (false) TGLog(@"IOS6MEDIA unsupported game");
            break;
        case (int32_t)0x773f4e66:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            while (false) TGLog(@"IOS6MEDIA unsupported poll flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xca5cab89:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            while (false) TGLog(@"IOS6MEDIA unsupported videoStream flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xaa073beb:
        {
            int32_t flags = [is readInt32];
            CodexReadInt64Vector(is);
            if (flags & (1 << 1))
                CodexSkipStringVector(is);
            if (flags & (1 << 3))
                [is readString];
            [is readInt32];
            if (flags & (1 << 4))
                [is readInt32];
            if (flags & (1 << 5))
                [is readInt64];
            [is readInt32];
            while (false) TGLog(@"IOS6MEDIA unsupported giveaway flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xceaa3ea1:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            if (flags & (1 << 3))
                [is readInt32];
            [is readInt32];
            [is readInt32];
            [is readInt32];
            CodexReadInt64Vector(is);
            if (flags & (1 << 4))
                [is readInt32];
            if (flags & (1 << 5))
                [is readInt64];
            if (flags & (1 << 1))
                [is readString];
            [is readInt32];
            while (false) TGLog(@"IOS6MEDIA unsupported giveawayResults flags=0x%08x", flags);
            break;
        }
        case (int32_t)0xa8852491:
            [is readInt64];
            CodexReadObjectVector(is, environment, error);
            while (false) TGLog(@"IOS6MEDIA unsupported paidMedia");
            break;
        case (int32_t)0x8a53b014:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                CodexReadObjectVector(is, environment, error);
            while (false) TGLog(@"IOS6MEDIA unsupported todo flags=0x%08x", flags);
            break;
        }
        default:
            while (false) TGLog(@"IOS6MEDIA unsupported unknown sig=0x%08x", signature);
            break;
    }
    if (error != NULL && *error != nil)
        return nil;
    return [[TLMessageMedia$messageMediaUnsupported alloc] init];
}

@end

@interface TLCodexModernMessageMediaGeoLiveParser : TLMessageMedia$messageMediaGeoLive
@end

@implementation TLCodexModernMessageMediaGeoLiveParser

- (int32_t)TLconstructorSignature
{
    return (int32_t)0xb940c666;
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernMessageMediaGeoLiveParser *result = [[TLCodexModernMessageMediaGeoLiveParser alloc] init];
    int32_t flags = [is readInt32];
    result.geo = (TLGeoPoint *)CodexReadObject(is, environment, error);
    if (flags & (1 << 0))
        [is readInt32];
    result.period = [is readInt32];
    if (flags & (1 << 1))
        [is readInt32];
    while (false) TGLog(@"IOS6MEDIA messageMediaGeoLive flags=0x%08x period=%d geo=%@", flags, result.period, result.geo);
    return result;
}

@end

@interface TLCodexModernMessageMediaPhotoParser : TLMessageMedia$messageMediaPhoto
@end

@implementation TLCodexModernMessageMediaPhotoParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernMessageMediaPhotoParser *result = [[TLCodexModernMessageMediaPhotoParser alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    if (flags & (1 << 0))
        result.photo = (TLPhoto *)CodexReadObject(is, environment, error);
    if (flags & (1 << 2))
        result.ttl_seconds = [is readInt32];
    if (flags & (1 << 4))
        CodexReadObject(is, environment, error);
    return result;
}

@end

@interface TLCodexModernMessageMediaDocumentParser : TLMessageMedia$messageMediaDocument
@end

@implementation TLCodexModernMessageMediaDocumentParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernMessageMediaDocumentParser *result = [[TLCodexModernMessageMediaDocumentParser alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    if (flags & (1 << 0))
        result.document = (TLDocument *)CodexReadObject(is, environment, error);
    if (flags & (1 << 5))
    {
        int32_t marker = [is readInt32];
        CodexReadObjectVectorOrSingleWithMarker(is, marker, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    if (flags & (1 << 9))
        CodexReadObject(is, environment, error);
    if (flags & (1 << 10))
        [is readInt32];
    if (flags & (1 << 2))
        result.ttl_seconds = [is readInt32];
    return result;
}

@end

@interface TLCodexModernMessageMediaWebPageParser : TLMessageMedia$messageMediaWebPage
@end

@implementation TLCodexModernMessageMediaWebPageParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernMessageMediaWebPageParser *result = [[TLCodexModernMessageMediaWebPageParser alloc] init];
    [is readInt32];
    result.webpage = (TLWebPage *)CodexReadObject(is, environment, error);
    return result;
}

@end

@interface TLCodexModernMessageMediaDiceParser : TLMessageMedia$messageMediaUnsupported
@end

@implementation TLCodexModernMessageMediaDiceParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0x08cbec07)
    {
        int32_t flags = [is readInt32];
        int32_t value = [is readInt32];
        NSString *emoticon = [is readString];
        if (flags & (1 << 0))
            CodexReadObject(is, environment, error);
        while (false) TGLog(@"IOS6MEDIA messageMediaDice modern flags=0x%08x value=%d emoticon=%@", flags, value, emoticon);
    }
    else
    {
        int32_t value = [is readInt32];
        NSString *emoticon = [is readString];
        while (false) TGLog(@"IOS6MEDIA messageMediaDice legacy sig=0x%08x value=%d emoticon=%@", signature, value, emoticon);
    }
    if (error != NULL && *error != nil)
        return nil;
    return [[TLMessageMedia$messageMediaUnsupported alloc] init];
}

@end

@interface TLCodexModernMessageMediaPollParser : TLMessageMedia$messageMediaUnsupported
@end

@implementation TLCodexModernMessageMediaPollParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    return [[TLMessageMedia$messageMediaUnsupported alloc] init];
}

@end

@interface TLCodexModernMessageEntityMentionNameParser : TLMessageEntity$messageEntityMentionName
@end

@implementation TLCodexModernMessageEntityMentionNameParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLCodexModernMessageEntityMentionNameParser *result = [[TLCodexModernMessageEntityMentionNameParser alloc] init];
    result.offset = [is readInt32];
    result.length = [is readInt32];
    result.user_id = TGModernLegacyIdForModernId([is readInt64]);
    return result;
}

@end

@interface TLCodexModernMessageEntityCustomEmojiParser : TLMessageEntity$messageEntityUnknown
@end

@implementation TLCodexModernMessageEntityCustomEmojiParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLCodexModernMessageEntityCustomEmojiParser *result = [[TLCodexModernMessageEntityCustomEmojiParser alloc] init];
    result.offset = [is readInt32];
    result.length = [is readInt32];
    [is readInt64];
    return result;
}

@end

@interface TLCodexModernMessageEntitySimpleParser : TLMessageEntity$messageEntityUnknown
@end

@implementation TLCodexModernMessageEntitySimpleParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLCodexModernMessageEntitySimpleParser *result = [[TLCodexModernMessageEntitySimpleParser alloc] init];
    if (signature == (int32_t)0xf1ccaaac || signature == (int32_t)0x904ac7c7)
        [is readInt32];
    result.offset = [is readInt32];
    result.length = [is readInt32];
    if (signature == (int32_t)0x904ac7c7)
        [is readInt32];
    if (signature == (int32_t)0x6c622f67 || signature == (int32_t)0xc6c1e5a7)
        [is readString];
    return result;
}

@end

@interface TLCodexModernDialogsSliceParser : TLmessages_Dialogs$messages_dialogsSlice
@end

@implementation TLCodexModernDialogsSliceParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernDialogsSliceParser *result = [[TLCodexModernDialogsSliceParser alloc] init];
    result.count = [is readInt32];
    TGLog(@"IOS6DIALOGS parse sig=0x%08x count=%d", signature, result.count);
    if (signature == (int32_t)0x0200185b)
    {
        result.dialogs = @[];
        result.messages = @[];
        result.chats = @[];
        result.users = @[];
        TGLog(@"IOS6DIALOGS notModified count=%d", result.count);
        return result;
    }
    result.dialogs = CodexReadObjectVector(is, environment, error);
    TGLog(@"IOS6DIALOGS dialogs=%d error=%@", (int)result.dialogs.count, error != NULL ? *error : nil);
    if (error != NULL && *error != nil)
        return nil;
    result.messages = CodexReadObjectVector(is, environment, error);
    TGLog(@"IOS6DIALOGS messages=%d error=%@", (int)result.messages.count, error != NULL ? *error : nil);
    if (error != NULL && *error != nil)
        return nil;
    result.chats = CodexReadObjectVector(is, environment, error);
    TGLog(@"IOS6DIALOGS chats=%d error=%@", (int)result.chats.count, error != NULL ? *error : nil);
    if (error != NULL && *error != nil)
        return nil;
    result.users = CodexReadObjectVector(is, environment, error);
    TGLog(@"IOS6DIALOGS users=%d error=%@", (int)result.users.count, error != NULL ? *error : nil);
    return result;
}

@end

@interface TLCodexModernContactParser : TLContact$contact
@end

@implementation TLCodexModernContactParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernContactParser *result = [[TLCodexModernContactParser alloc] init];
    result.user_id = TGModernLegacyIdForModernId([is readInt64]);
    TLBool *mutual = (TLBool *)CodexReadObject(is, environment, error);
    result.mutual = [mutual boolValue];
    return result;
}

@end

@interface TLCodexModernContactsParser : TLcontacts_Contacts$contacts_contacts
@end

@implementation TLCodexModernContactsParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernContactsParser *result = [[TLCodexModernContactsParser alloc] init];
    int32_t vectorMarker = [is readInt32];
    int32_t count = 0;
    if (vectorMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
        count = [is readInt32];
    else if (vectorMarker >= 0 && vectorMarker <= 10000)
        count = vectorMarker;
    TGLog(@"IOS6AUTH contacts vectorMarker=0x%x count=%d", vectorMarker, count);
    
    NSMutableArray *contacts = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)MAX(0, count)];
    bool hasUsersMarker = false;
    int32_t usersMarker = 0;
    for (int32_t i = 0; i < count; i++)
    {
        int32_t contactSignature = [is readInt32];
        if (contactSignature == TL_UNIVERSAL_VECTOR_CONSTRUCTOR || (contactSignature >= 0 && contactSignature <= 10000))
        {
            TGLog(@"IOS6AUTH contacts early users marker=0x%x at index=%d expected=%d", contactSignature, i, count);
            hasUsersMarker = true;
            usersMarker = contactSignature;
            break;
        }
        if (contactSignature == (int32_t)0x145ade0b)
        {
            TLContact$contact *contact = [[TLContact$contact alloc] init];
            contact.user_id = TGModernLegacyIdForModernId([is readInt64]);
            int32_t mutualSignature = [is readInt32];
            contact.mutual = mutualSignature == (int32_t)TL_BOOL_TRUE_CONSTRUCTOR;
            [contacts addObject:contact];
        }
        else
        {
            id contact = TLMetaClassStore::constructObject(is, contactSignature, environment, nil, error);
            if (error != nil && *error != nil)
                return nil;
            if (contact != nil)
                [contacts addObject:contact];
        }
    }
    
    result.contacts = contacts;
    if (hasUsersMarker)
    {
        result.saved_count = 0;
        result.users = CodexReadMaybeDoubleObjectVectorWithMarker(is, usersMarker, environment, error);
        TGLog(@"IOS6AUTH contacts early contacts=%d users=%d error=%@", (int)result.contacts.count, (int)result.users.count, error != NULL ? *error : nil);
        return result;
    }
    int32_t nextMarker = [is readInt32];
    TGLog(@"IOS6AUTH contacts nextMarker=0x%x contacts=%d", nextMarker, (int)result.contacts.count);
    if (nextMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
    {
        result.saved_count = 0;
        result.users = CodexReadMaybeDoubleObjectVectorWithMarker(is, nextMarker, environment, error);
    }
    else
    {
        result.saved_count = nextMarker;
        int32_t usersMarker = [is readInt32];
        TGLog(@"IOS6AUTH contacts saved_count=%d usersMarker=0x%x", result.saved_count, usersMarker);
        result.users = CodexReadMaybeDoubleObjectVectorWithMarker(is, usersMarker, environment, error);
    }
    return result;
}

@end

@interface TLCodexModernBlockedParser : TLcontacts_Blocked$contacts_blocked
@end

@implementation TLCodexModernBlockedParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLcontacts_Blocked$contacts_blocked *result = [[TLcontacts_Blocked$contacts_blocked alloc] init];
    if (signature == (int32_t)0xe1664194)
        [is readInt32];
    CodexReadObjectVector(is, environment, error);
    CodexReadObjectVector(is, environment, error);
    result.blocked = @[];
    result.users = CodexReadObjectVector(is, environment, error);
    TGLog(@"IOS6AUTH contacts.blocked users=%d error=%@", (int)result.users.count, error != NULL ? *error : nil);
    return result;
}

@end

@interface TLCodexModernMessageFwdHeaderParser : TLMessageFwdHeader$messageFwdHeaderMeta
@end

@implementation TLCodexModernMessageFwdHeaderParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernMessageFwdHeaderParser *result = [[TLCodexModernMessageFwdHeaderParser alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    if (flags & (1 << 0))
    {
        TLPeer *fromPeer = (TLPeer *)CodexReadObject(is, environment, error);
        if ([fromPeer isKindOfClass:[TLPeer$peerUser class]])
            result.from_id = ((TLPeer$peerUser *)fromPeer).user_id;
        else if ([fromPeer isKindOfClass:[TLPeer$peerChannel class]])
            result.channel_id = ((TLPeer$peerChannel *)fromPeer).channel_id;
        else if ([fromPeer isKindOfClass:[TLPeer$peerChat class]])
            result.from_id = ((TLPeer$peerChat *)fromPeer).chat_id;
    }
    if (flags & (1 << 5))
        [is readString];
    result.date = [is readInt32];
    if (flags & (1 << 2))
        result.channel_post = [is readInt32];
    if (flags & (1 << 3))
        result.post_author = [is readString];
    if (flags & (1 << 4))
    {
        result.saved_from_peer = (TLPeer *)CodexReadObject(is, environment, error);
        result.saved_from_msg_id = [is readInt32];
    }
    if (flags & (1 << 8))
        CodexReadObject(is, environment, error);
    if (flags & (1 << 9))
        [is readString];
    if (flags & (1 << 10))
        [is readInt32];
    if (flags & (1 << 6))
        [is readString];
    return result;
}

@end

@interface TLCodexMessageViewsResultParser : NSObject<TLObject>
@end

@implementation TLCodexMessageViewsResultParser

- (int32_t)TLconstructorSignature
{
    return (int32_t)0xb6c4f543;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xb6c4f543;
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    int32_t vectorMarker = [is readInt32];
    int32_t count = 0;
    if (vectorMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
        count = [is readInt32];
    else if (vectorMarker >= 0 && vectorMarker <= 10000)
        count = vectorMarker;
    else
    {
        TGLog(@"IOS6VIEWS expected views vector, got 0x%08x", vectorMarker);
        count = 0;
    }
    
    NSMutableArray *viewCounts = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)MAX(0, count)];
    for (int32_t i = 0; i < count; i++)
    {
        int32_t itemSignature = [is readInt32];
        int32_t views = 0;
        if (itemSignature == (int32_t)0x455b853d)
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                views = [is readInt32];
            if (flags & (1 << 1))
                [is readInt32];
            if (flags & (1 << 2))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 3))
                CodexReadObject(is, environment, error);
            if (error != nil && *error != nil)
            {
                TGLog(@"IOS6VIEWS failed nested field index=%d flags=0x%08x error=%@", i, flags, *error);
                *error = nil;
            }
        }
        else
            TGLog(@"IOS6VIEWS unknown MessageViews item sig=0x%08x index=%d", itemSignature, i);
        [viewCounts addObject:@(views)];
    }
    
    CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6VIEWS failed chats vector error=%@", *error);
        *error = nil;
    }
    CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6VIEWS failed users vector error=%@", *error);
        *error = nil;
    }
    
    TGLog(@"IOS6VIEWS parsed messageViews count=%d", (int)viewCounts.count);
    return (id<TLObject>)viewCounts;
}

@end

@interface TLCodexModernMessagesParser : TLmessages_Messages$messages_messages
@end

@implementation TLCodexModernMessagesParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernMessagesParser *result = [[TLCodexModernMessagesParser alloc] init];
    result.messages = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS messages.messages failed at messages error=%@", *error);
        return nil;
    }
    if (signature == (int32_t)0x1d73e7ea)
    {
        NSArray *topics = CodexReadObjectVector(is, environment, error);
        if (error != nil && *error != nil)
        {
            TGLog(@"IOS6DIALOGS messages.messages failed at topics messages=%d error=%@", (int)result.messages.count, *error);
            return nil;
        }
        TGLog(@"IOS6DIALOGS messages.messages topics=%d", (int)topics.count);
    }
    result.chats = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS messages.messages failed at chats messages=%d error=%@", (int)result.messages.count, *error);
        return nil;
    }
    result.users = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS messages.messages failed at users messages=%d chats=%d error=%@", (int)result.messages.count, (int)result.chats.count, *error);
        *error = nil;
        result.users = @[];
        return result;
    }
    
    TGLog(@"IOS6DIALOGS messages.messages messages=%d chats=%d users=%d", (int)result.messages.count, (int)result.chats.count, (int)result.users.count);
    return result;
}

@end

@interface TLCodexModernMessagesSliceParser : TLmessages_Messages$messages_messagesSlice
@end

@implementation TLCodexModernMessagesSliceParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernMessagesSliceParser *result = [[TLCodexModernMessagesSliceParser alloc] init];
    int32_t flags = [is readInt32];
    result.count = [is readInt32];
    if (flags & (1 << 0))
        [is readInt32];
    if (flags & (1 << 2))
        [is readInt32];
    if (signature == (int32_t)0x5f206716 && (flags & (1 << 3)))
    {
        CodexReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    
    result.messages = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS messagesSlice failed at messages count=%d flags=%d error=%@", result.count, flags, *error);
        return nil;
    }
    if (signature == (int32_t)0x5f206716)
    {
        NSArray *topics = CodexReadObjectVector(is, environment, error);
        if (error != nil && *error != nil)
        {
            TGLog(@"IOS6DIALOGS messagesSlice failed at topics count=%d messages=%d flags=%d error=%@", result.count, (int)result.messages.count, flags, *error);
            return nil;
        }
        TGLog(@"IOS6DIALOGS messagesSlice topics=%d", (int)topics.count);
    }
    result.chats = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS messagesSlice failed at chats count=%d messages=%d flags=%d error=%@", result.count, (int)result.messages.count, flags, *error);
        return nil;
    }
    result.users = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS messagesSlice failed at users count=%d messages=%d chats=%d flags=%d error=%@", result.count, (int)result.messages.count, (int)result.chats.count, flags, *error);
        *error = nil;
        result.users = @[];
        return result;
    }
    
    TGLog(@"IOS6DIALOGS messagesSlice count=%d messages=%d chats=%d users=%d flags=%d", result.count, (int)result.messages.count, (int)result.chats.count, (int)result.users.count, flags);
    return result;
}

@end

@interface TLCodexModernDraftMessageParser : TLDraftMessage$draftMessage
@end

@implementation TLCodexModernDraftMessageParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLDraftMessage$draftMessage *result = [[TLDraftMessage$draftMessage alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    if (flags & (1 << 4))
        CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    result.message = [is readString];
    if (flags & (1 << 3))
        result.entities = CodexReadObjectVectorOrSingle(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS draftMessage entities skipped error=%@", *error);
        *error = nil;
        result.entities = @[];
    }
    if (flags & (1 << 5))
        CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    result.date = [is readInt32];
    if (flags & (1 << 7))
        [is readInt64];
    if (flags & (1 << 8))
        CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    if (flags & (1 << 9))
        CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS draftMessage tail skipped error=%@", *error);
        *error = nil;
    }
    TGLog(@"IOS6DIALOGS draftMessage flags=0x%08x textLen=%d", flags, (int)result.message.length);
    return result;
}

@end

@interface TLCodexModernUpdateDraftMessageParser : TLUpdate$updateDraftMessage
@end

@implementation TLCodexModernUpdateDraftMessageParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLUpdate$updateDraftMessage *result = [[TLUpdate$updateDraftMessage alloc] init];
    int32_t flags = [is readInt32];
    result.peer = (TLPeer *)CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    if (flags & (1 << 0))
        [is readInt32];
    result.draft = (TLDraftMessage *)CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS updateDraftMessage draft skipped flags=0x%08x error=%@", flags, *error);
        *error = nil;
    }
    TGLog(@"IOS6DIALOGS updateDraftMessage flags=0x%08x draft=%@", flags, NSStringFromClass([result.draft class]));
    return result;
}

@end

@interface TLCodexModernChannelParticipantParser : NSObject <TLObject>
@end

@implementation TLCodexModernChannelParticipantParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    int32_t flags = 0;
    TLChannelParticipant *result = nil;
    switch (signature)
    {
        case (int32_t)0x1bd54456:
        {
            flags = [is readInt32];
            TLChannelParticipant$channelParticipant *participant = [[TLChannelParticipant$channelParticipant alloc] init];
            participant.user_id = TGModernLegacyIdForModernId([is readInt64]);
            participant.date = [is readInt32];
            if (flags & (1 << 0)) [is readInt32];
            if (flags & (1 << 2)) [is readString];
            result = participant;
            break;
        }
        case (int32_t)0xa9478a1a:
        {
            flags = [is readInt32];
            TLChannelParticipant$channelParticipantSelf *participant = [[TLChannelParticipant$channelParticipantSelf alloc] init];
            participant.user_id = TGModernLegacyIdForModernId([is readInt64]);
            participant.inviter_id = TGModernLegacyIdForModernId([is readInt64]);
            participant.date = [is readInt32];
            if (flags & (1 << 1)) [is readInt32];
            if (flags & (1 << 2)) [is readString];
            result = participant;
            break;
        }
        case (int32_t)0x2fe601d3:
        {
            flags = [is readInt32];
            TLChannelParticipant$channelParticipantCreator *participant = [[TLChannelParticipant$channelParticipantCreator alloc] init];
            participant.user_id = TGModernLegacyIdForModernId([is readInt64]);
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0)) [is readString];
            result = participant;
            break;
        }
        case (int32_t)0x34c3bb53:
        {
            flags = [is readInt32];
            TLChannelParticipant$channelParticipantAdmin *participant = [[TLChannelParticipant$channelParticipantAdmin alloc] init];
            participant.flags = flags;
            participant.user_id = TGModernLegacyIdForModernId([is readInt64]);
            if (flags & (1 << 1))
                participant.inviter_id = TGModernLegacyIdForModernId([is readInt64]);
            participant.promoted_by = TGModernLegacyIdForModernId([is readInt64]);
            participant.date = [is readInt32];
            participant.admin_rights = (TLChannelAdminRights *)CodexReadObject(is, environment, error);
            if (flags & (1 << 2)) [is readString];
            result = participant;
            break;
        }
        case (int32_t)0xd5f0ad91:
        {
            flags = [is readInt32];
            TLChannelParticipant$channelParticipantBanned *participant = [[TLChannelParticipant$channelParticipantBanned alloc] init];
            participant.flags = flags;
            CodexReadObject(is, environment, error);
            participant.kicked_by = TGModernLegacyIdForModernId([is readInt64]);
            participant.date = [is readInt32];
            participant.banned_rights = (TLChannelBannedRights *)CodexReadObject(is, environment, error);
            if (flags & (1 << 2)) [is readString];
            result = participant;
            break;
        }
        case (int32_t)0x1b03f006:
        {
            CodexReadObject(is, environment, error);
            result = [[TLChannelParticipant alloc] init];
            break;
        }
    }
    if (error != nil && *error != nil)
        return nil;
    TGLog(@"IOS6DIALOGS channelParticipant sig=0x%08x user=%d flags=0x%08x", signature, result.user_id, flags);
    return result;
}

@end

@interface TLCodexModernChannelsParticipantsParser : TLchannels_ChannelParticipants$channels_channelParticipants
@end

@implementation TLCodexModernChannelsParticipantsParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLchannels_ChannelParticipants$channels_channelParticipants *result = [[TLchannels_ChannelParticipants$channels_channelParticipants alloc] init];
    result.count = [is readInt32];
    result.participants = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    result.users = CodexReadObjectVector(is, environment, error);
    TGLog(@"IOS6DIALOGS channelParticipants count=%d participants=%d users=%d", result.count, (int)result.participants.count, (int)result.users.count);
    return result;
}

@end

@interface TLCodexModernMessageEmptyParser : TLMessage$messageEmpty
@end

@implementation TLCodexModernMessageEmptyParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLMessage$messageEmpty *result = [[TLMessage$messageEmpty alloc] init];
    int32_t flags = [is readInt32];
    result.n_id = [is readInt32];
    if (flags & (1 << 0))
        CodexReadObject(is, environment, error);
    TGLog(@"IOS6MSG messageEmpty id=%d flags=0x%08x", result.n_id, flags);
    return result;
}

@end

@interface TLCodexModernPeerSettingsParser : TLPeerSettings$peerSettings
@end

@implementation TLCodexModernPeerSettingsParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLPeerSettings$peerSettings *result = [[TLPeerSettings$peerSettings alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    if (flags & (1 << 6))
        [is readInt32];
    if (flags & (1 << 9))
    {
        [is readString];
        [is readInt32];
    }
    if (flags & (1 << 13))
    {
        [is readInt64];
        [is readString];
    }
    if (flags & (1 << 14))
        [is readInt64];
    if (flags & (1 << 15))
        [is readString];
    if (flags & (1 << 16))
        [is readString];
    if (flags & (1 << 17))
        [is readInt32];
    if (flags & (1 << 18))
        [is readInt32];
    TGLog(@"IOS6DIALOGS peerSettings flags=0x%08x", flags);
    return result;
}

@end

@interface TLCodexInputGroupCallParser : NSObject <TLObject>
@end

@implementation TLCodexInputGroupCallParser

- (int32_t)TLconstructorSignature
{
    return (int32_t)0xd8aa840f;
}

- (int32_t)TLconstructorName
{
    return 0;
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    [is readInt64];
    [is readInt64];
    return nil;
}

@end

@interface TLCodexModernBotCommandParser : TLBotCommand$botCommand
@end

@implementation TLCodexModernBotCommandParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLBotCommand$botCommand *result = [[TLBotCommand$botCommand alloc] init];
    result.command = [is readString];
    result.n_description = [is readString];
    return result;
}

@end

@interface TLCodexModernAllStickersParser : TLmessages_AllStickers$messages_allStickers
@end

@implementation TLCodexModernAllStickersParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0xe86602c3)
    {
        IOS6_NOOP_LOG(@"IOS6STICKER tl.allStickersNotModified");
        return [[TLmessages_AllStickers$messages_allStickersNotModified alloc] init];
    }
    
    TLmessages_AllStickers$messages_allStickers *result = [[TLmessages_AllStickers$messages_allStickers alloc] init];
    result.n_hash = (int32_t)[is readInt64];
    result.sets = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    id firstSet = result.sets.count == 0 ? nil : result.sets[0];
    IOS6_NOOP_LOG(@"IOS6STICKER tl.allStickers hash=%d sets=%d first=%@", result.n_hash, (int)result.sets.count, firstSet == nil ? nil : NSStringFromClass([firstSet class]));
    return result;
}

@end

@interface TLCodexModernRecentStickersParser : TLmessages_RecentStickers$messages_recentStickers
@end

@implementation TLCodexModernRecentStickersParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0x0b17f890)
    {
        IOS6_NOOP_LOG(@"IOS6STICKER tl.recentStickersNotModified");
        return [[TLmessages_RecentStickers$messages_recentStickersNotModified alloc] init];
    }
    
    TLmessages_RecentStickers$messages_recentStickers *result = [[TLmessages_RecentStickers$messages_recentStickers alloc] init];
    result.n_hash = (int32_t)[is readInt64];
    result.packs = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    result.stickers = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    result.dates = CodexReadInt32Vector(is);
    IOS6_NOOP_LOG(@"IOS6STICKER tl.recentStickers hash=%d packs=%d stickers=%d dates=%d", result.n_hash, (int)result.packs.count, (int)result.stickers.count, (int)result.dates.count);
    return result;
}

@end

@interface TLCodexModernFeaturedStickersParser : TLmessages_FeaturedStickers$messages_featuredStickers
@end

@implementation TLCodexModernFeaturedStickersParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0xc6dc0c66)
    {
        int32_t count = [is readInt32];
        IOS6_NOOP_LOG(@"IOS6STICKER tl.featuredStickersNotModified count=%d", count);
        return [[TLmessages_FeaturedStickers$messages_featuredStickersNotModified alloc] init];
    }
    
    TLmessages_FeaturedStickers$messages_featuredStickers *result = [[TLmessages_FeaturedStickers$messages_featuredStickers alloc] init];
    int32_t flags = [is readInt32];
    result.n_hash = (int32_t)[is readInt64];
    [is readInt32]; // count
    result.sets = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    result.unread = CodexReadInt64Vector(is);
    IOS6_NOOP_LOG(@"IOS6STICKER tl.featuredStickers flags=0x%08x hash=%d sets=%d unread=%d", flags, result.n_hash, (int)result.sets.count, (int)result.unread.count);
    return result;
}

@end

@interface TLCodexModernFavedStickersParser : TLmessages_FavedStickers$messages_favedStickers
@end

@implementation TLCodexModernFavedStickersParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0x9e8fa6d3)
    {
        IOS6_NOOP_LOG(@"IOS6STICKER tl.favedStickersNotModified");
        return [[TLmessages_FavedStickers$messages_favedStickersNotModified alloc] init];
    }
    
    TLmessages_FavedStickers$messages_favedStickers *result = [[TLmessages_FavedStickers$messages_favedStickers alloc] init];
    result.n_hash = (int32_t)[is readInt64];
    result.packs = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    result.stickers = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    id firstSticker = result.stickers.count == 0 ? nil : result.stickers[0];
    IOS6_NOOP_LOG(@"IOS6STICKER tl.favedStickers hash=%d packs=%d stickers=%d firstSticker=%@", result.n_hash, (int)result.packs.count, (int)result.stickers.count, firstSticker == nil ? nil : NSStringFromClass([firstSticker class]));
    return result;
}

@end

@interface TLCodexModernInputStickerSetParser : TLInputStickerSet
@end

@implementation TLCodexModernInputStickerSetParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    if (signature == (int32_t)0x9de7a269)
    {
        TLInputStickerSet$inputStickerSetID *result = [[TLInputStickerSet$inputStickerSetID alloc] init];
        result.n_id = [is readInt64];
        result.access_hash = [is readInt64];
        IOS6_NOOP_LOG(@"IOS6STICKER tl.inputStickerSetID id=%lld", (long long)result.n_id);
        return result;
    }
    if (signature == (int32_t)0x861cc8a0)
    {
        TLInputStickerSet$inputStickerSetShortName *result = [[TLInputStickerSet$inputStickerSetShortName alloc] init];
        result.short_name = [is readString];
        IOS6_NOOP_LOG(@"IOS6STICKER tl.inputStickerSetShortName short=%@", result.short_name);
        return result;
    }
    if (signature == (int32_t)0xe67f520e)
        [is readString];
    
    IOS6_NOOP_LOG(@"IOS6STICKER tl.inputStickerSet.emptyish sig=0x%08x", signature);
    return [[TLInputStickerSet$inputStickerSetEmpty alloc] init];
}

@end

@interface TLCodexModernDocumentAttributeStickerParser : TLDocumentAttributeSticker
@end

@implementation TLCodexModernDocumentAttributeStickerParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLDocumentAttributeSticker *result = [[TLDocumentAttributeSticker alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    result.alt = [is readString];
    result.stickerset = (TLInputStickerSet *)CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    if (flags & (1 << 0))
        result.mask_coords = (TLMaskCoords *)CodexReadObject(is, environment, error);
    IOS6_NOOP_LOG(@"IOS6STICKER tl.documentAttributeSticker flags=0x%08x alt=%@ set=%@ mask=%d", flags, result.alt, NSStringFromClass([result.stickerset class]), (flags & (1 << 0)) ? 1 : 0);
    return result;
}

@end

@interface TLCodexModernStickerSetMetaParser : TLStickerSet$stickerSetMeta
@end

@implementation TLCodexModernStickerSetMetaParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLStickerSet$stickerSetMeta *result = [[TLStickerSet$stickerSetMeta alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    if (flags & (1 << 0))
        result.installed_date = [is readInt32];
    result.n_id = [is readInt64];
    result.access_hash = [is readInt64];
    result.title = [is readString];
    result.short_name = [is readString];
    if (flags & (1 << 4))
    {
        CodexReadObjectVector(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
        [is readInt32];
        [is readInt32];
    }
    if (flags & (1 << 8))
        [is readInt64];
    result.count = [is readInt32];
    result.n_hash = [is readInt32];
    IOS6_NOOP_LOG(@"IOS6STICKER tl.stickerSetMeta sig=0x%08x flags=0x%08x id=%lld title=%@ short=%@ count=%d hash=%d", signature, flags, (long long)result.n_id, result.title, result.short_name, result.count, result.n_hash);
    return result;
}

@end

@interface TLCodexModernStickerKeywordParser : NSObject <TLObject>
@end

@implementation TLCodexModernStickerKeywordParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    [is readInt64];
    CodexSkipStringVector(is);
    return nil;
}

@end

@interface TLCodexModernStickerSetParser : TLmessages_StickerSet$messages_stickerSet
@end

@implementation TLCodexModernStickerSetParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0xd3f924eb)
    {
        IOS6_NOOP_LOG(@"IOS6STICKER tl.stickerSetNotModified");
        return [[TLmessages_StickerSet alloc] init];
    }
    
    TLmessages_StickerSet$messages_stickerSet *result = [[TLmessages_StickerSet$messages_stickerSet alloc] init];
    result.set = (TLStickerSet *)CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    result.packs = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    result.documents = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    id firstDocument = result.documents.count == 0 ? nil : result.documents[0];
    IOS6_NOOP_LOG(@"IOS6STICKER tl.stickerSet set=%@ packs=%d documents=%d firstDocument=%@", result.set, (int)result.packs.count, (int)result.documents.count, firstDocument == nil ? nil : NSStringFromClass([firstDocument class]));
    return result;
}

@end

@interface TLCodexModernStickerSetCoveredParser : TLStickerSetCovered$stickerSetMultiCovered
@end

@implementation TLCodexModernStickerSetCoveredParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0x6410a5d2)
    {
        TLStickerSetCovered$stickerSetCovered *result = [[TLStickerSetCovered$stickerSetCovered alloc] init];
        result.set = (TLStickerSet *)CodexReadObject(is, environment, error);
        result.cover = (TLDocument *)CodexReadObject(is, environment, error);
        IOS6_NOOP_LOG(@"IOS6STICKER tl.stickerSetCovered single sig=0x%08x set=%@ cover=%@", signature, result.set, result.cover == nil ? nil : NSStringFromClass([result.cover class]));
        return result;
    }

    TLStickerSetCovered$stickerSetMultiCovered *result = [[TLStickerSetCovered$stickerSetMultiCovered alloc] init];
    result.set = (TLStickerSet *)CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;

    if (signature == (int32_t)0x3407e51b)
    {
        result.covers = CodexReadObjectVector(is, environment, error);
    }
    else if (signature == (int32_t)0x40d13c0e)
    {
        CodexReadObjectVector(is, environment, error);
        CodexReadObjectVector(is, environment, error);
        result.covers = CodexReadObjectVector(is, environment, error);
    }
    else
    {
        result.covers = @[];
    }

    id firstCover = result.covers.count == 0 ? nil : result.covers[0];
    IOS6_NOOP_LOG(@"IOS6STICKER tl.stickerSetCovered sig=0x%08x set=%@ covers=%d firstCover=%@", signature, result.set, (int)result.covers.count, firstCover == nil ? nil : NSStringFromClass([firstCover class]));
    return result;
}

@end

@interface TLCodexModernStickerSetInstallResultParser : TLmessages_StickerSetInstallResult
@end

@implementation TLCodexModernStickerSetInstallResultParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0x38641628)
    {
        IOS6_NOOP_LOG(@"IOS6STICKER tl.installResult success");
        return [[TLmessages_StickerSetInstallResult$messages_stickerSetInstallResultSuccess alloc] init];
    }
    
    TLmessages_StickerSetInstallResult$messages_stickerSetInstallResultArchive *result = [[TLmessages_StickerSetInstallResult$messages_stickerSetInstallResultArchive alloc] init];
    result.sets = CodexReadObjectVector(is, environment, error);
    IOS6_NOOP_LOG(@"IOS6STICKER tl.installResult archive sets=%d", (int)result.sets.count);
    return result;
}

@end

@interface TLCodexModernFoundStickerSetsParser : TLmessages_FoundStickerSets$messages_foundStickerSets
@end

@implementation TLCodexModernFoundStickerSetsParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0x0d54b65d)
    {
        IOS6_NOOP_LOG(@"IOS6STICKER tl.foundStickerSetsNotModified");
        return [[TLmessages_FoundStickerSets alloc] init];
    }
    
    TLmessages_FoundStickerSets$messages_foundStickerSets *result = [[TLmessages_FoundStickerSets$messages_foundStickerSets alloc] init];
    result.n_hash = [is readInt32];
    result.sets = CodexReadObjectVector(is, environment, error);
    IOS6_NOOP_LOG(@"IOS6STICKER tl.foundStickerSets hash=%d sets=%d", result.n_hash, (int)result.sets.count);
    return result;
}

@end

@interface TLCodexModernExportedAuthorizationParser : TLauth_ExportedAuthorization$auth_exportedAuthorization
@end

@implementation TLCodexModernExportedAuthorizationParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLauth_ExportedAuthorization$auth_exportedAuthorization *result = [[TLauth_ExportedAuthorization$auth_exportedAuthorization alloc] init];
    result.n_id = (int32_t)[is readInt64];
    result.bytes = [is readBytes];
    TGLog(@"IOS6AUTH exportedAuthorization bytes=%d", (int)result.bytes.length);
    return result;
}

@end

@interface TLCodexModernBotInfoParser : TLBotInfo$botInfo
@end

@implementation TLCodexModernBotInfoParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLBotInfo$botInfo *result = [[TLBotInfo$botInfo alloc] init];
    int32_t flags = [is readInt32];
    if (flags & (1 << 0))
    {
        int64_t userId = [is readInt64];
        result.user_id = TGModernLegacyIdForModernId(userId);
    }
    if (flags & (1 << 1))
        result.n_description = [is readString];
    if (flags & (1 << 4))
        CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    if (flags & (1 << 5))
        CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    if (flags & (1 << 2))
        result.commands = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    if (flags & (1 << 3))
        CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    TGLog(@"IOS6DIALOGS botInfo user=%d commands=%d flags=0x%08x", result.user_id, (int)result.commands.count, flags);
    return result;
}

@end

@interface TLCodexPeerSettingsContainerParser : TLPeerSettings$peerSettings
@end

@implementation TLCodexPeerSettingsContainerParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLPeerSettings *settings = (TLPeerSettings *)CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    return settings != nil ? settings : [[TLPeerSettings$peerSettings alloc] init];
}

@end

@interface TLCodexForumTopicParser : NSObject <TLObject>
@end

@implementation TLCodexForumTopicParser

- (int32_t)TLconstructorSignature
{
    return 0x71701da9;
}

- (int32_t)TLconstructorName
{
    return 0;
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0x023f109b)
    {
        [is readInt32];
        return nil;
    }
    
    int32_t flags = [is readInt32];
    [is readInt32];
    [is readInt32];
    if (signature == (int32_t)0xfcdad815)
    {
        CodexReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    [is readString];
    [is readInt32];
    if (flags & (1 << 0))
        [is readInt64];
    [is readInt32];
    [is readInt32];
    [is readInt32];
    [is readInt32];
    [is readInt32];
    [is readInt32];
    if (signature == (int32_t)0xfcdad815)
        [is readInt32];
    CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    CodexReadObject(is, environment, error);
    if (error != nil && *error != nil)
        return nil;
    if (flags & (1 << 4))
        CodexReadObject(is, environment, error);
    
    return nil;
}

@end

@interface TLCodexModernChannelMessagesParser : TLmessages_Messages$messages_channelMessages
@end

@implementation TLCodexModernChannelMessagesParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernChannelMessagesParser *result = [[TLCodexModernChannelMessagesParser alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    result.pts = [is readInt32];
    result.count = [is readInt32];
    if (flags & (1 << 2))
        [is readInt32];
    
    result.messages = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS channelMessages failed at messages count=%d flags=%d error=%@", result.count, flags, *error);
        return nil;
    }
    
    NSArray *topics = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS channelMessages failed at topics count=%d messages=%d flags=%d error=%@", result.count, (int)result.messages.count, flags, *error);
        return nil;
    }
    
    result.chats = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS channelMessages failed at chats count=%d messages=%d topics=%d flags=%d error=%@", result.count, (int)result.messages.count, (int)topics.count, flags, *error);
        return nil;
    }
    
    result.users = CodexReadObjectVector(is, environment, error);
    if (error != nil && *error != nil)
    {
        TGLog(@"IOS6DIALOGS channelMessages failed at users count=%d messages=%d topics=%d chats=%d flags=%d error=%@", result.count, (int)result.messages.count, (int)topics.count, (int)result.chats.count, flags, *error);
        return nil;
    }
    
    TGLog(@"IOS6DIALOGS channelMessages count=%d pts=%d messages=%d topics=%d chats=%d users=%d flags=%d", result.count, result.pts, (int)result.messages.count, (int)topics.count, (int)result.chats.count, (int)result.users.count, flags);
    return result;
}

@end

@interface TLCodexModernMessageActionParser : TLMessageAction
@end

@implementation TLCodexModernMessageActionParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    switch (signature)
    {
        case (int32_t)0xb6aef7b0:
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x80e11a7f:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            if (flags & (1 << 0))
                [is readInt32];
            if (flags & (1 << 1))
                [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0xbd47cbad:
        {
            TLMessageAction$messageActionChatCreate *result = [[TLMessageAction$messageActionChatCreate alloc] init];
            result.title = [is readString];
            result.users = CodexReadInt64Vector(is);
            return result;
        }
        case (int32_t)0xb5a1ce5a:
        {
            TLMessageAction$messageActionChatEditTitle *result = [[TLMessageAction$messageActionChatEditTitle alloc] init];
            result.title = [is readString];
            return result;
        }
        case (int32_t)0x7fcb13a8:
        {
            TLMessageAction$messageActionChatEditPhoto *result = [[TLMessageAction$messageActionChatEditPhoto alloc] init];
            result.photo = (TLPhoto *)CodexReadObject(is, environment, error);
            return result;
        }
        case (int32_t)0x95e3fbef:
            return [[TLMessageAction$messageActionChatDeletePhoto alloc] init];
        case (int32_t)0x15cefd00:
        {
            TLMessageAction$messageActionChatAddUser *result = [[TLMessageAction$messageActionChatAddUser alloc] init];
            result.users = CodexReadInt64Vector(is);
            return result;
        }
        case (int32_t)0xa43f30cc:
        {
            TLMessageAction$messageActionChatDeleteUser *result = [[TLMessageAction$messageActionChatDeleteUser alloc] init];
            result.user_id = TGModernLegacyIdForModernId([is readInt64]);
            return result;
        }
        case (int32_t)0x31224c3:
        {
            TLMessageAction$messageActionChatJoinedByLink *result = [[TLMessageAction$messageActionChatJoinedByLink alloc] init];
            result.inviter_id = TGModernLegacyIdForModernId([is readInt64]);
            return result;
        }
        case (int32_t)0x95d2ac92:
        {
            TLMessageAction$messageActionChannelCreate *result = [[TLMessageAction$messageActionChannelCreate alloc] init];
            result.title = [is readString];
            return result;
        }
        case (int32_t)0xe1037f92:
        {
            TLMessageAction$messageActionChatMigrateTo *result = [[TLMessageAction$messageActionChatMigrateTo alloc] init];
            result.channel_id = (int32_t)[is readInt64];
            return result;
        }
        case (int32_t)0xea3948e9:
        {
            TLMessageAction$messageActionChannelMigrateFrom *result = [[TLMessageAction$messageActionChannelMigrateFrom alloc] init];
            result.title = [is readString];
            result.chat_id = (int32_t)[is readInt64];
            return result;
        }
        case (int32_t)0x94bd38ed:
            return [[TLMessageAction$messageActionPinMessage alloc] init];
        case (int32_t)0x9fbab604:
            return [[TLMessageAction$messageActionHistoryClear alloc] init];
        case (int32_t)0x92a72876:
        {
            TLMessageAction$messageActionGameScore *result = [[TLMessageAction$messageActionGameScore alloc] init];
            result.game_id = [is readInt64];
            result.score = [is readInt32];
            return result;
        }
        case (int32_t)0x3c134d7b:
        {
            int32_t flags = [is readInt32];
            [is readInt32];
            if (flags & (1 << 0))
                [is readInt64];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0xcc02aa6d:
            [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x0d999256:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt32];
            if (flags & (1 << 0))
                [is readInt64];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x8f31b327:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            [is readBytes];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 1))
                [is readString];
            CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x96163f56:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            if (flags & (1 << 0))
                [is readString];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x4792929b:
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xfae69f56:
            [is readString];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xc516d679:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                [is readString];
            if (flags & (1 << 2))
                CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x1b287353:
            CodexReadObjectVector(is, environment, error);
            CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xd95c6154:
            CodexReadObjectVector(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x98e0d697:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x7a0d7f42:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 0))
                [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x502f92f7:
            CodexReadObject(is, environment, error);
            CodexReadInt64Vector(is);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xb3a07661:
            CodexReadObject(is, environment, error);
            [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xaa786345:
            [is readString];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x47dd8079:
            [is readString];
            [is readString];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xb4c38cb5:
            [is readString];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xc83d6aec:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            [is readInt32];
            if (flags & (1 << 0))
            {
                [is readString];
                [is readInt64];
            }
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0xc0944820:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                [is readString];
            if (flags & (1 << 1))
                [is readInt64];
            if (flags & (1 << 2))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 3))
                CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x57de635e:
            CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x31518e9b:
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x5060a3f4:
        {
            [is readInt32];
            CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x678c2e09:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            [is readInt32];
            [is readString];
            if (flags & (1 << 2))
            {
                [is readString];
                [is readInt64];
            }
            if (flags & (1 << 3))
            {
                [is readString];
                [is readInt64];
            }
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x332ba9ed:
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x2a9fadc5:
            [is readInt32];
            [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x93b31848:
            [is readInt32];
            CodexReadObjectVector(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x41b3e202:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            [is readString];
            [is readInt64];
            if (flags & (1 << 0))
                [is readBytes];
            CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x45d5b021:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            [is readInt64];
            if (flags & (1 << 0))
            {
                [is readString];
                [is readInt64];
            }
            if (flags & (1 << 1))
                [is readString];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0xffa00ccc:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            [is readBytes];
            if (flags & (1 << 0))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 1))
                [is readString];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 4))
                [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0xc624b16e:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            if (flags & (1 << 0))
                [is readString];
            if (flags & (1 << 4))
                [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0xb91bbd3a:
            CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x48e91302:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            [is readInt32];
            if (flags & (1 << 0))
            {
                [is readString];
                [is readInt64];
            }
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x31c48347:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            [is readInt32];
            [is readString];
            if (flags & (1 << 2))
            {
                [is readString];
                [is readInt64];
            }
            if (flags & (1 << 3))
            {
                [is readString];
                [is readInt64];
            }
            if (flags & (1 << 4))
                CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0xa80f51e4:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 0))
                [is readInt64];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x87e2f155:
            [is readInt32];
            [is readInt32];
            [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xb00c47a2:
            [is readInt32];
            [is readInt64];
            [is readString];
            CodexReadObject(is, environment, error);
            [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xea2c31d3:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 1))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 4))
                [is readInt64];
            if (flags & (1 << 5))
                [is readInt32];
            if (flags & (1 << 8))
                [is readInt64];
            if (flags & (1 << 11))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 12))
            {
                CodexReadObject(is, environment, error);
                [is readInt64];
            }
            if (flags & (1 << 14))
                [is readString];
            if (flags & (1 << 15))
                [is readInt32];
            if (flags & (1 << 18))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 19))
                [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0xe6c31522:
        {
            int32_t flags = [is readInt32];
            CodexReadObject(is, environment, error);
            if (flags & (1 << 3))
                [is readInt32];
            if (flags & (1 << 4))
                [is readInt64];
            if (flags & (1 << 6))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 7))
            {
                CodexReadObject(is, environment, error);
                [is readInt64];
            }
            if (flags & (1 << 8))
                CodexReadObject(is, environment, error);
            if (flags & (1 << 9))
                [is readInt32];
            if (flags & (1 << 10))
                [is readInt32];
            if (flags & (1 << 12))
                [is readInt64];
            if (flags & (1 << 15))
                [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0xac1f1fcd:
            [is readInt32];
            [is readInt64];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x84b88578:
            [is readInt32];
            [is readInt64];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x2ffe2f7a:
        {
            int32_t flags = [is readInt32];
            [is readInt64];
            if (flags & (1 << 2))
                [is readInt32];
            if (flags & (1 << 3))
                CodexReadObjectVector(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0xcc7c5c89:
            CodexReadInt32Vector(is);
            CodexReadInt32Vector(is);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xc7edbc83:
            CodexReadObjectVector(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xee7a1596:
        {
            int32_t flags = [is readInt32];
            if (flags & (1 << 2))
                [is readString];
            if (flags & (1 << 3))
                [is readInt32];
            if (flags & (1 << 4))
                CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x95ddcf69:
            CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x69f916f8:
            [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xa8a3c699:
        {
            int32_t flags = [is readInt32];
            [is readString];
            [is readInt64];
            [is readString];
            [is readInt64];
            if (flags & (1 << 0))
                [is readString];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        }
        case (int32_t)0x2c8f2a25:
            CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x774278d4:
            [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            [is readInt32];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x73ada76b:
            [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xb07ed085:
        case (int32_t)0xe188503b:
            [is readInt64];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xbf7d6572:
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x3e2793ba:
            [is readInt32];
            CodexReadObject(is, environment, error);
            CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x9da1cd6c:
        case (int32_t)0x399674dc:
            CodexReadObject(is, environment, error);
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0x16605e3e:
            [is readInt64];
            return [[TLMessageAction$messageActionEmpty alloc] init];
        case (int32_t)0xf3f25f76:
        case (int32_t)0xebbca3cb:
        case (int32_t)0xd7c0ff9c:
            return [[TLMessageAction$messageActionEmpty alloc] init];
        default:
            TGLog(@"IOS6AUTH modern messageAction fallback sig=0x%08x", signature);
            return [[TLMessageAction$messageActionEmpty alloc] init];
    }
}

@end

@interface TLCodexModernDocumentParser : TLDocument$document
@end

@implementation TLCodexModernDocumentParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernDocumentParser *result = [[TLCodexModernDocumentParser alloc] init];
    int32_t flags = [is readInt32];
    result.n_id = [is readInt64];
    result.access_hash = [is readInt64];
    result.file_reference = [is readBytes];
    result.date = [is readInt32];
    result.mime_type = [is readString];
    result.size = (int32_t)[is readInt64];
    
    if (flags & (1 << 0))
    {
        NSArray *thumbs = CodexReadObjectVector(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
        if (thumbs.count != 0)
            result.thumb = [thumbs objectAtIndex:0];
    }
    
    if (flags & (1 << 1))
    {
        CodexReadObjectVectorOrSingle(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    
    int32_t dcIdOrAttributesMarker = [is readInt32];
    if (dcIdOrAttributesMarker == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
    {
        result.dc_id = 0;
        result.attributes = CodexReadObjectVectorWithMarker(is, dcIdOrAttributesMarker, environment, error);
        TGLog(@"IOS6AUTH modern document without dc_id id=%lld flags=0x%08x", (long long)result.n_id, flags);
    }
    else
    {
        result.dc_id = dcIdOrAttributesMarker;
        int32_t attributesMarker = [is readInt32];
        result.attributes = CodexReadObjectVectorOrSingleWithMarker(is, attributesMarker, environment, error);
        if ((error == nil || *error == nil) && attributesMarker == (int32_t)0xd38ff1c2)
        {
            for (int32_t i = 0; i < 3; i++)
            {
                int32_t tailWord = [is readInt32];
                if (CodexSkipBareDocumentAttributeTailWord(is, tailWord))
                {
                    continue;
                }
                else if (CodexLooksLikeStringFirstWord(tailWord))
                {
                    CodexSkipStringWithFirstWord(is, tailWord);
                    TGLog(@"IOS6AUTH skipped bare document attribute string first=0x%08x id=%lld", tailWord, (long long)result.n_id);
                }
                else if (CodexLooksLikeTinyBareDocumentTailWord(tailWord))
                {
                    TGLog(@"IOS6AUTH skipped bare document attribute tail word=0x%08x id=%lld", tailWord, (long long)result.n_id);
                }
                else
                    break;
            }
        }
    }
    if (error != nil && *error != nil)
        return nil;
    
    return result;
}

@end

@interface TLCodexModernDocumentAttributeVideoParser : TLDocumentAttribute$documentAttributeVideo
@end

@implementation TLCodexModernDocumentAttributeVideoParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLCodexModernDocumentAttributeVideoParser *result = [[TLCodexModernDocumentAttributeVideoParser alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    result.duration = (int32_t)[is readDouble];
    result.w = [is readInt32];
    result.h = [is readInt32];
    TGLog(@"IOS6AUTH documentAttributeVideo d38 flags=0x%08x duration=%d w=%d h=%d unknown=0x%08x", flags, result.duration, result.w, result.h, flags & ~((1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)));
    if (flags & (1 << 2))
        [is readInt32];
    if (flags & (1 << 4))
        [is readDouble];
    if (flags & (1 << 5))
        [is readString];
    return result;
}

@end

@interface TLCodexModernDocumentAttributeVideoD38Parser : TLDocumentAttribute$documentAttributeVideo
@end

@implementation TLCodexModernDocumentAttributeVideoD38Parser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLCodexModernDocumentAttributeVideoD38Parser *result = [[TLCodexModernDocumentAttributeVideoD38Parser alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    result.duration = (int32_t)[is readDouble];
    result.w = [is readInt32];
    result.h = [is readInt32];
    if (flags & (1 << 2))
        [is readInt32];
    TGLog(@"IOS6AUTH documentAttributeVideo d38 flags=0x%08x duration=%d w=%d h=%d unknown=0x%08x", flags, result.duration, result.w, result.h, flags & ~((1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)));
    return result;
}

@end

@interface TLCodexModernDocumentAttributeFilenameLikeParser : TLDocumentAttribute
@end

@implementation TLCodexModernDocumentAttributeFilenameLikeParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    [is readString];
    TGLog(@"IOS6AUTH documentAttribute filename-like 6a4a7967");
    return [[TLDocumentAttribute alloc] init];
}

@end

@interface TLCodexModernUserProfilePhotoParser : TLUserProfilePhoto$userProfilePhoto
@end

@implementation TLCodexModernUserProfilePhotoParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLCodexModernUserProfilePhotoParser *result = [[TLCodexModernUserProfilePhotoParser alloc] init];
    int32_t flags = [is readInt32];
    result.photo_id = [is readInt64];
    if (flags & (1 << 1))
        [is readBytes];
    result.dc_id = [is readInt32];
    // High-volume success path.
    return result;
}

@end

@interface TLCodexModernChatPhotoParser : TLChatPhoto$chatPhoto
@end

@implementation TLCodexModernChatPhotoParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLChatPhoto$chatPhoto *result = [[TLChatPhoto$chatPhoto alloc] init];
    if (signature == (int32_t)0x1c6e1c11)
    {
        int32_t flags = [is readInt32];
        result.photo_id = [is readInt64];
        if (flags & (1 << 1))
            [is readBytes];
        result.dc_id = [is readInt32];
        // High-volume success path.
    }
    return result;
}

@end

@interface TLCodexModernChatParser : TLChat$chat
@end

@implementation TLCodexModernChatParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLChat$chat *result = [[TLChat$chat alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    result.creator = (flags & (1 << 0));
    result.left = (flags & (1 << 2));
    result.deactivated = (flags & (1 << 5));
    int64_t chatId = [is readInt64];
    result.n_id = (int32_t)chatId;
    result.title = [is readString];
    result.photo = (TLChatPhoto *)CodexReadObject(is, environment, error);
    result.participants_count = [is readInt32];
    result.date = [is readInt32];
    result.version = [is readInt32];
    if (flags & (1 << 6))
        result.migrated_to = (TLInputChannel *)CodexReadObject(is, environment, error);
    if (flags & (1 << 14))
        CodexReadObject(is, environment, error);
    if (flags & (1 << 18))
        CodexReadObject(is, environment, error);
    return result;
}

@end

@interface TLCodexModernChatForbiddenParser : TLChat$chatForbidden
@end

@implementation TLCodexModernChatForbiddenParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLChat$chatForbidden *result = [[TLChat$chatForbidden alloc] init];
    int64_t chatId = [is readInt64];
    result.n_id = (int32_t)chatId;
    result.title = [is readString];
    return result;
}

@end

@interface TLCodexModernChannelParser : TLChat$channel
@end

@implementation TLCodexModernChannelParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLChat$channel *result = [[TLChat$channel alloc] init];
    int32_t flags = [is readInt32];
    int32_t flags2 = [is readInt32];
    result.flags = flags;
    result.flags2 = flags2;
    int64_t channelId = [is readInt64];
    result.n_id = (int32_t)channelId;
    if (flags & (1 << 13))
        result.access_hash = [is readInt64];
    result.title = [is readString];
    if (flags & (1 << 6))
        result.username = [is readString];
    result.photo = (TLChatPhoto *)CodexReadObject(is, environment, error);
    result.date = [is readInt32];
    if (flags & (1 << 9))
        CodexReadObjectVector(is, environment, error);
    if (flags & (1 << 14))
        result.admin_rights = (TLChannelAdminRights *)CodexReadObject(is, environment, error);
    if (flags & (1 << 15))
        result.banned_rights = (TLChannelBannedRights *)CodexReadObject(is, environment, error);
    if (flags & (1 << 18))
        CodexReadObject(is, environment, error);
    if (flags & (1 << 17))
        result.participants_count = [is readInt32];
    if (flags2 & (1 << 0))
        CodexReadObjectVector(is, environment, error);
    if (flags2 & (1 << 4))
        [is readInt32];
    if (flags2 & (1 << 7))
        CodexReadObject(is, environment, error);
    if (flags2 & (1 << 8))
        CodexReadObject(is, environment, error);
    if (flags2 & (1 << 9))
        CodexReadObject(is, environment, error);
    if (flags2 & (1 << 10))
        [is readInt32];
    if (flags2 & (1 << 11))
        [is readInt32];
    if (flags2 & (1 << 13))
        [is readInt64];
    if (flags2 & (1 << 14))
        [is readInt64];
    if (flags2 & (1 << 18))
        [is readInt64];
    TGLog(@"IOS6DIALOGS channel sig=0x%08x id=%lld stored=%d hash=%lld flags=0x%08x flags2=0x%08x title=%@", signature, channelId, result.n_id, result.access_hash, flags, flags2, result.title);
    return result;
}

@end

@interface TLCodexModernChannelFullParser : TLChatFull$chatFull
@end

@implementation TLCodexModernChannelFullParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLCodexModernChannelFullParser *result = [[TLCodexModernChannelFullParser alloc] init];
    int32_t flags = [is readInt32];
    int32_t flags2 = 0;
    bool isModernChannelFull = signature == (int32_t)0xa04e8d3a;
    if (isModernChannelFull)
        flags2 = [is readInt32];
    int64_t channelId = [is readInt64];
    result.n_id = (int32_t)channelId;
    [is readString];
    if (!isModernChannelFull)
    {
        CodexReadObject(is, environment, error);
        if (flags & (1 << 2))
            result.chat_photo = (TLPhoto *)CodexReadObject(is, environment, error);
        result.notify_settings = (TLPeerNotifySettings *)CodexReadObject(is, environment, error);
        if (flags & (1 << 13))
            result.exported_invite = (TLExportedChatInvite *)CodexReadObject(is, environment, error);
        if (flags & (1 << 3))
            result.bot_info = CodexReadObjectVector(is, environment, error);
        if (flags & (1 << 6)) [is readInt32];
        if (flags & (1 << 11)) [is readInt32];
        if (flags & (1 << 12)) CodexReadObject(is, environment, error);
        if (flags & (1 << 14)) [is readInt32];
        if (flags & (1 << 15)) CodexReadObject(is, environment, error);
        if (flags & (1 << 16)) [is readString];
        if (flags & (1 << 17)) { [is readInt32]; CodexReadInt64Vector(is); }
        if (flags & (1 << 18)) CodexReadObject(is, environment, error);
        if (flags & (1 << 20)) [is readInt32];
        TGLog(@"IOS6DIALOGS chatFull sig=0x%08x id=%d flags=0x%08x bots=%d", signature, result.n_id, flags, (int)result.bot_info.count);
        return result;
    }

    if (flags & (1 << 0)) [is readInt32];
    if (flags & (1 << 1)) [is readInt32];
    if (flags & (1 << 2)) { [is readInt32]; [is readInt32]; }
    if (flags & (1 << 13)) [is readInt32];
    [is readInt32];
    [is readInt32];
    [is readInt32];
    result.chat_photo = (TLPhoto *)CodexReadObject(is, environment, error);
    result.notify_settings = (TLPeerNotifySettings *)CodexReadObject(is, environment, error);
    if (flags & (1 << 23))
        result.exported_invite = (TLExportedChatInvite *)CodexReadObject(is, environment, error);
    result.bot_info = CodexReadObjectVector(is, environment, error);
    if (flags & (1 << 4)) { [is readInt64]; [is readInt32]; }
    if (flags & (1 << 5)) [is readInt32];
    if (flags & (1 << 8)) CodexReadObject(is, environment, error);
    if (flags & (1 << 9)) [is readInt32];
    if (flags & (1 << 11)) [is readInt32];
    if (flags & (1 << 14)) [is readInt64];
    if (flags & (1 << 15)) CodexReadObject(is, environment, error);
    if (flags & (1 << 17)) [is readInt32];
    if (flags & (1 << 18)) [is readInt32];
    if (flags & (1 << 12)) [is readInt32];
    [is readInt32];
    if (flags & (1 << 21)) CodexReadObject(is, environment, error);
    if (flags & (1 << 24)) [is readInt32];
    if (flags & (1 << 25)) CodexSkipStringVector(is);
    if (flags & (1 << 26)) CodexReadObject(is, environment, error);
    if (flags & (1 << 27)) [is readString];
    if (flags & (1 << 28)) { [is readInt32]; CodexReadInt64Vector(is); }
    if (flags & (1 << 29)) CodexReadObject(is, environment, error);
    if (flags & (1 << 30)) CodexReadObject(is, environment, error);
    if (flags2 & (1 << 4)) CodexReadObject(is, environment, error);
    if (flags2 & (1 << 7)) CodexReadObject(is, environment, error);
    if (flags2 & (1 << 8)) [is readInt32];
    if (flags2 & (1 << 9)) [is readInt32];
    if (flags2 & (1 << 10)) CodexReadObject(is, environment, error);
    if (flags2 & (1 << 13)) [is readInt32];
    if (isModernChannelFull)
    {
        if (flags2 & (1 << 17)) CodexReadObject(is, environment, error);
        if (flags2 & (1 << 18)) [is readInt32];
        if (flags2 & (1 << 21)) [is readInt64];
        if (flags2 & (1 << 22)) CodexReadObject(is, environment, error);
        if (flags2 & (1 << 23)) [is readInt64];
    }
    TGLog(@"IOS6DIALOGS channelFull sig=0x%08x id=%d flags=0x%08x flags2=0x%08x bots=%d", signature, result.n_id, flags, flags2, (int)result.bot_info.count);
    return result;
}

@end

@interface TLCodexModernChannelForbiddenParser : TLChat$channelForbidden
@end

@implementation TLCodexModernChannelForbiddenParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLChat$channelForbidden *result = [[TLChat$channelForbidden alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    int64_t channelId = [is readInt64];
    result.n_id = (int32_t)channelId;
    result.access_hash = [is readInt64];
    result.title = [is readString];
    if (flags & (1 << 16))
        result.until_date = [is readInt32];
    return result;
}

@end

@interface TLCodexModernPeerUserParser : TLPeer$peerUser
@end

@implementation TLCodexModernPeerUserParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLPeer$peerUser *result = [[TLPeer$peerUser alloc] init];
    int64_t userId = [is readInt64];
    result.user_id = TGModernLegacyIdForModernId(userId);
    return result;
}

@end

@interface TLCodexModernPeerChatParser : TLPeer$peerChat
@end

@implementation TLCodexModernPeerChatParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLPeer$peerChat *result = [[TLPeer$peerChat alloc] init];
    int64_t chatId = [is readInt64];
    result.chat_id = (int32_t)chatId;
    return result;
}

@end

@interface TLCodexModernPeerChannelParser : TLPeer$peerChannel
@end

@implementation TLCodexModernPeerChannelParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLPeer$peerChannel *result = [[TLPeer$peerChannel alloc] init];
    int64_t channelId = [is readInt64];
    result.channel_id = (int32_t)channelId;
    return result;
}

@end

static void CodexSkipNotificationSound(NSInputStream *is)
{
    int32_t signature = [is readInt32];
    switch (signature)
    {
        case (int32_t)0x97e8bebe:
        case (int32_t)0x6f0c34df:
            break;
        case (int32_t)0x830b9ae4:
            [is readString];
            [is readString];
            break;
        case (int32_t)0xff6c8049:
            [is readInt64];
            break;
        default:
            TGLog(@"IOS6AUTH unknown NotificationSound sig=0x%08x", signature);
            break;
    }
}

@interface TLCodexModernPeerNotifySettingsParser : TLPeerNotifySettings$peerNotifySettings
@end

@implementation TLCodexModernPeerNotifySettingsParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLPeerNotifySettings$peerNotifySettings *result = [[TLPeerNotifySettings$peerNotifySettings alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    if (flags & (1 << 0))
        result.showPreviews = [is readInt32] == TL_BOOL_TRUE_CONSTRUCTOR;
    if (flags & (1 << 1))
        result.silent = [is readInt32] == TL_BOOL_TRUE_CONSTRUCTOR;
    if (flags & (1 << 2))
        result.mute_until = [is readInt32];
    if (flags & (1 << 3))
        CodexSkipNotificationSound(is);
    if (flags & (1 << 4))
        CodexSkipNotificationSound(is);
    if (flags & (1 << 5))
        CodexSkipNotificationSound(is);
    if (flags & (1 << 6))
        [is readInt32];
    if (flags & (1 << 7))
        [is readInt32];
    if (flags & (1 << 8))
        CodexSkipNotificationSound(is);
    if (flags & (1 << 9))
        CodexSkipNotificationSound(is);
    if (flags & (1 << 10))
        CodexSkipNotificationSound(is);
    return result;
}

@end

@interface TLCodexModernDialogParser : TLDialog$dialog
@end

@implementation TLCodexModernDialogParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLDialog$dialog *result = [[TLDialog$dialog alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    result.peer = (TLPeer *)CodexReadObject(is, environment, error);
    result.top_message = [is readInt32];
    result.read_inbox_max_id = [is readInt32];
    result.read_outbox_max_id = [is readInt32];
    result.unread_count = [is readInt32];
    result.unread_mentions_count = [is readInt32];
    [is readInt32];
    if (signature == (int32_t)0x69274bc6 || signature == (int32_t)0xfc89f7f3)
        [is readInt32];
    result.notify_settings = (TLPeerNotifySettings *)CodexReadObject(is, environment, error);
    if (flags & (1 << 0))
        result.pts = [is readInt32];
    if (flags & (1 << 1))
        result.draft = (TLDraftMessage *)CodexReadObject(is, environment, error);
    if (flags & (1 << 4))
        [is readInt32];
    if (flags & (1 << 5))
        [is readInt32];
    return result;
}

@end

@interface TLCodexDialogFolderParser : TLDialog$dialog
@end

@implementation TLCodexDialogFolderParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLDialog$dialog *result = [[TLDialog$dialog alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    
    int32_t folderSignature = [is readInt32];
    if (folderSignature == (int32_t)0xff544e65)
    {
        int32_t folderFlags = [is readInt32];
        [is readInt32];
        NSString *title = [is readString];
        if (folderFlags & (1 << 3))
            CodexReadObject(is, environment, error);
        TGLog(@"IOS6AUTH dialogFolder title=%@ flags=%d folderFlags=%d", title, flags, folderFlags);
    }
    else
    {
        TLMetaClassStore::constructObject(is, folderSignature, environment, nil, error);
    }
    
    result.peer = (TLPeer *)CodexReadObject(is, environment, error);
    result.top_message = [is readInt32];
    [is readInt32];
    [is readInt32];
    [is readInt32];
    [is readInt32];
    TGLog(@"IOS6AUTH skip dialogFolder from main list");
    return nil;
}

@end

@interface TLCodexModernImportedContactParser : TLImportedContact$importedContact
@end

@implementation TLCodexModernImportedContactParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLImportedContact$importedContact *result = [[TLImportedContact$importedContact alloc] init];
    int64_t userId = [is readInt64];
    result.user_id = TGModernLegacyIdForModernId(userId);
    result.client_id = [is readInt64];
    return result;
}

@end

@interface TLCodexUserStatusEmptyParser : TLUserStatus$userStatusEmpty
@end

@implementation TLCodexUserStatusEmptyParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)__unused is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    return [[TLUserStatus$userStatusEmpty alloc] init];
}

@end

@interface TLCodexUserStatusOnlineParser : TLUserStatus$userStatusOnline
@end

@implementation TLCodexUserStatusOnlineParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLUserStatus$userStatusOnline *result = [[TLUserStatus$userStatusOnline alloc] init];
    result.expires = [is readInt32];
    return result;
}

@end

@interface TLCodexUserStatusOfflineParser : TLUserStatus$userStatusOffline
@end

@implementation TLCodexUserStatusOfflineParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLUserStatus$userStatusOffline *result = [[TLUserStatus$userStatusOffline alloc] init];
    result.was_online = [is readInt32];
    return result;
}

@end

@interface TLCodexUserStatusNoPayloadParser : TLUserStatus$userStatusRecently
@end

@implementation TLCodexUserStatusNoPayloadParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    switch (signature)
    {
        case 0x7b197dc8:
        case 0x541a1d1a:
        case 0x65899777:
        {
            int32_t flags = [is readInt32];
            return [[TLUserStatus$userStatusRecently alloc] init];
        }
        default:
            return [[TLUserStatus$userStatusRecently alloc] init];
    }
}

@end

@interface TLCodexModernContactStatusParser : TLContactStatus$contactStatus
@end

@implementation TLCodexModernContactStatusParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLContactStatus$contactStatus *result = [[TLContactStatus$contactStatus alloc] init];
    int64_t userId = [is readInt64];
    int32_t statusSignature = [is readInt32];
    result.user_id = TGModernLegacyIdForModernId(userId);
    result.status = (TLUserStatus *)TLMetaClassStore::constructObject(is, statusSignature, environment, nil, error);
    return result;
}

@end

@interface TLCodexModernKeyboardButtonStyleParser : NSObject <TLObject>
@end

@implementation TLCodexModernKeyboardButtonStyleParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    int32_t flags = [is readInt32];
    if (flags & (1 << 3))
        [is readInt64];
    return self;
}

@end

@interface TLCodexModernReplyMarkupParser : TLReplyMarkup
@end

@implementation TLCodexModernReplyMarkupParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0xa03e5b85)
    {
        TLReplyMarkup$replyKeyboardHide *result = [[TLReplyMarkup$replyKeyboardHide alloc] init];
        result.flags = [is readInt32];
        return result;
    }
    else if (signature == (int32_t)0x86b40b08 || signature == (int32_t)0xf4108aa0)
    {
        TLReplyMarkup$replyKeyboardForceReply *result = [[TLReplyMarkup$replyKeyboardForceReply alloc] init];
        int32_t flags = [is readInt32];
        result.flags = flags;
        if (flags & (1 << 3))
            [is readString];
        return result;
    }
    else if (signature == (int32_t)0x85dd99d1 || signature == (int32_t)0x3502758c)
    {
        TLReplyMarkup$replyKeyboardMarkup *result = [[TLReplyMarkup$replyKeyboardMarkup alloc] init];
        int32_t flags = [is readInt32];
        result.flags = flags;
        result.rows = CodexReadObjectVector(is, environment, error);
        if (flags & (1 << 3))
            [is readString];
        TGLog(@"IOS6BOT replyKeyboardMarkup flags=0x%08x rows=%d error=%@", flags, (int)result.rows.count, error != NULL ? *error : nil);
        return result;
    }
    else if (signature == (int32_t)0x48a30254)
    {
        TLReplyMarkup$replyInlineMarkup *result = [[TLReplyMarkup$replyInlineMarkup alloc] init];
        result.rows = CodexReadObjectVector(is, environment, error);
        TGLog(@"IOS6BOT replyInlineMarkup rows=%d error=%@", (int)result.rows.count, error != NULL ? *error : nil);
        return result;
    }
    
    return nil;
}

@end

@interface TLCodexModernKeyboardButtonRowParser : TLKeyboardButtonRow
@end

@implementation TLCodexModernKeyboardButtonRowParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLKeyboardButtonRow$keyboardButtonRow *result = [[TLKeyboardButtonRow$keyboardButtonRow alloc] init];
    result.buttons = CodexReadObjectVector(is, environment, error);
    TGLog(@"IOS6BOT keyboardButtonRow buttons=%d error=%@", (int)result.buttons.count, error != NULL ? *error : nil);
    return result;
}

@end

@interface TLCodexModernKeyboardButtonParser : TLKeyboardButton
@end

@implementation TLCodexModernKeyboardButtonParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    int32_t flags = 0;
    bool hasModernFlags = signature == (int32_t)0x7d170cff || signature == (int32_t)0xd80c25ec || signature == (int32_t)0xe62bc960 || signature == (int32_t)0x417efd8f || signature == (int32_t)0xaa40f94d || signature == (int32_t)0x0568a748 || signature == (int32_t)0x991399fc || signature == (int32_t)0x89c590f9 || signature == (int32_t)0x3fa53905 || signature == (int32_t)0xf51006f9 || signature == (int32_t)0x68013e72 || signature == (int32_t)0x7a11d782 || signature == (int32_t)0x7d5e07c7 || signature == (int32_t)0xc0fd5d09 || signature == (int32_t)0xe846b1a0 || signature == (int32_t)0xe15c4370 || signature == (int32_t)0x5b0f15f5 || signature == (int32_t)0x02b78156 || signature == (int32_t)0xbcc4af10;
    if (hasModernFlags)
    {
        flags = [is readInt32];
        if (flags & (1 << 10))
            CodexReadObject(is, environment, error);
    }
    
    if (signature == (int32_t)0x7a11d782 && (flags & (1 << 0)))
        CodexReadObject(is, environment, error);
    NSString *text = [is readString];
    TLKeyboardButton *result = nil;
    
    if (signature == (int32_t)0x258aff05 || signature == (int32_t)0xd80c25ec || signature == (int32_t)0xe846b1a0 || signature == (int32_t)0xe15c4370)
    {
        TLKeyboardButton$keyboardButtonUrl *button = [[TLKeyboardButton$keyboardButtonUrl alloc] init];
        button.text = text;
        button.url = [is readString];
        result = button;
    }
    else if (signature == (int32_t)0x683a5e46 || signature == (int32_t)0xe62bc960)
    {
        TLKeyboardButton$keyboardButtonCallback *button = [[TLKeyboardButton$keyboardButtonCallback alloc] init];
        button.text = text;
        button.data = [is readBytes];
        result = button;
    }
    else if (signature == (int32_t)0xb16a6c29 || signature == (int32_t)0x417efd8f)
    {
        TLKeyboardButton$keyboardButtonRequestPhone *button = [[TLKeyboardButton$keyboardButtonRequestPhone alloc] init];
        button.text = text;
        result = button;
    }
    else if (signature == (int32_t)0xfc796b3f || signature == (int32_t)0xaa40f94d)
    {
        TLKeyboardButton$keyboardButtonRequestGeoLocation *button = [[TLKeyboardButton$keyboardButtonRequestGeoLocation alloc] init];
        button.text = text;
        result = button;
    }
    else if (signature == (int32_t)0x0568a748 || signature == (int32_t)0x991399fc)
    {
        TLKeyboardButton$keyboardButtonSwitchInline *button = [[TLKeyboardButton$keyboardButtonSwitchInline alloc] init];
        button.flags = flags;
        button.text = text;
        button.query = [is readString];
        if ((flags & (1 << 1)) && signature == (int32_t)0x991399fc)
            CodexReadObjectVector(is, environment, error);
        result = button;
    }
    else if (signature == (int32_t)0x50f41ccf || signature == (int32_t)0x89c590f9)
    {
        TLKeyboardButton$keyboardButtonGame *button = [[TLKeyboardButton$keyboardButtonGame alloc] init];
        button.text = text;
        result = button;
    }
    else if (signature == (int32_t)0xafd93fbb || signature == (int32_t)0x3fa53905)
    {
        TLKeyboardButton$keyboardButtonBuy *button = [[TLKeyboardButton$keyboardButtonBuy alloc] init];
        button.text = text;
        result = button;
    }
    else if (signature == (int32_t)0xf51006f9 || signature == (int32_t)0x68013e72)
    {
        if ((signature == (int32_t)0xf51006f9 && (flags & (1 << 0))) || (signature == (int32_t)0x68013e72 && (flags & (1 << 1))))
            [is readString];
        TLKeyboardButton$keyboardButtonUrl *button = [[TLKeyboardButton$keyboardButtonUrl alloc] init];
        button.text = text;
        button.url = [is readString];
        if (signature == (int32_t)0xf51006f9)
            [is readInt32];
        else
            CodexReadObject(is, environment, error);
        result = button;
    }
    else if (signature == (int32_t)0x7a11d782)
    {
    }
    else if (signature == (int32_t)0x7d5e07c7)
    {
        CodexReadObject(is, environment, error);
    }
    else if (signature == (int32_t)0xc0fd5d09)
    {
        [is readInt64];
    }
    else if (signature == (int32_t)0x5b0f15f5 || signature == (int32_t)0x02b78156)
    {
        [is readInt32];
        CodexReadObject(is, environment, error);
        [is readInt32];
    }
    else if (signature == (int32_t)0xbcc4af10)
    {
        [is readString];
    }
    
    if (result == nil)
    {
        TLKeyboardButton$keyboardButton *button = [[TLKeyboardButton$keyboardButton alloc] init];
        button.text = text;
        result = button;
    }
    
    TGLog(@"IOS6BOT keyboardButton sig=0x%08x text=%@ class=%@", signature, text, NSStringFromClass([result class]));
    return result;
}

@end

@interface TLCodexModernUpdateUserStatusParser : TLUpdate$updateUserStatus
@end

@implementation TLCodexModernUpdateUserStatusParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLUpdate$updateUserStatus *result = [[TLUpdate$updateUserStatus alloc] init];
    int64_t userId = [is readInt64];
    int32_t statusSignature = [is readInt32];
    result.user_id = TGModernLegacyIdForModernId(userId);
    result.status = (TLUserStatus *)TLMetaClassStore::constructObject(is, statusSignature, environment, nil, error);
    TGLog(@"IOS6AUTH updateUserStatus userId=%lld statusSig=0x%08x status=%@", userId, statusSignature, result.status);
    return result;
}

@end

@interface TLCodexModernUpdateChannelTooLongParser : TLUpdate$updateChannelTooLong
@end

@implementation TLCodexModernUpdateChannelTooLongParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLUpdate$updateChannelTooLong *result = [[TLUpdate$updateChannelTooLong alloc] init];
    int32_t flags = [is readInt32];
    int64_t channelId = [is readInt64];
    result.flags = flags;
    result.channel_id = (int32_t)channelId;
    if (flags & 1)
        result.pts = [is readInt32];
    TGLog(@"IOS6AUTH updateChannelTooLong modern channel=%lld flags=%d pts=%d", channelId, flags, result.pts);
    return result;
}

@end

@interface TLCodexModernUpdateShortMessageParser : TLUpdates$modernUpdateShortMessage
@end

@implementation TLCodexModernUpdateShortMessageParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLUpdates$modernUpdateShortMessage *result = [[TLUpdates$modernUpdateShortMessage alloc] init];
    result.flags = [is readInt32];
    result.n_id = [is readInt32];
    result.user_id = TGModernLegacyIdForModernId([is readInt64]);
    result.message = [is readString];
    result.pts = [is readInt32];
    result.pts_count = [is readInt32];
    result.date = [is readInt32];
    if (result.flags & (1 << 2))
        result.fwd_header = (TLMessageFwdHeader *)CodexReadObject(is, environment, error);
    if (result.flags & (1 << 11))
        result.via_bot_id = TGModernLegacyIdForModernId([is readInt64]);
    if (result.flags & (1 << 3))
        CodexReadReplyHeaderCompat(is, environment, error);
    if (result.flags & (1 << 7))
        result.entities = CodexReadObjectVector(is, environment, error);
    if (result.flags & (1 << 25))
        [is readInt32];
    TGLog(@"IOS6AUTH updateShortMessage modern id=%d user=%d flags=%d", result.n_id, result.user_id, result.flags);
    return result;
}

@end

@interface TLCodexModernUpdateShortChatMessageParser : TLUpdates$modernUpdateShortChatMessage
@end

@implementation TLCodexModernUpdateShortChatMessageParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLUpdates$modernUpdateShortChatMessage *result = [[TLUpdates$modernUpdateShortChatMessage alloc] init];
    result.flags = [is readInt32];
    result.n_id = [is readInt32];
    result.from_id = TGModernLegacyIdForModernId([is readInt64]);
    result.chat_id = (int32_t)[is readInt64];
    result.message = [is readString];
    result.pts = [is readInt32];
    result.pts_count = [is readInt32];
    result.date = [is readInt32];
    if (result.flags & (1 << 2))
        result.fwd_header = (TLMessageFwdHeader *)CodexReadObject(is, environment, error);
    if (result.flags & (1 << 11))
        result.via_bot_id = TGModernLegacyIdForModernId([is readInt64]);
    if (result.flags & (1 << 3))
        result.reply_to_msg_id = CodexReadReplyHeaderCompat(is, environment, error);
    if (result.flags & (1 << 7))
        result.entities = CodexReadObjectVector(is, environment, error);
    if (result.flags & (1 << 25))
        [is readInt32];
    TGLog(@"IOS6AUTH updateShortChatMessage modern id=%d from=%d chat=%d flags=%d", result.n_id, result.from_id, result.chat_id, result.flags);
    return result;
}

@end

@interface TLCodexModernUpdateShortSentMessageParser : TLUpdates$updateShortSentMessage
@end

@implementation TLCodexModernUpdateShortSentMessageParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLUpdates$updateShortSentMessage *result = [[TLUpdates$updateShortSentMessage alloc] init];
    result.flags = [is readInt32];
    result.n_id = [is readInt32];
    result.pts = [is readInt32];
    result.pts_count = [is readInt32];
    result.date = [is readInt32];
    if (result.flags & (1 << 9))
        result.media = (TLMessageMedia *)CodexReadObject(is, environment, error);
    if (result.flags & (1 << 7))
        result.entities = CodexReadObjectVector(is, environment, error);
    if (result.flags & (1 << 25))
        [is readInt32];
    TGLog(@"IOS6AUTH updateShortSentMessage modern id=%d flags=%d", result.n_id, result.flags);
    return result;
}

@end

@interface TLCodexModernUpdatesStateParser : TLupdates_State$updates_state
@end

@implementation TLCodexModernUpdatesStateParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLupdates_State$updates_state *result = [[TLupdates_State$updates_state alloc] init];
    result.pts = [is readInt32];
    result.qts = [is readInt32];
    result.date = [is readInt32];
    result.seq = [is readInt32];
    result.unread_count = [is readInt32];
    CodexLastReadUpdatesState = result;
    TGLog(@"IOS6AUTH updates.state pts=%d qts=%d date=%d seq=%d unread=%d", result.pts, result.qts, result.date, result.seq, result.unread_count);
    return result;
}

@end

static TLupdates_State *CodexReadUpdatesStateCompat(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t stateSignature = [is readInt32];
    if (stateSignature == (int32_t)0xa56c2a3e)
    {
        TLupdates_State$updates_state *result = [[TLupdates_State$updates_state alloc] init];
        result.pts = [is readInt32];
        result.qts = [is readInt32];
        result.date = [is readInt32];
        result.seq = [is readInt32];
        result.unread_count = [is readInt32];
        CodexLastReadUpdatesState = result;
        TGLog(@"IOS6AUTH updates.state.inline pts=%d qts=%d date=%d seq=%d unread=%d", result.pts, result.qts, result.date, result.seq, result.unread_count);
        return result;
    }
    
    return (TLupdates_State *)TLMetaClassStore::constructObject(is, stateSignature, environment, nil, error);
}

@interface TLCodexModernUpdatesParser : TLUpdates$updates
@end

@implementation TLCodexModernUpdatesParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0x78d4dec1)
    {
        TLUpdates$updateShort *result = [[TLUpdates$updateShort alloc] init];
        result.update = (TLUpdate *)CodexReadObject(is, environment, error);
        result.date = [is readInt32];
        TGLog(@"IOS6AUTH updateShort date=%d update=%@", result.date, result.update);
        return result;
    }
    
    if (signature == (int32_t)0x725b04c3)
    {
        TLUpdates$updatesCombined *result = [[TLUpdates$updatesCombined alloc] init];
        result.updates = CodexReadUpdateVectorSkippingSmallJunk(is, environment, error);
        result.users = CodexReadObjectVector(is, environment, error);
        result.chats = CodexReadObjectVector(is, environment, error);
        result.date = [is readInt32];
        result.seq_start = [is readInt32];
        result.seq = [is readInt32];
        TGLog(@"IOS6AUTH updatesCombined updates=%d users=%d chats=%d date=%d seq=%d", (int)result.updates.count, (int)result.users.count, (int)result.chats.count, result.date, result.seq);
        return result;
    }
    
    TLUpdates$updates *result = [[TLUpdates$updates alloc] init];
    result.updates = CodexReadUpdateVectorSkippingSmallJunk(is, environment, error);
    result.users = CodexReadObjectVector(is, environment, error);
    result.chats = CodexReadObjectVector(is, environment, error);
    result.date = [is readInt32];
    result.seq = [is readInt32];
    TGLog(@"IOS6AUTH updates updates=%d users=%d chats=%d date=%d seq=%d", (int)result.updates.count, (int)result.users.count, (int)result.chats.count, result.date, result.seq);
    return result;
}

@end

@interface TLCodexModernDifferenceParser : TLupdates_Difference$updates_difference
@end

@implementation TLCodexModernDifferenceParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    if (signature == (int32_t)0xa8fb1981)
    {
        TLupdates_Difference$updates_differenceSlice *result = [[TLupdates_Difference$updates_differenceSlice alloc] init];
        @try
        {
            result.n_new_messages = CodexReadObjectVector(is, environment, error);
            result.n_new_encrypted_messages = CodexReadObjectVector(is, environment, error);
            result.other_updates = CodexReadUpdateVectorSkippingSmallJunk(is, environment, error);
            result.chats = CodexReadObjectVector(is, environment, error);
            result.users = CodexReadObjectVector(is, environment, error);
            result.intermediate_state = CodexReadUpdatesStateCompat(is, environment, error);
        }
        @catch (NSException *exception)
        {
            if ([exception.reason rangeOfString:@"end of stream"].location != NSNotFound && result.n_new_messages != nil && result.other_updates != nil && result.chats != nil && result.users != nil)
            {
                if (result.intermediate_state == nil)
                    result.intermediate_state = CodexLastReadUpdatesState;
                if (error != NULL)
                    *error = nil;
                TGLog(@"IOS6AUTH updates.differenceSlice accepted EOF after state messages=%d other=%d chats=%d users=%d", (int)result.n_new_messages.count, (int)result.other_updates.count, (int)result.chats.count, (int)result.users.count);
                return result;
            }
            @throw;
        }
        TGLog(@"IOS6AUTH updates.differenceSlice messages=%d encrypted=%d other=%d chats=%d users=%d error=%@", (int)result.n_new_messages.count, (int)result.n_new_encrypted_messages.count, (int)result.other_updates.count, (int)result.chats.count, (int)result.users.count, error != NULL ? *error : nil);
        return result;
    }
    
    TLupdates_Difference$updates_difference *result = [[TLupdates_Difference$updates_difference alloc] init];
    @try
    {
        result.n_new_messages = CodexReadObjectVector(is, environment, error);
        result.n_new_encrypted_messages = CodexReadObjectVector(is, environment, error);
        result.other_updates = CodexReadUpdateVectorSkippingSmallJunk(is, environment, error);
        result.chats = CodexReadObjectVector(is, environment, error);
        result.users = CodexReadObjectVector(is, environment, error);
        result.state = CodexReadUpdatesStateCompat(is, environment, error);
    }
    @catch (NSException *exception)
    {
        if ([exception.reason rangeOfString:@"end of stream"].location != NSNotFound && result.n_new_messages != nil && result.other_updates != nil && result.chats != nil && result.users != nil)
        {
            if (result.state == nil)
                result.state = CodexLastReadUpdatesState;
            if (error != NULL)
                *error = nil;
            TGLog(@"IOS6AUTH updates.difference accepted EOF after state messages=%d other=%d chats=%d users=%d", (int)result.n_new_messages.count, (int)result.other_updates.count, (int)result.chats.count, (int)result.users.count);
            return result;
        }
        @throw;
    }
    TGLog(@"IOS6AUTH updates.difference messages=%d encrypted=%d other=%d chats=%d users=%d error=%@", (int)result.n_new_messages.count, (int)result.n_new_encrypted_messages.count, (int)result.other_updates.count, (int)result.chats.count, (int)result.users.count, error != NULL ? *error : nil);
    return result;
}

@end

@interface TLCodexModernChannelDifferenceParser : TLUpdates_ChannelDifference$channelDifference
@end

@implementation TLCodexModernChannelDifferenceParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLUpdates_ChannelDifference$channelDifference *result = [[TLUpdates_ChannelDifference$channelDifference alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    result.pts = [is readInt32];
    if (flags & (1 << 1))
        result.timeout = [is readInt32];
    
    result.n_new_messages = CodexReadObjectVector(is, environment, error);
    if (error != NULL && *error != nil)
        return nil;
    result.other_updates = CodexReadUpdateVectorSkippingSmallJunk(is, environment, error);
    if (error != NULL && *error != nil)
        return nil;
    result.chats = CodexReadObjectVector(is, environment, error);
    if (error != NULL && *error != nil)
        return nil;
    result.users = CodexReadObjectVector(is, environment, error);
    TGLog(@"IOS6AUTH channelDifference pts=%d messages=%d updates=%d chats=%d users=%d error=%@", result.pts, (int)result.n_new_messages.count, (int)result.other_updates.count, (int)result.chats.count, (int)result.users.count, error != NULL ? *error : nil);
    return result;
}

@end

@interface TLCodexChannelDifferenceTooLongParser : TLchannelDifferenceTooLong
@end

@implementation TLCodexChannelDifferenceTooLongParser

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLchannelDifferenceTooLong *result = [[TLchannelDifferenceTooLong alloc] init];
    int32_t flags = [is readInt32];
    result.flags = flags;
    if (flags & (1 << 1))
        result.timeout = [is readInt32];
    id dialog = CodexReadObject(is, environment, error);
    if ([dialog isKindOfClass:[TLDialog$dialogMeta class]]) {
        TLDialog$dialogMeta *dialogMeta = (TLDialog$dialogMeta *)dialog;
        result.pts = dialogMeta.pts;
        result.top_message = dialogMeta.top_message;
        result.unread_count = dialogMeta.unread_count;
        result.unread_mentions_count = dialogMeta.unread_mentions_count;
        result.read_inbox_max_id = dialogMeta.read_inbox_max_id;
        result.read_outbox_max_id = dialogMeta.read_outbox_max_id;
    }
    result.messages = CodexReadObjectVector(is, environment, error);
    result.chats = CodexReadObjectVector(is, environment, error);
    result.users = CodexReadObjectVector(is, environment, error);
    TGLog(@"IOS6AUTH channelDifferenceTooLong pts=%d top=%d messages=%d chats=%d users=%d error=%@", result.pts, result.top_message, (int)result.messages.count, (int)result.chats.count, (int)result.users.count, error != NULL ? *error : nil);
    return result;
}

@end

void TLMetaClassStore::registerObjectClass(id<TLObject> objectClass)
{
    objectClassesByConstructorNames.insert(std::pair<int32_t, id<TLObject> >([objectClass TLconstructorName], objectClass));
}

void TLMetaClassStore::registerVectorClass(id<TLVector> vectorClass)
{
#if TARGET_IPHONE_SIMULATOR
    std::unordered_map<int32_t, id<TLVector> >::iterator it = vectorClassesBySignature.find([vectorClass TLconstructorSignature]);
    if (it != vectorClassesBySignature.end())
        TGLog(@"***** Overriding constructor 0x%x with %@ (was %@)", [vectorClass TLconstructorSignature], [vectorClass class], [it->second class]);
    
#endif
    vectorClassesBySignature.insert(std::pair<int32_t, id<TLVector> >([vectorClass TLconstructorSignature], vectorClass));
}

id<TLObject> TLMetaClassStore::getObjectClass(int32_t name)
{
    std::unordered_map<int32_t, id<TLObject> >::iterator it = objectClassesByConstructorNames.find(name);
    if (it == objectClassesByConstructorNames.end())
    {
        TGLog(@"%.8x -> %@", name, stringForHash(name));
        return nil;
    }
    return it->second;
}

void TLMetaClassStore::clearScheme()
{
    constructorsBySignature.clear();
    constructorsByName.clear();
    typesByName.clear();
    vectorElementTypesByConstructor.clear();
}

TLMetaTypeArgument createTypeArgumentFromString(NSString *desc, std::set<int32_t> &typesToResolve, std::map<int32_t, TLMetaTypeArgumentWithName> &vectorTypeMap, bool &hasUnresolvedTypes)
{
    TLMetaTypeArgument type;
    
    type.unboxedConstructorName = 0;
    type.unboxedConstructorSignature = 0;
    
    TLMetaTypeCategory category;
    int32_t typeName = 0;
    
    std::vector<TLMetaTypeArgument> typeArguments;
    
    if ([desc isEqualToString:@"int"])
    {
        typeName = murMurHash32(@"Int");
        addHashToString(typeName, @"Int");
        
        category = TLMetaTypeCategoryBuiltinInt32;
        type.boxed = false;
        type.unboxedConstructorSignature = TL_INT32_CONSTRUCTOR;
    }
    else if ([desc isEqualToString:@"Int"])
    {
        typeName = murMurHash32(@"Int");
        addHashToString(typeName, @"Int");
        
        category = TLMetaTypeCategoryBuiltinInt32;
        type.boxed = true;
    }
    else if ([desc isEqualToString:@"long"])
    {
        typeName = murMurHash32(@"Long");
        addHashToString(typeName, @"Long");
        
        category = TLMetaTypeCategoryBuiltinInt64;
        type.boxed = false;
        type.unboxedConstructorSignature = TL_INT64_CONSTRUCTOR;
    }
    else if ([desc isEqualToString:@"Long"])
    {
        typeName = murMurHash32(@"Long");
        addHashToString(typeName, @"Long");
        
        category = TLMetaTypeCategoryBuiltinInt64;
        type.boxed = true;
    }
    else if ([desc isEqualToString:@"int128"])
    {
        typeName = murMurHash32(@"Int128");
        addHashToString(typeName, @"Int128");
        
        category = TLMetaTypeCategoryBuiltinInt128;
        type.boxed = false;
        type.unboxedConstructorSignature = TL_INT128_CONSTRUCTOR;
    }
    else if ([desc isEqualToString:@"int256"])
    {
        typeName = murMurHash32(@"Int256");
        addHashToString(typeName, @"Int256");
        
        category = TLMetaTypeCategoryBuiltinInt256;
        type.boxed = false;
        type.unboxedConstructorSignature = TL_INT256_CONSTRUCTOR;
    }
    else if ([desc isEqualToString:@"double"])
    {
        typeName = murMurHash32(@"Double");
        addHashToString(typeName, @"Double");
        
        category = TLMetaTypeCategoryBuiltinDouble;
        type.boxed = false;
        type.unboxedConstructorSignature = TL_DOUBLE_CONSTRUCTOR;
    }
    else if ([desc isEqualToString:@"Double"])
    {
        typeName = murMurHash32(@"Double");
        addHashToString(typeName, @"Double");
        
        category = TLMetaTypeCategoryBuiltinDouble;
        type.boxed = true;
    }
    else if ([desc isEqualToString:@"string"])
    {
        typeName = murMurHash32(@"String");
        addHashToString(typeName, @"String");
        
        category = TLMetaTypeCategoryBuiltinString;
        type.boxed = false;
        type.unboxedConstructorSignature = TL_STRING_CONSTRUCTOR;
    }
    else if ([desc isEqualToString:@"String"])
    {
        typeName = murMurHash32(@"String");
        addHashToString(typeName, @"String");
        
        category = TLMetaTypeCategoryBuiltinString;
        type.boxed = true;
    }
    else if ([desc isEqualToString:@"bytes"])
    {
        typeName = murMurHash32(@"Bytes");
        addHashToString(typeName, @"Bytes");
        
        category = TLMetaTypeCategoryBuiltinBytes;
        type.boxed = false;
        type.unboxedConstructorSignature = TL_BYTES_CONSTRUCTOR;
    }
    else if ([desc isEqualToString:@"Bytes"])
    {
        typeName = murMurHash32(@"Bytes");
        addHashToString(typeName, @"Bytes");
        
        category = TLMetaTypeCategoryBuiltinBytes;
        type.boxed = true;
    }
    else if ([desc isEqualToString:@"Bool"])
    {
        typeName = murMurHash32(@"Bool");
        addHashToString(typeName, @"Bool");
        
        category = TLMetaTypeCategoryBuiltinBool;
        type.boxed = true;
    }
    else if ([desc hasPrefix:@"Vector<"])
    {
        typeName = murMurHash32(desc);
        addHashToString(typeName, desc);
        
        NSString *typeArgumentDesc = [desc substringWithRange:NSMakeRange(7, desc.length - 7 - 1)];
        TLMetaTypeArgument typeArgument = createTypeArgumentFromString(typeArgumentDesc, typesToResolve, vectorTypeMap, hasUnresolvedTypes);
        typeArguments.push_back(typeArgument);
        
        TLMetaTypeArgumentWithName typeArgumentWithName;
        typeArgumentWithName.boxed = typeArgument.boxed;
        typeArgumentWithName.unboxedConstructorSignature = typeArgument.unboxedConstructorSignature;
        typeArgumentWithName.type = typeArgument.type;
        
        const char *utf8String = [typeArgumentDesc UTF8String];
        typeArgumentWithName.name.insert(typeArgumentWithName.name.end(), utf8String, utf8String + strlen(utf8String));
        
        vectorTypeMap[typeArgument.type->getName()] = typeArgumentWithName;
        
        category = TLMetaTypeCategoryBuiltinVector;
        type.boxed = true;
        
        type.unboxedConstructorName = murMurHash32(desc);

        const char *vectorPrefix = "vector # [ ";
        const char *vectorSuffix = " ] = Vector ";
        
        const char *utf8string = [typeArgumentDesc UTF8String];
        
        std::vector<char> signatureString;
        signatureString.insert(signatureString.end(), vectorPrefix, vectorPrefix + 11);
        signatureString.insert(signatureString.end(), utf8string, utf8string + strlen(utf8string));
        signatureString.insert(signatureString.end(), vectorSuffix, vectorSuffix + 12);
        signatureString.insert(signatureString.end(), utf8string, utf8string + strlen(utf8string));
        
        type.unboxedConstructorSignature = (int32_t)crc32(0, (const Bytef *)signatureString.data(), (int32_t)signatureString.size());
    }
    else if ([desc hasPrefix:@"vector<"])
    {
        typeName = murMurHash32(desc);
        addHashToString(typeName, desc);
        
        NSString *typeArgumentDesc = [desc substringWithRange:NSMakeRange(7, desc.length - 7 - 1)];
        TLMetaTypeArgument typeArgument = createTypeArgumentFromString(typeArgumentDesc, typesToResolve, vectorTypeMap, hasUnresolvedTypes);
        typeArguments.push_back(typeArgument);
        
        TLMetaTypeArgumentWithName typeArgumentWithName;
        typeArgumentWithName.boxed = typeArgument.boxed;
        typeArgumentWithName.unboxedConstructorSignature = typeArgument.unboxedConstructorSignature;
        typeArgumentWithName.unboxedConstructorName = typeArgument.unboxedConstructorName;
        typeArgumentWithName.type = typeArgument.type;
        
        const char *utf8String = [typeArgumentDesc UTF8String];
        typeArgumentWithName.name.insert(typeArgumentWithName.name.end(), utf8String, utf8String + strlen(utf8String));
        
        vectorTypeMap[typeArgument.type->getName()] = typeArgumentWithName;
        
        category = TLMetaTypeCategoryBuiltinVector;
        type.boxed = false;
        
        const char *vectorPrefix = "vector # [ ";
        const char *vectorSuffix = " ] = Vector ";
        
        const char *utf8string = [typeArgumentDesc UTF8String];

        std::vector<char> signatureString;
        signatureString.insert(signatureString.end(), vectorPrefix, vectorPrefix + 11);
        signatureString.insert(signatureString.end(), utf8string, utf8string + strlen(utf8string));
        signatureString.insert(signatureString.end(), vectorSuffix, vectorSuffix + 12);
        signatureString.insert(signatureString.end(), utf8string, utf8string + strlen(utf8string));
        
        type.unboxedConstructorSignature = (int32_t)crc32(0, (const Bytef *)signatureString.data(), (int32_t)signatureString.size());
    }
    else if ([desc isEqualToString:@"Object"])
    {
        typeName = murMurHash32(@"Object");
        addHashToString(typeName, @"Object");
        
        category = TLMetaTypeCategoryObject;
        type.boxed = true;
    }
    else
    {
        NSString *boxedDesc = desc;
        
        NSRange range = [desc rangeOfString:@"."];
        if (range.location == NSNotFound)
        {
            unichar c = [desc characterAtIndex:0];
            type.boxed = isupper(c);
            
            if (!type.boxed)
            {
                c = (unichar)toupper(c);
                boxedDesc = [desc stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[NSString stringWithCharacters:&c length:1]];
            }
        }
        else
        {
            unichar c = [desc characterAtIndex:range.location + 1];
            type.boxed = isupper(c);
            
            if (!type.boxed)
            {
                c = (unichar)toupper(c);
                boxedDesc = [desc stringByReplacingCharactersInRange:NSMakeRange(range.location + 1, 1) withString:[NSString stringWithCharacters:&c length:1]];
            }
        }
        
        typeName = murMurHash32(boxedDesc);
        addHashToString(typeName, boxedDesc);
        
        category = TLMetaTypeCategoryObject;
        
        type.unboxedConstructorSignature = 0;
        type.unboxedConstructorName = 0;
        if (!type.boxed)
        {
            type.unboxedConstructorName = murMurHash32(desc);
            addHashToString(type.unboxedConstructorName, desc);
            hasUnresolvedTypes = true;
        }
        
        typesToResolve.insert(typeName);
    }
    
    std::shared_ptr<TLMetaType> metaType(new TLMetaType(typeName, category, typeArguments));
    
    type.type = metaType;
    
    return type;
}

bool resolveUnboxedTypes(TLMetaTypeArgument *type, std::unordered_map<int32_t, std::shared_ptr<TLMetaConstructor> > const &constructorsByName, std::unordered_map<int32_t, TLMetaTypeArgument> const &vectorElementTypes)
{
    for (std::vector<TLMetaTypeArgument>::iterator it = type->type->getArguments().begin(); it != type->type->getArguments().end(); it++)
    {
        if (!resolveUnboxedTypes(&(*it), constructorsByName, vectorElementTypes))
            return false;
    }
    
    if (!type->boxed && type->unboxedConstructorSignature == 0)
    {
        std::unordered_map<int32_t, std::shared_ptr<TLMetaConstructor> >::const_iterator foundIt = constructorsByName.find(type->unboxedConstructorName);
        if (foundIt != constructorsByName.end())
        {
            type->unboxedConstructorSignature = foundIt->second->getSignature();
        }
        else
        {
            TGLog(@"***** Failed to resolve unboxed type %@", stringForHash(type->unboxedConstructorName));
            return false;
        }
    }
    
    return true;
}

std::shared_ptr<TLMetaType> createTypeFromString(NSString *desc, std::set<int32_t> &typesToResolve, std::map<int32_t, TLMetaTypeArgumentWithName> &vectorTypeMap)
{
    bool hasUnresolvedTypes = false;
    TLMetaTypeArgument type = createTypeArgumentFromString(desc, typesToResolve, vectorTypeMap, hasUnresolvedTypes);
    return type.type;
}

void TLMetaClassStore::mergeScheme(TLScheme *scheme)
{
    if ([scheme isKindOfClass:[TLScheme$scheme class]])
    {   
        std::unordered_map<int32_t, std::pair<TLMetaTypeArgument, bool> > cachedFieldTypes;
        std::map<int32_t, TLMetaTypeArgumentWithName> vectorTypeMap;
        std::set<int32_t> typesToResolve;
        std::vector<std::shared_ptr<TLMetaConstructor> > constructorsWithUnresolvedTypes;
        
        NSMutableArray *types = [[NSMutableArray alloc] initWithArray:((TLScheme$scheme *)scheme).types];
        NSMutableArray *methods = [[NSMutableArray alloc] initWithArray:((TLScheme$scheme *)scheme).methods];
        
        {
            id<TLObject> object = [[TLDestroySessionsRes$destroy_sessions_res alloc] init];
            manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >([object TLconstructorSignature], object));
        }
        
        {
            TLSchemeType$schemeType *constructor = [[TLSchemeType$schemeType alloc] init];
            constructor.n_id = (int32_t)0x73f1f8dc;
            constructor.predicate = @"msg_container";
            constructor.type = @"MessageContainer";
            NSMutableArray *fields = [[NSMutableArray alloc] init];
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"messages";
                arg.type = @"vector<protoMessage>";
                [fields addObject:arg];
            }
            constructor.params = fields;
            [types addObject:constructor];
            
            manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(constructor.n_id, [[TLMessageContainer$msg_container alloc] init]));
        }
        
        {
            TLSchemeType$schemeType *constructor = [[TLSchemeType$schemeType alloc] init];
            constructor.n_id = (int32_t)0xf35c6d01;
            constructor.predicate = @"rpc_result";
            constructor.type = @"RpcResult";
            NSMutableArray *fields = [[NSMutableArray alloc] init];
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"req_msg_id";
                arg.type = @"long";
                [fields addObject:arg];
            }
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"result";
                arg.type = @"Object";
                [fields addObject:arg];
            }
            constructor.params = fields;
            [types addObject:constructor];
            
            manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(constructor.n_id, [[TLRpcResult$rpc_result alloc] init]));
        }
        
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x5162463, [[TLResPQ$resPQ_manual alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x62d6b459, [[TLMsgsAck$msgs_ack_manual alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x44f9b43d, [[TLMessage$modernMessage alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x9e19a1f6, [[TLMessage$modernMessageService alloc] init]));
        
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5f07b4bc, [[TLWebPage_manual alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x31774388, [[TLUser$modernUser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x2e13f4c3, [[TLUser$modernUser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x215c4438, [[TLUser$modernUser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x83314fca, [[TLUser$modernUser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x2813e6db, [[TLUser$modernUser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x1afeb7ac, [[TLUser$modernUser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xd0a1d008, [[TLUser$modernUser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xd7c0ff9c, [[TLUser$modernUser alloc] init]));
        objectClassesByConstructorNames[(int32_t)0xd7c0ff9c] = [[TLUser$modernUser alloc] init];
        TGLog(@"IOS6AUTH registered modern user constructor alias 0xd7c0ff9c");
        objectClassesByConstructorNames[(int32_t)0x9fbde43f] = [[TLChat$channelMeta alloc] init];
        addHashToString((int32_t)0x9fbde43f, @"channel");
        TGLog(@"IOS6AUTH registered modern channel meta alias 0x9fbde43f");
        objectClassesByConstructorNames[(int32_t)0xe2f65ce2] = [[TLUserFull$userFullMeta alloc] init];
        addHashToString((int32_t)0xe2f65ce2, @"UserFull");
        TGLog(@"IOS6AUTH registered modern UserFull type alias 0xe2f65ce2");
        objectClassesByConstructorNames[(int32_t)0x8c5d990f] = [[TLupdates_ChannelDifference$updates_channelDifferenceMeta alloc] init];
        addHashToString((int32_t)0x8c5d990f, @"updates.ChannelDifference");
        TGLog(@"IOS6AUTH registered modern channelDifference meta alias 0x8c5d990f");
        objectClassesByConstructorNames[(int32_t)0x4ccda305] = [[TLCodexSkipObjectParser alloc] init];
        addHashToString((int32_t)0x4ccda305, @"updatePinnedChannelMessages");
        TGLog(@"IOS6AUTH registered modern updatePinnedChannelMessages meta skip alias 0x4ccda305");
        objectClassesByConstructorNames[(int32_t)0xf9a7c6d9] = [[TLCodexSkipObjectParser alloc] init];
        addHashToString((int32_t)0xf9a7c6d9, @"businessLocation");
        TGLog(@"IOS6AUTH registered modern businessLocation meta skip alias 0xf9a7c6d9");
        objectClassesByConstructorNames[(int32_t)0xae9f31e8] = [[TLCodexSkipObjectParser alloc] init];
        addHashToString((int32_t)0xae9f31e8, @"pollAnswerVoters");
        TGLog(@"IOS6AUTH registered modern pollAnswerVoters meta skip alias 0xae9f31e8");
        objectClassesByConstructorNames[(int32_t)0xd5d4c7f5] = [[TLCodexSkipObjectParser alloc] init];
        addHashToString((int32_t)0xd5d4c7f5, @"mediaAreaSuggestedReaction");
        TGLog(@"IOS6AUTH registered modern mediaAreaSuggestedReaction meta skip alias 0xd5d4c7f5");
        objectClassesByConstructorNames[(int32_t)0x377d3538] = [[TLCodexSkipObjectParser alloc] init];
        addHashToString((int32_t)0x377d3538, @"webPageAttributeStickerSet");
        TGLog(@"IOS6AUTH registered modern webPageAttributeStickerSet meta alias 0x377d3538");
        objectClassesByConstructorNames[(int32_t)0x9ac0c0cc] = [[TLCodexSkipObjectParser alloc] init];
        addHashToString((int32_t)0x9ac0c0cc, @"messageEntityFormattedDate");
        TGLog(@"IOS6AUTH registered modern messageEntityFormattedDate meta alias 0x9ac0c0cc");
        objectClassesByConstructorNames[(int32_t)0x1f1ea79e] = [[TLCodexSkipObjectParser alloc] init];
        addHashToString((int32_t)0x1f1ea79e, @"PeerColor");
        TGLog(@"IOS6AUTH registered modern peerColor meta alias 0x1f1ea79e");
        objectClassesByConstructorNames[(int32_t)0xa61d7ecc] = [[TLCodexSkipObjectParser alloc] init];
        addHashToString((int32_t)0xa61d7ecc, @"botApp");
        TGLog(@"IOS6AUTH registered modern botApp meta alias 0xa61d7ecc");
        objectClassesByConstructorNames[(int32_t)0xd91a34ac] = [[TLCodexSkipObjectParser alloc] init];
        addHashToString((int32_t)0xd91a34ac, @"storyViews");
        TGLog(@"IOS6AUTH registered modern storyViews meta alias 0xd91a34ac");
        objectClassesByConstructorNames[(int32_t)0x731eca73] = [[TLCodexSkipObjectParser alloc] init];
        addHashToString((int32_t)0x731eca73, @"updatePinnedDialogs");
        TGLog(@"IOS6AUTH registered modern updatePinnedDialogs meta skip alias 0x731eca73");
        objectClassesByConstructorNames[(int32_t)0x8350972b] = [[TLCodexSkipObjectParser alloc] init];
        addHashToString((int32_t)0x8350972b, @"recentStory");
        TGLog(@"IOS6AUTH registered modern recentStory meta alias 0x8350972b");
        objectClassesByConstructorNames[(int32_t)0xcba86ca2] = [[TLCodexSkipObjectParser alloc] init];
        addHashToString((int32_t)0xcba86ca2, @"RequestPeerType");
        TGLog(@"IOS6AUTH registered modern requestPeerType meta alias 0xcba86ca2");
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x09d05049, [[TLCodexUserStatusEmptyParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xedb93949, [[TLCodexUserStatusOnlineParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x008c703f, [[TLCodexUserStatusOfflineParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x7b197dc8, [[TLCodexUserStatusNoPayloadParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x541a1d1a, [[TLCodexUserStatusNoPayloadParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x65899777, [[TLCodexUserStatusNoPayloadParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x16d9703b, [[TLCodexModernContactStatusParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xe5bdf8de, [[TLCodexModernUpdateUserStatusParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x18b7a10d, [[TLDcOption$modernDcOption alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x14b24500, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5bb98608, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x50cc03d3, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x8d595cd6, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x4e80a379, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x48e246c2, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xdc58f31e, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xac072444, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xe46bcee4, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x914FBF11, [[TLUpdates$modernUpdateShortMessage alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x313bc7f8, [[TLCodexModernUpdateShortMessageParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x16812688, [[TLUpdates$modernUpdateShortChatMessage alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x4d6deea5, [[TLCodexModernUpdateShortChatMessageParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xBC0F17BC, [[TLmessages_Messages$modernChannelMessages alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x11f1331c, [[TLUpdates$updateShortSentMessage alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x9015e101, [[TLCodexModernUpdateShortSentMessageParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa56c2a3e, [[TLCodexModernUpdatesStateParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x78d4dec1, [[TLCodexModernUpdatesParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x725b04c3, [[TLCodexModernUpdatesParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x74ae4240, [[TLCodexModernUpdatesParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x00f49ca0, [[TLCodexModernDifferenceParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa8fb1981, [[TLCodexModernDifferenceParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x2064674E, [[TLCodexModernChannelDifferenceParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x3E11AFFB, [[TLUpdates_ChannelDifference$empty alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xc88974ac, [[TLChat$channel alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x0aadfc8f, [[TLCodexModernChannelParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x1c32b11c, [[TLCodexModernChannelParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x17d493d5, [[TLCodexModernChannelForbiddenParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x76af5481, [[TLChatFull$channelFull alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xbbab348d, [[TLCodexModernChannelFullParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa04e8d3a, [[TLCodexModernChannelFullParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xFC900C2B, [[TLChatParticipants$chatParticipantsForbidden alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xD91CDD54, [[TLChat$chat alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x41cbf256, [[TLCodexModernChatParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x6592a1a7, [[TLCodexModernChatForbiddenParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x1c6e1c11, [[TLCodexModernChatPhotoParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xB08FBB93, [[TLWebPage$webPageExternal alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x947ca848, [[TLMessages_BotResults$botResults alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x764cf810, [[TLBotInlineMessage$botInlineMessageMediaAuto alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x8c7f65e2, [[TLBotInlineMessage$botInlineMessageText alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xb722de65, [[TLBotInlineMessage$botInlineMessageMediaGeo alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x8a86659c, [[TLBotInlineMessage$botInlineMessageMediaVenue alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x18d1cdc2, [[TLBotInlineMessage$botInlineMessageMediaContact alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x11965f3a, [[TLBotInlineResult$botInlineResult alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x9852F9C6, [[TLDocumentAttribute$documentAttributeAudio alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x43c57c48, [[TLCodexModernDocumentAttributeVideoParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x559ebe6d, [[TLMessageFwdHeader$messageFwdHeader alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xf220f3f, [[TLUserFull$userFull alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x3b6d152e, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xcc997720, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xd2234ea0, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x06cbe645, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x8c92b098, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x120b1ab9, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5a0a066d, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x711d692d, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x75b3b798, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers[(int32_t)0x1bf335b9] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x7d627683] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1824e40b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x0ab4a819, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc01e857f, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc32d5b12, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5e1b3cb8, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xd6b19546, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x51e6ee4f, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xea29055d, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x922e6e10, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x9c974fdf, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x8951abef, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb75f99a9, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xf226ac08, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x6f7863f4, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x86fccf85, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x74c34319, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xffadc913, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb390dc08, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x16a4b93c, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xedf164f1, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x79b26a24, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x68cb6283, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x9a35e999, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x63c3dd0a, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb826e150, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x2e94c3e7, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xcf6f6db8, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x31cad303, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x01c641c2, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xbbb6b4a3, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x74aee3e0, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x313a9547, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x85f0a9cd, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x565251e2, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x4e7085ea, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x9f2504e4, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xe0bff26c, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x36437737, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xdbce6389, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xf08d516b, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x78fbf3a8, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xcef7e7a8, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xaff56398, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x71f276c4, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x4d4bd46a, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x3458f9c8, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xfe333952, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x771a4e66, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x972dabbf, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x2eeed1c4, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x3aae0528, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x0aa021e5, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xbe82db9c, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb282217f, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xcad5452d, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x14455871, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x2271f2bf, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5787686d, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xdf8b3b22, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa5d9abb8, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers[(int32_t)0xde4c5d93] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb0bdeac5] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9083670b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xbd74cf49] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x59d78fc5] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xde9eed1d] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xe87acbc0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xe2de7737] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x6090d6d5] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xbbab2643] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xcfcd0f13] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xaa5f789c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xa388a368] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x2ed82995] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x3de1dfed] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x416c56e8] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x41df43fc] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x95f389b1] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x69279795] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xf101aa7f] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x2085c238] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x84aa3a9c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x48aaae3c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x4a162433] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1f01c757] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x2eb1b658] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x947a12df] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9d6b13b0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xa0ba4f17] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x8a2932f3] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x512fe446] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x99ea331d] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x6b39f4ec] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x42b00348] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x7d5bd1f0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xd31bc45d] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xdb33dad0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xaef6abbc] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x46c6e36f] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xf74e932b, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb05ac6b1, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xeb0467fb, [[TLUpdate$updateChannelTooLong alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x108d941f, [[TLCodexModernUpdateChannelTooLongParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa4bcc6fe, [[TLCodexChannelDifferenceTooLongParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x38faab5f, [[TLauth_SentCode$auth_sentCode alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x5e002502, [[TLauth_SentCode$auth_sentCode alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x36585ea4, [[TLmessages_BotCallbackAnswer$botCallbackAnswer alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x17db940b, [[TLBotInlineResult$botInlineMediaResult alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xe4def5db, [[TLCodexModernDialogParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xd58a08c6, [[TLCodexModernDialogParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x90a6ca84, [[TLCodexModernMessageEmptyParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb6c4f543, [[TLCodexMessageViewsResultParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x8c718e87, [[TLCodexModernMessagesParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x1d73e7ea, [[TLCodexModernMessagesParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x3a54685e, [[TLCodexModernMessagesSliceParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5f206716, [[TLCodexModernMessagesSliceParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x3e0b5b6a, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc776ba4e, [[TLCodexModernChannelMessagesParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x9ab0feaf, [[TLCodexModernChannelsParticipantsParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x1bd54456, [[TLCodexModernChannelParticipantParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa9478a1a, [[TLCodexModernChannelParticipantParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x2fe601d3, [[TLCodexModernChannelParticipantParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x34c3bb53, [[TLCodexModernChannelParticipantParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xd5f0ad91, [[TLCodexModernChannelParticipantParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x1b03f006, [[TLCodexModernChannelParticipantParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x71701da9, [[TLCodexForumTopicParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xfcdad815, [[TLCodexForumTopicParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x023f109b, [[TLCodexForumTopicParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x71e094f3, [[TLCodexModernDialogsSliceParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x0200185b, [[TLCodexModernDialogsSliceParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x94345242, [[TLMessage$modernMessage alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x7600b9d3, [[TLMessage$modernMessage alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x95ef6f2b, [[TLMessage$modernMessage alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x2b085862, [[TLMessage$modernMessageService alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x7a800e0a, [[TLMessage$modernMessageService alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x6a3ac8ea, [[TLMessage$modernMessageService alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x4fdd3430, [[TLCodexModernKeyboardButtonStyleParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa03e5b85, [[TLCodexModernReplyMarkupParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x86b40b08, [[TLCodexModernReplyMarkupParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xf4108aa0, [[TLCodexModernReplyMarkupParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x85dd99d1, [[TLCodexModernReplyMarkupParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x3502758c, [[TLCodexModernReplyMarkupParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x48a30254, [[TLCodexModernReplyMarkupParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x77608b83, [[TLCodexModernKeyboardButtonRowParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa2fa4880, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x7d170cff, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x258aff05, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xd80c25ec, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x683a5e46, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xe62bc960, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb16a6c29, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x417efd8f, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xfc796b3f, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xaa40f94d, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x0568a748, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x991399fc, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x50f41ccf, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x89c590f9, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xafd93fbb, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x3fa53905, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xf51006f9, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x68013e72, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x7a11d782, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x7d5e07c7, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc0fd5d09, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xe846b1a0, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xe15c4370, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5b0f15f5, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x02b78156, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xbcc4af10, [[TLCodexModernKeyboardButtonParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5f3b8a00, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc9f06e1b, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x339bef6c, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x3e81e078, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x71bd134c, [[TLCodexDialogFolderParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x69274bc6, [[TLCodexModernDialogParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xfc89f7f3, [[TLCodexModernDialogParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x59511722, [[TLCodexModernPeerUserParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x3fccf7ef, [[TLCodexModernPeerUserParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x36c6019a, [[TLCodexModernPeerChatParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa2a5371e, [[TLCodexModernPeerChannelParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb9c0639a, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5da674b7, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x95fcd1d6, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x99622c0c, [[TLCodexModernPeerNotifySettingsParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc13e3c50, [[TLCodexModernImportedContactParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5ce14175, [[TLPopularContact$popularContact alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5fb224d5, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x9f120418, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xd072acb4, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb4073647, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb54b5acf, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x2de11aae, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x929b619d, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xfa30a8c7, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xee8c1e86, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xf35aec28, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5b934f9d, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xcdbbcebb, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xbe382906, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x2cb51097, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x03d1ea4e, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xcfc9e002, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x770416af, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x37381085, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x49a6549c, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x50a04e45, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xfffe1bac, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x65427b82, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb8905fb2, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xf888fa1a, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x8b73e763, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xe4621141, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x6b134e8e, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x41c87565, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xf7e8d89b, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xece9814b, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x2dd14edc, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x4f2b9479, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x0a339f0b, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa3d1cb80, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x8c79b63c, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x1b2286b8, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x8935fc73, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x79f5d419, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x523da4eb, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xeafc32bc, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x52928bca, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x661d4037, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xe9baa668, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x19360dc0, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x695c9e7c, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x4f11bae1, [[TLUserProfilePhoto$userProfilePhotoEmpty alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x82d1f706, [[TLCodexModernUserProfilePhotoParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xebd1c797, [[TLCodexModernUserProfilePhotoParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x85dd99d1, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x48a30254, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa03e5b85, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x86b40b08, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x77608b83, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa2fa4880, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x258aff05, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x35bbdb6b, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb16a6c29, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xfc796b3f, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x93b9fbb5, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x50f41ccf, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xafd93fbb, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x10b78d29, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xd02e7fd4, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xbbc7515d, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xe988037b, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x308660c1, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x13767230, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa0c0505c, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x53d7bfd8, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc9662d05, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x36086d42, [[TLDialog$dialogFeed alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xfd8e711f, [[TLDraftMessage$draftMessage alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x60fe3294, [[TLCodexModernDraftMessageParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x1b49ec6d, [[TLCodexModernUpdateDraftMessageParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x8f300b57, [[TLCodexModernBotInfoParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc27ac8c7, [[TLCodexModernBotCommandParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x7533a588, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x4258c205, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc7b57ce6, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xdb74f558, [[TLChatInvite$chatInvite alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x3213dbba, [[TLConfig$config alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xcc1a241e, [[TLCodexModernConfigParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xcd050916, [[TLauth_Authorization$auth_authorization alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x2ea2c0d4, [[TLauth_Authorization$auth_authorization alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x6319d612, [[TLDocumentAttributeSticker alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x6c37c15c, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x11b58939, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x17399fad, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x15590068, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x9801d2f7, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xfd149899, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xbdf9653b, [[TLGame$game alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xcde200d1, [[TLPageBlock$pageBlockEmbed alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x1b8f4ad1, [[TLPhoneCall$phoneCallWaiting alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xebe46819, [[TLUpdate$updateServiceNotification alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x50ca4de1, [[TLPhoneCall$phoneCallDiscarded alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xeed42858, [[TLPhoneCall$phoneCallWaitingMeta alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x45361c63, [[TLPhoneCall$phoneCallRequested alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x22fd7181, [[TLPhoneCall$phoneCallAccepted alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x3ba5940c, [[TLPhoneCall$phoneCall alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xf9d25503, [[TLPhoneCall$phoneCallDiscardedMeta alloc] init]));
        objectClassesByConstructorNames[(int32_t)0xdc7555ab] = [[TLPhoneCall$phoneCallWaitingMeta alloc] init];
        objectClassesByConstructorNames[(int32_t)0x9627ce57] = [[TLPhoneCall$phoneCallRequested alloc] init];
        objectClassesByConstructorNames[(int32_t)0xd149f2bd] = [[TLPhoneCall$phoneCallAccepted alloc] init];
        objectClassesByConstructorNames[(int32_t)0xc9908a15] = [[TLPhoneCall$phoneCall alloc] init];
        objectClassesByConstructorNames[(int32_t)0xf01017df] = [[TLPhoneCall$phoneCallDiscardedMeta alloc] init];
        TLCodexPhoneConnectionParser *phoneConnectionParser = [[TLCodexPhoneConnectionParser alloc] init];
        manualObjectParsers[(int32_t)0x9cc123c7] = phoneConnectionParser;
        manualObjectParsers[(int32_t)0x635fe375] = phoneConnectionParser;
        TGLog(@"IOS6CALL registered modern PhoneCall aliases 5.12/5.13");
        manualObjectParsers[(int32_t)0xeccaad39] = [[TLCodexSkipObjectParser alloc] init];
        objectClassesByConstructorNames[(int32_t)0xeccaad39] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9bc80023] = [[TLCodexSkipObjectParser alloc] init];
        objectClassesByConstructorNames[(int32_t)0x9bc80023] = [[TLCodexSkipObjectParser alloc] init];
        TGLog(@"IOS6CALL registered post-call update skip aliases eccaad39/9bc80023");
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xea4cb65b, [[TLUpdate$updatePinnedDialogs alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x80e11a7f, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb6aef7b0, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xbd47cbad, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb5a1ce5a, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x7fcb13a8, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x95e3fbef, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x15cefd00, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xa43f30cc, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x031224c3, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x95d2ac92, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xe1037f92, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xea3948e9, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x94bd38ed, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x9fbab604, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x92a72876, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x3c134d7b, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xcc02aa6d, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x0d999256, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x8f31b327, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x96163f56, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x4792929b, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xfae69f56, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc516d679, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x1b287353, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xd95c6154, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x98e0d697, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x7a0d7f42, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x502f92f7, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb3a07661, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xaa786345, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x47dd8079, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb4c38cb5, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc83d6aec, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc0944820, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x57de635e, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x31518e9b, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x5060a3f4, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x678c2e09, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x332ba9ed, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x2a9fadc5, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x93b31848, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x41b3e202, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x45d5b021, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xf3f25f76, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xebbca3cb, [[TLCodexModernMessageActionParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xd7c0ff9c, [[TLUser$modernUser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xc30aa358, [[TLInvoice$invoice alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x84551347, [[TLMessageMedia$messageMediaInvoice alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x3f56aea3, [[TLpayments_PaymentForm$payments_paymentForm alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xfb8fe43c, [[TLpayments_SavedInfo$payments_savedInfo alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x909c3f94, [[TLPaymentRequestedInfo$paymentRequestedInfo alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x500911e1, [[TLPayments_PaymentCeceipt$payments_paymentReceipt alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xd1451883, [[TLpayments_ValidatedRequestedInfo$payments_validatedRequestedInfo alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x6c47ac9f, [[TLLangPackStringPluralized alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x289da732, [[TLChat$channelForbidden alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x695150d7, [[TLCodexModernMessageMediaPhotoParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xe216eb63, [[TLCodexModernMessageMediaPhotoParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xb940c666, [[TLCodexModernMessageMediaGeoLiveParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xddf10c3b, [[TLCodexModernMessageMediaWebPageParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x3f7ee58b, [[TLCodexModernMessageMediaDiceParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x08cbec07, [[TLCodexModernMessageMediaDiceParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xdc7b1140, [[TLCodexModernMessageEntityMentionNameParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xc8cf05f8, [[TLCodexModernMessageEntityCustomEmojiParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x145ade0b, [[TLCodexModernContactParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x6a7e7366, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x9cb070d7, [[TLCodexModernMessageMediaDocumentParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x4cf4d72d, [[TLCodexModernMessageMediaDocumentParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x52d8ccd9, [[TLCodexModernMessageMediaDocumentParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xfb197a65, [[TLCodexModernPhotoParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x75c78e60, [[TLCodexModernPhotoSizeParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x021e1ad6, [[TLCodexModernPhotoSizeParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xe0b0bc2e, [[TLCodexModernPhotoSizeParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xfa3efb95, [[TLCodexModernPhotoSizeParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xd8214d41, [[TLCodexModernPhotoSizeParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xde33b094, [[TLCodexModernPhotoSizeParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0xf85c413c, [[TLCodexModernPhotoSizeParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x0da082fe, [[TLCodexModernPhotoSizeParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x77d01c3b, [[TLCodexModernImportedContactsParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x83d60fc2, [[TLCodexSkipObjectParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >((int32_t)0x8fd4c4d8, [[TLCodexModernDocumentParser alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x6a9d7b35, [[TLchannelDifferenceTooLong alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x55c3a1b1, [[TLmessages_FeedMessages$messages_feedMessages alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x8e8bca3d, [[TLchannels_FeedSources$channels_feedSources alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x31bc3d25, [[TLInputSingleMedia$inputSingleMedia alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x5585a139, [[TLStickerSet$stickerSet alloc] init]));
        manualObjectParsers[(int32_t)0x6410a5d2] = [[TLCodexModernStickerSetCoveredParser alloc] init];
        manualObjectParsers[(int32_t)0x3407e51b] = [[TLCodexModernStickerSetCoveredParser alloc] init];
        manualObjectParsers[(int32_t)0x40d13c0e] = [[TLCodexModernStickerSetCoveredParser alloc] init];
        manualObjectParsers[(int32_t)0x77b15d1c] = [[TLCodexModernStickerSetCoveredParser alloc] init];
        manualObjectParsers[(int32_t)0xcdbbcebb] = [[TLCodexModernAllStickersParser alloc] init];
        manualObjectParsers[(int32_t)0x2cb51097] = [[TLCodexModernFavedStickersParser alloc] init];
        manualObjectParsers[(int32_t)0xfcfeb29c] = [[TLCodexModernStickerKeywordParser alloc] init];
        manualObjectParsers[(int32_t)0x6e153f16] = [[TLCodexModernStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0xe86602c3] = [[TLCodexModernAllStickersParser alloc] init];
        manualObjectParsers[(int32_t)0x9e8fa6d3] = [[TLCodexModernFavedStickersParser alloc] init];
        manualObjectParsers[(int32_t)0x88d37c56] = [[TLCodexModernRecentStickersParser alloc] init];
        manualObjectParsers[(int32_t)0x0b17f890] = [[TLCodexModernRecentStickersParser alloc] init];
        manualObjectParsers[(int32_t)0xbe382906] = [[TLCodexModernFeaturedStickersParser alloc] init];
        manualObjectParsers[(int32_t)0xc6dc0c66] = [[TLCodexModernFeaturedStickersParser alloc] init];
        manualObjectParsers[(int32_t)0x38641628] = [[TLCodexModernStickerSetInstallResultParser alloc] init];
        manualObjectParsers[(int32_t)0x35e410a8] = [[TLCodexModernStickerSetInstallResultParser alloc] init];
        manualObjectParsers[(int32_t)0x8af09dd2] = [[TLCodexModernFoundStickerSetsParser alloc] init];
        manualObjectParsers[(int32_t)0x0d54b65d] = [[TLCodexModernFoundStickerSetsParser alloc] init];
        manualObjectParsers[(int32_t)0x2dd14edc] = [[TLCodexModernStickerSetMetaParser alloc] init];
        manualObjectParsers[(int32_t)0xd3f924eb] = [[TLCodexModernStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0x6319d612] = [[TLCodexModernDocumentAttributeStickerParser alloc] init];
        manualObjectParsers[(int32_t)0xffb62b95] = [[TLCodexModernInputStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0x9de7a269] = [[TLCodexModernInputStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0x861cc8a0] = [[TLCodexModernInputStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0x028703c8] = [[TLCodexModernInputStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0xe67f520e] = [[TLCodexModernInputStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0xcde3739] = [[TLCodexModernInputStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0xc88b3b02] = [[TLCodexModernInputStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0x04c4d4ce] = [[TLCodexModernInputStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0x29d0f5ee] = [[TLCodexModernInputStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0x44c1f8e9] = [[TLCodexModernInputStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0x49748553] = [[TLCodexModernInputStickerSetParser alloc] init];
        manualObjectParsers[(int32_t)0x1cf671a0] = [[TLCodexModernInputStickerSetParser alloc] init];
        addHashToString((int32_t)0x2dd14edc, @"stickerSet");
        addHashToString((int32_t)0x88d37c56, @"messages.recentStickers");
        addHashToString((int32_t)0xbe382906, @"messages.featuredStickers");
        addHashToString((int32_t)0x8af09dd2, @"messages.foundStickerSets");
        addHashToString((int32_t)0x6319d612, @"documentAttributeSticker");
        IOS6_NOOP_LOG(@"IOS6STICKER registered modern sticker parsers");
        manualObjectParsers[(int32_t)0xb434e2b8] = [[TLCodexModernExportedAuthorizationParser alloc] init];
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x6fa68e41, [[TLUpdate$updateReadFeed alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xe09e1fb8, [[TLhelp_ProxyData$proxyDataEmpty alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x2bf7ee23, [[TLhelp_ProxyData$proxyDataPromo alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x780a0310, [[TLhelp_TermsOfService$help_termsOfService alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x187fa0ca, [[TLSecureValue$secureValue alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xdb21d0a7, [[TLInputSecureValue$inputSecureValue alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xad2e1cd8, [[TLaccount_AuthorizationForm$account_authorizationForm alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xaf509d20, [[TLPeerNotifySettings$peerNotifySettings alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x6a4ee832, [[TLhelp_DeepLinkInfo$help_deepLinkInfo alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x1b0c841a, [[TLDraftMessage$draftMessageEmpty alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x1da7158f, [[TLhelp_AppUpdate$help_appUpdate alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0xad2641f8, [[TLaccount_Password$account_password alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x957b50fb, [[TLaccount_Password$account_password alloc] init]));
        manualObjectParsers.insert(std::pair<int32_t, id<TLObject> >(0x9a5c33e5, [[TLaccount_PasswordSettings$account_passwordSettings alloc] init]));

        manualObjectParsers[(int32_t)0x80e11a7f] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xffa00ccc] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xc624b16e] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xb91bbd3a] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x48e91302] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x31c48347] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xa80f51e4] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x87e2f155] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xb00c47a2] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xea2c31d3] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xe6c31522] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xac1f1fcd] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x84b88578] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x2ffe2f7a] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xcc7c5c89] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xc7edbc83] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xee7a1596] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x95ddcf69] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x69f916f8] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xa8a3c699] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x2c8f2a25] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x774278d4] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x73ada76b] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xb07ed085] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xe188503b] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xbf7d6572] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x3e2793ba] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x9da1cd6c] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x399674dc] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x16605e3e] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0xd7c0ff9c] = [[TLUser$modernUser alloc] init];
        manualObjectParsers[(int32_t)0xd8aa840f] = [[TLCodexInputGroupCallParser alloc] init];
        manualObjectParsers[(int32_t)0x6880b94d] = [[TLCodexPeerSettingsContainerParser alloc] init];
        manualObjectParsers[(int32_t)0xacd66c5e] = [[TLCodexModernPeerSettingsParser alloc] init];
        manualObjectParsers[(int32_t)0xcc02aa6d] = [[TLCodexModernMessageActionParser alloc] init];
        manualObjectParsers[(int32_t)0x83314fca] = [[TLUser$modernUser alloc] init];
        manualObjectParsers[(int32_t)0x2813e6db] = [[TLUser$modernUser alloc] init];
        manualObjectParsers[(int32_t)0x1afeb7ac] = [[TLUser$modernUser alloc] init];
        manualObjectParsers[(int32_t)0xd0a1d008] = [[TLUser$modernUser alloc] init];
        manualObjectParsers[(int32_t)0x145ade0b] = [[TLCodexModernContactParser alloc] init];
        manualObjectParsers[(int32_t)0xeae87e42] = [[TLCodexModernContactsParser alloc] init];
        manualObjectParsers[(int32_t)0x0ade1591] = [[TLCodexModernBlockedParser alloc] init];
        manualObjectParsers[(int32_t)0xe1664194] = [[TLCodexModernBlockedParser alloc] init];
        manualObjectParsers[(int32_t)0xe8fd8014] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x211a1788] = [[TLCodexModernWebPageEmptyParser alloc] init];
        manualObjectParsers[(int32_t)0xe89c45b2] = [[TLCodexModernWebPageParser alloc] init];
        manualObjectParsers[(int32_t)0xddf10c3b] = [[TLCodexModernMessageMediaWebPageParser alloc] init];
        manualObjectParsers[(int32_t)0xb53e8b21] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x8c9a88ac] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x3f7ee58b] = [[TLCodexModernMessageMediaDiceParser alloc] init];
        manualObjectParsers[(int32_t)0x08cbec07] = [[TLCodexModernMessageMediaDiceParser alloc] init];
        manualObjectParsers[(int32_t)0x4bd6e798] = [[TLCodexModernMessageMediaPollParser alloc] init];
        manualObjectParsers[(int32_t)0xb2a2f663] = [[TLCodexModernGeoPointSkipParser alloc] init];
        manualObjectParsers[(int32_t)0x4e4df4bb] = [[TLCodexModernMessageFwdHeaderParser alloc] init];
        manualObjectParsers[(int32_t)0xdc7b1140] = [[TLCodexModernMessageEntityMentionNameParser alloc] init];
        manualObjectParsers[(int32_t)0xc8cf05f8] = [[TLCodexModernMessageEntityCustomEmojiParser alloc] init];
        manualObjectParsers[(int32_t)0x9c4e7e8b] = [[TLCodexModernMessageEntitySimpleParser alloc] init];
        manualObjectParsers[(int32_t)0xbf0693d4] = [[TLCodexModernMessageEntitySimpleParser alloc] init];
        manualObjectParsers[(int32_t)0x761e6af4] = [[TLCodexModernMessageEntitySimpleParser alloc] init];
        manualObjectParsers[(int32_t)0x32ca960f] = [[TLCodexModernMessageEntitySimpleParser alloc] init];
        manualObjectParsers[(int32_t)0xf1ccaaac] = [[TLCodexModernMessageEntitySimpleParser alloc] init];
        manualObjectParsers[(int32_t)0x904ac7c7] = [[TLCodexModernMessageEntitySimpleParser alloc] init];
        manualObjectParsers[(int32_t)0x71777116] = [[TLCodexModernMessageEntitySimpleParser alloc] init];
        manualObjectParsers[(int32_t)0xc6c1e5a7] = [[TLCodexModernMessageEntitySimpleParser alloc] init];
        manualObjectParsers[(int32_t)0x0652c1c5] = [[TLCodexModernMessageEntitySimpleParser alloc] init];
        manualObjectParsers[(int32_t)0x6c622f67] = [[TLCodexModernMessageEntitySimpleParser alloc] init];
        manualObjectParsers[(int32_t)0x751f3146] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x58747131] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xff16e2ca] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x7adf2420] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xf8227181] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xebe07752] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x20529438] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x635b4c09] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x6c8e1e06] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x3b6ddad2] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xd38ff1c2] = [[TLCodexModernDocumentAttributeVideoD38Parser alloc] init];
        manualObjectParsers[(int32_t)0xeeca5ce3] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x17399fad] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xfd149899] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x6a7e7366] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x98657f0d] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xde33b094] = [[TLCodexModernPhotoSizeParser alloc] init];
        manualObjectParsers[(int32_t)0xf85c413c] = [[TLCodexModernPhotoSizeParser alloc] init];
        manualObjectParsers[(int32_t)0x0da082fe] = [[TLCodexModernPhotoSizeParser alloc] init];
        manualObjectParsers[(int32_t)0x1759c560] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x8c88c923] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x7c8fe7b6] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x39f23300] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xa8718dc5] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xf259a80b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x65a0fa4d] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x031f9590] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xef1751b5] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x804361ea] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1e148390] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xbf4dea82] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x76768bed] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x16115a96] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xa44f3ef6] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x25e073fc] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xe4e88011] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb92fb6cd] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9a8ae1e1] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x5e068047] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x98dd8936] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x6f747657] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xdc3d824f] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0x744694e0] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0x6724abc4] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0xd912a59c] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0xc12622c4] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0x9bf8bb95] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0x6c3f19b9] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0x3c2884c1] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0xde5a0dd6] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0x7e6260d7] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0xed6a8504] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0xc7fb5e01] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0x034b8621] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0x1ccb966a] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0x081ccf4f] = [[TLCodexRichTextSkipParser alloc] init];
        manualObjectParsers[(int32_t)0x35553762] = [[TLCodexRichTextSkipParser alloc] init];

        manualObjectParsers[(int32_t)0x2633421b] = [[TLCodexModernChannelFullParser alloc] init];
        manualObjectParsers[(int32_t)0x3ded6320] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0x56e0d474] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0x70322949] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0x9f84f49e] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0x2ec0533f] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0xfdb19008] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0xf6a548d3] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0x773f4e66] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0xaa073beb] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0xceaa3ea1] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0xa8852491] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0x8a53b014] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0xca5cab89] = [[TLCodexModernMessageMediaUnsupportedParser alloc] init];
        manualObjectParsers[(int32_t)0x904dd49c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xac21d3ce] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x09cb7759] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x8ae5c97a] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9ddb347c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x07df587c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xa02a982e] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1ea2fda7] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xa584b019] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x283bd312] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x8b725fce] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x77b0e372] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xa4a79376] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9f812b08] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x683b2c52] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xdef143d0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xfb9c547a] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x54b56617] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x7781fe18] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb98cd696] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x72c64955] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xab339c00] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9f27d26e] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xe477092e] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xd3656499] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xa2c0f695] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xe7ff068a] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x7184603b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x07141dbf] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xac5c1af7] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x21108ff7] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xe519abab] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xc9b9e2b9] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xc3f2f501] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xcc4d9ecc] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xef156a5c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1b0e4f07] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x4b3e14d6] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x8f34b2f5] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xfebe5491] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x206ad49e] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1f0c1ad9] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xdc6cfcf0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xad628cc8] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xee479c64] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xcba9a52f] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x49b92a26] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x221bb5e4] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xcae68768] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xfd5e12bd] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x257e962b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xeb983f8f] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x4367daa0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xe175e66f] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb2539d54] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9a9d77e0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x86f8613c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xc448415c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9ae228e2] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x4959427a] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xe7058e7f] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x8a480e27] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x50cd067c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1f2bf4a] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xedf3add0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x93037e20] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb8ea86a9] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x26219a58] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x767d61eb] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xadec6ebe] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x2ba1f5ce] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x00f8ed08] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x64407ea7] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xf83ae221] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x44ba9dd9] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xc01f6fe8] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xcb6ff828] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x889b59ef] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x3259950a] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x3bb842ac] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x2aee9191] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x6f8b32aa] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x0194cb3b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x832175e0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x033ed001] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x17d7f87b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x09c469cd] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xc4e5921e] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb88cf373] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1d998733] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x114ff30d] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x628c9224] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb4ae666f] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xec43a2d1] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9a23af21] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x93c3e27e] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xd1ed9a5b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xbddb616e] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb89bfccf] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x95f2bfe4] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb457b375] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x7b560a0b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x250dbaf8] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xe92fd902] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xd80da15d] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x60682812] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xf9677aad] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x0bd915c0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x13659eb0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x6c9ce8ed] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x6c207376] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1dab80b7] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x394e7f21] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x5e0589f1] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x5416d58] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x2e6eab1a] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x94ce852a] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x54236209] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xdd0c66f2] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x19a13f71] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x98d5ea1d] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb4d5d859] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xf93cd45c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1e109708] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xe581e4e9] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb4f67e93] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xa0624cf7] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xc69708d3] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xea32b4b1] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xeb032884] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xc387c04e] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xe7e82e12] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x0e8e37e5] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9325705a] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xc3987a3a] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x374fa7ad] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xd5e58274] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x87e5dfe4] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1a8afc7e] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xee430c85] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9d1dbd26] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xda2ad647] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x59e65335] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x44e56023] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x90d7adfa] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xcff63ea9] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9bad6414] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xc1f46103] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x6c9d0efe] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xf1d628ec] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x933ca597] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x79eb8cb3] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xbaf39d8b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x7dbf8673] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xffda656d] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1839490f] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x31bd492d] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xc077ec01] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9f071957] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x768e3aad] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xd08ce645] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x90c467d1] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb06fdbdf] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xeafdf716] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x5f2d1df2] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb81c7034] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x367617d3] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x43b46b20] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x481eadfa] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x7a1e11d1] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x7a9abda9] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x80d26cc7] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x093bcf34] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x6fb4ad87] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x881fb94b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xa26156c0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xc556a45d] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9e84bc99] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x2f2f21bf] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x0bb2d201] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x31c24808] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xb23fc698] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x9d2216e0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xbb9bb9a5] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x1e297bfa] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xfa0f3ca2] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xfb4c496c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x28373599] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x30f443db] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x07b68920] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x39c67432] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xa477288f] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x8c0f91fb] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x140502d1] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xd90d8dfe] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xcfb9d957] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x5334759c] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x4345be73] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x527d22eb] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xbbf51685] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x922e55a9] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xdb909ec2] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x96d074fd] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x2b96cd1b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xe1bb0d61] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x3fc9053b] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x6ebdff91] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0xbac3a61a] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x4b9e22a0] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x71e4ea58] = [[TLCodexSkipObjectParser alloc] init];
        manualObjectParsers[(int32_t)0x98613ebf] = [[TLCodexSkipObjectParser alloc] init];

        {
            TLSchemeType$schemeType *constructor = [[TLSchemeType$schemeType alloc] init];
            constructor.n_id = (int32_t)0xae500895;
            constructor.predicate = @"futuresalts";
            constructor.type = @"FutureSalts";
            NSMutableArray *fields = [[NSMutableArray alloc] init];
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"req_msg_id";
                arg.type = @"long";
                [fields addObject:arg];
            }
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"now";
                arg.type = @"int";
                [fields addObject:arg];
            }
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"salts";
                arg.type = @"vector<futureSalt>";
                [fields addObject:arg];
            }
            constructor.params = fields;
            [types addObject:constructor];
        }
        {
            TLSchemeMethod$schemeMethod *method = [[TLSchemeMethod$schemeMethod alloc] init];
            method.n_id = (int32_t)0x19c2f763;
            method.method = @"updates.getDifference";
            method.type = @"updates.Difference";
            NSMutableArray *fields = [[NSMutableArray alloc] init];
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"flags";
                arg.type = @"int";
                [fields addObject:arg];
            }
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"pts";
                arg.type = @"int";
                [fields addObject:arg];
            }
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"pts_limit";
                arg.type = @"flags.1?int";
                [fields addObject:arg];
            }
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"pts_total_limit";
                arg.type = @"flags.0?int";
                [fields addObject:arg];
            }
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"date";
                arg.type = @"int";
                [fields addObject:arg];
            }
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"qts";
                arg.type = @"int";
                [fields addObject:arg];
            }
            {
                TLSchemeParam$schemeParam *arg = [[TLSchemeParam$schemeParam alloc] init];
                arg.name = @"qts_limit";
                arg.type = @"flags.2?int";
                [fields addObject:arg];
            }
            method.params = fields;
            [methods addObject:method];
        }
        
        for (TLSchemeType *typeDesc in types)
        {
            NSString *name = typeDesc.type;
            if ([name isEqualToString:@"Bool"] || [name isEqualToString:@"Null"] || [name hasPrefix:@"Vector<"])
            {
                continue;
            }
            
            std::shared_ptr<std::vector<TLMetaField> > fields(new std::vector<TLMetaField>());
            
            bool hasUnresolvedTypes = false;
            
            for (TLSchemeParam *argDesc in typeDesc.params)
            {
                TLMetaField field;
                field.name = murMurHash32(argDesc.name);
                field.hasFlag = false;
                field.flagName = 0;
                field.flagBit = 0;
                field.flagOnly = false;
                
                NSString *typeName = argDesc.type;
                NSRange optionalRange = [typeName rangeOfString:@"?"];
                if (optionalRange.location != NSNotFound)
                {
                    NSString *flagDesc = [typeName substringToIndex:optionalRange.location];
                    NSString *actualTypeName = [typeName substringFromIndex:optionalRange.location + 1];
                    NSRange dotRange = [flagDesc rangeOfString:@"."];
                    if (dotRange.location != NSNotFound)
                    {
                        NSString *flagName = [flagDesc substringToIndex:dotRange.location];
                        NSString *flagBit = [flagDesc substringFromIndex:dotRange.location + 1];
                        field.hasFlag = true;
                        field.flagName = murMurHash32(flagName);
                        field.flagBit = [flagBit intValue];
                        field.flagOnly = [actualTypeName isEqualToString:@"true"];
                        typeName = field.flagOnly ? @"Bool" : actualTypeName;
                    }
                }
                
                int32_t fieldTypeName = murMurHash32(typeName);
                std::unordered_map<int32_t, std::pair<TLMetaTypeArgument, bool> >::iterator it = cachedFieldTypes.find(fieldTypeName);
                if (it == cachedFieldTypes.end())
                {
                    bool fieldUnresolvedTypes = false;
                    field.type = createTypeArgumentFromString(typeName, typesToResolve, vectorTypeMap, fieldUnresolvedTypes);
                    cachedFieldTypes.insert(std::pair<int32_t, std::pair<TLMetaTypeArgument, bool> >(fieldTypeName, std::make_pair(field.type, fieldUnresolvedTypes)));
                    if (fieldUnresolvedTypes)
                        hasUnresolvedTypes = true;
                }
                else
                {
                    field.type = it->second.first;
                    if (it->second.second)
                        hasUnresolvedTypes = true;
                }
                
                fields->push_back(field);
            }
            
            std::shared_ptr<TLMetaType> resultType = createTypeFromString(name, typesToResolve, vectorTypeMap);
            typesByName[resultType->getName()] = resultType;
            
            std::shared_ptr<TLMetaConstructor> constructor(new TLMetaConstructor(murMurHash32(typeDesc.predicate), typeDesc.n_id, fields, resultType));
            constructorsBySignature[constructor->getSignature()] = constructor;
            constructorsByName[constructor->getName()] = constructor;
            
            if (hasUnresolvedTypes)
            {
                constructorsWithUnresolvedTypes.push_back(constructor);
            }
        }
        
        for (TLSchemeMethod *method in methods)
        {
            if ([method.type hasPrefix:@"Vector<"])
            {
                bool hasUnresolvedTypes = false;
                createTypeArgumentFromString(method.type, typesToResolve, vectorTypeMap, hasUnresolvedTypes);
            }
        }
        
        const char *vectorPrefix = "vector # [ ";
        const char *vectorSuffix = " ] = Vector ";
        for (std::map<int32_t, TLMetaTypeArgumentWithName>::iterator it = vectorTypeMap.begin(); it != vectorTypeMap.end(); it++)
        {
            std::vector<char> signatureString;
            signatureString.insert(signatureString.end(), vectorPrefix, vectorPrefix + 11);
            signatureString.insert(signatureString.end(), it->second.name.begin(), it->second.name.end());
            signatureString.insert(signatureString.end(), vectorSuffix, vectorSuffix + 12);
            signatureString.insert(signatureString.end(), it->second.name.begin(), it->second.name.end());
            
            int32_t signature = (int32_t)crc32(0, (const Bytef *)signatureString.data(), (int32_t)signatureString.size());
            
            TLMetaTypeArgument typeArgument;
            typeArgument.boxed = it->second.boxed;
            typeArgument.unboxedConstructorName = it->second.unboxedConstructorName;
            typeArgument.unboxedConstructorSignature = it->second.unboxedConstructorSignature;
            typeArgument.type = it->second.type;
            
            vectorElementTypesByConstructor.insert(std::pair<int32_t, TLMetaTypeArgument>(signature, typeArgument));
        }
        
        for (TLSchemeMethod *methodDesc in ((TLScheme$scheme *)scheme).methods)
        {
            NSString *resultTypeName = methodDesc.type;
            NSString *method = methodDesc.method;
            
            std::shared_ptr<std::vector<TLMetaField> > fields(new std::vector<TLMetaField>());
            
            bool hasUnresolvedTypes = false;
            
            for (TLSchemeParam *argDesc in methodDesc.params)
            {
                TLMetaField field;
                field.name = murMurHash32(argDesc.name);
                field.hasFlag = false;
                field.flagName = 0;
                field.flagBit = 0;
                field.flagOnly = false;
                
                NSString *typeName = argDesc.type;
                NSRange optionalRange = [typeName rangeOfString:@"?"];
                if (optionalRange.location != NSNotFound)
                {
                    NSString *flagDesc = [typeName substringToIndex:optionalRange.location];
                    NSString *actualTypeName = [typeName substringFromIndex:optionalRange.location + 1];
                    NSRange dotRange = [flagDesc rangeOfString:@"."];
                    if (dotRange.location != NSNotFound)
                    {
                        NSString *flagName = [flagDesc substringToIndex:dotRange.location];
                        NSString *flagBit = [flagDesc substringFromIndex:dotRange.location + 1];
                        field.hasFlag = true;
                        field.flagName = murMurHash32(flagName);
                        field.flagBit = [flagBit intValue];
                        field.flagOnly = [actualTypeName isEqualToString:@"true"];
                        typeName = field.flagOnly ? @"Bool" : actualTypeName;
                    }
                }
                
                int32_t fieldTypeName = murMurHash32(typeName);
                std::unordered_map<int32_t, std::pair<TLMetaTypeArgument, bool> >::iterator it = cachedFieldTypes.find(fieldTypeName);
                if (it == cachedFieldTypes.end())
                {
                    bool fieldUnresolvedTypes = false;
                    field.type = createTypeArgumentFromString(typeName, typesToResolve, vectorTypeMap, fieldUnresolvedTypes);
                    cachedFieldTypes.insert(std::pair<int32_t, std::pair<TLMetaTypeArgument, bool> >(fieldTypeName, std::make_pair(field.type, fieldUnresolvedTypes)));
                    if (fieldUnresolvedTypes)
                        hasUnresolvedTypes = true;
                }
                else
                {
                    field.type = it->second.first;
                    if (it->second.second)
                        hasUnresolvedTypes = true;
                }
                
                fields->push_back(field);
            }
            
            std::shared_ptr<TLMetaType> resultType = createTypeFromString(resultTypeName, typesToResolve, vectorTypeMap);
            
            if (!([resultTypeName isEqualToString:@"Bool"] || [resultTypeName hasPrefix:@"Vector<"]))
            {
                if (typesByName.find(resultType->getName()) == typesByName.end())
                {
                    TGLog(@"***** Type %@ not registered", resultTypeName);
                }
            }
            
            std::shared_ptr<TLMetaConstructor> constructor(new TLMetaConstructor(murMurHash32(method), methodDesc.n_id, fields, resultType));
            constructorsBySignature[constructor->getSignature()] = constructor;
            constructorsByName[constructor->getName()] = constructor;
            
            if (hasUnresolvedTypes)
            {
                constructorsWithUnresolvedTypes.push_back(constructor);
            }
        }
        
        for (std::set<int32_t>::iterator it = typesToResolve.begin(); it != typesToResolve.end(); it++)
        {
            if (typesByName.find(*it) == typesByName.end())
            {
                TGLog(@"***** Failed to resolve type %@", stringForHash(*it));
            }
        }
        
        for (std::vector<std::shared_ptr<TLMetaConstructor> >::iterator it = constructorsWithUnresolvedTypes.begin(); it != constructorsWithUnresolvedTypes.end(); it++)
        {
            std::shared_ptr<std::vector<TLMetaField> > fields = (*it)->getFields();
            for (std::vector<TLMetaField>::iterator fieldIt = fields->begin(); fieldIt != fields->end(); fieldIt++)
            {
                resolveUnboxedTypes(&fieldIt->type, constructorsByName, vectorElementTypesByConstructor);
            }
        }
        
        for (std::unordered_map<int32_t, TLMetaTypeArgument>::iterator it = vectorElementTypesByConstructor.begin(); it != vectorElementTypesByConstructor.end(); it++)
        {
            resolveUnboxedTypes(&it->second, constructorsByName, vectorElementTypesByConstructor);
        }
    }
}

id TLMetaClassStore::constructObject(NSInputStream *is, int32_t signature, id<TLSerializationEnvironment> environment, TLSerializationContext *context, __autoreleasing NSError **error)
{
    TLConstructedValue value = constructValue(is, signature, environment, context, error);
    if (error != nil && *error != nil)
    {
        return nil;
    }
    
    switch (value.type)
    {
        case TLConstructedValueTypeEmpty:
            return nil;
        case TLConstructedValueTypeObject:
            return value.nativeObject;
        case TLConstructedValueTypePrimitiveInt32:
            return [NSNumber numberWithInt:value.primitive.int32Value];
        case TLConstructedValueTypePrimitiveInt64:
            return [NSNumber numberWithLongLong:value.primitive.int64Value];
        case TLConstructedValueTypePrimitiveDouble:
            return [NSNumber numberWithDouble:value.primitive.doubleValue];
        case TLConstructedValueTypePrimitiveBool:
            return [NSNumber numberWithBool:value.primitive.boolValue];
        case TLConstructedValueTypeString:
            return value.nativeObject;
        case TLConstructedValueTypeBytes:
            return value.nativeObject;
        case TLConstructedValueTypeVector:
            return value.nativeObject;
        default:
            break;
    }
    
    return nil;
}

TLConstructedValue TLMetaClassStore::constructValue(NSInputStream *is, int32_t signature, id<TLSerializationEnvironment> environment, TLSerializationContext *context, __autoreleasing NSError **error)
{
    if (signature == 0x3072cfa1) //gzip_packed
    {
        NSData *packedData = [is readBytes];
        NSData *unpackedData = [packedData decompressGZip];
        if (unpackedData == nil)
        {
            if (error != NULL)
            {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setValue:@"Couldn't unpack gzipped data" forKey:NSLocalizedDescriptionKey];
                *error = [[NSError alloc] initWithDomain:@"TL" code:-1 userInfo:userInfo];
            }
            return TLConstructedValue();
        }
        
        //TGLog(@"===== Packed / Unpacked: %d / %d kb", packedData.length / 1024, unpackedData.length / 1024);
        
        NSInputStream *unpackedIs = [NSInputStream inputStreamWithData:unpackedData];
        [unpackedIs open];
        int32_t unpackedSignature = [unpackedIs readInt32];
        TLConstructedValue result = constructValue(unpackedIs, unpackedSignature, environment, context, error);
        [unpackedIs close];
        
        return result;
    }
    
    switch (signature)
    {
        case TL_INT32_CONSTRUCTOR:
        {
            TLConstructedValue result;
            result.type = TLConstructedValueTypePrimitiveInt32;
            result.primitive.int32Value = [is readInt32];
            return result;
        }
        case TL_INT64_CONSTRUCTOR:
        {
            TLConstructedValue result;
            result.type = TLConstructedValueTypePrimitiveInt64;
            result.primitive.int64Value = [is readInt64];
            return result;
        }
        case TL_INT128_CONSTRUCTOR:
        {
            TLConstructedValue result;
            result.type = TLConstructedValueTypeBytes;
            NSData *data = [is readData:16];
            result.nativeObject = data;
            return result;
        }
        case TL_INT256_CONSTRUCTOR:
        {
            TLConstructedValue result;
            result.type = TLConstructedValueTypeBytes;
            NSData *data = [is readData:32];
            result.nativeObject = data;
            return result;
        }
        case TL_STRING_CONSTRUCTOR:
        {
            TLConstructedValue result;
            result.type = TLConstructedValueTypeString;
            NSString *data = [is readString];
            result.nativeObject = data;
            return result;
        }
        case TL_BYTES_CONSTRUCTOR:
        {
            TLConstructedValue result;
            result.type = TLConstructedValueTypeBytes;
            NSData *data = [is readBytes];
            result.nativeObject = data;
            return result;
        }
        case TL_DOUBLE_CONSTRUCTOR:
        {
            TLConstructedValue result;
            result.type = TLConstructedValueTypePrimitiveDouble;
            result.primitive.doubleValue = [is readDouble];
            return result;
        }
        case TL_BOOL_TRUE_CONSTRUCTOR:
        {
            TLConstructedValue result;
            result.type = TLConstructedValueTypePrimitiveBool;
            result.primitive.boolValue = true;
            return result;
        }
        case TL_BOOL_FALSE_CONSTRUCTOR:
        {
            TLConstructedValue result;
            result.type = TLConstructedValueTypePrimitiveBool;
            result.primitive.boolValue = false;
            return result;
        }
        case TL_NULL_CONSTRUCTOR:
        {
            TLConstructedValue result;
            result.type = TLConstructedValueTypeObject;
            result.nativeObject = nil;
            return result;
        }
        default:
            break;
    }
    
    if (signature == TL_UNIVERSAL_VECTOR_CONSTRUCTOR)
    {
        if (context != nil)
        {
            if (context.impliedSignature != 0)
                signature = context.impliedSignature;
            else
            {
                int32_t count = [is readInt32];
                NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)MAX(0, count)];
                TGLog(@"IOS6AUTH generic vector-as-object count=%d manual=0x%08x parser=%@", count, CodexCurrentManualSignature, CodexCurrentManualParser);
                for (int32_t i = 0; i < count; i++)
                {
                    int32_t itemSignature = [is readInt32];
                    id object = TLMetaClassStore::constructObject(is, itemSignature, environment, nil, error);
                    if (object != nil)
                        [array addObject:object];
                    if (error != NULL && *error != nil)
                    {
                        TGLog(@"IOS6AUTH generic vector-as-object failed index=%d/%d sig=0x%08x manual=0x%08x parser=%@ error=%@", i, count, itemSignature, CodexCurrentManualSignature, CodexCurrentManualParser, *error);
                        CodexReportCritical(@"tl_generic_vector_failed", [NSString stringWithFormat:@"index=%d/%d sig=0x%08x sigName=%@ manual=0x%08x manualName=%@ parser=%@ error=%@", i, count, itemSignature, stringForHash(itemSignature), CodexCurrentManualSignature, stringForHash(CodexCurrentManualSignature), CodexCurrentManualParser, *error]);
                        break;
                    }
                }
                TLConstructedValue result;
                result.type = TLConstructedValueTypeVector;
                result.nativeObject = array;
                return result;
            }
        }
        else
        {
            int32_t count = [is readInt32];
            NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)MAX(0, count)];
            TGLog(@"IOS6AUTH generic vector-as-object count=%d manual=0x%08x parser=%@", count, CodexCurrentManualSignature, CodexCurrentManualParser);
            for (int32_t i = 0; i < count; i++)
            {
                int32_t itemSignature = [is readInt32];
                id object = TLMetaClassStore::constructObject(is, itemSignature, environment, nil, error);
                if (object != nil)
                    [array addObject:object];
                if (error != NULL && *error != nil)
                {
                    TGLog(@"IOS6AUTH generic vector-as-object failed index=%d/%d sig=0x%08x manual=0x%08x parser=%@ error=%@", i, count, itemSignature, CodexCurrentManualSignature, CodexCurrentManualParser, *error);
                    CodexReportCritical(@"tl_generic_vector_failed", [NSString stringWithFormat:@"index=%d/%d sig=0x%08x sigName=%@ manual=0x%08x manualName=%@ parser=%@ error=%@", i, count, itemSignature, stringForHash(itemSignature), CodexCurrentManualSignature, stringForHash(CodexCurrentManualSignature), CodexCurrentManualParser, *error]);
                    break;
                }
            }
            TLConstructedValue result;
            result.type = TLConstructedValueTypeVector;
            result.nativeObject = array;
            return result;
        }
    }
    
    auto manualIt = manualObjectParsers.find(signature);
    if (manualIt != manualObjectParsers.end())
    {
        id<TLObject> parser = manualIt->second;
        id<TLObject> result = nil;
        int32_t previousManualSignature = CodexCurrentManualSignature;
        NSString *previousManualParser = CodexCurrentManualParser;
        CodexCurrentManualSignature = signature;
        CodexCurrentManualParser = NSStringFromClass([parser class]);
        @try
        {
            result = [parser TLdeserialize:is signature:signature environment:environment context:nil error:error];
        }
        @catch (NSException *exception)
        {
            CodexCurrentManualSignature = previousManualSignature;
            CodexCurrentManualParser = previousManualParser;
            TGLog(@"IOS6AUTH TL exception sig=0x%08x parser=%@ name=%@ reason=%@", signature, NSStringFromClass([parser class]), exception.name, exception.reason);
            CodexReportCritical(@"tl_exception", [NSString stringWithFormat:@"sig=0x%08x sigName=%@ parser=%@ name=%@ reason=%@", signature, stringForHash(signature), NSStringFromClass([parser class]), exception.name, exception.reason]);
            if (error != NULL)
            {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setValue:[NSString stringWithFormat:@"Exception while parsing 0x%08x with %@: %@", signature, NSStringFromClass([parser class]), exception.reason] forKey:NSLocalizedDescriptionKey];
                *error = [[NSError alloc] initWithDomain:@"TL" code:-1 userInfo:userInfo];
            }
            return TLConstructedValue();
        }
        if (error && *error != nil)
        {
            TGLog(@"IOS6AUTH TL manual error sig=0x%08x parser=%@ error=%@", signature, NSStringFromClass([parser class]), *error);
            CodexReportCritical(@"tl_manual_error", [NSString stringWithFormat:@"sig=0x%08x sigName=%@ parser=%@ error=%@", signature, stringForHash(signature), NSStringFromClass([parser class]), *error]);
            CodexCurrentManualSignature = previousManualSignature;
            CodexCurrentManualParser = previousManualParser;
            return TLConstructedValue();
        }
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = result;
        
        CodexCurrentManualSignature = previousManualSignature;
        CodexCurrentManualParser = previousManualParser;
        return value;
    }
    
    std::shared_ptr<TLMetaConstructor> constructor = getConstructorBySignature(signature);
    
    if (constructor == NULL)
    {
        std::unordered_map<int32_t, TLMetaTypeArgument>::iterator it = vectorElementTypesByConstructor.find(signature);
        if (it != vectorElementTypesByConstructor.end())
        {
            int32_t count = [is readInt32];
            
            std::unordered_map<int32_t, id<TLVector> >::iterator classIt = vectorClassesBySignature.find(signature);
            
            NSMutableArray *array = nil;
            if (classIt != vectorClassesBySignature.end())
                array = [classIt->second TLvectorConstruct];
            else
                array = [[NSMutableArray alloc] init];
            
            TLConstructedValue result;
            result.type = TLConstructedValueTypeVector;
            
            for (int32_t i = 0; i < count; i++)
            {
                int itemSignature = 0;
                if (it->second.boxed)
                    itemSignature = [is readInt32];
                else
                    itemSignature = it->second.unboxedConstructorSignature;
                
                TLConstructedValue itemValue = constructValue(is, itemSignature, environment, nil, error);
                if (error != nil && *error != nil)
                {
                    return TLConstructedValue();
                }
                
                id nativeValue = nil;
                
                switch (itemValue.type)
                {
                    case TLConstructedValueTypePrimitiveInt32:
                        nativeValue = [[NSNumber alloc] initWithInt:itemValue.primitive.int32Value];
                        break;
                    case TLConstructedValueTypePrimitiveInt64:
                        nativeValue = [[NSNumber alloc] initWithLongLong:itemValue.primitive.int64Value];
                        break;
                    case TLConstructedValueTypePrimitiveBool:
                        nativeValue = [[NSNumber alloc] initWithBool:itemValue.primitive.boolValue];
                        break;
                    case TLConstructedValueTypePrimitiveDouble:
                        nativeValue = [[NSNumber alloc] initWithDouble:itemValue.primitive.doubleValue];
                        break;
                    case TLConstructedValueTypeObject:
                        nativeValue = itemValue.nativeObject;
                        break;
                    case TLConstructedValueTypeString:
                        nativeValue = itemValue.nativeObject;
                        break;
                    case TLConstructedValueTypeBytes:
                        nativeValue = itemValue.nativeObject;
                        break;
                    case TLConstructedValueTypeVector:
                        nativeValue = itemValue.nativeObject;
                        break;
                    default:
                        break;
                }
                
                if (nativeValue != nil)
                    [array addObject:nativeValue];
            }
            
            result.nativeObject = array;
            
            return result;
        }
        else
        {
            if (error != NULL)
            {
#if defined(DEBUG) || defined(INTERNAL_RELEASE)
      //@throw [[NSException alloc] initWithName:@"tlmetaclassstore" reason:[NSString stringWithFormat:@"Constructor with signature %.8x not found", signature] userInfo:@{}];
#endif
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setValue:[NSString stringWithFormat:@"Constructor with signature %.8x not found", signature] forKey:NSLocalizedDescriptionKey];
                TGLog(@"IOS6AUTH unknown signature=0x%08x currentManual=0x%08x parser=%@", signature, CodexCurrentManualSignature, CodexCurrentManualParser);
                CodexReportCritical(@"tl_unknown_constructor", [NSString stringWithFormat:@"sig=0x%08x sigName=%@ currentManual=0x%08x currentManualName=%@ parser=%@", signature, stringForHash(signature), CodexCurrentManualSignature, stringForHash(CodexCurrentManualSignature), CodexCurrentManualParser]);
                *error = [[NSError alloc] initWithDomain:@"TL" code:-1 userInfo:userInfo];
            }
            return TLConstructedValue();
        }
    }
    
    @try
    {
        return constructor->construct(is, environment, nil, error);
    }
    @catch (NSException *exception)
    {
        TGLog(@"IOS6AUTH TL auto exception sig=0x%08x name=%@ reason=%@", signature, exception.name, exception.reason);
        CodexReportCritical(@"tl_auto_exception", [NSString stringWithFormat:@"sig=0x%08x sigName=%@ name=%@ reason=%@", signature, stringForHash(signature), exception.name, exception.reason]);
        if (error != NULL)
        {
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
            [userInfo setValue:[NSString stringWithFormat:@"Exception while auto parsing 0x%08x: %@", signature, exception.reason] forKey:NSLocalizedDescriptionKey];
            *error = [[NSError alloc] initWithDomain:@"TL" code:-1 userInfo:userInfo];
        }
        return TLConstructedValue();
    }
}

void TLMetaClassStore::serializeObject(NSOutputStream *os, id<TLObject> object, bool boxed)
{
    //TGLog(@"serialize object %@", object);

    if ([object isKindOfClass:[TLBool class]])
    {
        [os writeInt32:[((TLBool *)object) boolValue] ? TL_BOOL_TRUE_CONSTRUCTOR : TL_BOOL_FALSE_CONSTRUCTOR];
    }
    else if ([object TLconstructorSignature] == 0x3072cfa1)
    {
        if (boxed)
            [os writeInt32:[object TLconstructorSignature]];
        [os writeBytes:((TLCompressedObject *)object).compressedData];
    }
    else if ([object isKindOfClass:[TLMsgsAck class]])
    {
        if (boxed)
            [os writeInt32:[object TLconstructorSignature]];
        
        std::shared_ptr<TLMetaConstructor> constructor = getConstructorByName([object TLconstructorName]);
        
        std::map<int32_t, TLConstructedValue> fieldValues;
        [object TLfillFieldsWithValues:&fieldValues];
        
        std::vector<TLMetaField>::iterator fieldsEnd = constructor->fields->end();
        for (std::vector<TLMetaField>::iterator it = constructor->fields->begin(); it != fieldsEnd; it++)
        {
            std::map<int32_t, TLConstructedValue>::iterator fieldIt = fieldValues.find(it->name);
            
            if (it->type.boxed)
            {
                [os writeInt32:it->type.unboxedConstructorSignature];
            }
            
            NSArray *array = fieldIt->second.nativeObject;
            [os writeInt32:(int32_t)array.count];
            
            for (id item in array)
            {
                [os writeInt64:[item longLongValue]];
            }
        }
    }
    else
    {
        if ([object TLconstructorName] == -1)
        {
            if (boxed)
                [os writeInt32:[object TLconstructorSignature]];
            [object TLserialize:os];
        }
        else
        {
            std::shared_ptr<TLMetaConstructor> constructor = getConstructorByName([object TLconstructorName]);
            if (constructor != NULL)
            {
                if (boxed)
                    [os writeInt32:constructor->getSignature()];
                constructor->serialize(os, object);
            }
            else
            {
                if ([object isKindOfClass:[TLRPCphone_sendSignalingData class]])
                {
                    TLRPCphone_sendSignalingData *request = (TLRPCphone_sendSignalingData *)object;
                    TGLog(@"IOS6CALL signaling.serialize.fallback boxed=%d peer=%@ dataLen=%d", boxed ? 1 : 0, request.peer, (int)request.data.length);
                    if (boxed)
                        [os writeInt32:(int32_t)0xff7a9383];
                    TLMetaClassStore::serializeObject(os, request.peer, true);
                    [os writeBytes:request.data];
                }
                else
                {
                    TGLog(@"***** Constructor with name %.8x not found", [object TLconstructorName]);
                    if (boxed)
                        [os writeInt32:TL_NULL_CONSTRUCTOR];
                }
            }
        }
    }
}
