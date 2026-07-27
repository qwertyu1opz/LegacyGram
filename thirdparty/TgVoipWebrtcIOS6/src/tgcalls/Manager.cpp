#include "Manager.h"

#include "CryptoHelper.h"

#include "rtc_base/byte_buffer.h"
#include "rtc_base/logging.h"
#include "StaticThreads.h"

#include <fstream>
#include <iomanip>
#include <stdio.h>
#include <syslog.h>
#include <sstream>

namespace tgcalls {
namespace {

void dumpStatsLog(const FilePath &path, const CallStats &stats) {
	if (path.data.empty()) {
		return;
	}
    std::ofstream file;
    file.open(path.data);

    file << "{";
    file << "\"v\":\"" << 1 << "\"";
    file << ",";

    file << "\"codec\":\"" << stats.outgoingCodec << "\"";
    file << ",";

    file << "\"bitrate\":[";
    bool addComma = false;
    for (auto &it : stats.bitrateRecords) {
        if (addComma) {
            file << ",";
        }
        file << "{";
        file << "\"t\":\"" << it.timestamp << "\"";
        file << ",";
        file << "\"b\":\"" << it.bitrate << "\"";
        file << "}";
        addComma = true;
    }
    file << "]";
    file << ",";

    file << "\"network\":[";
    addComma = false;
    for (auto &it : stats.networkRecords) {
        if (addComma) {
            file << ",";
        }
        file << "{";
        file << "\"t\":\"" << it.timestamp << "\"";
        file << ",";
        file << "\"e\":\"" << (int)(it.endpointType) << "\"";
        file << ",";
        file << "\"w\":\"" << (it.isLowCost ? 1 : 0) << "\"";
        file << "}";
        addComma = true;
    }
    file << "]";

    file << "}";

	file.close();
}

std::string fingerprintFromKey(const EncryptionKey &key) {
	if (key.value == nullptr) {
		return "00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF";
	}
	const auto digest = ConcatSHA256(MemorySpan{ key.value->data(), EncryptionKey::kSize });
	std::ostringstream result;
	result << std::uppercase << std::hex << std::setfill('0');
	for (size_t i = 0; i < digest.size(); i++) {
		if (i != 0) {
			result << ":";
		}
		result << std::setw(2) << (unsigned int)digest[i];
	}
	return result.str();
}

Message makeRemoteBatteryLevelIsLowMessage(bool batteryLow) {
	RemoteBatteryLevelIsLowMessage payload;
	payload.batteryLow = batteryLow;
	Message message;
	message.data = payload;
	return message;
}

Message makeRemoteNetworkStatusMessage(bool isLowCost, bool isLowDataRequested) {
	RemoteNetworkStatusMessage payload;
	payload.isLowCost = isLowCost;
	payload.isLowDataRequested = isLowDataRequested;
	Message message;
	message.data = payload;
	return message;
}

std::string ios6JsonEscape(const std::string &value) {
	std::string result;
	result.reserve(value.size() + 8);
	for (char c : value) {
		if (c == '\\' || c == '"') {
			result.push_back('\\');
			result.push_back(c);
		} else if (c == '\n') {
			result += "\\n";
		} else if (c == '\r') {
			result += "\\r";
		} else if (c == '\t') {
			result += "\\t";
		} else {
			result.push_back(c);
		}
	}
	return result;
}

} // namespace

bool Manager::ResolvedNetworkStatus::operator==(const ResolvedNetworkStatus &rhs) const {
    if (rhs.isLowCost != isLowCost) {
        return false;
    }
    if (rhs.isLowDataRequested != isLowDataRequested) {
        return false;
    }
    return true;
}

bool Manager::ResolvedNetworkStatus::operator!=(const ResolvedNetworkStatus &rhs) const {
    return !(*this == rhs);
}

Manager::Manager(rtc::Thread *thread, Descriptor &&descriptor) :
_thread(thread),
_encryptionKey(descriptor.encryptionKey),
_signaling(
	EncryptedConnection::Type::Signaling,
	_encryptionKey,
	[=](int delayMs, int cause) { sendSignalingAsync(delayMs, cause); }),
_enableP2P(descriptor.config.enableP2P),
_enableTCP(descriptor.config.allowTCP),
_enableStunMarking(descriptor.config.enableStunMarking),
_protocolVersion(descriptor.config.protocolVersion),
_statsLogPath(descriptor.config.statsLogPath),
_rtcServers(std::move(descriptor.rtcServers)),
_proxy(std::move(descriptor.proxy)),
_mediaDevicesConfig(std::move(descriptor.mediaDevicesConfig)),
_videoCapture(std::move(descriptor.videoCapture)),
_stateUpdated(std::move(descriptor.stateUpdated)),
_remoteMediaStateUpdated(std::move(descriptor.remoteMediaStateUpdated)),
_remoteBatteryLevelIsLowUpdated(std::move(descriptor.remoteBatteryLevelIsLowUpdated)),
_remotePrefferedAspectRatioUpdated(std::move(descriptor.remotePrefferedAspectRatioUpdated)),
_signalingDataEmitted(std::move(descriptor.signalingDataEmitted)),
_signalBarsUpdated(std::move(descriptor.signalBarsUpdated)),
_audioLevelUpdated(std::move(descriptor.audioLevelUpdated)),
_createAudioDeviceModule(std::move(descriptor.createAudioDeviceModule)),
_enableHighBitrateVideo(descriptor.config.enableHighBitrateVideo),
_dataSaving(descriptor.config.dataSaving) {
	fprintf(stderr, "IOS6WEBRTC cxx.manager.init.enter servers=%lu enableP2P=%d enableTCP=%d protocol=%d\n",
		(unsigned long)_rtcServers.size(),
		_enableP2P ? 1 : 0,
		_enableTCP ? 1 : 0,
		(int)_protocolVersion);
	fflush(stderr);
	syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.init.enter servers=%lu enableP2P=%d enableTCP=%d protocol=%d",
		(unsigned long)_rtcServers.size(),
		_enableP2P ? 1 : 0,
		_enableTCP ? 1 : 0,
		(int)_protocolVersion);
	assert(_thread->IsCurrent());
	assert(_stateUpdated != nullptr);
	assert(_signalingDataEmitted != nullptr);

