#import <Foundation/Foundation.h>

#ifndef TGCALLS_IOS6_AUDIO_ONLY
#define TGCALLS_IOS6_AUDIO_ONLY 1
#endif

#include "../thirdparty/TgVoipWebrtcIOS6/include/tgcalls/TGIOS6CxxCompat.h"
#include "../thirdparty/TgVoipWebrtcIOS6/src/tgcalls/Instance.h"
#include "../thirdparty/TgVoipWebrtcIOS6/src/tgcalls/InstanceImpl.h"

#include <array>
#include <memory>
#include <vector>

@interface TGIOS6WebrtcCallbackProxy : NSObject

@property (nonatomic, copy) void (^signalBarsChanged)(int32_t);
@property (nonatomic, copy) void (^stateChanged)(int32_t, int32_t, int32_t, int32_t, int32_t, float);

- (void)emitSignalBars:(int32_t)bars;
- (void)emitState:(int32_t)state;

@end

@implementation TGIOS6WebrtcCallbackProxy

- (void)emitSignalBars:(int32_t)bars
{
    if (_signalBarsChanged != nil)
        _signalBarsChanged(bars);
}

- (void)emitState:(int32_t)state
{
    if (_stateChanged != nil)
        _stateChanged(state, 0, 0, 0, 0, 0.0f);
}

@end

namespace {

class TGIOS6WebrtcCppBridge {
public:
    TGIOS6WebrtcCppBridge(TGIOS6WebrtcCallbackProxy *callbackProxy) :
    _callbackProxy(callbackProxy) {
        static bool registered = false;
        if (!registered) {
            tgcalls::Register<tgcalls::InstanceImpl>();
            registered = true;
        }
    }

