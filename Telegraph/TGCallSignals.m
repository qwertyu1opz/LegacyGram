#import "TGCallSignals.h"

#import "TGDatabase.h"
#import "TGTelegramNetworking.h"
#import "TL/TLMetaScheme.h"
#import "TGTelegraph.h"

#import "TGRequestEncryptedChatActor.h"

#import "../submodules/MtProtoKit/MTProtoKit/MTProtoKit.h"

#import "TGAppDelegate.h"
#import "TGUploadFileSignals.h"
#import "TGSendMessageSignals.h"
#import "TLInputMediaUploadedDocument.h"

#import "TGCallContext.h"
#import "TLRPCphone_sendSignalingData.h"

const int32_t TGCallMinLayer = 65;
const int32_t TGCallMaxLayer = 92;
const int32_t TGCallLegacyMaxLayer = 92;

@interface OngoingCallThreadLocalContextWebrtc : NSObject
+ (NSArray *)versionsWithIncludeReference:(bool)includeReference;
@end

@implementation TGCallSignals

+ (SSignal *)encryptionConfig {
    return [SSignal defer:^SSignal *{
        TLmessages_DhConfig$messages_dhConfig *config = [TGRequestEncryptedChatActor cachedEncryptionConfig];
        if (config != nil) {
            return [SSignal single:config];
        } else {
            TLRPCmessages_getDhConfig$messages_getDhConfig *getDhConfig = [[TLRPCmessages_getDhConfig$messages_getDhConfig alloc] init];
            getDhConfig.version = 0;
            getDhConfig.random_length = 256;
            
            return [[[TGTelegramNetworking instance] requestSignal:getDhConfig] mapToSignal:^SSignal *(TLmessages_DhConfig *config) {
                if ([config isKindOfClass:[TLmessages_DhConfig$messages_dhConfig class]])
                {
                    TLmessages_DhConfig$messages_dhConfig *concreteConfig = (TLmessages_DhConfig$messages_dhConfig *)config;
                    
                    if (!MTCheckIsSafeG(concreteConfig.g)) {
                        return [SSignal fail:nil];
                    }
                    
                    if (!MTCheckMod(concreteConfig.p, concreteConfig.g, [MTFileBasedKeychain keychainWithName:@"legacyPrimes" documentsPath:[TGAppDelegate documentsPath]]))
                    {
                        return [SSignal fail:nil];
                    }
                    
                    if (!MTCheckIsSafePrime(concreteConfig.p, [MTFileBasedKeychain keychainWithName:@"legacyPrimes" documentsPath:[TGAppDelegate documentsPath]]))
                    {
                        return [SSignal fail:nil];
                    }
                    
                    [TGRequestEncryptedChatActor setCachedEncryptionConfig:concreteConfig];
                    return [SSignal single:concreteConfig];
                } else {
                    return [SSignal fail:nil];
                }
            }];
        }
    }];
}

+ (TLPhoneCallProtocol$phoneCallProtocol *)protocol {
    TLPhoneCallProtocol$phoneCallProtocol *phoneCallProtocol = [[TLPhoneCallProtocol$phoneCallProtocol alloc] init];
    phoneCallProtocol.flags = (1 << 0) | (1 << 1);
    phoneCallProtocol.min_layer = TGCallMinLayer;
    phoneCallProtocol.max_layer = TGCallMaxLayer;
    Class callContextClass = NSClassFromString(@"OngoingCallThreadLocalContextWebrtc");
    phoneCallProtocol.library_versions = callContextClass != Nil
        ? [(id)callContextClass versionsWithIncludeReference:false]
        : [NSArray array];
    TGLog(@"IOS6CALL protocol local flags=%d min=%d max=%d libs=%@", phoneCallProtocol.flags, phoneCallProtocol.min_layer, phoneCallProtocol.max_layer, phoneCallProtocol.library_versions);
    return phoneCallProtocol;
}

