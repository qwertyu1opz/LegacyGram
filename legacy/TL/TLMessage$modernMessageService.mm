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

static int32_t TGModernServiceReadReplyHeader(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t signature = [is readInt32];
    if (signature == (int32_t)0xafbc09db)
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
        return replyToMessageId;
    }
    else if (signature == (int32_t)0x0e5af939)
    {
        TGModernServiceReadObject(is, environment, error);
        [is readInt32];
        return 0;
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
    bool isLayer181MessageService = signature == (int32_t)0x2b085862;
    
    result.flags = flags;
    result.n_id = [is readInt32];
    
    if (flags & (1 << 8))
    {
        if (isLayer181MessageService)
        {
            TLPeer *fromPeer = (TLPeer *)TGModernServiceReadObject(is, environment, error);
            if (error != nil && *error != nil)
                return nil;
            result.from_id = TGModernServicePeerLegacyId(fromPeer);
        }
        else
            result.from_id = [is readInt32];
    }
    
    result.to_id = (TLPeer *)TGModernServiceReadObject(is, environment, error);
    if (error != nil && *error != nil) {
        return nil;
    }
    
    if (flags & (1 << 3)) {
        result.reply_to_msg_id = isLayer181MessageService ? TGModernServiceReadReplyHeader(is, environment, error) : [is readInt32];
        if (error != nil && *error != nil)
            return nil;
    }
    
    result.date = [is readInt32];
    
    int32_t actionSignature = [is readInt32];
    if (isLayer181MessageService && actionSignature == (int32_t)0x80e11a7f)
    {
        int32_t actionFlags = [is readInt32];
        [is readInt64];
        if (actionFlags & (1 << 0))
            [is readInt32];
        if (actionFlags & (1 << 1))
            [is readInt32];
        result.action = [[TLMessageAction$messageActionEmpty alloc] init];
    }
    else if (isLayer181MessageService && actionSignature == (int32_t)0xcc02aa6d)
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
    
    if (isLayer181MessageService && (flags & (1 << 25)))
        [is readInt32];
    
    return result;
}


@end