    bool start(
        NSString *version,
        NSString *customParameters,
        NSData *key,
        bool isOutgoing,
        NSArray *connections,
        int32_t maxLayer,
        bool allowP2P,
        bool allowTCP,
        void (^sendSignalingData)(NSData *),
        TGIOS6WebrtcCallbackProxy *callbackProxy) {
        if (key.length != tgcalls::EncryptionKey::kSize) {
            NSLog(@"IOS6WEBRTC cpp.start.fail badKeyLen=%d", (int)key.length);
            return false;
        }

        tgcalls::Descriptor descriptor;
        descriptor.version = version.length == 0 ? "5.0.0" : std::string(version.UTF8String);
        descriptor.config.customParameters = customParameters.length == 0 ? "{}" : std::string(customParameters.UTF8String);
        descriptor.config.maxApiLayer = maxLayer;
        descriptor.config.enableP2P = allowP2P;
        descriptor.config.allowTCP = allowTCP;
        descriptor.config.protocolVersion = descriptor.version == "5.0.0" ? tgcalls::ProtocolVersion::V1 : tgcalls::ProtocolVersion::V0;
        descriptor.initialNetworkType = tgcalls::NetworkType::WiFi;

        std::shared_ptr<std::array<uint8_t, tgcalls::EncryptionKey::kSize>> keyValue(new std::array<uint8_t, tgcalls::EncryptionKey::kSize>());
        memcpy(keyValue->data(), key.bytes, tgcalls::EncryptionKey::kSize);
        descriptor.encryptionKey = tgcalls::EncryptionKey(keyValue, isOutgoing);

        for (id item in connections) {
            tgcalls::RtcServer server;
            NSNumber *reflectorId = [item valueForKey:@"reflectorId"];
            NSString *ip = [item valueForKey:@"ip"];
            NSNumber *port = [item valueForKey:@"port"];
            NSString *username = [item valueForKey:@"username"];
            NSString *password = [item valueForKey:@"password"];
            NSNumber *hasTurn = [item valueForKey:@"hasTurn"];
            NSNumber *hasTcp = [item valueForKey:@"hasTcp"];
            
            if (reflectorId != nil)
                server.id = (uint8_t)[reflectorId intValue];
            if (ip.length != 0)
                server.host = std::string([ip UTF8String]);
            if (port != nil)
                server.port = (uint16_t)[port intValue];
            if (username.length != 0)
                server.login = std::string([username UTF8String]);
            if (password.length != 0)
                server.password = std::string([password UTF8String]);
            if (hasTurn != nil)
                server.isTurn = [hasTurn boolValue];
            if (hasTcp != nil)
                server.isTcp = [hasTcp boolValue];
            if (!server.host.empty() && server.port != 0)
                descriptor.rtcServers.push_back(server);
        }
        
        NSLog(@"IOS6WEBRTC cpp.descriptor version=%s outgoing=%d rtcServers=%lu customParametersLen=%lu allowP2P=%d allowTCP=%d",
              descriptor.version.c_str(),
              isOutgoing ? 1 : 0,
              (unsigned long)descriptor.rtcServers.size(),
              (unsigned long)descriptor.config.customParameters.size(),
              allowP2P ? 1 : 0,
              allowTCP ? 1 : 0);

        void (^sendSignalingDataCopy)(NSData *) = [sendSignalingData copy];
        int emittedSignalingPackets = 0;
        int emittedCandidatePackets = 0;
        descriptor.signalingDataEmitted = [sendSignalingDataCopy, emittedSignalingPackets, emittedCandidatePackets](const std::vector<uint8_t> &data) mutable {
            if (sendSignalingDataCopy != nil && !data.empty()) {
                emittedSignalingPackets++;
                if (data.size() == 59) {
                    emittedCandidatePackets++;
                }
                NSData *payload = [[NSData alloc] initWithBytes:data.data() length:data.size()];
                const unsigned long payloadLength = (unsigned long)data.size();
                const int packetIndex = emittedSignalingPackets;
                const int candidateIndex = emittedCandidatePackets;
                NSLog(@"IOS6WEBRTC cpp.signaling.callback len=%lu packet=%d candidate=%d main=%d",
                      payloadLength,
                      packetIndex,
                      candidateIndex,
                      [NSThread isMainThread] ? 1 : 0);
                if ([NSThread isMainThread]) {
                    NSLog(@"IOS6WEBRTC cpp.signaling.emit len=%lu packet=%d candidate=%d main=1", payloadLength, packetIndex, candidateIndex);
                    sendSignalingDataCopy(payload);
                    NSLog(@"IOS6WEBRTC cpp.signaling.emit.done len=%lu packet=%d", payloadLength, packetIndex);
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"IOS6WEBRTC cpp.signaling.emit len=%lu packet=%d candidate=%d main=1", payloadLength, packetIndex, candidateIndex);
                        sendSignalingDataCopy(payload);
                        NSLog(@"IOS6WEBRTC cpp.signaling.emit.done len=%lu packet=%d", payloadLength, packetIndex);
                    });
                }
            }
        };
        descriptor.signalBarsUpdated = [callbackProxy](int bars) {
            [callbackProxy emitSignalBars:(int32_t)bars];
        };
        descriptor.stateUpdated = [callbackProxy](tgcalls::State state) {
            int32_t mapped = 0;
            if (state == tgcalls::State::Established)
                mapped = 1;
            else if (state == tgcalls::State::Failed)
                mapped = 2;
            else if (state == tgcalls::State::Reconnecting)
                mapped = 3;
            [callbackProxy emitState:mapped];
        };
        descriptor.remoteMediaStateUpdated = [](tgcalls::AudioState, tgcalls::VideoState) {
        };
        descriptor.remoteBatteryLevelIsLowUpdated = [](bool) {
        };
        descriptor.remotePrefferedAspectRatioUpdated = [](float) {
        };
        descriptor.audioLevelUpdated = [](float) {
        };

        NSLog(@"IOS6WEBRTC cpp.create.before version=%s rtcServers=%lu keyOutgoing=%d",
              descriptor.version.c_str(),
              (unsigned long)descriptor.rtcServers.size(),
              isOutgoing ? 1 : 0);
        @try {
            _instance = tgcalls::Meta::Create(descriptor.version, std::move(descriptor));
        } @catch (NSException *exception) {
            NSLog(@"IOS6WEBRTC cpp.create.exception name=%@ reason=%@", exception.name, exception.reason);
            return false;
        }
        NSLog(@"IOS6WEBRTC cpp.create.after instance=%p", _instance.get());
        if (!_instance) {
            NSLog(@"IOS6WEBRTC cpp.start.fail noInstance version=%@ servers=%d", version, (int)connections.count);
            return false;
        }

        NSLog(@"IOS6WEBRTC cpp.network.before");
        _instance->setNetworkType(tgcalls::NetworkType::WiFi);
        NSLog(@"IOS6WEBRTC cpp.start.ok version=%@ servers=%d", version, (int)connections.count);
        return true;
    }

    void receiveSignalingData(NSData *data) {
        if (!_instance || data.length == 0)
            return;

        std::vector<uint8_t> payload((const uint8_t *)data.bytes, (const uint8_t *)data.bytes + data.length);
        _instance->receiveSignalingData(payload);
    }

    void stop(void (^completion)(NSString *, int64_t, int64_t, int64_t, int64_t)) {
        if (!_instance) {
            if (completion != nil)
                completion(@"", 0, 0, 0, 0);
            return;
        }

        std::unique_ptr<tgcalls::Instance> instance = std::move(_instance);
        instance->stop([completion](tgcalls::FinalState finalState) {
            if (completion != nil) {
                NSString *debugLog = [NSString stringWithUTF8String:finalState.debugLog.c_str()] ?: @"";
                completion(debugLog,
                           (int64_t)finalState.trafficStats.bytesSentWifi,
                           (int64_t)finalState.trafficStats.bytesReceivedWifi,
                           (int64_t)finalState.trafficStats.bytesSentMobile,
                           (int64_t)finalState.trafficStats.bytesReceivedMobile);
            }
        });
    }

