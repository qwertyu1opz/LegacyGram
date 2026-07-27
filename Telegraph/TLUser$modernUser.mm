#import "TLUser$modernUser.h"

#import "TLMetaClassStore.h"

static NSMutableDictionary *TGModernUserIdMap()
{
    static NSMutableDictionary *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        dict = [[NSMutableDictionary alloc] init];
    });
    return dict;
}

static NSMutableDictionary *TGLegacyUserIdMap()
{
    static NSMutableDictionary *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        dict = [[NSMutableDictionary alloc] init];
    });
    return dict;
}

int64_t TGModernUserIdForLegacyId(int32_t uid)
{
    NSNumber *value = nil;
    @synchronized(TGModernUserIdMap())
    {
        value = [TGModernUserIdMap() objectForKey:@(uid)];
    }
    return value == nil ? (int64_t)uid : [value longLongValue];
}

int32_t TGModernLegacyIdForModernId(int64_t modernUserId)
{
    NSNumber *value = nil;
    @synchronized(TGLegacyUserIdMap())
    {
        value = [TGLegacyUserIdMap() objectForKey:@(modernUserId)];
    }
    if (value != nil)
        return [value intValue];

    if (modernUserId > 0 && modernUserId <= 0x7fffffffLL)
    {
        TGRegisterModernUserId((int32_t)modernUserId, modernUserId);
        return (int32_t)modernUserId;
    }

    uint32_t mixed = (uint32_t)(modernUserId ^ (modernUserId >> 32));
    int32_t legacyId = (int32_t)(1000000000 + (mixed % 1000000000));
    TGRegisterModernUserId(legacyId, modernUserId);
    return legacyId;
}

void TGRegisterModernUserId(int32_t uid, int64_t modernUserId)
{
    if (uid == 0 || modernUserId == 0)
        return;
    @synchronized(TGModernUserIdMap())
    {
        [TGModernUserIdMap() setObject:@(modernUserId) forKey:@(uid)];
    }
    @synchronized(TGLegacyUserIdMap())
    {
        [TGLegacyUserIdMap() setObject:@(uid) forKey:@(modernUserId)];
    }
}

static int64_t TGModernUserReadEmojiStatusDocumentId(NSInputStream *is, int32_t signature, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    if (signature == (int32_t)0x2de11aae)
        return 0;
    if (signature == (int32_t)0xe7ff068a)
    {
        int32_t flags = [is readInt32];
        int64_t documentId = [is readInt64];
        if (flags & (1 << 0))
            [is readInt32];
        return documentId;
    }
    if (signature == (int32_t)0x7184603b)
    {
        int32_t flags = [is readInt32];
        [is readInt64];
        int64_t documentId = [is readInt64];
        [is readString];
        [is readString];
        [is readInt64];
        [is readInt32]; [is readInt32]; [is readInt32]; [is readInt32];
        if (flags & (1 << 0))
            [is readInt32];
        return documentId;
    }
    TLMetaClassStore::constructObject(is, signature, environment, nil, error);
    return 0;
}

static void TGModernUserSkipObjectVector(NSInputStream *is, id<TLSerializationEnvironment> environment, __autoreleasing NSError **error)
{
    int32_t vectorMarker = [is readInt32];
    if (vectorMarker != 0x1cb5c415)
        return;
    
    int32_t count = [is readInt32];
    for (int32_t i = 0; i < count; i++)
    {
        TLMetaClassStore::constructObject(is, [is readInt32], environment, nil, error);
        if (error != nil && *error != nil)
            return;
    }
}

@implementation TLUser$modernUser

