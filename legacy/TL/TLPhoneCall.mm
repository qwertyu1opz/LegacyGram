#import "TLPhoneCall.h"

#import "../NSInputStream+TL.h"
#import "../NSOutputStream+TL.h"

#import "TLPhoneCallProtocol.h"
#import "TLPhoneCallDiscardReason.h"
#import "TLPhoneConnection.h"

static NSArray *IOS6PhoneCallConnectionsFromMetaObject(std::shared_ptr<TLMetaObject> metaObject)
{
    if (!metaObject || !metaObject->values)
        return nil;
    
    Class arrayClass = [NSArray class];
    Class phoneConnectionClass = [TLPhoneConnection class];
    
    for (size_t i = 0; i < metaObject->values->size(); i++)
    {
        TLConstructedValue value = metaObject->values->at(i);
        if (value.type != TLConstructedValueTypeVector)
            continue;
        
        id nativeObject = value.nativeObject;
        if (nativeObject == nil || ![nativeObject isKindOfClass:arrayClass])
            continue;
        
        NSArray *array = (NSArray *)nativeObject;
        for (id item in array)
        {
            if ([item isKindOfClass:phoneConnectionClass])
            {
                TGLog(@"IOS6CALL fullPhoneCall.connections.vector index=%d count=%d", (int)i, (int)array.count);
                return array;
            }
        }
    }
    
    return nil;
}

@implementation TLPhoneCall


- (int32_t)TLconstructorSignature
{
    TGLog(@"constructorSignature is not implemented for base type");
    return 0;
}

- (int32_t)TLconstructorName
{
    TGLog(@"constructorName is not implemented for base type");
    return 0;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)__unused metaObject
{
    int32_t flags = metaObject->getInt32((int32_t)0x81915c23);
    int64_t callId = metaObject->getInt64((int32_t)0x7a5601fb);
    int64_t accessHash = metaObject->getInt64((int32_t)0x8f305224);
    int32_t date = metaObject->getInt32((int32_t)0xb76958ba);
    int32_t adminId = (int32_t)metaObject->getInt64((int32_t)0xdf3d1ee7);
    int32_t participantId = (int32_t)metaObject->getInt64((int32_t)0x9abadf01);
    TLPhoneCallProtocol *protocol = metaObject->getObject((int32_t)0xd45aa5f2);
    
    NSData *gAHash = metaObject->getBytes((int32_t)0xb39b1140);
    if (gAHash != nil)
    {
        TLPhoneCall$phoneCallRequested *object = [[TLPhoneCall$phoneCallRequested alloc] init];
        object.flags = flags;
        object.n_id = callId;
        object.access_hash = accessHash;
        object.date = date;
        object.admin_id = adminId;
        object.participant_id = participantId;
        object.g_a_hash = gAHash;
        object.protocol = protocol;
        TGLog(@"IOS6CALL baseParsed requested call=%lld", object.n_id);
        return object;
    }
    
    NSData *gB = metaObject->getBytes((int32_t)0x5643e234);
    if (gB != nil)
    {
        TLPhoneCall$phoneCallAccepted *object = [[TLPhoneCall$phoneCallAccepted alloc] init];
        object.flags = flags;
        object.n_id = callId;
        object.access_hash = accessHash;
        object.date = date;
        object.admin_id = adminId;
        object.participant_id = participantId;
        object.g_b = gB;
        object.protocol = protocol;
        TGLog(@"IOS6CALL baseParsed accepted call=%lld", object.n_id);
        return object;
    }
    
    NSData *gAOrB = metaObject->getBytes((int32_t)0x817dfd4a);
    if (gAOrB != nil)
    {
        TLPhoneCall$phoneCall *object = [[TLPhoneCall$phoneCall alloc] init];
        object.flags = flags;
        object.n_id = callId;
        object.access_hash = accessHash;
        object.date = date;
        object.admin_id = adminId;
        object.participant_id = participantId;
        object.g_a_or_b = gAOrB;
        object.key_fingerprint = metaObject->getInt64((int32_t)0x3633de43);
        object.protocol = protocol;
        object.connection = metaObject->getObject((int32_t)0xb5b12f84);
        object.alternative_connections = metaObject->getArray((int32_t)0x39153642);
        object.connections = IOS6PhoneCallConnectionsFromMetaObject(metaObject);
        object.start_date = metaObject->getInt32((int32_t)0x1c46df41);
        TGLog(@"IOS6CALL baseParsed full call=%lld legacyAlt=%d modernConnections=%d", object.n_id, (int)object.alternative_connections.count, (int)object.connections.count);
        return object;
    }
    
    id reason = metaObject->getObject((int32_t)0x3405f57);
    int32_t duration = metaObject->getInt32((int32_t)0xac00f752);
    if (reason != nil || duration != 0 || (flags & ((1 << 0) | (1 << 1) | (1 << 2) | (1 << 3))) != 0)
    {
        TLPhoneCall$phoneCallDiscardedMeta *object = [[TLPhoneCall$phoneCallDiscardedMeta alloc] init];
        object.flags = flags;
        object.n_id = callId;
        object.reason = reason;
        object.duration = duration;
        TGLog(@"IOS6CALL baseParsed discarded call=%lld", object.n_id);
        return object;
    }
    
    TLPhoneCall$phoneCallWaitingMeta *object = [[TLPhoneCall$phoneCallWaitingMeta alloc] init];
    object.flags = flags;
    object.n_id = callId;
    object.access_hash = accessHash;
    object.date = date;
    object.admin_id = adminId;
    object.participant_id = participantId;
    object.protocol = protocol;
    object.receive_date = metaObject->getInt32((int32_t)0xeedcab88);
    TGLog(@"IOS6CALL baseParsed waiting call=%lld", object.n_id);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)__unused values
{
    TGLog(@"TLfillFieldsWithValues is not implemented for base type");
}