private:
    std::unique_ptr<tgcalls::Instance> _instance;
    TGIOS6WebrtcCallbackProxy *_callbackProxy;
};

}

@interface OngoingCallConnectionDescriptionWebrtc : NSObject

@property (nonatomic, assign) uint8_t reflectorId;
@property (nonatomic, assign) bool hasStun;
@property (nonatomic, assign) bool hasTurn;
@property (nonatomic, assign) bool hasTcp;
@property (nonatomic, strong) NSString *ip;
@property (nonatomic, assign) int32_t port;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

- (instancetype)initWithReflectorId:(uint8_t)reflectorId hasStun:(bool)hasStun hasTurn:(bool)hasTurn hasTcp:(bool)hasTcp ip:(NSString *)ip port:(int32_t)port username:(NSString *)username password:(NSString *)password;

@end

@implementation OngoingCallConnectionDescriptionWebrtc

- (instancetype)initWithReflectorId:(uint8_t)reflectorId hasStun:(bool)hasStun hasTurn:(bool)hasTurn hasTcp:(bool)hasTcp ip:(NSString *)ip port:(int32_t)port username:(NSString *)username password:(NSString *)password
{
    self = [super init];
    if (self != nil) {
        _reflectorId = reflectorId;
        _hasStun = hasStun;
        _hasTurn = hasTurn;
        _hasTcp = hasTcp;
        _ip = [ip copy];
        _port = port;
        _username = [username copy];
        _password = [password copy];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<WebrtcConnection id=%d ip=%@ port=%d stun=%d turn=%d tcp=%d user=%@ passLen=%d>",
            (int)_reflectorId, _ip, _port, _hasStun ? 1 : 0, _hasTurn ? 1 : 0, _hasTcp ? 1 : 0, _username, (int)_password.length];
}

@end

@interface OngoingCallThreadLocalContextWebrtc : NSObject

@property (nonatomic, copy) void (^signalBarsChanged)(int32_t);
@property (nonatomic, copy) void (^stateChanged)(int32_t, int32_t, int32_t, int32_t, int32_t, float);

- (instancetype)initWithVersion:(NSString *)version customParameters:(NSString *)customParameters queue:(id)queue proxy:(id)proxy networkType:(int32_t)networkType dataSaving:(int32_t)dataSaving derivedState:(NSData *)derivedState key:(NSData *)key isOutgoing:(bool)isOutgoing connections:(NSArray *)connections maxLayer:(int32_t)maxLayer allowP2P:(bool)allowP2P allowTCP:(bool)allowTCP enableStunMarking:(bool)enableStunMarking logPath:(NSString *)logPath statsLogPath:(NSString *)statsLogPath sendSignalingData:(void (^)(NSData *))sendSignalingData videoCapturer:(id)videoCapturer preferredVideoCodec:(NSString *)preferredVideoCodec audioInputDeviceId:(NSString *)audioInputDeviceId audioDevice:(id)audioDevice directConnection:(id)directConnection;
- (void)addSignalingData:(NSData *)data;
- (void)stop:(void (^)(NSString *debugLog, int64_t bytesSentWifi, int64_t bytesReceivedWifi, int64_t bytesSentMobile, int64_t bytesReceivedMobile))completion;