    _preferredCodecs = descriptor.config.preferredVideoCodecs;

	_sendSignalingMessage = [=](const Message &message) {
		fprintf(stderr, "IOS6WEBRTC cxx.manager.signaling.prepare.enter\n");
		fflush(stderr);
		syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.signaling.prepare.enter");
		if (const auto candidates = absl::get_if<CandidatesListMessage>(&message.data)) {
			fprintf(stderr, "IOS6WEBRTC cxx.manager.signaling.candidates count=%lu ufrag=%lu pwd=%lu\n",
				(unsigned long)candidates->candidates.size(),
				(unsigned long)candidates->iceParameters.ufrag.size(),
				(unsigned long)candidates->iceParameters.pwd.size());
			fflush(stderr);
			syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.signaling.candidates count=%lu ufrag=%lu pwd=%lu",
				(unsigned long)candidates->candidates.size(),
				(unsigned long)candidates->iceParameters.ufrag.size(),
				(unsigned long)candidates->iceParameters.pwd.size());
			RTC_LOG(LS_INFO) << "IOS6WEBRTC manager.signaling.candidates count=" << candidates->candidates.size()
				<< " ufragLen=" << candidates->iceParameters.ufrag.size()
				<< " pwdLen=" << candidates->iceParameters.pwd.size();
				if (!_sentIos6V2Bootstrap) {
					_sentIos6V2Bootstrap = true;
					const std::string ufrag = ios6JsonEscape(candidates->iceParameters.ufrag);
					const std::string pwd = ios6JsonEscape(candidates->iceParameters.pwd);
						const std::string fingerprint = fingerprintFromKey(_encryptionKey);
						syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.fingerprint hash=sha-256 len=%lu", (unsigned long)fingerprint.size());
					std::string initialJson = std::string("{\"@type\":\"InitialSetup\",\"ufrag\":\"") + ufrag
						+ "\",\"pwd\":\"" + pwd
						+ "\",\"renomination\":true,\"fingerprints\":[{\"hash\":\"sha-256\",\"setup\":\"actpass\",\"fingerprint\":\""
						+ fingerprint + "\"}]}";

				std::ostringstream candidatesJson;
				candidatesJson << "{\"@type\":\"Candidates\",\"candidates\":[";
				for (size_t i = 0; i < candidates->candidates.size(); i++) {
					if (i != 0) {
						candidatesJson << ",";
					}
					candidatesJson << "{\"sdpString\":\"" << ios6JsonEscape(candidates->candidates[i].ToString()) << "\"}";
				}
				candidatesJson << "]}";
				const std::string candidatesJsonString = candidatesJson.str();
				const std::string negotiateJson =
					"{\"@type\":\"NegotiateChannels\",\"exchangeId\":\"1\",\"contents\":[{\"type\":\"audio\",\"ssrc\":\"314366526\","
					"\"payloadTypes\":[{\"id\":111,\"name\":\"opus\",\"clockrate\":48000,\"channels\":2,"
					"\"feedbackTypes\":[],\"parameters\":{\"minptime\":\"10\",\"useinbandfec\":\"1\"}}],"
					"\"rtpExtensions\":[{\"uri\":\"http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\",\"id\":3},"
					"{\"uri\":\"http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\",\"id\":2}]}]}";

				rtc::CopyOnWriteBuffer initialBuffer;
				initialBuffer.AppendData(initialJson.data(), initialJson.size());
				rtc::CopyOnWriteBuffer negotiateBuffer;
				negotiateBuffer.AppendData(negotiateJson.data(), negotiateJson.size());
				rtc::CopyOnWriteBuffer candidatesBuffer;
				candidatesBuffer.AppendData(candidatesJsonString.data(), candidatesJsonString.size());

						if (_protocolVersion == ProtocolVersion::V1) {
							syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v1.bootstrap.prepare.initial json=%lu",
								(unsigned long)initialJson.size());
							const auto rawInitialPacket = _signaling.encryptRawPacket(initialBuffer);
							if (rawInitialPacket) {
								std::vector<uint8_t> rawBytes(rawInitialPacket->data(), rawInitialPacket->data() + rawInitialPacket->size());
								syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v1.bootstrap.initial json=%lu bytes=%lu",
									(unsigned long)initialJson.size(),
									(unsigned long)rawBytes.size());
								_signalingDataEmitted(rawBytes);
								const auto rawNegotiatePacket = _signaling.encryptRawPacket(negotiateBuffer);
								if (rawNegotiatePacket) {
									std::vector<uint8_t> rawNegotiateBytes(rawNegotiatePacket->data(), rawNegotiatePacket->data() + rawNegotiatePacket->size());
									syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v1.bootstrap.negotiate json=%lu bytes=%lu",
										(unsigned long)negotiateJson.size(),
										(unsigned long)rawNegotiateBytes.size());
									_signalingDataEmitted(rawNegotiateBytes);
								} else {
									syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v1.bootstrap.negotiate.nil");
								}
								const auto rawCandidatesPacket = _signaling.encryptRawPacket(candidatesBuffer);
								if (rawCandidatesPacket) {
									std::vector<uint8_t> rawCandidatesBytes(rawCandidatesPacket->data(), rawCandidatesPacket->data() + rawCandidatesPacket->size());
									syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v1.bootstrap.candidates json=%lu count=%lu bytes=%lu",
										(unsigned long)candidatesJsonString.size(),
										(unsigned long)candidates->candidates.size(),
										(unsigned long)rawCandidatesBytes.size());
									_signalingDataEmitted(rawCandidatesBytes);
								} else {
									syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v1.bootstrap.candidates.nil");
								}
								return uint32_t(1);
							}
							syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v1.bootstrap.initial.nil");
							return uint32_t(0);
						}

						syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v2.bootstrap.prepare.initial json=%lu",
							(unsigned long)initialJson.size());
						const auto initialPacket = _signaling.prepareForSendingRawMessage(initialBuffer, true);
						const auto negotiatePacket = _signaling.prepareForSendingRawMessage(negotiateBuffer, false);
						const auto candidatesPacket = _signaling.prepareForSendingRawMessage(candidatesBuffer, false);

				if (initialPacket) {
					syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v2.bootstrap.initial json=%lu bytes=%lu counter=%u",
						(unsigned long)initialJson.size(),
						(unsigned long)initialPacket->bytes.size(),
						initialPacket->counter);
				} else {
					syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v2.bootstrap.initial.nil");
				}
				if (candidatesPacket) {
					syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v2.bootstrap.candidates json=%lu count=%lu bytes=%lu counter=%u",
						(unsigned long)candidatesJsonString.size(),
						(unsigned long)candidates->candidates.size(),
						(unsigned long)candidatesPacket->bytes.size(),
						candidatesPacket->counter);
				} else {
					syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v2.bootstrap.candidates.nil");
				}
				if (negotiatePacket) {
					syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v2.bootstrap.negotiate json=%lu bytes=%lu counter=%u",
						(unsigned long)negotiateJson.size(),
						(unsigned long)negotiatePacket->bytes.size(),
						negotiatePacket->counter);
				} else {
					syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v2.bootstrap.negotiate.nil");
				}

					if (initialPacket) {
						_signalingDataEmitted(initialPacket->bytes);
					}
					if (negotiatePacket) {
						_signalingDataEmitted(negotiatePacket->bytes);
					}
						if (candidatesPacket) {
							syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v2.bootstrap.candidates.emitSynthetic bytes=%lu",
								(unsigned long)candidatesPacket->bytes.size());
							_signalingDataEmitted(candidatesPacket->bytes);
						}
							syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.v2.bootstrap.emitted initial=%d negotiate=%d candidates=%d",
								initialPacket ? 1 : 0,
								negotiatePacket ? 1 : 0,
								candidatesPacket ? 1 : 0);
					if (candidatesPacket) {
						return candidatesPacket->counter;
					}
					if (negotiatePacket) {
						return negotiatePacket->counter;
					}
					if (initialPacket) {
						return initialPacket->counter;
					}
					return uint32_t(0);
				}
			} else if (absl::get_if<RemoteNetworkStatusMessage>(&message.data)) {
			RTC_LOG(LS_INFO) << "IOS6WEBRTC manager.signaling.dropRemoteNetworkStatus";
			return uint32_t(0);
		} else if (absl::get_if<RemoteMediaStateMessage>(&message.data)) {
			RTC_LOG(LS_INFO) << "IOS6WEBRTC manager.signaling.dropRemoteMediaState";
			return uint32_t(0);
		} else if (absl::get_if<VideoFormatsMessage>(&message.data)) {
			RTC_LOG(LS_INFO) << "IOS6WEBRTC manager.signaling.dropVideoFormats";
			return uint32_t(0);
		} else {
			RTC_LOG(LS_INFO) << "IOS6WEBRTC manager.signaling.dropOther";
			return uint32_t(0);
		}
		if (const auto prepared = _signaling.prepareForSending(message)) {
			fprintf(stderr, "IOS6WEBRTC cxx.manager.signaling.emit bytes=%lu counter=%u\n",
				(unsigned long)prepared->bytes.size(),
				prepared->counter);
			fflush(stderr);
			syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.signaling.emit bytes=%lu counter=%u",
				(unsigned long)prepared->bytes.size(),
				prepared->counter);
			_signalingDataEmitted(prepared->bytes);
			return prepared->counter;
		}
		fprintf(stderr, "IOS6WEBRTC cxx.manager.signaling.prepare.nil\n");
		fflush(stderr);
		syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.signaling.prepare.nil");
		return uint32_t(0);
	};
	_sendTransportMessage = [=](Message &&message) {
		std::shared_ptr<Message> messagePtr(new Message(std::move(message)));
		_networkManager->perform([messagePtr](NetworkManager *networkManager) {
			networkManager->sendMessage(*messagePtr);
		});
	};
}

