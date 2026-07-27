#ifndef TGIOS6_API_JSEP_ICE_CANDIDATE_H
#define TGIOS6_API_JSEP_ICE_CANDIDATE_H

#include "api/candidate.h"

namespace webrtc {

class JsepIceCandidate {
public:
	JsepIceCandidate(const std::string &, int) {
	}

	void SetCandidate(const cricket::Candidate &candidate) {
		_candidate = candidate;
	}

	bool ToString(std::string *value) const {
		if (value != nullptr) {
			*value = _candidate.ToString();
		}
		return true;
	}

	bool Initialize(const std::string &value, void *) {
		_candidate.FromString(value);
		return true;
	}

	const cricket::Candidate &candidate() const {
		return _candidate;
	}

private:
	cricket::Candidate _candidate;
};

} // namespace webrtc

#endif