+ (SSignal *)requestedOutgoingCallWithPeerId:(int64_t)peerId {
    TGLog(@"IOS6CALL signal.requestedOutgoing peer=%lld", peerId);
    return [[TGDatabaseInstance() modify:^id{
        return [TGTelegraphInstance createInputUserForUid:(int32_t)peerId];
    }] mapToSignal:^SSignal *(TLInputUser *inputUser) {
        if (inputUser == nil) {
            TGLog(@"IOS6CALL signal.requestedOutgoing.noInputUser peer=%lld", peerId);
            return [SSignal fail:nil];
        }
        TGLog(@"IOS6CALL signal.requestedOutgoing.inputUser peer=%lld class=%@", peerId, NSStringFromClass([inputUser class]));
        
        return [[self encryptionConfig] mapToSignal:^SSignal *(TLmessages_DhConfig$messages_dhConfig *config) {
            TLRPCphone_requestCall$phone_requestCall *requestCall = [[TLRPCphone_requestCall$phone_requestCall alloc] init];
            requestCall.flags = 0;
            requestCall.user_id = inputUser;
            requestCall.random_id = (int32_t)arc4random();
            
            uint8_t rawABytes[256];
            __unused int result = SecRandomCopyBytes(kSecRandomDefault, 256, rawABytes);
            
            for (int i = 0; i < 256 && i < (int)config.random.length; i++)
            {
                uint8_t currentByte = ((uint8_t *)config.random.bytes)[i];
                rawABytes[i] ^= currentByte;
            }
            
            NSData *aBytes = [[NSData alloc] initWithBytes:rawABytes length:256];
            
            int32_t tmpG = config.g;
            tmpG = NSSwapInt(tmpG);
            NSData *g = [[NSData alloc] initWithBytes:&tmpG length:4];
            
            NSData *gA = MTExp(g, aBytes, config.p);
            if (!MTCheckIsSafeGAOrB(gA, config.p)) {
                return [SSignal fail:nil];
            }
            
            NSData *gAHash = MTSha256(gA);
            requestCall.g_a_hash = gAHash;
            requestCall.protocol = [self protocol];
            TGLog(@"IOS6CALL rpc.phone.requestCall peer=%lld minLayer=%d maxLayer=%d", peerId, TGCallMinLayer, TGCallMaxLayer);
            
            return [[[TGTelegramNetworking instance] requestSignal:requestCall continueOnServerErrors:false failOnFloodErrors:true] mapToSignal:^SSignal *(TLphone_PhoneCall *result) {
                TGLog(@"IOS6CALL rpc.phone.requestCall.result peer=%lld result=%@ call=%@", peerId, NSStringFromClass([result class]), NSStringFromClass([result.phone_call class]));
                if (result.phone_call == nil) {
                    TGLog(@"IOS6CALL rpc.phone.requestCall.nilPhoneCall peer=%lld keepContext=1 pendingWaiting=1", peerId);
                    return [SSignal single:[[TGCallWaitingContext alloc] initWithCallId:0 accessHash:0 date:0 adminId:0 participantId:(int32_t)peerId a:aBytes gA:gA dhConfig:config receiveDate:0]];
                } else if ([result.phone_call isKindOfClass:[TLPhoneCall$phoneCallWaitingMeta class]]) {
                    TLPhoneCall$phoneCallWaitingMeta *concreteCall = (TLPhoneCall$phoneCallWaitingMeta *)result.phone_call;
                    TGLog(@"IOS6CALL rpc.phone.requestCall.waiting call=%lld access=%lld admin=%d participant=%d", concreteCall.n_id, concreteCall.access_hash, concreteCall.admin_id, concreteCall.participant_id);
                    return [SSignal single:[[TGCallWaitingContext alloc] initWithCallId:concreteCall.n_id accessHash:concreteCall.access_hash date:concreteCall.date adminId:concreteCall.admin_id participantId:concreteCall.participant_id a:aBytes gA:gA dhConfig:config receiveDate:concreteCall.receive_date]];
                } else if ([result.phone_call isKindOfClass:[TLPhoneCall$phoneCallDiscardedMeta class]]) {
                    TLPhoneCall$phoneCallDiscardedMeta *concreteCall = (TLPhoneCall$phoneCallDiscardedMeta *)result.phone_call;
                    TGLog(@"IOS6CALL rpc.phone.requestCall.discarded call=%lld reason=%@", concreteCall.n_id, NSStringFromClass([concreteCall.reason class]));
                    bool needsRating = concreteCall.flags & (1 << 2);
                    bool needsDebug = concreteCall.flags & (1 << 3);
                    TGCallDiscardedContext *callContext = [[TGCallDiscardedContext alloc] initWithCallId:concreteCall.n_id reason:[TGCallDiscardReasonAdapter reasonForTLObject:concreteCall.reason] outside:true needsRating:needsRating needsDebug:needsDebug error:nil];
                    return [SSignal single:callContext];
                } else {
                    TGLog(@"IOS6CALL rpc.phone.requestCall.unknown peer=%lld call=%@", peerId, NSStringFromClass([result.phone_call class]));
                    return [SSignal fail:nil];
                }
            }];
        }];
        
    }];
}

