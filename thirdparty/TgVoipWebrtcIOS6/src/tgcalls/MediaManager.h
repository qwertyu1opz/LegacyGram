#ifndef TGCALLS_MEDIA_MANAGER_H
#define TGCALLS_MEDIA_MANAGER_H

#ifdef TGCALLS_IOS6_AUDIO_ONLY

#include "Instance.h"
#include "Message.h"
#include "Stats.h"
#include "rtc_base/logging.h"

#include "../../../../submodules/libtgvoip/MediaStreamItf.h"
#include "../../../../submodules/libtgvoip/audio/AudioInput.h"
#include "../../../../submodules/libtgvoip/audio/AudioOutput.h"
#include "../../../../submodules/libtgvoip/os/darwin/AudioUnitIO.h"

extern "C" {
#include "opus.h"
}

#include <arpa/inet.h>
#include <algorithm>
#include <deque>
#include <memory>
#include <pthread.h>
#include <vector>

namespace tgcalls {

class MediaManager {
public:
	static rtc::Thread *getWorkerThread() {
		return nullptr;
	}

	MediaManager(
		rtc::Thread *,
		bool isOutgoing,
        ProtocolVersion,
		const MediaDevicesConfig &,
		std::shared_ptr<VideoCaptureInterface>,
		std::function<void(Message &&)> sendSignalingMessage,
		std::function<void(Message &&)> sendTransportMessage,
        std::function<void(int)> signalBarsUpdated,
        std::function<void(float)> audioLevelUpdated,
		std::function<webrtc::scoped_refptr<webrtc::AudioDeviceModule>(webrtc::TaskQueueFactory*)>,
        bool,
        std::vector<std::string>) :
		_isOutgoing(isOutgoing),
		_sendSignalingMessage(sendSignalingMessage),
		_sendTransportMessage(sendTransportMessage),
		_signalBarsUpdated(signalBarsUpdated),
		_audioLevelUpdated(audioLevelUpdated) {
		pthread_mutex_init(&_pcmMutex, NULL);
		pthread_mutex_init(&_outgoingPacketsMutex, NULL);
		pthread_cond_init(&_outgoingPacketsCond, NULL);
	}

	void start() {
		if (_started) {
			return;
		}
		_started = true;
		int error = 0;
		_opusEncoder = opus_encoder_create(48000, 1, OPUS_APPLICATION_VOIP, &error);
		if (_opusEncoder != NULL) {
			opus_encoder_ctl(_opusEncoder, OPUS_SET_BITRATE(32000));
			opus_encoder_ctl(_opusEncoder, OPUS_SET_COMPLEXITY(5));
			opus_encoder_ctl(_opusEncoder, OPUS_SET_SIGNAL(OPUS_SIGNAL_VOICE));
			opus_encoder_ctl(_opusEncoder, OPUS_SET_INBAND_FEC(1));
			opus_encoder_ctl(_opusEncoder, OPUS_SET_PACKET_LOSS_PERC(10));
		}
		_opusDecoder = opus_decoder_create(48000, 1, &error);
		if (pthread_create(&_outgoingPacketsThread, NULL, &MediaManager::OutgoingPacketsThreadEntry, this) == 0) {
			_outgoingPacketsThreadStarted = true;
		}
		RTC_LOG(LS_INFO) << "IOS6WEBRTC media.audio.unitDisabled hard=1";
		_audioInput.reset();
		_audioOutput.reset();
		_audioUnit.reset();
		RTC_LOG(LS_INFO) << "IOS6WEBRTC media.audio.start encoder=" << (_opusEncoder != NULL)
			<< " decoder=" << (_opusDecoder != NULL)
			<< " input=" << (_audioInput ? 1 : 0)
			<< " output=" << (_audioOutput ? 1 : 0);
	}
	void setIsConnected(bool connected) {
		_isConnected = connected;
		RTC_LOG(LS_INFO) << "IOS6WEBRTC media.audio.connected value=" << (_isConnected ? 1 : 0);
	}
	void notifyPacketSent(const rtc::SentPacket &) {
	}
	void setSendVideo(std::shared_ptr<VideoCaptureInterface>) {
	}
	void sendVideoDeviceUpdated() {
	}
    void setRequestedVideoAspect(float) {
	}
	void setMuteOutgoingAudio(bool mute) {
		_muted = mute;
	}
	void setIncomingVideoOutput(std::weak_ptr<rtc::VideoSinkInterface<webrtc::VideoFrame>>) {
	}
	void receiveMessage(DecryptedMessage &&message) {
		if (_shuttingDown) {
			return;
		}
		const Message *wrapped = &message.message;
		if (const AudioDataMessage *audio = absl::get_if<AudioDataMessage>(&wrapped->data)) {
			handleIncomingRtp(audio->data);
		}
	}
    void remoteVideoStateUpdated(VideoState) {
	}
    void setNetworkParameters(bool, bool) {
	}
    void fillCallStats(CallStats &) {
	}