Manager::~Manager() {
	assert(_thread->IsCurrent());
}

void Manager::sendSignalingAsync(int delayMs, int cause) {
	std::weak_ptr<Manager> weak(shared_from_this());
	auto task = [weak, cause] {
		const auto strong = weak.lock();
		if (!strong) {
			return;
		}
		if (const auto prepared = strong->_signaling.prepareForSendingService(cause)) {
			strong->_signalingDataEmitted(prepared->bytes);
		}
	};
	if (delayMs) {
		_thread->PostDelayedTask(std::move(task), webrtc::TimeDelta::Millis(delayMs));
	} else {
		_thread->PostTask(std::move(task));
	}
}

void Manager::start() {
	fprintf(stderr, "IOS6WEBRTC cxx.manager.start.enter servers=%lu\n", (unsigned long)_rtcServers.size());
	fflush(stderr);
	syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.start.enter servers=%lu", (unsigned long)_rtcServers.size());
	const auto weak = std::weak_ptr<Manager>(shared_from_this());
	const auto thread = _thread;
	const auto sendSignalingMessage = [=](Message &&message) {
		std::shared_ptr<Message> messagePtr(new Message(std::move(message)));
		thread->PostTask([=]() mutable {
			const auto strong = weak.lock();
			if (!strong) {
				return;
			}
			strong->_sendSignalingMessage(std::move(*messagePtr));
		});
	};
	EncryptionKey encryptionKey = _encryptionKey;
	bool enableP2P = _enableP2P;
	bool enableTCP = _enableTCP;
	bool enableStunMarking = _enableStunMarking;
	std::vector<RtcServer> rtcServers = _rtcServers;
	std::shared_ptr<std::unique_ptr<Proxy>> proxyPtr(new std::unique_ptr<Proxy>(std::move(_proxy)));
	fprintf(stderr, "IOS6WEBRTC cxx.manager.network.before\n");
	fflush(stderr);
	syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.network.before");
	_networkManager.reset(new ThreadLocalObject<NetworkManager>(StaticThreads::getNetworkThread(), [weak, thread, sendSignalingMessage, encryptionKey, enableP2P, enableTCP, enableStunMarking, rtcServers, proxyPtr] () mutable {
		fprintf(stderr, "IOS6WEBRTC cxx.manager.network.construct.lambda servers=%lu\n", (unsigned long)rtcServers.size());
		fflush(stderr);
		syslog(LOG_NOTICE, "IOS6WEBRTC cxx.manager.network.construct.lambda servers=%lu", (unsigned long)rtcServers.size());
		return std::make_shared<NetworkManager>(
            StaticThreads::getNetworkThread(),
			encryptionKey,
			enableP2P,
            enableTCP,
            enableStunMarking,
			rtcServers,
            std::move(*proxyPtr),
			[=](const NetworkManager::State &state) {
				thread->PostTask([=] {
					const auto strong = weak.lock();
					if (!strong) {
						return;
					}
                    State mappedState;
                    if (state.isFailed) {
                        mappedState = State::Failed;
                    } else {
                        mappedState = state.isReadyToSendData
                            ? State::Established
                            : State::Reconnecting;
                    }
                    bool isFirstConnection = false;
					if (state.isReadyToSendData) {
						if (!strong->_didConnectOnce) {
							strong->_didConnectOnce = true;
                            isFirstConnection = true;
						}
					}
					strong->_state = mappedState;
					strong->_stateUpdated(mappedState);

					strong->_mediaManager->perform([=](MediaManager *mediaManager) {
						mediaManager->setIsConnected(state.isReadyToSendData);
					});

                    if (isFirstConnection) {
                        strong->sendInitialSignalingMessages();
                    }
				});
			},
			[=](DecryptedMessage &&message) {
				std::shared_ptr<DecryptedMessage> messagePtr(new DecryptedMessage(std::move(message)));
				thread->PostTask([=]() mutable {
					if (const auto strong = weak.lock()) {
						strong->receiveMessage(std::move(*messagePtr));
					}
				});
			},
			sendSignalingMessage,
			[=](int delayMs, int cause) {
				const auto task = [=] {
					if (const auto strong = weak.lock()) {
						strong->_networkManager->perform([=](NetworkManager *networkManager) {
							networkManager->sendTransportService(cause);
							});
					}
				};
				if (delayMs) {
					thread->PostDelayedTask(task, webrtc::TimeDelta::Millis(delayMs));
				} else {
					thread->PostTask(task);
				}
			});
	}));
	bool isOutgoing = _encryptionKey.isOutgoing;
	ProtocolVersion protocolVersion = _protocolVersion;
	std::shared_ptr<VideoCaptureInterface> videoCapture = _videoCapture;
	MediaDevicesConfig mediaDevicesConfig = _mediaDevicesConfig;
	bool enableHighBitrateVideo = _enableHighBitrateVideo;
	std::function<void(int)> signalBarsUpdated = _signalBarsUpdated;
	std::function<void(float)> audioLevelUpdated = _audioLevelUpdated;
	std::vector<std::string> preferredCodecs = _preferredCodecs;
	std::function<webrtc::scoped_refptr<webrtc::AudioDeviceModule>(webrtc::TaskQueueFactory*)> createAudioDeviceModule = _createAudioDeviceModule;
	_mediaManager.reset(new ThreadLocalObject<MediaManager>(StaticThreads::getMediaThread(), [weak, isOutgoing, protocolVersion, thread, sendSignalingMessage, videoCapture, mediaDevicesConfig, enableHighBitrateVideo, signalBarsUpdated, audioLevelUpdated, preferredCodecs, createAudioDeviceModule]() {
		return std::make_shared<MediaManager>(
            StaticThreads::getMediaThread(),
			isOutgoing,
            protocolVersion,
			mediaDevicesConfig,
			videoCapture,
			sendSignalingMessage,
			[=](Message &&message) {
				std::shared_ptr<Message> messagePtr(new Message(std::move(message)));
				thread->PostTask([=]() mutable {
					const auto strong = weak.lock();
					if (!strong) {
						return;
					}
					strong->_sendTransportMessage(std::move(*messagePtr));
				});
			},
            signalBarsUpdated,
            audioLevelUpdated,
			createAudioDeviceModule,
			enableHighBitrateVideo,
            preferredCodecs);
	}));
    _networkManager->perform([](NetworkManager *networkManager) {
        networkManager->start();
    });
	_mediaManager->perform([](MediaManager *mediaManager) {
		mediaManager->start();
	});
}

