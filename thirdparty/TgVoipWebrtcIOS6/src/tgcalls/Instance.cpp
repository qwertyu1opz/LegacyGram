#include "Instance.h"

#include <algorithm>
#include <stdio.h>
#include <stdarg.h>
#include <syslog.h>

namespace tgcalls {
namespace {

std::function<void(std::string const &)> globalLoggingFunction;

std::map<std::string, std::shared_ptr<Meta>> &MetaMap() {
	static auto result = std::map<std::string, std::shared_ptr<Meta>>();
	return result;
}

} // namespace

std::vector<std::string> Meta::Versions() {
	auto &map = MetaMap();
	auto result = std::vector<std::string>();
	result.reserve(map.size());
	for (const auto &entry : map) {
		result.push_back(entry.first);
	}
	return result;
}

int Meta::MaxLayer() {
	auto result = 0;
	for (const auto &entry : MetaMap()) {
		result = std::max(result, entry.second->connectionMaxLayer());
	}
	return result;
}

std::unique_ptr<Instance> Meta::Create(
		const std::string &version,
		Descriptor &&descriptor) {
	fprintf(stderr, "IOS6WEBRTC cxx.meta.create.enter version=%s servers=%lu keyOutgoing=%d\n",
		version.c_str(),
		(unsigned long)descriptor.rtcServers.size(),
		descriptor.encryptionKey.isOutgoing ? 1 : 0);
	fflush(stderr);
	syslog(LOG_NOTICE, "IOS6WEBRTC cxx.meta.create.enter version=%s servers=%lu keyOutgoing=%d",
		version.c_str(),
		(unsigned long)descriptor.rtcServers.size(),
		descriptor.encryptionKey.isOutgoing ? 1 : 0);
	const auto i = MetaMap().find(version);
	fprintf(stderr, "IOS6WEBRTC cxx.meta.create.lookup found=%d mapSize=%lu\n",
		i != MetaMap().end() ? 1 : 0,
		(unsigned long)MetaMap().size());
	fflush(stderr);
	syslog(LOG_NOTICE, "IOS6WEBRTC cxx.meta.create.lookup found=%d mapSize=%lu",
		i != MetaMap().end() ? 1 : 0,
		(unsigned long)MetaMap().size());

	// Enforce correct protocol version.
	if (version == "2.7.7") {
		descriptor.config.protocolVersion = ProtocolVersion::V0;
	} else if (version == "5.0.0") {
		descriptor.config.protocolVersion = ProtocolVersion::V1;
	}

	if (i == MetaMap().end()) {
		fprintf(stderr, "IOS6WEBRTC cxx.meta.create.missing version=%s\n", version.c_str());
		fflush(stderr);
		syslog(LOG_NOTICE, "IOS6WEBRTC cxx.meta.create.missing version=%s", version.c_str());
		return nullptr;
	}
	fprintf(stderr, "IOS6WEBRTC cxx.meta.create.construct.before version=%s\n", version.c_str());
	fflush(stderr);
	syslog(LOG_NOTICE, "IOS6WEBRTC cxx.meta.create.construct.before version=%s", version.c_str());
	std::unique_ptr<Instance> result = i->second->construct(std::move(descriptor));
	fprintf(stderr, "IOS6WEBRTC cxx.meta.create.construct.after instance=%p\n", result.get());
	fflush(stderr);
	syslog(LOG_NOTICE, "IOS6WEBRTC cxx.meta.create.construct.after instance=%p", result.get());
	return result;
}

void Meta::RegisterOne(std::shared_ptr<Meta> meta) {
	if (meta) {
		const auto versions = meta->versions();
        for (auto &it : versions) {
			fprintf(stderr, "IOS6WEBRTC cxx.meta.register version=%s\n", it.c_str());
			fflush(stderr);
			syslog(LOG_NOTICE, "IOS6WEBRTC cxx.meta.register version=%s", it.c_str());
            MetaMap().emplace(it, meta);
        }
	}
}

void SetLoggingFunction(std::function<void(std::string const &)> loggingFunction) {
	globalLoggingFunction = loggingFunction;
}

} // namespace tgcalls