+ (SSignal *)discardedCallWithCallId:(int64_t)callId accessHash:(int64_t)accessHash reason:(TGCallDiscardReason)reason duration:(int32_t)duration {
    TLRPCphone_discardCall$phone_discardCall *discardCall = [[TLRPCphone_discardCall$phone_discardCall alloc] init];
    TLInputPhoneCall$inputPhoneCall *inputPhoneCall = [[TLInputPhoneCall$inputPhoneCall alloc] init];
    inputPhoneCall.n_id = callId;
    inputPhoneCall.access_hash = accessHash;
    discardCall.peer = inputPhoneCall;
    discardCall.reason = [TGCallDiscardReasonAdapter TLObjectForReason:reason];
    discardCall.duration = duration;
    return [[[TGTelegramNetworking instance] requestSignal:discardCall] mapToSignal:^SSignal *(TLUpdates$updates *updates) {
        TLPhoneCall$phoneCallDiscardedMeta *concreteCall = nil;
        NSMutableArray *otherUpdates = [[NSMutableArray alloc] init];
        
        for (TLUpdate *update in updates.updates)
        {
            if ([update isKindOfClass:[TLUpdate$updatePhoneCall class]])
            {
                TLUpdate$updatePhoneCall *callUpdate = (TLUpdate$updatePhoneCall *)update;
                if ([callUpdate.phone_call isKindOfClass:[TLPhoneCall$phoneCallDiscardedMeta class]])
                    concreteCall = (TLPhoneCall$phoneCallDiscardedMeta *)callUpdate.phone_call;
            }
            else
            {
                [otherUpdates addObject:update];
            }
        }
        updates.updates = otherUpdates;
        [[TGTelegramNetworking instance] addUpdates:updates];
        
        bool needsRating = concreteCall.flags & (1 << 2);
        bool needsDebug = concreteCall.flags & (1 << 3);
        TGCallDiscardedContext *callContext = [[TGCallDiscardedContext alloc] initWithCallId:callId reason:reason outside:false needsRating:needsRating needsDebug:needsDebug error:nil];
        return [SSignal single:callContext];
    }];
}

+ (SSignal *)receivedIncomingCallWithCallId:(int64_t)callId accessHash:(int64_t)accessHash date:(int32_t)date adminId:(int32_t)adminId participantId:(int32_t)participantId gAHash:(NSData *)gAHash {
    return [[self encryptionConfig] mapToSignal:^SSignal *(TLmessages_DhConfig$messages_dhConfig *config) {
        uint8_t bBytes[256];
        __unused int result = SecRandomCopyBytes(kSecRandomDefault, 256, bBytes);
        
        for (int i = 0; i < 256 && i < (int)config.random.length; i++) {
            uint8_t currentByte = ((uint8_t *)config.random.bytes)[i];
            bBytes[i] ^= currentByte;
        }
        NSData *b = [[NSData alloc] initWithBytes:bBytes length:256];
        
        int32_t tmpG = config.g;
        tmpG = NSSwapInt(tmpG);
        NSData *g = [[NSData alloc] initWithBytes:&tmpG length:4];
        
        NSData *gB = MTExp(g, b, config.p);
        if (!MTCheckIsSafeGAOrB(gB, config.p)) {
            return [SSignal fail:nil];
        }

        TLRPCphone_receivedCall$phone_receivedCall *receivedCall = [[TLRPCphone_receivedCall$phone_receivedCall alloc] init];
        TLInputPhoneCall$inputPhoneCall *inputPhoneCall = [[TLInputPhoneCall$inputPhoneCall alloc] init];
        inputPhoneCall.n_id = callId;
        inputPhoneCall.access_hash = accessHash;
        receivedCall.peer = inputPhoneCall;

        return [[[TGTelegramNetworking instance] requestSignal:receivedCall] mapToSignal:^SSignal *(__unused id next) {
            return [SSignal single:[[TGCallReceivedContext alloc] initWithCallId:callId accessHash:accessHash date:date adminId:adminId participantId:participantId dhConfig:config b:b gB:gB gAHash:gAHash]];
        }];
    }];
}

