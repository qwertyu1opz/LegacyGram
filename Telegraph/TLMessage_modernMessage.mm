#import "TLMessage$modernMessage.h"

#import "TLMetaClassStore.h"
#import "TLPeer.h"

//message flags:# out:flags.1?true mentioned:flags.4?true media_unread:flags.5?true silent:flags.13?true post:flags.14?true id:int from_id:flags.8?int to_id:Peer fwd_from:flags.2?MessageFwdHeader via_bot_id:flags.11?int reply_to_msg_id:flags.3?int date:int message:string media:flags.9?MessageMedia reply_markup:flags.6?ReplyMarkup entities:flags.7?Vector<MessageEntity> views:flags.10?int edit_date:flags.15?int post_author:flags.16?string grouped_id:flags.17?long = Message;

static id<TLObject> TGModernReadObject(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t signature = [is readInt32];
    id<TLObject> object = TLMetaClassStore::constructObject(is, signature, environment, nil, error);
    if (error != nil && *error != nil)
        TGLog(@"IOS6MSG readObject failed signature=0x%08x error=%@", signature, *error);
    return object;
}

static NSArray *TGModernReadObjectVector(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
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
        id object = TGModernReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
        if (object != nil)
            [objects addObject:object];
    }
    return objects;
}

static NSString *TGModernReadReactionSummary(NSInputStream *is, id<TLSerializationEnvironment> environment, NSString **chosenReaction, __autoreleasing NSError **error)
{
    if (chosenReaction != NULL)
        *chosenReaction = nil;
    int32_t signature = [is readInt32];
    if (signature != (int32_t)0x0a339f0b && signature != (int32_t)0xdaad85b0 && signature != (int32_t)0x4f2b9479)
    {
        TLMetaClassStore::constructObject(is, signature, environment, nil, error);
        return nil;
    }

    int32_t flags = [is readInt32];
    int32_t vectorSignature = [is readInt32];
    if (vectorSignature != (int32_t)0x1cb5c415)
    {
        if (error != nil)
            *error = [[NSError alloc] initWithDomain:@"TL" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid reaction results vector"}];
        return nil;
    }

    int32_t count = [is readInt32];
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    for (int32_t i = 0; i < count; i++)
    {
        int32_t countSignature = [is readInt32];
        if (countSignature != (int32_t)0xa3d1cb80)
        {
            TLMetaClassStore::constructObject(is, countSignature, environment, nil, error);
            if (error != nil && *error != nil)
                return nil;
            continue;
        }

        int32_t countFlags = [is readInt32];
        bool chosen = (countFlags & (1 << 0)) != 0;
        if (chosen)
            [is readInt32];

        int32_t reactionSignature = [is readInt32];
        NSString *emoji = nil;
        if (reactionSignature == (int32_t)0x1b2286b8)
            emoji = [is readString];
        else if (reactionSignature == (int32_t)0x8935fc73)
        {
            [is readInt64];
            emoji = @"◆";
        }
        else if (reactionSignature == (int32_t)0x523da4eb)
            emoji = @"★";
        else if (reactionSignature != (int32_t)0x79f5d419)
            TLMetaClassStore::constructObject(is, reactionSignature, environment, nil, error);

        int32_t reactionCount = [is readInt32];
        if (chosen && emoji.length != 0 && chosenReaction != NULL)
            *chosenReaction = emoji;
        if (emoji.length != 0 && reactionCount > 0 && parts.count < 3)
            [parts addObject:[NSString stringWithFormat:@"%@ %d", emoji, reactionCount]];
    }

    if (flags & (1 << 1))
        TGModernReadObjectVector(is, environment, error);
    if (signature != (int32_t)0x4f2b9479 && (flags & (1 << 4)))
        TGModernReadObjectVector(is, environment, error);

    return parts.count == 0 ? nil : [parts componentsJoinedByString:@"  "];
}

static int32_t TGModernPeerLegacyId(TLPeer *peer)
{
    if ([peer isKindOfClass:[TLPeer$peerUser class]])
        return ((TLPeer$peerUser *)peer).user_id;
    if ([peer isKindOfClass:[TLPeer$peerChat class]])
        return ((TLPeer$peerChat *)peer).chat_id;
    if ([peer isKindOfClass:[TLPeer$peerChannel class]])
        return ((TLPeer$peerChannel *)peer).channel_id;
    return 0;
}

static TLPeer *TGModernReadPeerCompat(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t signature = [is readInt32];
    if (signature == (int32_t)0x59511722 || signature == (int32_t)0x36c6019a || signature == (int32_t)0xa2a5371e ||
        signature == (int32_t)0x9db1bc6d || signature == (int32_t)0xbad0e5bb || signature == (int32_t)0xbddde532)
    {
        return (TLPeer *)TLMetaClassStore::constructObject(is, signature, environment, nil, error);
    }
    
    int32_t highPeerId = [is readInt32];
    int64_t rawPeerId = (((int64_t)highPeerId) << 32) | ((uint32_t)signature);
    TGLog(@"IOS6MSG legacy raw peer_id64=%lld low=%d high=%d", rawPeerId, signature, highPeerId);
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

static int32_t TGModernReadReplyHeader(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t signature = [is readInt32];
    
    if (signature == (int32_t)0xafbc09db || signature == (int32_t)0x1b97dd66)
    {
        int32_t flags = [is readInt32];
        int32_t replyToMessageId = 0;
        if (flags & (1 << 4))
            replyToMessageId = [is readInt32];
        if (flags & (1 << 0))
            TGModernReadObject(is, environment, error);
        if (flags & (1 << 5))
            TGModernReadObject(is, environment, error);
        if (flags & (1 << 8))
            TGModernReadObject(is, environment, error);
        if (flags & (1 << 1))
            [is readInt32];
        if (flags & (1 << 6))
            [is readString];
        if (flags & (1 << 7))
            TGModernReadObjectVector(is, environment, error);
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
        TGModernReadObject(is, environment, error);
        [is readInt32];
        return 0;
    }
    else if (signature > 0 && signature < 10000000)
    {
        TGLog(@"IOS6MSG legacy reply_to_msg_id=%d", signature);
        return signature;
    }
    
    TLMetaClassStore::constructObject(is, signature, environment, nil, error);
    return 0;
}

@implementation TLMessage$modernMessage

- (void)TLserialize:(NSOutputStream *)__unused os
{
    TGLog(@"***** TLMessage$modernMessage serialization not supported");
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLMessage$modernMessage *result = [[TLMessage$modernMessage alloc] init];
    
    int32_t flags = [is readInt32];
    int32_t flags2 = 0;
    bool hasModernFlags2 = signature == (int32_t)0x94345242 || signature == (int32_t)0x7600b9d3;
    bool isLatestLongPeerMessage = signature == (int32_t)0x7600b9d3;
    if (hasModernFlags2)
        flags2 = [is readInt32];
    
    result.flags = flags;
    result.n_id = [is readInt32];
    TGLog(@"IOS6MSG message sig=0x%08x flags=0x%08x flags2=0x%08x id=%d", signature, flags, flags2, result.n_id);
    
    if (flags & (1 << 8))
    {
        if (isLatestLongPeerMessage)
        {
            TLPeer *fromPeer = (TLPeer *)TGModernReadObject(is, environment, error);
            if (error != nil && *error != nil)
                return nil;
            result.from_id = TGModernPeerLegacyId(fromPeer);
        }
        else
            result.from_id = [is readInt32];
    }
    
    if (hasModernFlags2 && (flags & (1 << 29)))
        [is readInt32];
    
    if (isLatestLongPeerMessage && (flags2 & (1 << 12)))
        [is readString];
    
    result.to_id = TGModernReadPeerCompat(is, environment, error);
    if (error != nil && *error != nil) {
        return nil;
    }
    
    if (hasModernFlags2 && (flags & (1 << 28)))
    {
        TGModernReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    
    if (flags & (1 << 2))
    {
        result.fwd_from = (TLMessageFwdHeader *)TGModernReadObject(is, environment, error);
        if (error != nil && *error != nil) {
            return nil;
        }
    }
    
    if (flags & (1 << 11))
    {
        result.via_bot_id = hasModernFlags2 ? (int32_t)[is readInt64] : [is readInt32];
    }
    
    if (hasModernFlags2 && (flags2 & (1 << 0)))
    {
        [is readInt64];
    }
    
    if (isLatestLongPeerMessage && (flags2 & (1 << 19)))
    {
        TGModernReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    
    if (flags & (1 << 3))
    {
        result.reply_to_msg_id = hasModernFlags2 ? TGModernReadReplyHeader(is, environment, error) : [is readInt32];
        if (error != nil && *error != nil)
            return nil;
    }
    
    result.date = [is readInt32];
    
    result.message = [is readString];
    
    if (flags & (1 << 9))
    {
        TGLog(@"IOS6MSG id=%d parse media", result.n_id);
        int32_t mediaSignature = [is readInt32];
        TGLog(@"IOS6MSG id=%d mediaSignature=0x%08x", result.n_id, mediaSignature);
        result.media = TLMetaClassStore::constructObject(is, mediaSignature, environment, nil, error);
        if (error != nil && *error != nil) {
            TGLog(@"IOS6MSG id=%d media failed signature=0x%08x error=%@", result.n_id, mediaSignature, *error);
            return nil;
        }
    }
    
    if (flags & (1 << 6))
    {
        int32_t replyMarkupSignature = [is readInt32];
        result.reply_markup = TLMetaClassStore::constructObject(is, replyMarkupSignature, environment, nil, error);
        if (error != nil && *error != nil) {
            return nil;
        }
    }
    
    if (flags & (1 << 7))
    {
        __unused int32_t entitiesSignature = [is readInt32];
        int32_t count = [is readInt32];
        NSMutableArray *entities = [[NSMutableArray alloc] init];
        for (int32_t i = 0; i < count; i++)
        {
            int32_t signature = [is readInt32];
            id entity = TLMetaClassStore::constructObject(is, signature, environment, nil, error);
            if (error != nil && *error != nil) {
                return nil;
            }
            if (entity != nil)
                [entities addObject:entity];
        }
        result.entities = entities;
    }
    
    if (flags & (1 << 10)) {
        result.views = [is readInt32];
        if (hasModernFlags2)
            [is readInt32];
    }
    
    if (hasModernFlags2 && (flags & (1 << 23))) {
        TGModernReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    
    if (flags & (1 << 15)) {
        result.edit_date = [is readInt32];
    }
    
    if (flags & (1 << 16)) {
        result.post_author = [is readString];
    }
    
    if (flags & (1 << 17)) {
        result.grouped_id = [is readInt64];
    }
    
    if (hasModernFlags2 && (flags & (1 << 20))) {
        TGLog(@"IOS6MSG id=%d parse reactions", result.n_id);
        NSString *chosenReaction = nil;
        result.reactionSummary = TGModernReadReactionSummary(is, environment, &chosenReaction, error);
        result.chosenReaction = chosenReaction;
        if (error != nil && *error != nil)
            return nil;
    }
    
    if (hasModernFlags2 && (flags & (1 << 22))) {
        TGModernReadObjectVector(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    
    if (hasModernFlags2 && (flags & (1 << 25)))
        [is readInt32];
    
    if (hasModernFlags2 && (flags & (1 << 30)))
        [is readInt32];
    
    if (hasModernFlags2 && (flags2 & (1 << 2)))
        [is readInt64];
    
    if (hasModernFlags2 && (flags2 & (1 << 3))) {
        TGLog(@"IOS6MSG id=%d parse factcheck", result.n_id);
        TGModernReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    
    if (isLatestLongPeerMessage && (flags2 & (1 << 5)))
        [is readInt32];
    
    if (isLatestLongPeerMessage && (flags2 & (1 << 6)))
        [is readInt64];
    
    if (isLatestLongPeerMessage && (flags2 & (1 << 7))) {
        TGModernReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    
    if (isLatestLongPeerMessage && (flags2 & (1 << 10)))
        [is readInt32];
    
    if (isLatestLongPeerMessage && (flags2 & (1 << 11)))
        [is readString];
    
    if (isLatestLongPeerMessage && (flags2 & (1 << 13))) {
        TGModernReadObject(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    
    return result;
}

@end
