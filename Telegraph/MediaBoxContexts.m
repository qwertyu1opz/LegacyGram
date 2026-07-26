#import "MediaBoxContexts.h"

@implementation MediaResourceStatus

- ( instancetype)initWithStatus:(MediaResourceStatusType)status progress:(float)progress {
    self = [super init];
    if (self != nil) {
        _status = status;
        _progress = progress;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[MediaResourceStatus class]] && _status == ((MediaResourceStatus *)object)->_status && _progress == ((MediaResourceStatus *)object)->_progress;
}

@end

@implementation ResourceStatusContext

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _subscribers = [[SBag alloc] init];
    }
    return self;
}

@end

@implementation ResourceData

- ( instancetype)initWithPath:(NSString * )path size:(int32_t)size complete:(bool)complete {
    self = [super init];
    if (self != nil) {
        _path = path;
        _size = size;
        _complete = complete;
    }
    return self;
}

@end

@implementation ResourceDataContext

- ( instancetype)initWithData:(ResourceData * )data {
    self = [super init];
    if (self != nil) {
        _data = data;
        _completeDataSubscribers = [[SBag alloc] init];
        _fetchSubscribers = [[SBag alloc] init];
    }
    return self;
}

@end

@implementation ResourceStorePaths

- ( instancetype)initWithPartial:(NSString * )partial complete:(NSString * )complete {
    self = [super init];
    if (self != nil) {
        _partial = partial;
        _complete = complete;
    }
    return self;
}

@end

@implementation MediaResourceDataFetchResult

- ( instancetype)initWithData:(NSData * )data complete:(bool)complete {
    self = [super init];
    if (self != nil) {
        _data = data;
        _complete = complete;
    }
    return self;
}

@end
