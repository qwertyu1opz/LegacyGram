#ifndef TGIOS6_RTC_BASE_TIME_UTILS_H
#define TGIOS6_RTC_BASE_TIME_UTILS_H

#include <stdint.h>

namespace rtc {

static inline uint32_t HostToNetwork32(uint32_t value) {
	return ((value & 0x000000ffU) << 24)
		| ((value & 0x0000ff00U) << 8)
		| ((value & 0x00ff0000U) >> 8)
		| ((value & 0xff000000U) >> 24);
}

static inline uint32_t NetworkToHost32(uint32_t value) {
	return HostToNetwork32(value);
}

} // namespace rtc

#endif
