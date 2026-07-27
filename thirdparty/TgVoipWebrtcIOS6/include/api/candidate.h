#ifndef TGIOS6_API_CANDIDATE_H
#define TGIOS6_API_CANDIDATE_H

#include <string>

namespace cricket {

class Candidate {
public:
	Candidate() {
	}

	std::string ToString() const {
		return _sdp;
	}

	void FromString(const std::string &sdp) {
		_sdp = sdp;
	}

private:
	std::string _sdp;
};

} // namespace cricket

#endif
