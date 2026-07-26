#import "TLRPCmessages_sendMessage_manual.h"

#import "TL/TLMetaScheme.h"
#import "TLMetaClassStore.h"

@implementation TLRPCmessages_sendMessage_manual

- (int32_t)TLconstructorSignature
{
    return 0xFA88427A;
}

- (int32_t)TLconstructorName
{
    return -1;
}

- (Class)responseClass
{
    return [TLUpdates class];
}

- (int)impliedResponseSignature
{
    return 0;
}

- (int)layerVersion
{
    return 26;
}

- (void)TLserialize:(NSOutputStream *)os
{
    [os writeInt32:_flags];
    
    TLMetaClassStore::serializeObject(os, _peer, true);
    
    if (_flags & (1 << 0))
        [os writeInt32:_reply_to_msg_id];
    
    [os writeString:_message];
    [os writeInt64:_random_id];
    
    if (_flags & (1 << 3)) {
        int32_t vectorSignature = TL_UNIVERSAL_VECTOR_CONSTRUCTOR;
        [os writeInt32:vectorSignature];
        
        [os writeInt32:(int32_t)_entities.count];
        for (TLMessageEntity *entity in _entities) {
            TLMetaClassStore::serializeObject(os, entity, true);
        }
    }
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)__unused is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TGLog(@"***** TLRPCmessages_sendMessage_manual deserialization not supported");
    return nil;
}

@end

@implementation TLRPCmessages_sendReaction_manual

- (int32_t)TLconstructorSignature
{
    return (int32_t)0xd30d78d4;
}

- (int32_t)TLconstructorName
{
    return -1;
}

- (Class)responseClass
{
    return [TLUpdates class];
}

- (int)impliedResponseSignature
{
    return 0;
}

- (int)layerVersion
{
    return 26;
}

- (void)TLserialize:(NSOutputStream *)os
{
    int32_t flags = _flags;
    if (_reaction.length != 0)
        flags |= (1 << 0);

    [os writeInt32:flags];
    TLMetaClassStore::serializeObject(os, _peer, true);
    [os writeInt32:_msg_id];

    if (flags & (1 << 0))
    {
        [os writeInt32:TL_UNIVERSAL_VECTOR_CONSTRUCTOR];
        [os writeInt32:1];
        [os writeInt32:(int32_t)0x1b2286b8]; // reactionEmoji
        [os writeString:_reaction];
    }
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)__unused is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    return nil;
}

@end