	void setAudioInputDevice(std::string) {
	}
	void setAudioOutputDevice(std::string) {
	}
	void setInputVolume(float) {
	}
	void setOutputVolume(float) {
	}
    void addExternalAudioSamples(std::vector<uint8_t> &&) {
	}

	~MediaManager() {
		_shuttingDown = true;
		pthread_mutex_lock(&_outgoingPacketsMutex);
		pthread_cond_signal(&_outgoingPacketsCond);
		pthread_mutex_unlock(&_outgoingPacketsMutex);
		if (_audioInput) {
			_audioInput->SetCallback(NULL, NULL);
			_audioInput->Stop();
			_audioInput.reset();
		}
		if (_audioOutput) {
			_audioOutput->SetCallback(NULL, NULL);
			_audioOutput->Stop();
			_audioOutput.reset();
		}
		_audioUnit.reset();
		if (_opusEncoder != NULL) {
			opus_encoder_destroy(_opusEncoder);
			_opusEncoder = NULL;
		}
		if (_opusDecoder != NULL) {
			opus_decoder_destroy(_opusDecoder);
			_opusDecoder = NULL;
		}
		pthread_mutex_lock(&_pcmMutex);
		_decodedPcm.clear();
		pthread_mutex_unlock(&_pcmMutex);
		if (_outgoingPacketsThreadStarted) {
			pthread_join(_outgoingPacketsThread, NULL);
			_outgoingPacketsThreadStarted = false;
		}
		pthread_mutex_lock(&_outgoingPacketsMutex);
		_outgoingRtpPackets.clear();
		pthread_mutex_unlock(&_outgoingPacketsMutex);
		pthread_cond_destroy(&_outgoingPacketsCond);
		pthread_mutex_destroy(&_outgoingPacketsMutex);
		pthread_mutex_destroy(&_pcmMutex);
	}

private:
	static size_t InputCallback(unsigned char *data, size_t length, void *param) {
		if (param == NULL) {
			return 0;
		}
		return ((MediaManager *)param)->handleInputPcm(data, length);
	}

	static size_t OutputCallback(unsigned char *data, size_t length, void *param) {
		if (param == NULL) {
			if (data != NULL && length != 0) {
				memset(data, 0, length);
			}
			return 0;
		}
		return ((MediaManager *)param)->fillOutputPcm(data, length);
	}

	size_t handleInputPcm(unsigned char *data, size_t length) {
		if (_shuttingDown || !_isConnected || _muted || _opusEncoder == NULL || _sendTransportMessage == nullptr || length != 960 * 2) {
			return 0;
		}
		if (!_outgoingAudioTransportEnabled) {
			return 0;
		}

		unsigned char opusBuffer[512];
		int encoded = opus_encode(_opusEncoder, (const opus_int16 *)data, 960, opusBuffer, sizeof(opusBuffer));
		if (encoded <= 0) {
			return 0;
		}

		rtc::CopyOnWriteBuffer packet;
		unsigned char header[12];
		header[0] = 0x80;
		header[1] = 111;
		uint16_t seq = htons(_rtpSeq++);
		uint32_t timestamp = htonl(_rtpTimestamp);
		uint32_t ssrc = htonl(2);
		memcpy(header + 2, &seq, sizeof(seq));
		memcpy(header + 4, &timestamp, sizeof(timestamp));
		memcpy(header + 8, &ssrc, sizeof(ssrc));
		packet.AppendData(header, sizeof(header));
		packet.AppendData(opusBuffer, (size_t)encoded);
		_rtpTimestamp += 960;

		std::vector<uint8_t> queuedPacket((const uint8_t *)packet.data(), (const uint8_t *)packet.data() + packet.size());
		pthread_mutex_lock(&_outgoingPacketsMutex);
		if (!_shuttingDown) {
			if (_outgoingRtpPackets.size() > 8) {
				_outgoingRtpPackets.pop_front();
			}
			_outgoingRtpPackets.push_back(queuedPacket);
			pthread_cond_signal(&_outgoingPacketsCond);
		}
		pthread_mutex_unlock(&_outgoingPacketsMutex);
		_sentPackets++;
		if ((_sentPackets % 50) == 0) {
			RTC_LOG(LS_INFO) << "IOS6WEBRTC media.audio.sent packets=" << _sentPackets
				<< " opusLen=" << encoded;
		}
		return 0;
	}