@end

@implementation TLPhoneCall$phoneCallEmpty : TLPhoneCall


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x5366c915;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xc76344fc;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)metaObject
{
    TLPhoneCall$phoneCallEmpty *object = [[TLPhoneCall$phoneCallEmpty alloc] init];
    object.n_id = metaObject->getInt64((int32_t)0x7a5601fb);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt64;
        value.primitive.int64Value = self.n_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x7a5601fb, value));
    }
}


@end

@implementation TLPhoneCall$phoneCallWaitingMeta : TLPhoneCall


- (int32_t)TLconstructorSignature
{
    return (int32_t)0xc5226f17;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xdc7555ab;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)metaObject
{
    TLPhoneCall$phoneCallWaitingMeta *object = [[TLPhoneCall$phoneCallWaitingMeta alloc] init];
    object.flags = metaObject->getInt32((int32_t)0x81915c23);
    object.n_id = metaObject->getInt64((int32_t)0x7a5601fb);
    object.access_hash = metaObject->getInt64((int32_t)0x8f305224);
    object.date = metaObject->getInt32((int32_t)0xb76958ba);
    object.admin_id = (int32_t)metaObject->getInt64((int32_t)0xdf3d1ee7);
    object.participant_id = (int32_t)metaObject->getInt64((int32_t)0x9abadf01);
    object.protocol = metaObject->getObject((int32_t)0xd45aa5f2);
    object.receive_date = metaObject->getInt32((int32_t)0xeedcab88);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.flags;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x81915c23, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt64;
        value.primitive.int64Value = self.n_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x7a5601fb, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt64;
        value.primitive.int64Value = self.access_hash;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x8f305224, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.date;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xb76958ba, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.admin_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xdf3d1ee7, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.participant_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x9abadf01, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.protocol;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xd45aa5f2, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.receive_date;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xeedcab88, value));
    }
}


@end

@implementation TLPhoneCall$phoneCallRequested : TLPhoneCall


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x14b0ed0c;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0x9627ce57;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)metaObject
{
    TLPhoneCall$phoneCallRequested *object = [[TLPhoneCall$phoneCallRequested alloc] init];
    object.flags = metaObject->getInt32((int32_t)0x81915c23);
    object.n_id = metaObject->getInt64((int32_t)0x7a5601fb);
    object.access_hash = metaObject->getInt64((int32_t)0x8f305224);
    object.date = metaObject->getInt32((int32_t)0xb76958ba);
    object.admin_id = (int32_t)metaObject->getInt64((int32_t)0xdf3d1ee7);
    object.participant_id = (int32_t)metaObject->getInt64((int32_t)0x9abadf01);
    object.g_a_hash = metaObject->getBytes((int32_t)0xb39b1140);
    object.protocol = metaObject->getObject((int32_t)0xd45aa5f2);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.flags;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x81915c23, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt64;
        value.primitive.int64Value = self.n_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x7a5601fb, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt64;
        value.primitive.int64Value = self.access_hash;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x8f305224, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.date;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xb76958ba, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.admin_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xdf3d1ee7, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.participant_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x9abadf01, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeBytes;
        value.nativeObject = self.g_a_hash;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xb39b1140, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.protocol;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xd45aa5f2, value));
    }
}


