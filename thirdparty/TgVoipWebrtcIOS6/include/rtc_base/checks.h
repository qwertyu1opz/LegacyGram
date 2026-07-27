#ifndef TGIOS6_RTC_BASE_CHECKS_H
#define TGIOS6_RTC_BASE_CHECKS_H

#include <sstream>

namespace tgcalls_ios6_rtc {

class LogSink {
public:
	template <class T>
	LogSink &operator<<(const T &) {
		return *this;
	}
};

} // namespace tgcalls_ios6_rtc

#define RTC_FATAL() tgcalls_ios6_rtc::LogSink()

#endif
