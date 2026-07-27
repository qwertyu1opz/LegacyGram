#ifndef TGIOS6_API_RTP_PARAMETERS_H
#define TGIOS6_API_RTP_PARAMETERS_H

#include <string>

namespace webrtc {

struct RtpExtension {
	std::string uri;
	int id = 0;

	RtpExtension() {
	}

	RtpExtension(const std::string &uri_, int id_) : uri(uri_), id(id_) {
	}

	bool operator==(const RtpExtension &rhs) const {
		return uri == rhs.uri && id == rhs.id;
	}

	bool operator!=(const RtpExtension &rhs) const {
		return !(*this == rhs);
	}

	static const char *kAbsSendTimeUri;
	static const char *kTransportSequenceNumberUri;
	static const char *kVideoRotationUri;
};

} // namespace webrtc

#endif