void Manager::receiveSignalingData(const std::vector<uint8_t> &data) {
	if (auto decrypted = _signaling.handleIncomingPacket((const char*)data.data(), data.size())) {
		receiveMessage(std::move(decrypted->main));
		for (auto &message : decrypted->additional) {
			receiveMessage(std::move(message));
		}
	}
}

void Manager::receiveMessage(DecryptedMessage &&message) {
	const auto data = &message.message.data;
	if (const auto candidatesList = absl::get_if<CandidatesListMessage>(data)) {
		std::shared_ptr<DecryptedMessage> messagePtr(new DecryptedMessage(std::move(message)));
		_networkManager->perform([messagePtr](NetworkManager *networkManager) mutable {
			networkManager->receiveSignalingMessage(std::move(*messagePtr));
		});
	} else if (const auto videoFormats = absl::get_if<VideoFormatsMessage>(data)) {
		std::shared_ptr<DecryptedMessage> messagePtr(new DecryptedMessage(std::move(message)));
		_mediaManager->perform([messagePtr](MediaManager *mediaManager) mutable {
			mediaManager->receiveMessage(std::move(*messagePtr));
		});
    } else if (const auto remoteMediaState = absl::get_if<RemoteMediaStateMessage>(data)) {
		if (_remoteMediaStateUpdated) {
			_remoteMediaStateUpdated(
				remoteMediaState->audio,
				remoteMediaState->video);
		}
		VideoState video = remoteMediaState->video;
        _mediaManager->perform([video](MediaManager *mediaManager) {
            mediaManager->remoteVideoStateUpdated(video);
        });
	} else if (const auto remoteBatteryLevelIsLow = absl::get_if<RemoteBatteryLevelIsLowMessage>(data)) {
        if (_remoteBatteryLevelIsLowUpdated) {
			_remoteBatteryLevelIsLowUpdated(remoteBatteryLevelIsLow->batteryLow);
        }
    } else if (const auto remoteNetworkStatus = absl::get_if<RemoteNetworkStatusMessage>(data)) {
        _remoteNetworkIsLowCost = remoteNetworkStatus->isLowCost;
        _remoteIsLowDataRequested = remoteNetworkStatus->isLowDataRequested;
        updateCurrentResolvedNetworkStatus();
    } else {
        if (const auto videoParameters = absl::get_if<VideoParametersMessage>(data)) {
            float value = ((float)videoParameters->aspectRatio) / 1000.0;
			if (_remotePrefferedAspectRatioUpdated) {
				_remotePrefferedAspectRatioUpdated(value);
			}
        }
		std::shared_ptr<DecryptedMessage> messagePtr(new DecryptedMessage(std::move(message)));
		_mediaManager->perform([=](MediaManager *mediaManager) mutable {
			mediaManager->receiveMessage(std::move(*messagePtr));
		});
	}
}