	static void *OutgoingPacketsThreadEntry(void *param) {
		((MediaManager *)param)->outgoingPacketsLoop();
		return NULL;
	}

	void outgoingPacketsLoop() {
		while (true) {
			std::vector<uint8_t> packetBytes;
			pthread_mutex_lock(&_outgoingPacketsMutex);
			while (!_shuttingDown && _outgoingRtpPackets.empty()) {
				pthread_cond_wait(&_outgoingPacketsCond, &_outgoingPacketsMutex);
			}
			if (_shuttingDown && _outgoingRtpPackets.empty()) {
				pthread_mutex_unlock(&_outgoingPacketsMutex);
				break;
			}
			packetBytes = _outgoingRtpPackets.front();
			_outgoingRtpPackets.pop_front();
			pthread_mutex_unlock(&_outgoingPacketsMutex);

			if (_shuttingDown || _sendTransportMessage == nullptr || packetBytes.empty()) {
				continue;
			}
			rtc::CopyOnWriteBuffer packet;
			packet.AppendData(packetBytes.data(), packetBytes.size());
			Message message;
			message.data = AudioDataMessage{ packet };
			_sendTransportMessage(std::move(message));
		}
	}

	size_t fillOutputPcm(unsigned char *data, size_t length) {
		if (_shuttingDown) {
			if (data != NULL && length != 0) {
				memset(data, 0, length);
			}
			return 0;
		}
		pthread_mutex_lock(&_pcmMutex);
		if (!_decodedPcm.empty()) {
			std::vector<uint8_t> frame = _decodedPcm.front();
			_decodedPcm.pop_front();
			pthread_mutex_unlock(&_pcmMutex);
			size_t copyLength = std::min(length, frame.size());
			memcpy(data, frame.data(), copyLength);
			if (copyLength < length) {
				memset(data + copyLength, 0, length - copyLength);
			}
			return copyLength;
		}
		pthread_mutex_unlock(&_pcmMutex);
		memset(data, 0, length);
		return 0;
	}

	void handleIncomingRtp(const rtc::CopyOnWriteBuffer &packet) {
		if (_shuttingDown || _opusDecoder == NULL || packet.size() <= 12) {
			return;
		}
		const uint8_t *bytes = (const uint8_t *)packet.data();
		size_t headerLength = 12 + ((bytes[0] & 0x0f) * 4);
		if (packet.size() <= headerLength) {
			return;
		}
		opus_int16 pcm[960];
		int decoded = opus_decode(_opusDecoder, bytes + headerLength, (opus_int32)(packet.size() - headerLength), pcm, 960, 0);
		if (decoded <= 0) {
			return;
		}
		std::vector<uint8_t> frame((uint8_t *)pcm, (uint8_t *)pcm + decoded * 2);
		pthread_mutex_lock(&_pcmMutex);
		if (_decodedPcm.size() > 24) {
			_decodedPcm.pop_front();
		}
		_decodedPcm.push_back(frame);
		pthread_mutex_unlock(&_pcmMutex);
		_receivedPackets++;
		if (_signalBarsUpdated && (_receivedPackets % 20) == 0) {
			_signalBarsUpdated(4);
		}
		if (_audioLevelUpdated && (_receivedPackets % 20) == 0) {
			_audioLevelUpdated(1.0f);
		}
		if ((_receivedPackets % 50) == 0) {
			RTC_LOG(LS_INFO) << "IOS6WEBRTC media.audio.recv packets=" << _receivedPackets
				<< " payloadLen=" << (packet.size() - headerLength)
				<< " decoded=" << decoded;
		}
	}

private:
	bool _isOutgoing = false;
	bool _started = false;
	bool _isConnected = false;
	bool _muted = false;
	bool _shuttingDown = false;
	bool _outgoingAudioTransportEnabled = false;
	uint16_t _rtpSeq = 1;
	uint32_t _rtpTimestamp = 0;
	uint32_t _sentPackets = 0;
	uint32_t _receivedPackets = 0;
	OpusEncoder *_opusEncoder = NULL;
	OpusDecoder *_opusDecoder = NULL;
	std::function<void(Message &&)> _sendSignalingMessage;
	std::function<void(Message &&)> _sendTransportMessage;
	std::function<void(int)> _signalBarsUpdated;
	std::function<void(float)> _audioLevelUpdated;
	std::unique_ptr<tgvoip::audio::AudioUnitIO> _audioUnit;
	std::unique_ptr<tgvoip::audio::AudioInput> _audioInput;
	std::unique_ptr<tgvoip::audio::AudioOutput> _audioOutput;
	pthread_mutex_t _pcmMutex;
	std::deque<std::vector<uint8_t> > _decodedPcm;
	pthread_t _outgoingPacketsThread;
	bool _outgoingPacketsThreadStarted = false;
	pthread_mutex_t _outgoingPacketsMutex;
	pthread_cond_t _outgoingPacketsCond;
	std::deque<std::vector<uint8_t> > _outgoingRtpPackets;
};

} // namespace tgcalls