+ (SSignal *)acceptedIncomingCallWithCallId:(int64_t)callId accessHash:(int64_t)accessHash dhConfig:(id)dhConfig bBytes:(NSData *)bBytes gBBytes:(NSData *)gBBytes gAHash:(NSData *)gAHash {
    TLRPCphone_acceptCall$phone_acceptCall *acceptCall = [[TLRPCphone_acceptCall$phone_acceptCall alloc] init];
    TLInputPhoneCall$inputPhoneCall *inputPhoneCall = [[TLInputPhoneCall$inputPhoneCall alloc] init];
    inputPhoneCall.n_id = callId;
    inputPhoneCall.access_hash = accessHash;
    acceptCall.peer = inputPhoneCall;
    acceptCall.g_b = gBBytes;
    acceptCall.protocol = [self protocol];
    TGLog(@"IOS6CALL rpc.phone.acceptCall call=%lld access=%lld minLayer=%d maxLayer=%d", callId, accessHash, TGCallMinLayer, TGCallMaxLayer);
    
    return [[[TGTelegramNetworking instance] requestSignal:acceptCall] mapToSignal:^SSignal *(TLphone_PhoneCall *result) {
        TGLog(@"IOS6CALL rpc.phone.acceptCall.result call=%lld result=%@ phoneCall=%@", callId, NSStringFromClass([result class]), NSStringFromClass([result.phone_call class]));
        if ([result.phone_call isKindOfClass:[TLPhoneCall$phoneCallWaitingMeta class]]) {
            TLPhoneCall$phoneCallWaitingMeta *concreteCall = (TLPhoneCall$phoneCallWaitingMeta *)result.phone_call;
            TGCallWaitingConfirmContext *callContext = [[TGCallWaitingConfirmContext alloc] initWithCallId:callId accessHash:accessHash date:concreteCall.date adminId:concreteCall.admin_id participantId:concreteCall.participant_id b:bBytes gAHash:gAHash dhConfig:dhConfig receiveDate:concreteCall.receive_date];
            return [SSignal single:callContext];
        } else if ([result.phone_call isKindOfClass:[TLPhoneCall$phoneCallDiscardedMeta class]]) {
            TLPhoneCall$phoneCallDiscardedMeta *concreteCall = (TLPhoneCall$phoneCallDiscardedMeta *)result.phone_call;
            bool needsRating = concreteCall.flags & (1 << 2);
            bool needsDebug = concreteCall.flags & (1 << 3);
            TGCallDiscardedContext *callContext = [[TGCallDiscardedContext alloc] initWithCallId:concreteCall.n_id reason:[TGCallDiscardReasonAdapter reasonForTLObject:concreteCall.reason] outside:true needsRating:needsRating needsDebug:needsDebug error:nil];
            return [SSignal single:callContext];
        } else {
            return [SSignal fail:nil];
        }
    }];
}