void Manager::setVideoCapture(std::shared_ptr<VideoCaptureInterface> videoCapture) {
	assert(_didConnectOnce);

	if (_videoCapture == videoCapture) {
		return;
	}
    _videoCapture = videoCapture;
    _mediaManager->perform([videoCapture](MediaManager *mediaManager) {
        mediaManager->setSendVideo(videoCapture);
    });
}

void Manager::sendVideoDeviceUpdated() {
    _mediaManager->perform([](MediaManager *mediaManager) {
        mediaManager->sendVideoDeviceUpdated();
    });
}

void Manager::setRequestedVideoAspect(float aspect) {
    _mediaManager->perform([aspect](MediaManager *mediaManager) {
        mediaManager->setRequestedVideoAspect(aspect);
    });
}

void Manager::setMuteOutgoingAudio(bool mute) {
	_mediaManager->perform([mute](MediaManager *mediaManager) {
		mediaManager->setMuteOutgoingAudio(mute);
	});
}

void Manager::setIncomingVideoOutput(std::weak_ptr<rtc::VideoSinkInterface<webrtc::VideoFrame>> sink) {
	_mediaManager->perform([sink](MediaManager *mediaManager) {
		mediaManager->setIncomingVideoOutput(sink);
	});
}

void Manager::setIsLowBatteryLevel(bool isLowBatteryLevel) {
    _sendTransportMessage(makeRemoteBatteryLevelIsLowMessage(isLowBatteryLevel));
}

