#import <Foundation/Foundation.h>

@interface TGCallConnectionDescription : NSObject

@property (nonatomic, readonly) int64_t identifier;
@property (nonatomic, strong, readonly) NSString *ipv4;
@property (nonatomic, strong, readonly) NSString *ipv6;
@property (nonatomic, readonly) int32_t port;
@property (nonatomic, strong, readonly) NSData *peerTag;

- (instancetype)initWithIdentifier:(int64_t)identifier ipv4:(NSString *)ipv4 ipv6:(NSString *)ipv6 port:(int32_t)port peerTag:(NSData *)peerTag;

@end

@interface TGCallWebrtcConnectionDescription : NSObject

@property (nonatomic, readonly) int64_t identifier;
@property (nonatomic, readonly) int32_t flags;
@property (nonatomic, readonly) bool turn;
@property (nonatomic, readonly) bool stun;
@property (nonatomic, strong, readonly) NSString *ipv4;
@property (nonatomic, strong, readonly) NSString *ipv6;
@property (nonatomic, readonly) int32_t port;
@property (nonatomic, strong, readonly) NSString *username;
@property (nonatomic, strong, readonly) NSString *password;

- (instancetype)initWithIdentifier:(int64_t)identifier flags:(int32_t)flags ipv4:(NSString *)ipv4 ipv6:(NSString *)ipv6 port:(int32_t)port username:(NSString *)username password:(NSString *)password;

@end


@interface TGCallConnection : NSObject

@property (nonatomic, strong, readonly) NSData *key;
@property (nonatomic, strong, readonly) NSData *keyHash;
@property (nonatomic, strong, readonly) TGCallConnectionDescription *defaultConnection;
@property (nonatomic, strong, readonly) NSArray *alternativeConnections;
@property (nonatomic, strong, readonly) NSArray *webrtcConnections;
@property (nonatomic, strong, readonly) NSString *customParameters;

- (instancetype)initWithKey:(NSData *)key keyHash:(NSData *)keyHash defaultConnection:(TGCallConnectionDescription *)defaultConnection alternativeConnections:(NSArray *)alternativeConnections;
- (instancetype)initWithKey:(NSData *)key keyHash:(NSData *)keyHash defaultConnection:(TGCallConnectionDescription *)defaultConnection alternativeConnections:(NSArray *)alternativeConnections webrtcConnections:(NSArray *)webrtcConnections customParameters:(NSString *)customParameters;

@end
