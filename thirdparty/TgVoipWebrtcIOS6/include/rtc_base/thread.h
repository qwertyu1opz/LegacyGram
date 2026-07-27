#ifndef TGIOS6_RTC_BASE_THREAD_H
#define TGIOS6_RTC_BASE_THREAD_H

#include <memory>
#include <string>

namespace rtc {

class Thread {
public:
	static std::unique_ptr<Thread> Create() {
		return std::unique_ptr<Thread>(new Thread());
	}

	static std::unique_ptr<Thread> CreateWithSocketServer() {
		return std::unique_ptr<Thread>(new Thread());
	}

	void SetName(const std::string &, const void *) {
	}

	bool Start() {
		return true;
	}

	bool IsCurrent() const {
		return true;
	}

	void AllowInvokesToThread(Thread *) {
	}

	template <class Functor>
	void PostTask(Functor functor) {
		functor();
	}

	template <class Functor, class Delay>
	void PostDelayedTask(Functor functor, Delay) {
		functor();
	}
};

} // namespace rtc

#endif
