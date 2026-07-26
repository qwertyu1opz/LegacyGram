#import "TLMessage$modernMessageService.h"

#import "TLMetaClassStore.h"
#import "TLMessageAction.h"
#import "TLPeer.h"

//messageService flags:# out:flags.1?true mentioned:flags.4?true media_unread:flags.5?true silent:flags.13?true post:flags.14?true id:int from_id:flags.8?int to_id:Peer date:int action:MessageAction = Message;

static id<TLObject> TGModernServiceReadObject(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t signature = [is readInt32];
    return TLMetaClassStore::constructObject(is, signature, environment, nil, error);
}

static NSArray *TGModernServiceReadObjectVector(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t vectorSignature = [is readInt32];
    if (vectorSignature != (int32_t)0x1cb5c415)
    {
        if (error != nil)
            *error = [[NSError alloc] initWithDomain:@"TL" code:-1 userInfo:@{NSLocalizedDescriptionKey: [[NSString alloc] initWithFormat:@"Expected vector, got 0x%08x", vectorSignature]}];
        return nil;
    }
    
    int32_t count = [is readInt32];
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    for (int32_t i = 0; i < count; i++)
    {
        id object = TGModernServiceReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
        if (object != nil)
            [objects addObject:object];
    }
    return objects;
}

static int32_t TGModernServicePeerLegacyId(TLPeer *peer)
{
    if ([peer isKindOfClass:[TLPeer$peerUser class]])
        return ((TLPeer$peerUser *)peer).user_id;
    if ([peer isKindOfClass:[TLPeer$peerChat class]])
        return ((TLPeer$peerChat *)peer).chat_id;
    if ([peer isKindOfClass:[TLPeer$peerChannel class]])
        return ((TLPeer$peerChannel *)peer).channel_id;
    return 0;
}

static TLPeer *TGModernServiceReadPeerCompat(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t signature = [is readInt32];
    if (signature == (int32_t)0x59511722 || signature == (int32_t)0x36c6019a || signature == (int32_t)0xa2a5371e ||
        signature == (int32_t)0x9db1bc6d || signature == (int32_t)0xbad0e5bb || signature == (int32_t)0xbddde532)
    {
        return (TLPeer *)TLMetaClassStore::constructObject(is, signature, environment, nil, error);
    }
    
    int32_t highPeerId = [is readInt32];
    int64_t rawPeerId = (((int64_t)highPeerId) << 32) | ((uint32_t)signature);
    TGLog(@"IOS6MSG legacy service raw peer_id64=%lld low=%d high=%d", rawPeerId, signature, highPeerId);
    if (rawPeerId < 0)
    {
        TLPeer$peerChannel *peer = [[TLPeer$peerChannel alloc] init];
        peer.channel_id = (int32_t)-rawPeerId;
        return peer;
    }
    else
    {
        TLPeer$peerUser *peer = [[TLPeer$peerUser alloc] init];
        peer.user_id = (int32_t)rawPeerId;
        return peer;
    }
}

static int32_t TGModernServiceReadReplyHeader(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t signature = [is readInt32];
    if (signature == (int32_t)0xafbc09db || signature == (int32_t)0x1b97dd66)
    {
        int32_t flags = [is readInt32];
        int32_t replyToMessageId = 0;
        if (flags & (1 << 4))
            replyToMessageId = [is readInt32];
        if (flags & (1 << 0))
            TGModernServiceReadObject(is, environment, error);
        if (flags & (1 << 5))
            TGModernServiceReadObject(is, environment, error);
        if (flags & (1 << 8))
            TGModernServiceReadObject(is, environment, error);
        if (flags & (1 << 1))
            [is readInt32];
        if (flags & (1 << 6))
            [is readString];
        if (flags & (1 << 7))
            TGModernServiceReadObjectVector(is, environment, error);
        if (flags & (1 << 10))
            [is readInt32];
        if (signature == (int32_t)0x1b97dd66 && (flags & (1 << 11)))
            [is readInt32];
        if (signature == (int32_t)0x1b97dd66 && (flags & (1 << 12)))
            [is readBytes];
        return replyToMessageId;
    }
    else if (signature == (int32_t)0x0e5af939)
    {
        TGModernServiceReadObject(is, environment, error);
        [is readInt32];
        return 0;
    }
    else if (signature > 0 && signature < 10000000)
    {
        TGLog(@"IOS6MSG legacy service reply_to_msg_id=%d", signature);
        return signature;
    }
    
    TLMetaClassStore::constructObject(is, signature, environment, nil, error);
    return 0;
}

@implementation TLMessage$modernMessageService

- (void)TLserialize:(NSOutputStream *)__unused os
{
    TGLog(@"***** TLMessage$modernMessageService serialization not supported");
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLMessage$modernMessageService *result = [[TLMessage$modernMessageService alloc] init];
    
    int32_t flags = [is readInt32];
    bool isModernMessageService = signature == (int32_t)0x2b085862 || signature == (int32_t)0x7a800e0a;
    
    result.flags = flags;
    result.n_id = [is readInt32];
    
    if (flags & (1 << 8))
    {
        if (isModernMessageService)
        {
            TLPeer *fromPeer = (TLPeer *)TGModernServiceReadObject(is, environment, error);
            if (error != nil && *error != nil)
                return nil;
            result.from_id = TGModernServicePeerLegacyId(fromPeer);
        }
        else
            result.from_id = [is readInt32];
    }
    
    result.to_id = TGModernServiceReadPeerCompat(is, environment, error);
    if (error != nil && *error != nil) {
        return nil;
    }
    
    if (isModernMessageService && (flags & (1 << 28)))
    {
        TGModernServiceReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    
    if (flags & (1 << 3)) {
        result.reply_to_msg_id = isModernMessageService ? TGModernServiceReadReplyHeader(is, environment, error) : [is readInt32];
        if (error != nil && *error != nil)
            return nil;
    }
    
    result.date = [is readInt32];
    
    int32_t actionSignature = [is readInt32];
    if (isModernMessageService && actionSignature == (int32_t)0x80e11a7f)
    {
        int32_t actionFlags = [is readInt32];
        [is readInt64];
        if (actionFlags & (1 << 0))
            [is readInt32];
        if (actionFlags & (1 << 1))
            [is readInt32];
        result.action = [[TLMessageAction$messageActionEmpty alloc] init];
    }
    else if (isModernMessageService && actionSignature == (int32_t)0xcc02aa6d)
    {
        [is readInt32];
        result.action = [[TLMessageAction$messageActionEmpty alloc] init];
    }
    else
    {
        result.action = TLMetaClassStore::constructObject(is, actionSignature, environment, nil, error);
        if (error != nil && *error != nil) {
            return nil;
        }
    }
    
    if (isModernMessageService && (flags & (1 << 20)))
    {
        TGModernServiceReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    
    if (isModernMessageService && (flags & (1 << 25)))
        [is readInt32];
    
    return result;
}


@end