#else

#include "rtc_base/thread.h"
#include "rtc_base/copy_on_write_buffer.h"
#include "rtc_base/third_party/sigslot/sigslot.h"
#include "api/transport/field_trial_based_config.h"
#include "pc/rtp_sender.h"
#include "media/base/media_channel.h"
#include "pc/media_factory.h"
#include "api/environment/environment.h"

#include "Instance.h"
#include "Message.h"
#include "VideoCaptureInterface.h"
#include "Stats.h"

#include <functional>
#include <memory>

namespace webrtc {
class Call;
class RtcEventLogNull;
class TaskQueueFactory;
class VideoBitrateAllocatorFactory;
class VideoTrackSourceInterface;
class AudioDeviceModule;
} // namespace webrtc

namespace cricket {
class MediaEngineInterface;
class VoiceMediaChannel;
class VideoMediaChannel;
} // namespace cricket

namespace tgcalls {

class VideoSinkInterfaceProxyImpl;

class MediaManager : public sigslot::has_slots<>, public std::enable_shared_from_this<MediaManager> {
public:
	static rtc::Thread *getWorkerThread();

	MediaManager(
		rtc::Thread *thread,
		bool isOutgoing,
        ProtocolVersion protocolVersion,
		const MediaDevicesConfig &devicesConfig,
		std::shared_ptr<VideoCaptureInterface> videoCapture,
		std::function<void(Message &&)> sendSignalingMessage,
		std::function<void(Message &&)> sendTransportMessage,
        std::function<void(int)> signalBarsUpdated,
        std::function<void(float)> audioLevelUpdated,
		std::function<webrtc::scoped_refptr<webrtc::AudioDeviceModule>(webrtc::TaskQueueFactory*)> createAudioDeviceModule,
        bool enableHighBitrateVideo,
        std::vector<std::string> preferredCodecs);
	~MediaManager();

	void start();
	void setIsConnected(bool isConnected);
	void notifyPacketSent(const rtc::SentPacket &sentPacket);
	void setSendVideo(std::shared_ptr<VideoCaptureInterface> videoCapture);
	void sendVideoDeviceUpdated();
    void setRequestedVideoAspect(float aspect);
	void setMuteOutgoingAudio(bool mute);
	void setIncomingVideoOutput(std::weak_ptr<rtc::VideoSinkInterface<webrtc::VideoFrame>> sink);
	void receiveMessage(DecryptedMessage &&message);
    void remoteVideoStateUpdated(VideoState videoState);
    void setNetworkParameters(bool isLowCost, bool isDataSavingActive);
    void fillCallStats(CallStats &callStats);

	void setAudioInputDevice(std::string id);
	void setAudioOutputDevice(std::string id);
	void setInputVolume(float level);
	void setOutputVolume(float level);

    void addExternalAudioSamples(std::vector<uint8_t> &&samples);

private:
	struct SSRC {
		uint32_t incoming = 0;
		uint32_t outgoing = 0;
		uint32_t fecIncoming = 0;
		uint32_t fecOutgoing = 0;
	};

	class NetworkInterfaceImpl : public cricket::MediaChannelNetworkInterface {
	public:
		NetworkInterfaceImpl(MediaManager *mediaManager, bool isVideo);
        
		bool SendPacket(rtc::CopyOnWriteBuffer *packet, const rtc::PacketOptions& options) override;
		bool SendRtcp(rtc::CopyOnWriteBuffer *packet, const rtc::PacketOptions& options) override;
		int SetOption(SocketType type, rtc::Socket::Option opt, int option) override;

	private:
		bool sendTransportMessage(rtc::CopyOnWriteBuffer *packet, const rtc::PacketOptions& options);

