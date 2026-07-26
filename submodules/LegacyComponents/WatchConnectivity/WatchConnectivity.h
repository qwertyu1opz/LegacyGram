#import <Foundation/Foundation.h>

extern NSString * const WCErrorDomain;

typedef NSInteger WCErrorCode;
#define WCErrorCodeDeliveryFailed 7014
#define WCErrorCodeNotReachable 7007

@class WCSession;
@class WCSessionFile;
@class WCSessionFileTransfer;

@protocol WCSessionDelegate <NSObject>
@end

@interface WCSessionFile : NSObject
@property (nonatomic, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSDictionary *metadata;
@end

@interface WCSessionFileTransfer : NSObject
@end

@interface WCSession : NSObject
+ (BOOL)isSupported;
+ (WCSession *)defaultSession;
@property (nonatomic, assign) id<WCSessionDelegate> delegate;
@property (nonatomic, readonly, getter=isReachable) BOOL reachable;
@property (nonatomic, readonly, getter=isPaired) BOOL paired;
@property (nonatomic, readonly, getter=isWatchAppInstalled) BOOL watchAppInstalled;
@property (nonatomic, readonly) NSDictionary *applicationContext;
@property (nonatomic, readonly) NSURL *watchDirectoryURL;
- (void)activateSession;
- (BOOL)updateApplicationContext:(NSDictionary *)applicationContext error:(NSError **)error;
- (void)sendMessageData:(NSData *)messageData replyHandler:(void (^)(NSData *replyMessageData))replyHandler errorHandler:(void (^)(NSError *error))errorHandler;
- (WCSessionFileTransfer *)transferFile:(NSURL *)file metadata:(NSDictionary *)metadata;
- (void)transferUserInfo:(NSDictionary *)userInfo;
@end
