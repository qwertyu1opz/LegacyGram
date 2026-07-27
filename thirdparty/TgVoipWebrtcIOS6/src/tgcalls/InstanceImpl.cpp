#include "InstanceImpl.h"

#include "LogSinkImpl.h"
#include "Manager.h"
#include "MediaManager.h"
#ifndef TGCALLS_IOS6_AUDIO_ONLY
#include "VideoCaptureInterfaceImpl.h"
#include "VideoCapturerInterface.h"
#endif

#include <stdio.h>
#include <syslog.h>

namespace tgcalls {

namespace {

rtc::Thread *makeManagerThread() {
	static std::unique_ptr<rtc::Thread> value = rtc::Thread::Create();
	value->SetName("WebRTC-Manager", nullptr);
	value->Start();
	return value.get();
}


rtc::Thread *getManagerThread() {
	static rtc::Thread *value = makeManagerThread();
	return value;
}

} // namespace

InstanceImpl::InstanceImpl(Descriptor &&descriptor)
: _logSink(std::make_unique<LogSinkImpl>(descriptor.config.logPath)) {
	fprintf(stderr, "IOS6WEBRTC cxx.instance.init.enter servers=%lu outgoing=%d protocol=%d logPath=%s\n",
		(unsigned long)descriptor.rtcServers.size(),
		descriptor.encryptionKey.isOutgoing ? 1 : 0,
		(int)descriptor.config.protocolVersion,
		descriptor.config.logPath.data.c_str());
	fflush(stderr);
	syslog(LOG_NOTICE, "IOS6WEBRTC cxx.instance.init.enter servers=%lu outgoing=%d protocol=%d",
		(unsigned long)descriptor.rtcServers.size(),
		descriptor.encryptionKey.isOutgoing ? 1 : 0,
		(int)descriptor.config.protocolVersion);
    rtc::LogMessage::LogToDebug(rtc::LS_INFO);
    rtc::LogMessage::SetLogToStderr(false);
	rtc::LogMessage::AddLogToStream(_logSink.get(), rtc::LS_INFO);

    auto networkType = descriptor.initialNetworkType;

    std::shared_ptr<Descriptor> descriptorPtr(new Descriptor(std::move(descriptor)));
	fprintf(stderr, "IOS6WEBRTC cxx.instance.manager.thread.before\n");
	fflush(stderr);
	syslog(LOG_NOTICE, "IOS6WEBRTC cxx.instance.manager.thread.before");
	_manager.reset(new ThreadLocalObject<Manager>(getManagerThread(), [descriptorPtr]() mutable {
		fprintf(stderr, "IOS6WEBRTC cxx.instance.manager.construct.lambda\n");
		fflush(stderr);
		syslog(LOG_NOTICE, "IOS6WEBRTC cxx.instance.manager.construct.lambda");
		return std::make_shared<Manager>(getManagerThread(), std::move(*descriptorPtr));
	}));
	fprintf(stderr, "IOS6WEBRTC cxx.instance.manager.thread.after\n");
	fflush(stderr);
	syslog(LOG_NOTICE, "IOS6WEBRTC cxx.instance.manager.thread.after");
	_manager->perform([](Manager *manager) {
		fprintf(stderr, "IOS6WEBRTC cxx.instance.manager.start.perform\n");
		fflush(stderr);
		syslog(LOG_NOTICE, "IOS6WEBRTC cxx.instance.manager.start.perform");
		manager->start();
	});

	fprintf(stderr, "IOS6WEBRTC cxx.instance.setNetwork.before type=%d\n", (int)networkType);
	fflush(stderr);
	syslog(LOG_NOTICE, "IOS6WEBRTC cxx.instance.setNetwork.before type=%d", (int)networkType);
    setNetworkType(networkType);
	fprintf(stderr, "IOS6WEBRTC cxx.instance.init.exit\n");
	fflush(stderr);
	syslog(LOG_NOTICE, "IOS6WEBRTC cxx.instance.init.exit");
}

InstanceImpl::~InstanceImpl() {
	rtc::LogMessage::RemoveLogToStream(_logSink.get());
}

void InstanceImpl::receiveSignalingData(const std::vector<uint8_t> &data) {
	_manager->perform([data](Manager *manager) {
		manager->receiveSignalingData(data);
	});
};

void InstanceImpl::setVideoCapture(std::shared_ptr<VideoCaptureInterface> videoCapture) {
    _manager->perform([videoCapture](Manager *manager) {
        manager->setVideoCapture(videoCapture);
    });
}

void InstanceImpl::sendVideoDeviceUpdated() {
    _manager->perform([](Manager *manager) {
        manager->sendVideoDeviceUpdated();
    });
}

void InstanceImpl::setRequestedVideoAspect(float aspect) {
    _manager->perform([aspect](Manager *manager) {
        manager->setRequestedVideoAspect(aspect);
    });
}

void InstanceImpl::setNetworkType(NetworkType networkType) {
    bool isLowCostNetwork = false;
    switch (networkType) {
        case NetworkType::WiFi:
        case NetworkType::Ethernet:
            isLowCostNetwork = true;
            break;
        default:
            break;
    }

    _manager->perform([isLowCostNetwork](Manager *manager) {
        manager->setIsLocalNetworkLowCost(isLowCostNetwork);
    });
}

void InstanceImpl::setMuteMicrophone(bool muteMicrophone) {
	_manager->perform([muteMicrophone](Manager *manager) {
		manager->setMuteOutgoingAudio(muteMicrophone);
	});
}

void InstanceImpl::setIncomingVideoOutput(std::weak_ptr<rtc::VideoSinkInterface<webrtc::VideoFrame>> sink) {
	_manager->perform([sink](Manager *manager) {
		manager->setIncomingVideoOutput(sink);
	});
}

void InstanceImpl::setAudioOutputGainControlEnabled(bool enabled) {
}

void InstanceImpl::setEchoCancellationStrength(int strength) {
}

void InstanceImpl::setAudioInputDevice(std::string id) {
	_manager->perform([id](Manager *manager) {
		manager->setAudioInputDevice(id);
	});
}

void InstanceImpl::setAudioOutputDevice(std::string id) {
	_manager->perform([id](Manager *manager) {
		manager->setAudioOutputDevice(id);
	});
}

void InstanceImpl::setInputVolume(float level) {
	_manager->perform([level](Manager *manager) {
		manager->setInputVolume(level);
	});
}

void InstanceImpl::setOutputVolume(float level) {
	_manager->perform([level](Manager *manager) {
		manager->setOutputVolume(level);
	});
}

void InstanceImpl::setAudioOutputDuckingEnabled(bool enabled) {
	// TODO: not implemented
}

void InstanceImpl::addExternalAudioSamples(std::vector<uint8_t> &&samples) {
    std::shared_ptr<std::vector<uint8_t>> samplesPtr(new std::vector<uint8_t>(std::move(samples)));
    _manager->perform([samplesPtr](Manager *manager) mutable {
        manager->addExternalAudioSamples(std::move(*samplesPtr));
    });
}

void InstanceImpl::setIsLowBatteryLevel(bool isLowBatteryLevel) {
    _manager->perform([isLowBatteryLevel](Manager *manager) {
        manager->setIsLowBatteryLevel(isLowBatteryLevel);
    });
}

std::string InstanceImpl::getLastError() {
	return "";  // TODO: not implemented
}

std::string InstanceImpl::getDebugInfo() {
	return "";  // TODO: not implemented
}

int64_t InstanceImpl::getPreferredRelayId() {
	return 0;  // we don't have endpoint ids
}

TrafficStats InstanceImpl::getTrafficStats() {
	return TrafficStats{};  // TODO: not implemented
}

PersistentState InstanceImpl::getPersistentState() {
	return PersistentState{};  // we dont't have such information
}

void InstanceImpl::stop(std::function<void(FinalState)> completion) {
    RTC_LOG(LS_INFO) << "Stopping InstanceImpl";
    
    std::string debugLog = _logSink->result();

    std::shared_ptr<std::string> debugLogPtr(new std::string(std::move(debugLog)));
    _manager->perform([completion, debugLogPtr](Manager *manager) {
        manager->getNetworkStats([completion, debugLogPtr](TrafficStats stats, CallStats callStats) {
            FinalState finalState;
            finalState.debugLog = *debugLogPtr;
            finalState.isRatingSuggested = false;
            finalState.trafficStats = stats;
            finalState.callStats = callStats;

            completion(finalState);
        });
    });
}

int InstanceImpl::GetConnectionMaxLayer() {
	return 92;
}

std::vector<std::string> InstanceImpl::GetVersions() {
    std::vector<std::string> result;
    result.push_back("2.7.7");
    result.push_back("5.0.0");
    result.push_back("8.0.0");
    return result;
}

template <>
bool Register<InstanceImpl>() {
	return Meta::RegisterOne<InstanceImpl>();
}

} // namespace tgcalls