+ (SSignal *)confirmedCallWithCallId:(int64_t)callId accessHash:(int64_t)accessHash key:(NSData *)key gABytes:(NSData *)gABytes keyId:(int64_t)keyId {
    TLRPCphone_confirmCall$phone_confirmCall *confirmCall = [[TLRPCphone_confirmCall$phone_confirmCall alloc] init];
    TLInputPhoneCall$inputPhoneCall *inputPhoneCall = [[TLInputPhoneCall$inputPhoneCall alloc] init];
    inputPhoneCall.n_id = callId;
    inputPhoneCall.access_hash = accessHash;
    confirmCall.peer = inputPhoneCall;
    confirmCall.g_a = gABytes;
    confirmCall.key_fingerprint = keyId;
    confirmCall.protocol = [self protocol];
    TGLog(@"IOS6CALL rpc.phone.confirmCall call=%lld access=%lld key=%lld minLayer=%d maxLayer=%d", callId, accessHash, keyId, TGCallMinLayer, TGCallMaxLayer);
    
    return [[[TGTelegramNetworking instance] requestSignal:confirmCall] mapToSignal:^SSignal *(TLphone_PhoneCall *result) {
        TGLog(@"IOS6CALL rpc.phone.confirmCall.result call=%lld result=%@ phoneCall=%@", callId, NSStringFromClass([result class]), NSStringFromClass([result.phone_call class]));
        if ([result.phone_call isKindOfClass:[TLPhoneCall$phoneCall class]]) {
            TLPhoneCall$phoneCall *concreteCall = (TLPhoneCall$phoneCall *)result.phone_call;
            TGLog(@"IOS6CALL confirmed.full call=%lld access=%lld key=%lld rawConn=%@ rawAlt=%@ rawConnections=%@ rawConnectionsCount=%d protocol=%@", concreteCall.n_id, concreteCall.access_hash, concreteCall.key_fingerprint, concreteCall.connection, concreteCall.alternative_connections, concreteCall.connections, (int)concreteCall.connections.count, concreteCall.protocol);
            TGLog(@"IOS6CALL key.check call=%lld authKeyLen=%lu keyFingerprintLocal=%lld keyFingerprintServer=%lld match=%d outgoing=1",
                  concreteCall.n_id,
                  (unsigned long)key.length,
                  keyId,
                  concreteCall.key_fingerprint,
                  keyId == concreteCall.key_fingerprint ? 1 : 0);
            
            __block int webRtcConnectionCount = 0;
            NSMutableArray *webrtcConnections = [[NSMutableArray alloc] init];
            NSString *customParameters = @"";
            if ([concreteCall respondsToSelector:NSSelectorFromString(@"custom_parameters")]) {
                id dataJson = [concreteCall valueForKey:@"custom_parameters"];
                if ([dataJson respondsToSelector:@selector(data)]) {
                    NSString *data = [dataJson valueForKey:@"data"];
                    if ([data isKindOfClass:[NSString class]])
                        customParameters = data;
                }
            }
            TGLog(@"IOS6CALL confirmed.customParameters len=%d data=%@", (int)customParameters.length, customParameters);
            TGCallConnectionDescription *(^deserializeConnection)(id) = ^TGCallConnectionDescription *(id connection) {
                if ([connection isKindOfClass:[TLPhoneConnection$phoneConnection class]]) {
                    TLPhoneConnection$phoneConnection *concreteConnection = (TLPhoneConnection$phoneConnection *)connection;
                    TGLog(@"IOS6CALL confirmed.connection id=%lld ip=%@ ipv6=%@ port=%d peerTagLen=%d", concreteConnection.n_id, concreteConnection.ip, concreteConnection.ipv6, concreteConnection.port, (int)concreteConnection.peer_tag.length);
                    if (concreteConnection.port == 0 || concreteConnection.peer_tag == nil || (concreteConnection.ip.length == 0 && concreteConnection.ipv6.length == 0)) {
                        TGLog(@"IOS6CALL confirmed.connection.skipBad id=%lld ip=%@ ipv6=%@ port=%d peerTag=%@", concreteConnection.n_id, concreteConnection.ip, concreteConnection.ipv6, concreteConnection.port, concreteConnection.peer_tag);
                        return nil;
                    }
                    return [[TGCallConnectionDescription alloc] initWithIdentifier:concreteConnection.n_id ipv4:concreteConnection.ip ipv6:concreteConnection.ipv6 port:concreteConnection.port peerTag:concreteConnection.peer_tag];
                }
                if ([connection isKindOfClass:[TLPhoneConnection$phoneConnectionWebrtc class]]) {
                    TLPhoneConnection$phoneConnectionWebrtc *webRtcConnection = (TLPhoneConnection$phoneConnectionWebrtc *)connection;
                    webRtcConnectionCount++;
                    TGLog(@"IOS6CALL confirmed.webrtc id=%lld flags=%d turn=%d stun=%d ip=%@ ipv6=%@ port=%d user=%@ passLen=%d",
                          webRtcConnection.n_id,
                          webRtcConnection.flags,
                          (webRtcConnection.flags & (1 << 0)) ? 1 : 0,
                          (webRtcConnection.flags & (1 << 1)) ? 1 : 0,
                          webRtcConnection.ip,
                          webRtcConnection.ipv6,
                          webRtcConnection.port,
                          webRtcConnection.username,
                          (int)webRtcConnection.password.length);
                    if (webRtcConnection.port != 0 && (webRtcConnection.ip.length != 0 || webRtcConnection.ipv6.length != 0)) {
                        [webrtcConnections addObject:[[TGCallWebrtcConnectionDescription alloc] initWithIdentifier:webRtcConnection.n_id flags:webRtcConnection.flags ipv4:webRtcConnection.ip ipv6:webRtcConnection.ipv6 port:webRtcConnection.port username:webRtcConnection.username password:webRtcConnection.password]];
                    } else {
                        TGLog(@"IOS6CALL confirmed.webrtc.skipBad id=%lld ip=%@ ipv6=%@ port=%d", webRtcConnection.n_id, webRtcConnection.ip, webRtcConnection.ipv6, webRtcConnection.port);
                    }
                    return nil;
                }
                TGLog(@"IOS6CALL confirmed.connection.skip class=%@", NSStringFromClass([connection class]));
                return nil;
            };
            
            NSMutableArray *allConnections = [[NSMutableArray alloc] init];
            
            TGCallConnectionDescription *legacyDefaultConnection = deserializeConnection(concreteCall.connection);
            if (legacyDefaultConnection != nil)
                [allConnections addObject:legacyDefaultConnection];
            
            for (id connection in concreteCall.alternative_connections) {
                TGCallConnectionDescription *callConnection = deserializeConnection(connection);
                if (callConnection != nil)
                    [allConnections addObject:callConnection];
            }
            
            for (id connection in concreteCall.connections) {
                TGCallConnectionDescription *callConnection = deserializeConnection(connection);
                if (callConnection != nil)
                    [allConnections addObject:callConnection];
            }
            
            TGCallConnectionDescription *defaultConnection = nil;
            NSMutableArray *alternativeConnections = [[NSMutableArray alloc] init];
            if (allConnections.count != 0) {
                defaultConnection = [allConnections objectAtIndex:0];
                for (NSUInteger i = 1; i < allConnections.count; i++)
                    [alternativeConnections addObject:[allConnections objectAtIndex:i]];
            }
            TGLog(@"IOS6CALL confirmed.deserialized default=%@ alt=%d total=%d", defaultConnection, (int)alternativeConnections.count, (int)allConnections.count);
            TGLog(@"IOS6CALL webrtc.required call=%lld webRtcConnections=%d legacyConnections=%d hasTgCallsEngine=0 legacyFallback=1",
                  concreteCall.n_id,
                  webRtcConnectionCount,
                  (int)allConnections.count);
            TGLog(@"IOS6CALL webrtc.context.ready call=%lld storedWebRtc=%d customParametersLen=%d", concreteCall.n_id, (int)webrtcConnections.count, (int)customParameters.length);

            return [SSignal single:[[TGCallOngoingContext alloc] initWithCallId:callId accessHash:accessHash date:concreteCall.date adminId:concreteCall.admin_id participantId:concreteCall.participant_id key:key keyFingerprint:keyId defaultConnection:defaultConnection alternativeConnections:alternativeConnections webrtcConnections:webrtcConnections customParameters:customParameters]];
        }
        else if ([result.phone_call isKindOfClass:[TLPhoneCall$phoneCallDiscardedMeta class]]) {
            TLPhoneCall$phoneCallDiscardedMeta *concreteCall = (TLPhoneCall$phoneCallDiscardedMeta *)result.phone_call;
            bool needsRating = concreteCall.flags & (1 << 2);
            bool needsDebug = concreteCall.flags & (1 << 3);
            TGCallDiscardedContext *callContext = [[TGCallDiscardedContext alloc] initWithCallId:concreteCall.n_id reason:[TGCallDiscardReasonAdapter reasonForTLObject:concreteCall.reason] outside:true needsRating:needsRating needsDebug:needsDebug error:nil];
            return [SSignal single:callContext];
        } else {
            return [SSignal fail:nil];
        }
    }];
}