void Manager::setIsLocalNetworkLowCost(bool isLocalNetworkLowCost) {
    if (isLocalNetworkLowCost != _localNetworkIsLowCost) {
        _networkManager->perform([isLocalNetworkLowCost](NetworkManager *networkManager) {
            networkManager->setIsLocalNetworkLowCost(isLocalNetworkLowCost);
        });

        _localNetworkIsLowCost = isLocalNetworkLowCost;
        updateCurrentResolvedNetworkStatus();
    }
}

void Manager::getNetworkStats(std::function<void (TrafficStats, CallStats)> completion) {
	rtc::Thread *thread = _thread;
	std::weak_ptr<Manager> weak(shared_from_this());
	std::shared_ptr<std::function<void (TrafficStats, CallStats)>> completionPtr(new std::function<void (TrafficStats, CallStats)>(std::move(completion)));
	FilePath statsLogPath = _statsLogPath;
    _networkManager->perform([thread, weak, completionPtr, statsLogPath](NetworkManager *networkManager) {
        auto networkStats = networkManager->getNetworkStats();

        CallStats callStats;
        networkManager->fillCallStats(callStats);

		std::shared_ptr<CallStats> callStatsPtr(new CallStats(std::move(callStats)));
        thread->PostTask([weak, networkStats, completionPtr, callStatsPtr, statsLogPath] {
            const auto strong = weak.lock();
            if (!strong) {
                return;
            }

            strong->_mediaManager->perform([networkStats, completionPtr, callStatsPtr, statsLogPath](MediaManager *mediaManager) {
                CallStats callStats = std::move(*callStatsPtr);
                mediaManager->fillCallStats(callStats);
                dumpStatsLog(statsLogPath, callStats);
                (*completionPtr)(networkStats, callStats);
            });
        });
    });
}

