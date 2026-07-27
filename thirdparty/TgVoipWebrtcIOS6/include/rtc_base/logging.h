#ifndef TGIOS6_RTC_BASE_LOGGING_H
#define TGIOS6_RTC_BASE_LOGGING_H

#include "rtc_base/checks.h"

namespace rtc {

enum LoggingSeverity {
	LS_VERBOSE,
	LS_INFO,
	LS_WARNING,
	LS_ERROR
};

class LogSink {
public:
	virtual ~LogSink() {
	}
	virtual void OnLogMessage(const std::string &, LoggingSeverity, const char *) {
	}
	virtual void OnLogMessage(const std::string &, LoggingSeverity) {
	}
	virtual void OnLogMessage(const std::string &) {
	}
};

class LogMessage {
public:
	static void LogToDebug(LoggingSeverity) {
	}
	static void SetLogToStderr(bool) {
	}
	static void AddLogToStream(LogSink *, LoggingSeverity) {
	}
	static void RemoveLogToStream(LogSink *) {
	}
};

} // namespace rtc

static const rtc::LoggingSeverity LS_ERROR = rtc::LS_ERROR;
static const rtc::LoggingSeverity LS_INFO = rtc::LS_INFO;
#define RTC_LOG(severity) tgcalls_ios6_rtc::LogSink()

#endif