+ (SSignal *)sendSignalingDataForCallId:(int64_t)callId accessHash:(int64_t)accessHash data:(NSData *)data {
    if (data.length == 0) {
        TGLog(@"IOS6CALL signaling.send.skipEmpty call=%lld", callId);
        return [SSignal complete];
    }
    
    TLRPCphone_sendSignalingData$phone_sendSignalingData *sendSignalingData = [[TLRPCphone_sendSignalingData$phone_sendSignalingData alloc] init];
    TLInputPhoneCall$inputPhoneCall *inputPhoneCall = [[TLInputPhoneCall$inputPhoneCall alloc] init];
    inputPhoneCall.n_id = callId;
    inputPhoneCall.access_hash = accessHash;
    sendSignalingData.peer = inputPhoneCall;
    sendSignalingData.data = data;
    
    TGLog(@"IOS6CALL signaling.send call=%lld access=%lld dataLen=%d", callId, accessHash, (int)data.length);
    return [[[TGTelegramNetworking instance] requestSignal:sendSignalingData] map:^id(id result) {
        TGLog(@"IOS6CALL signaling.send.result call=%lld result=%@", callId, NSStringFromClass([result class]));
        return result;
    }];
}

+ (SSignal *)_reportCallRatingWithCallId:(int64_t)callId accessHash:(int64_t)accessHash rating:(int32_t)rating comment:(NSString *)comment {
    TLRPCphone_setCallRating$phone_setCallRating *setCallRating = [[TLRPCphone_setCallRating$phone_setCallRating alloc] init];
    TLInputPhoneCall$inputPhoneCall *inputCall = [[TLInputPhoneCall$inputPhoneCall alloc] init];
    inputCall.n_id = callId;
    inputCall.access_hash = accessHash;
    setCallRating.peer = inputCall;
    setCallRating.rating = rating;
    setCallRating.comment = comment;
    return [[TGTelegramNetworking instance] requestSignal:setCallRating];
}

