#import "TLRPCupdates_getDifference.h"

#import "../NSInputStream+TL.h"
#import "../NSOutputStream+TL.h"

#import "TLupdates_Difference.h"

@implementation TLRPCupdates_getDifference


- (Class)responseClass
{
    return [TLupdates_Difference class];
}

- (int)impliedResponseSignature
{
    return 0;
}

- (int)layerVersion
{
    return 214;
}

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
    TGLog(@"TLbuildFromMetaObject is not implemented for base type");
    return nil;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)__unused values
{
    TGLog(@"TLfillFieldsWithValues is not implemented for base type");
}


@end

@implementation TLRPCupdates_getDifference$updates_getDifference : TLRPCupdates_getDifference


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x19c2f763;
}

- (int32_t)TLconstructorName
{
    return (int32_t)-1;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)metaObject
{
    TLRPCupdates_getDifference$updates_getDifference *object = [[TLRPCupdates_getDifference$updates_getDifference alloc] init];
    object.flags = metaObject->getInt32((int32_t)0x81915c23);
    object.pts = metaObject->getInt32((int32_t)0x4fc5f572);
    object.pts_limit = metaObject->getInt32((int32_t)0x68d4ea5f);
    object.pts_total_limit = metaObject->getInt32((int32_t)0x0f4d5d27);
    object.date = metaObject->getInt32((int32_t)0xb76958ba);
    object.qts = metaObject->getInt32((int32_t)0x3c528e55);
    object.qts_limit = metaObject->getInt32((int32_t)0x6c0132ca);
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
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.pts;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x4fc5f572, value));
    }
    if (self.flags & (1 << 1))
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.pts_limit;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x68d4ea5f, value));
    }
    if (self.flags & (1 << 0))
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.pts_total_limit;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x0f4d5d27, value));
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
        value.primitive.int32Value = self.qts;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x3c528e55, value));
    }
    if (self.flags & (1 << 2))
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.qts_limit;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x6c0132ca, value));
    }
}

- (void)TLserialize:(NSOutputStream *)os
{
    int32_t flags = 0;
    if (self.pts_total_limit != 0)
        flags |= (1 << 0);
    if (self.pts_limit != 0)
        flags |= (1 << 1);
    if (self.qts_limit != 0)
        flags |= (1 << 2);
    self.flags = flags;
    
    [os writeInt32:flags];
    [os writeInt32:self.pts];
    if (flags & (1 << 1))
        [os writeInt32:self.pts_limit];
    if (flags & (1 << 0))
        [os writeInt32:self.pts_total_limit];
    [os writeInt32:self.date];
    [os writeInt32:self.qts];
    if (flags & (1 << 2))
        [os writeInt32:self.qts_limit];
}


@end
