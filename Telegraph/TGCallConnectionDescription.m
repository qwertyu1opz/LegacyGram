#import "TGCallConnectionDescription.h"

@implementation TGCallConnectionDescription

- (instancetype)initWithIdentifier:(int64_t)identifier ipv4:(NSString *)ipv4 ipv6:(NSString *)ipv6 port:(int32_t)port peerTag:(NSData *)peerTag {
    self = [super init];
    if (self != nil) {
        _identifier = identifier;
        _ipv4 = ipv4 ?: @"";
        _ipv6 = ipv6 ?: @"";
        _port = port;
        _peerTag = peerTag;
    }
    return self;
}

@end

@implementation TGCallWebrtcConnectionDescription

- (instancetype)initWithIdentifier:(int64_t)identifier flags:(int32_t)flags ipv4:(NSString *)ipv4 ipv6:(NSString *)ipv6 port:(int32_t)port username:(NSString *)username password:(NSString *)password {
    self = [super init];
    if (self != nil) {
        _identifier = identifier;
        _flags = flags;
        _turn = (flags & (1 << 0)) != 0;
        _stun = (flags & (1 << 1)) != 0;
        _ipv4 = ipv4 ?: @"";
        _ipv6 = ipv6 ?: @"";
        _port = port;
        _username = username ?: @"";
        _password = password ?: @"";
    }
    return self;
}

@end


@implementation TGCallConnection

- (instancetype)initWithKey:(NSData *)key keyHash:(NSData *)keyHash defaultConnection:(TGCallConnectionDescription *)defaultConnection alternativeConnections:(NSArray *)alternativeConnections {
    return [self initWithKey:key keyHash:keyHash defaultConnection:defaultConnection alternativeConnections:alternativeConnections webrtcConnections:nil customParameters:nil];
}

- (instancetype)initWithKey:(NSData *)key keyHash:(NSData *)keyHash defaultConnection:(TGCallConnectionDescription *)defaultConnection alternativeConnections:(NSArray *)alternativeConnections webrtcConnections:(NSArray *)webrtcConnections customParameters:(NSString *)customParameters {
    self = [super init];
    if (self != nil) {
        _key = key;
        _keyHash = keyHash;
        _defaultConnection = defaultConnection;
        _alternativeConnections = alternativeConnections ?: @[];
        _webrtcConnections = webrtcConnections ?: @[];
        _customParameters = customParameters ?: @"";
    }
    return self;
}

@end