void Manager::updateCurrentResolvedNetworkStatus() {
    bool localIsLowDataRequested = false;
    switch (_dataSaving) {
        case DataSaving::Never:
            localIsLowDataRequested = false;
            break;
        case DataSaving::Mobile:
            localIsLowDataRequested = !_localNetworkIsLowCost;
            break;
        case DataSaving::Always:
            localIsLowDataRequested = true;
        default:
            break;
    }

    ResolvedNetworkStatus localStatus;
    localStatus.isLowCost = _localNetworkIsLowCost;
    localStatus.isLowDataRequested = localIsLowDataRequested;

    if (!_currentResolvedLocalNetworkStatus.has_value() || *_currentResolvedLocalNetworkStatus != localStatus) {
        _currentResolvedLocalNetworkStatus = localStatus;

        switch (_protocolVersion) {
            case ProtocolVersion::V1:
                RTC_LOG(LS_INFO) << "IOS6WEBRTC manager.skipNetworkStatusUpdate";
                break;
            default:
                break;
        }
    }

    ResolvedNetworkStatus status;
    status.isLowCost = _localNetworkIsLowCost && _remoteNetworkIsLowCost;
    status.isLowDataRequested = localIsLowDataRequested || _remoteIsLowDataRequested;

    if (!_currentResolvedNetworkStatus.has_value() || *_currentResolvedNetworkStatus != status) {
        _currentResolvedNetworkStatus = status;
        _mediaManager->perform([status](MediaManager *mediaManager) {
            mediaManager->setNetworkParameters(status.isLowCost, status.isLowDataRequested);
        });
    }
}

