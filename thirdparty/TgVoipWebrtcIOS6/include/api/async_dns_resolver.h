#ifndef TGIOS6_API_ASYNC_DNS_RESOLVER_H
#define TGIOS6_API_ASYNC_DNS_RESOLVER_H

namespace webrtc {

class AsyncDnsResolverFactoryInterface {
public:
	virtual ~AsyncDnsResolverFactoryInterface() {
	}
};

class BasicAsyncResolverFactory : public AsyncDnsResolverFactoryInterface {
};

} // namespace webrtc

#endif
