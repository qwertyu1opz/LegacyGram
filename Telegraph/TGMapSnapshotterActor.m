#import "TGMapSnapshotterActor.h"

#import <MapKit/MapKit.h>

#import "../submodules/LegacyComponents/LegacyComponents/TGModernCache.h"

#import "../submodules/LegacyComponents/LegacyComponents/ActionStage.h"

@implementation TGMapSnapshotOptions

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _mapType = MKMapTypeStandard;
    }
    return self;
}

- (id)mkMapSnapshotOptions
{
    return nil;
}

- (NSString *)uniqueIdentifier
{
    return [NSString stringWithFormat:@"applemaps://region=%.5f,%.5f,%.5f,%.5f&mapType=%d&showPOI=%d&showBuildings=%d&width=%d&height=%d&scale=%.2f",
            self.region.center.latitude, self.region.center.longitude, self.region.span.latitudeDelta, self.region.span.longitudeDelta,
            (int)self.mapType, self.showsPointsOfInterest, self.showsBuildings, (int)self.imageSize.width, (int)self.imageSize.height, self.scale];
}

@end

@interface TGMapSnapshotRequest : NSObject
{
    id _snapshotter;
}

@property (nonatomic, assign) bool cancelled;

- (void)cancel;
- (void)dispose;

@end

@implementation TGMapSnapshotRequest

- (instancetype)initWithOptions:(TGMapSnapshotOptions *)options
{
    self = [super init];
    if (self != nil)
    {
        _snapshotter = nil;
    }
    return self;
}

- (void)cancel
{
    self.cancelled = true;
    [_snapshotter cancel];
    [self dispose];
}

- (void)dispose
{
    _snapshotter = nil;
}

+ (TGMapSnapshotRequest *)requestWithOptions:(TGMapSnapshotOptions *)options completion:(void (^)(UIImage *image, NSError *error))completion
{
    if (completion == nil)
        return nil;
    
    TGMapSnapshotRequest *request = [[TGMapSnapshotRequest alloc] initWithOptions:options];
    if (request->_snapshotter == nil)
    {
        completion(nil, [NSError errorWithDomain:@"TGMapSnapshotterActor" code:-1 userInfo:nil]);
    }
    
    return request;
}

@end

@interface TGMapSnapshotterActor ()
{
    TGModernCache *_cache;
    TGMapSnapshotOptions *_options;
}
@end

@implementation TGMapSnapshotterActor

+ (void)load
{
    [ASActor registerActorClass:self];
}

+ (NSString *)genericPath
{
    return @"/mapSnapshot/@";
}

- (void)prepare:(NSDictionary *)options
{
    [super prepare:options];
    
    if (options[@"queue"] != nil)
        self.requestQueueName = options[@"queue"];
}

- (void)execute:(NSDictionary *)options
{
    _cache = options[@"cache"];
    _options = options[@"options"];
    
    self.cancelToken = [TGMapSnapshotRequest requestWithOptions:_options completion:^(UIImage *image, NSError *error)
    {
        if (image != nil || error == nil)
        {
            if (_cache != nil)
                [_cache setValue:UIImagePNGRepresentation(image) forKey:[[_options uniqueIdentifier] dataUsingEncoding:NSUTF8StringEncoding]];
            [ActionStageInstance() actionCompleted:self.path result:image];
        }
        else
        {
            [ActionStageInstance() actionFailed:self.path reason:-1];
        }
    }];
}

@end