- (void)TLserialize:(NSOutputStream *)__unused os
{
    TGLog(@"***** TLUser$modernUser serialization not supported");
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)signature environment:(id<TLSerializationEnvironment>)environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)error
{
    TLUser$modernUser *object = [[TLUser$modernUser alloc] init];
    
    object.flags = [is readInt32];
    int32_t flags2 = 0;
    bool hasModernFlags2 = signature == (int32_t)0x4b46c37e || signature == (int32_t)0xb1b8cc83 || signature == (int32_t)0x31774388 || signature == (int32_t)0x83314fca || signature == (int32_t)0x215c4438 || signature == (int32_t)0x2813e6db || signature == (int32_t)0x1afeb7ac || signature == (int32_t)0xd0a1d008;
    bool isModernLongUser = signature == (int32_t)0x4b46c37e || signature == (int32_t)0xb1b8cc83 || signature == (int32_t)0x31774388 || signature == (int32_t)0x83314fca || signature == (int32_t)0x215c4438 || signature == (int32_t)0x2813e6db || signature == (int32_t)0x1afeb7ac || signature == (int32_t)0xd0a1d008;
    if (hasModernFlags2)
        flags2 = [is readInt32];
    
    object.n_id_long = isModernLongUser ? [is readInt64] : [is readInt32];
    object.n_id = TGModernLegacyIdForModernId(object.n_id_long);
    TGRegisterModernUserId(object.n_id, object.n_id_long);
    
    if (object.flags & (1 << 0))
        object.access_hash = [is readInt64];
    
    if (object.flags & (1 << 1))
    {
        object.first_name = [is readString];
    }
    if (object.flags & (1 << 2))
    {
        object.last_name = [is readString];
    }
    
    if (object.flags & (1 << 3))
    {
        object.username = [is readString];
    }
    
    if (object.flags & (1 << 4))
    {
        object.phone = [is readString];
    }
    
    if (object.flags & (1 << 5))
    {
        int32_t signature = [is readInt32];
        object.photo = TLMetaClassStore::constructObject(is, signature, environment, nil, error);
        if (error != nil && *error != nil) {
            TGLog(@"IOS6AUTH modernUser id=%d photo failed sig=0x%x error=%@", object.n_id, signature, *error);
            return nil;
        }
    }
    
    if (object.flags & (1 << 6))
    {
        int32_t signature = [is readInt32];
        object.status = TLMetaClassStore::constructObject(is, signature, environment, nil, error);
        if (error != nil && *error != nil) {
            TGLog(@"IOS6AUTH modernUser id=%d status failed sig=0x%x error=%@", object.n_id, signature, *error);
            return nil;
        }
    }
    
    if (object.flags & (1 << 14))
        object.bot_info_version = [is readInt32];
    
    if (object.flags & (1 << 18))
    {
        if (isModernLongUser)
        {
            TGModernUserSkipObjectVector(is, environment, error);
            if (error != nil && *error != nil)
                return nil;
        }
        else
            object.restriction_reason = [is readString];
    }
    
    if (object.flags & (1 << 19)) {
        object.inlineBotPlaceholder = [is readString];
    }
    
    if (object.flags & (1 << 22)) {
        __unused NSString *langCode = [is readString];
    }
    
    if (hasModernFlags2 && (object.flags & (1 << 30)))
    {
        int32_t signature = [is readInt32];
        object.emojiStatusDocumentId = TGModernUserReadEmojiStatusDocumentId(is, signature, environment, error);
        if (error != nil && *error != nil)
        {
            TGLog(@"IOS6AUTH modernUser id=%d emoji_status failed sig=0x%x error=%@", object.n_id, signature, *error);
            return nil;
        }
    }
    
    if (hasModernFlags2 && (flags2 & (1 << 0)))
    {
        TGModernUserSkipObjectVector(is, environment, error);
        if (error != nil && *error != nil)
            return nil;
    }
    bool codexReadModernStoriesMaxId = false;
    if (signature == (int32_t)0x31774388)
        codexReadModernStoriesMaxId = hasModernFlags2 && (flags2 & (1 << 5));
    else if (signature == (int32_t)0x215c4438)
    {
        bool hasNewStoriesMaxId = (flags2 & (1 << 5));
        codexReadModernStoriesMaxId = hasNewStoriesMaxId;
    }
    else
        codexReadModernStoriesMaxId = hasModernFlags2 && (flags2 & (1 << 5));
    
    if (codexReadModernStoriesMaxId)
    {
        if (signature == (int32_t)0x2813e6db || signature == (int32_t)0x1afeb7ac || signature == (int32_t)0xd0a1d008)
        {
            int32_t recentStorySignature = [is readInt32];
            TLMetaClassStore::constructObject(is, recentStorySignature, environment, nil, error);
            if (error != nil && *error != nil)
            {
                TGLog(@"IOS6AUTH modernUser id=%d recent_story failed sig=0x%x error=%@", object.n_id, recentStorySignature, *error);
                return nil;
            }
        }
        else
        {
            if (signature == (int32_t)0x31774388)
            {
                int32_t recentStorySignature = [is readInt32];
                TLMetaClassStore::constructObject(is, recentStorySignature, environment, nil, error);
                if (error != nil && *error != nil)
                {
                    TGLog(@"IOS6AUTH modernUser id=%d recent_story failed sig=0x%x error=%@", object.n_id, recentStorySignature, *error);
                    return nil;
                }
            }
            else
            {
                int32_t storiesMaxId = [is readInt32];
            }
        }
    }
    if (hasModernFlags2 && (flags2 & (1 << 8)))
    {
        int32_t signature = [is readInt32];
        if (signature == 0)
        {
        }
        else
        {
            TLMetaClassStore::constructObject(is, signature, environment, nil, error);
            if (error != nil && *error != nil)
            {
                TGLog(@"IOS6AUTH modernUser id=%d color failed sig=0x%x error=%@", object.n_id, signature, *error);
                return nil;
            }
        }
    }
    if (hasModernFlags2 && (flags2 & (1 << 9)))
    {
        int32_t signature = [is readInt32];
        if (signature == 0)
        {
        }
        else
        {
            TLMetaClassStore::constructObject(is, signature, environment, nil, error);
            if (error != nil && *error != nil)
            {
                TGLog(@"IOS6AUTH modernUser id=%d profile_color failed sig=0x%x error=%@", object.n_id, signature, *error);
                return nil;
            }
        }
    }
    if (hasModernFlags2 && (flags2 & (1 << 12)))
        [is readInt32];
    if (hasModernFlags2 && (flags2 & (1 << 14)))
        [is readInt64];
    if (hasModernFlags2 && (flags2 & (1 << 15)))
        [is readInt64];
    // In user#31774388 flags2.20 is not a serialized field. Reading a long
    // here consumed the next constructor and corrupted the enclosing vector.
    if (signature == (int32_t)0xb1b8cc83 && (flags2 & (1 << 21)))
        [is readInt64];
    
    return object;
}

@end