void Manager::sendInitialSignalingMessages() {
    RTC_LOG(LS_INFO) << "IOS6WEBRTC manager.skipInitialNetworkStatus";
}

void Manager::setAudioInputDevice(std::string id) {
	_mediaManager->perform([id](MediaManager *mediaManager) {
		mediaManager->setAudioInputDevice(id);
	});
}

void Manager::setAudioOutputDevice(std::string id) {
	_mediaManager->perform([id](MediaManager *mediaManager) {
		mediaManager->setAudioOutputDevice(id);
	});
}

void Manager::setInputVolume(float level) {
	_mediaManager->perform([level](MediaManager *mediaManager) {
		mediaManager->setInputVolume(level);
	});
}

void Manager::setOutputVolume(float level) {
	_mediaManager->perform([level](MediaManager *mediaManager) {
		mediaManager->setOutputVolume(level);
	});
}

void Manager::addExternalAudioSamples(std::vector<uint8_t> &&samples) {
	std::shared_ptr<std::vector<uint8_t>> samplesPtr(new std::vector<uint8_t>(std::move(samples)));
    _mediaManager->perform([samplesPtr](MediaManager *mediaManager) mutable {
        mediaManager->addExternalAudioSamples(std::move(*samplesPtr));
    });
}

} // namespace tgcalls
