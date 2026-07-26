#import <Foundation/Foundation.h>

typedef NSString *PKPushType;
static PKPushType const PKPushTypeVoIP = @"PKPushTypeVoIP";

@class PKPushRegistry;
@class PKPushCredentials;
@class PKPushPayload;

@protocol PKPushRegistryDelegate <NSObject>
@end

@interface PKPushCredentials : NSObject
@property (nonatomic, retain) NSData *token;
@end

@interface PKPushPayload : NSObject
@property (nonatomic, retain) NSDictionary *dictionaryPayload;
@end

@interface PKPushRegistry : NSObject
@property (nonatomic, assign) id<PKPushRegistryDelegate> delegate;
@property (nonatomic, copy) NSSet *desiredPushTypes;
- (instancetype)initWithQueue:(dispatch_queue_t)queue;
@end
