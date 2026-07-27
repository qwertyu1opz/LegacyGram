#ifndef TGIOS6_RTC_BASE_SSL_FINGERPRINT_H
#define TGIOS6_RTC_BASE_SSL_FINGERPRINT_H

#include <memory>
#include <string>

namespace rtc {

class SSLFingerprint {
public:
	SSLFingerprint() {
	}

	explicit SSLFingerprint(const std::string &algorithm) : algorithm(algorithm) {
	}

	std::string algorithm;
	std::string digest;
};

} // namespace rtc

#endif