		MediaManager *_mediaManager = nullptr;
		bool _isVideo = false;

	};

	friend class MediaManager::NetworkInterfaceImpl;

	void setPeerVideoFormats(VideoFormatsMessage &&peerFormats);

	bool computeIsSendingVideo() const;
    void configureSendingVideoIfNeeded();
	void checkIsSendingVideoChanged(bool wasSending);
	bool videoCodecsNegotiated() const;

    int getMaxVideoBitrate() const;
    int getMaxAudioBitrate() const;
    void adjustBitratePreferences(bool resetStartBitrate);
    bool computeIsReceivingVideo() const;
    void checkIsReceivingVideoChanged(bool wasReceiving);

	void setOutgoingVideoState(VideoState state);
	void setOutgoingAudioState(AudioState state);
	void sendVideoParametersMessage();
	void sendOutgoingMediaStateMessage();

	webrtc::scoped_refptr<webrtc::AudioDeviceModule> createAudioDeviceModule();

    void beginStatsTimer(int timeoutMs);
    void beginLevelsTimer(int timeoutMs);
    void collectStats();

	rtc::Thread *_thread = nullptr;
	std::unique_ptr<webrtc::RtcEventLogNull> _eventLog;

	std::function<void(Message &&)> _sendSignalingMessage;
	std::function<void(Message &&)> _sendTransportMessage;
    std::function<void(int)> _signalBarsUpdated;
    std::function<void(float)> _audioLevelUpdated;
	std::function<webrtc::scoped_refptr<webrtc::AudioDeviceModule>(webrtc::TaskQueueFactory*)> _createAudioDeviceModule;

	SSRC _ssrcAudio;
	SSRC _ssrcVideo;
	bool _enableFlexfec = true;

    ProtocolVersion _protocolVersion;

	bool _isConnected = false;
    bool _didConnectOnce = false;
	bool _readyToReceiveVideo = false;
    bool _didConfigureVideo = false;
	AudioState _outgoingAudioState = AudioState::Active;
	VideoState _outgoingVideoState = VideoState::Inactive;

	VideoFormatsMessage _myVideoFormats;
	std::vector<cricket::VideoCodec> _videoCodecs;
	absl::optional<cricket::VideoCodec> _videoCodecOut;

    webrtc::Environment _webrtcEnvironment;
    std::unique_ptr<webrtc::MediaFactory> _mediaFactory;
    std::unique_ptr<cricket::MediaEngineInterface> _mediaEngine;
	std::unique_ptr<webrtc::Call> _call;
	webrtc::LocalAudioSinkAdapter _audioSource;
	webrtc::scoped_refptr<webrtc::AudioDeviceModule> _audioDeviceModule;
	std::unique_ptr<cricket::VoiceMediaSendChannelInterface> _audioSendChannel;
    std::unique_ptr<cricket::VoiceMediaReceiveChannelInterface> _audioReceiveChannel;
	std::unique_ptr<cricket::VideoMediaSendChannelInterface> _videoSendChannel;
    bool _haveVideoSendChannel = false;
    std::unique_ptr<cricket::VideoMediaReceiveChannelInterface> _videoReceiveChannel;
	std::unique_ptr<webrtc::VideoBitrateAllocatorFactory> _videoBitrateAllocatorFactory;
	std::shared_ptr<VideoCaptureInterface> _videoCapture;
	std::shared_ptr<bool> _videoCaptureGuard;
    bool _isScreenCapture = false;
    std::shared_ptr<VideoSinkInterfaceProxyImpl> _incomingVideoSinkProxy;
    webrtc::RtpHeaderExtensionMap _audioRtpHeaderExtensionMap;
    webrtc::RtpHeaderExtensionMap _videoRtpHeaderExtensionMap;

    float _localPreferredVideoAspectRatio = 0.0f;
    float _preferredAspectRatio = 0.0f;
    bool _enableHighBitrateVideo = false;
    bool _isLowCostNetwork = false;
    bool _isDataSavingActive = false;

    float _currentAudioLevel = 0.0f;
    float _currentMyAudioLevel = 0.0f;

	std::unique_ptr<MediaManager::NetworkInterfaceImpl> _audioNetworkInterface;
	std::unique_ptr<MediaManager::NetworkInterfaceImpl> _videoNetworkInterface;

    std::vector<CallStatsBitrateRecord> _bitrateRecords;

    std::vector<float> _externalAudioSamples;
    webrtc::Mutex _externalAudioSamplesMutex;
};

} // namespace tgcalls

#endif

#endif
