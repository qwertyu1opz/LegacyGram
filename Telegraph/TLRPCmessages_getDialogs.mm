#import "TLRPCmessages_getDialogs.h"

#import "TL/TLMetaScheme.h"
#import "TLMetaClassStore.h"


@implementation TLRPCmessages_getDialogs

- (int32_t)TLconstructorSignature
{
    return 0xa0f4cb4f;
}

- (int32_t)TLconstructorName
{
    return -1;
}

- (Class)responseClass
{
    return [TLmessages_Dialogs class];
}

- (int)impliedResponseSignature
{
    return 0;
}

- (int)layerVersion
{
    return 74;
}

- (void)TLserialize:(NSOutputStream *)os
{
    [os writeInt32:self.flags];
    
    if (self.flags & (1 << 1))
        [os writeInt32:self.folder_id];
    
    [os writeInt32:self.offset_date];
    
    [os writeInt32:self.offset_id];
    
    TLMetaClassStore::serializeObject(os, self.offset_peer, true);

    [os writeInt32:self.limit];
    
    // Modern Telegram layers require hash:long after limit. Zero disables cached diff mode.
    [os writeInt64:self.hash];
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)__unused is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TGLog(@"***** TLRPCmessages_getDialogs deserialization not supported");
    return nil;
}

@end
