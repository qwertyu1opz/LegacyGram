#ifndef TGIOS6_API_TRANSPORT_FIELD_TRIAL_BASED_CONFIG_H
#define TGIOS6_API_TRANSPORT_FIELD_TRIAL_BASED_CONFIG_H

namespace webrtc {

class FieldTrialsView {
public:
	virtual ~FieldTrialsView() {
	}
};

class FieldTrialBasedConfig : public FieldTrialsView {
};

} // namespace webrtc

#endif