@end

@implementation TLPhoneCall$phoneCallDiscardedMeta : TLPhoneCall


- (int32_t)TLconstructorSignature
{
    return (int32_t)0xc9d59add;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xf01017df;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)metaObject
{
    TLPhoneCall$phoneCallDiscardedMeta *object = [[TLPhoneCall$phoneCallDiscardedMeta alloc] init];
    object.flags = metaObject->getInt32((int32_t)0x81915c23);
    object.n_id = metaObject->getInt64((int32_t)0x7a5601fb);
    object.reason = metaObject->getObject((int32_t)0x3405f57);
    object.duration = metaObject->getInt32((int32_t)0xac00f752);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.flags;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x81915c23, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt64;
        value.primitive.int64Value = self.n_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x7a5601fb, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.reason;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x3405f57, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.duration;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xac00f752, value));
    }
}


@end

@implementation TLPhoneCall$phoneCallAccepted : TLPhoneCall


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x3660c311;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xd149f2bd;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)metaObject
{
    TLPhoneCall$phoneCallAccepted *object = [[TLPhoneCall$phoneCallAccepted alloc] init];
    object.flags = metaObject->getInt32((int32_t)0x81915c23);
    object.n_id = metaObject->getInt64((int32_t)0x7a5601fb);
    object.access_hash = metaObject->getInt64((int32_t)0x8f305224);
    object.date = metaObject->getInt32((int32_t)0xb76958ba);
    object.admin_id = (int32_t)metaObject->getInt64((int32_t)0xdf3d1ee7);
    object.participant_id = (int32_t)metaObject->getInt64((int32_t)0x9abadf01);
    object.g_b = metaObject->getBytes((int32_t)0x5643e234);
    object.protocol = metaObject->getObject((int32_t)0xd45aa5f2);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.flags;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x81915c23, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt64;
        value.primitive.int64Value = self.n_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x7a5601fb, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt64;
        value.primitive.int64Value = self.access_hash;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x8f305224, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.date;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xb76958ba, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.admin_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xdf3d1ee7, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.participant_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x9abadf01, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeBytes;
        value.nativeObject = self.g_b;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x5643e234, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.protocol;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xd45aa5f2, value));
    }
}


@end

@implementation TLPhoneCall$phoneCall : TLPhoneCall


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x30535af5;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xc9908a15;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)metaObject
{
    TLPhoneCall$phoneCall *object = [[TLPhoneCall$phoneCall alloc] init];
    object.flags = metaObject->getInt32((int32_t)0x81915c23);
    object.n_id = metaObject->getInt64((int32_t)0x7a5601fb);
    object.access_hash = metaObject->getInt64((int32_t)0x8f305224);
    object.date = metaObject->getInt32((int32_t)0xb76958ba);
    object.admin_id = (int32_t)metaObject->getInt64((int32_t)0xdf3d1ee7);
    object.participant_id = (int32_t)metaObject->getInt64((int32_t)0x9abadf01);
    object.g_a_or_b = metaObject->getBytes((int32_t)0x817dfd4a);
    object.key_fingerprint = metaObject->getInt64((int32_t)0x3633de43);
    object.protocol = metaObject->getObject((int32_t)0xd45aa5f2);
    object.connection = metaObject->getObject((int32_t)0xb5b12f84);
    object.alternative_connections = metaObject->getArray((int32_t)0x39153642);
    object.connections = IOS6PhoneCallConnectionsFromMetaObject(metaObject);
    object.start_date = metaObject->getInt32((int32_t)0x1c46df41);
    TGLog(@"IOS6CALL fullPhoneCall.parsed call=%lld legacyConn=%@ legacyAlt=%d modernConnections=%d start=%d", object.n_id, object.connection, (int)object.alternative_connections.count, (int)object.connections.count, object.start_date);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.flags;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x81915c23, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt64;
        value.primitive.int64Value = self.n_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x7a5601fb, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt64;
        value.primitive.int64Value = self.access_hash;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x8f305224, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.date;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xb76958ba, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.admin_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xdf3d1ee7, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.participant_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x9abadf01, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeBytes;
        value.nativeObject = self.g_a_or_b;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x817dfd4a, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt64;
        value.primitive.int64Value = self.key_fingerprint;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x3633de43, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.protocol;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xd45aa5f2, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.connection;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xb5b12f84, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeVector;
        value.nativeObject = self.alternative_connections;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x39153642, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.start_date;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x1c46df41, value));
    }
}


@end
