#ifndef TGIOS6_API_VIDEO_CODECS_SDP_VIDEO_FORMAT_H
#define TGIOS6_API_VIDEO_CODECS_SDP_VIDEO_FORMAT_H

#include <map>
#include <string>

namespace webrtc {

struct SdpVideoFormat {
	std::string name;
	std::map<std::string, std::string> parameters;

	SdpVideoFormat() {
	}

	explicit SdpVideoFormat(const std::string &name_) : name(name_) {
	}
};

} // namespace webrtc

#endif