@end

@implementation OngoingCallThreadLocalContextWebrtc {
    NSString *_version;
    NSString *_customParameters;
    NSData *_key;
    NSArray *_connections;
    bool _isOutgoing;
    void (^_sendSignalingData)(NSData *);
    TGIOS6WebrtcCallbackProxy *_callbackProxy;
    TGIOS6WebrtcCppBridge *_cppBridge;
}

+ (NSArray *)versionsWithIncludeReference:(bool)includeReference
{
    return @[ @"8.0.0" ];
}

- (instancetype)initWithVersion:(NSString *)version customParameters:(NSString *)customParameters queue:(id)queue proxy:(id)proxy networkType:(int32_t)networkType dataSaving:(int32_t)dataSaving derivedState:(NSData *)derivedState key:(NSData *)key isOutgoing:(bool)isOutgoing connections:(NSArray *)connections maxLayer:(int32_t)maxLayer allowP2P:(bool)allowP2P allowTCP:(bool)allowTCP enableStunMarking:(bool)enableStunMarking logPath:(NSString *)logPath statsLogPath:(NSString *)statsLogPath sendSignalingData:(void (^)(NSData *))sendSignalingData videoCapturer:(id)videoCapturer preferredVideoCodec:(NSString *)preferredVideoCodec audioInputDeviceId:(NSString *)audioInputDeviceId audioDevice:(id)audioDevice directConnection:(id)directConnection
{
    self = [super init];
    if (self != nil) {
        _version = [version copy];
        _customParameters = [customParameters copy];
        _key = [key copy];
        _connections = [connections copy];
        _isOutgoing = isOutgoing;
        _sendSignalingData = [sendSignalingData copy];
        _callbackProxy = [[TGIOS6WebrtcCallbackProxy alloc] init];
        
        NSLog(@"IOS6WEBRTC runtime.stub.init version=%@ outgoing=%d keyLen=%d connections=%d customParametersLen=%d maxLayer=%d allowTCP=%d",
              _version, _isOutgoing ? 1 : 0, (int)_key.length, (int)_connections.count, (int)_customParameters.length, maxLayer, allowTCP ? 1 : 0);
        _cppBridge = new TGIOS6WebrtcCppBridge(_callbackProxy);
        bool started = _cppBridge->start(_version, _customParameters, _key, _isOutgoing, _connections, maxLayer, allowP2P, allowTCP, _sendSignalingData, _callbackProxy);
        NSLog(@"IOS6WEBRTC runtime.cpp.startResult started=%d", started ? 1 : 0);
    }
    return self;
}

- (void)dealloc
{
    delete _cppBridge;
    _cppBridge = NULL;
}

- (void)setSignalBarsChanged:(void (^)(int32_t))signalBarsChanged
{
    _signalBarsChanged = [signalBarsChanged copy];
    _callbackProxy.signalBarsChanged = _signalBarsChanged;
    NSLog(@"IOS6WEBRTC runtime.callback.signalBars.set has=%d", _signalBarsChanged != nil ? 1 : 0);
}

- (void)setStateChanged:(void (^)(int32_t, int32_t, int32_t, int32_t, int32_t, float))stateChanged
{
    _stateChanged = [stateChanged copy];
    _callbackProxy.stateChanged = _stateChanged;
    NSLog(@"IOS6WEBRTC runtime.callback.state.set has=%d", _stateChanged != nil ? 1 : 0);
}

- (void)addSignalingData:(NSData *)data
{
    NSLog(@"IOS6WEBRTC runtime.cpp.receiveSignaling len=%d", (int)data.length);
    if (_cppBridge != NULL)
        _cppBridge->receiveSignalingData(data);
}

- (void)stop:(void (^)(NSString *, int64_t, int64_t, int64_t, int64_t))completion
{
    NSLog(@"IOS6WEBRTC runtime.cpp.stop");
    if (_cppBridge != NULL)
        _cppBridge->stop(completion);
    else if (completion != nil)
        completion(@"", 0, 0, 0, 0);
}

@end
