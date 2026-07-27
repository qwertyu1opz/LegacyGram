#ifndef TGIOS6_RTC_BASE_NETWORK_MONITOR_FACTORY_H
#define TGIOS6_RTC_BASE_NETWORK_MONITOR_FACTORY_H

namespace rtc {

class NetworkMonitorFactory {
public:
	virtual ~NetworkMonitorFactory() {
	}
};

struct NetworkRoute {
	bool connected = false;
};

} // namespace rtc

#endif
