#ifndef TGIOS6_RTC_BASE_THIRD_PARTY_SIGSLOT_SIGSLOT_H
#define TGIOS6_RTC_BASE_THIRD_PARTY_SIGSLOT_SIGSLOT_H

namespace sigslot {

template <class mt_policy = void>
class has_slots {
public:
	virtual ~has_slots() {
	}
};

} // namespace sigslot

#endif