+ (SSignal *)reportCallRatingWithCallId:(int64_t)callId accessHash:(int64_t)accessHash rating:(int32_t)rating comment:(NSString *)comment includeLogs:(bool)includeLogs
{
    int32_t voipUid = [TGTelegraphInstance createVoipSupportUserIfNeeded];
    
    SSignal *signal = [self _reportCallRatingWithCallId:callId accessHash:accessHash rating:rating comment:nil];
    if (comment.length > 0)
        signal = [signal then:[TGSendMessageSignals sendTextMessageWithPeerId:voipUid text:comment replyToMid:0]];
    
    if (includeLogs)
    {
        NSString *logsPath = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"calls"];
        NSString *logPath = [logsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld-%lld.log", callId, accessHash]];
        
        SSignal *logSignal = [SSignal complete];
        
        if (logPath.length > 0)
        {
            NSData *logData = [NSData dataWithContentsOfFile:logPath];
            if (logData != nil)
            {
                SSignal *uploadSignal = [[TGUploadFileSignals uploadedFileWithData:logData mediaTypeTag:TGNetworkMediaTypeTagDocument] map:^id(TLInputFile *file)
                {
                    return @{ @"file": file };
                }];
                
                TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] init];
                TGDocumentAttributeFilename *filename = [[TGDocumentAttributeFilename alloc] initWithFilename:[NSString stringWithFormat:@"call-%lld.log", callId]];
                documentAttachment.attributes = @[ filename ];
                documentAttachment.mimeType = @"text/plain";
                
                uploadSignal = [uploadSignal then:[TGSendMessageSignals sendMediaWithPeerId:voipUid replyToMid:0 attachment:documentAttachment uploadSignal:uploadSignal mediaProducer:^TLInputMedia *(NSDictionary *uploadInfo)
                {
                    TLInputMediaUploadedDocument *uploadedDocument = [[TLInputMediaUploadedDocument alloc] init];
                    uploadedDocument.file = uploadInfo[@"file"];
                    uploadedDocument.mime_type = @"text/plain";
                    
                    TLDocumentAttribute$documentAttributeFilename *filenameAttribute = [[TLDocumentAttribute$documentAttributeFilename alloc] init];
                    filenameAttribute.file_name = documentAttachment.fileName;
                    uploadedDocument.attributes = @[ filenameAttribute ];
                    
                    return uploadedDocument;
                }]];
                
                logSignal = uploadSignal;
            }
        }
        
        signal = [signal then:logSignal];
    }
    
    return signal;
}

+ (SSignal *)serverCallsConfig {
    return [[[TGTelegramNetworking instance] requestSignal:[[TLRPCphone_getCallConfig$phone_getCallConfig alloc] init]] map:^id(TLDataJSON *result) {
        return result.data;
    }];
}

+ (SSignal *)saveCallDebug:(int64_t)callId accessHash:(int64_t)accessHash data:(NSString *)data {
    TLRPCphone_saveCallDebug$phone_saveCallDebug *saveCallDebug = [[TLRPCphone_saveCallDebug$phone_saveCallDebug alloc] init];
    TLInputPhoneCall$inputPhoneCall *inputCall = [[TLInputPhoneCall$inputPhoneCall alloc] init];
    inputCall.n_id = callId;
    inputCall.access_hash = accessHash;
    saveCallDebug.peer = inputCall;
    TLDataJSON$dataJSON *dataJson = [[TLDataJSON$dataJSON alloc] init];
    dataJson.data = data;
    saveCallDebug.debug = dataJson;
    return [[TGTelegramNetworking instance] requestSignal:saveCallDebug];
}

@end
