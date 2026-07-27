#ifndef TGIOS6_RTC_BASE_COPY_ON_WRITE_BUFFER_H
#define TGIOS6_RTC_BASE_COPY_ON_WRITE_BUFFER_H

#include <stdint.h>
#include <string>
#include <vector>

namespace rtc {

class CopyOnWriteBuffer {
public:
	CopyOnWriteBuffer() {
	}

	CopyOnWriteBuffer(const uint8_t *data, size_t size) : _data(data, data + size) {
	}

	explicit CopyOnWriteBuffer(size_t size) : _data(size) {
	}

	const uint8_t *data() const {
		return _data.empty() ? nullptr : &_data[0];
	}

	uint8_t *data() {
		return _data.empty() ? nullptr : &_data[0];
	}

	const uint8_t *cdata() const {
		return data();
	}

	void *MutableData() {
		return _data.empty() ? nullptr : &_data[0];
	}

	size_t size() const {
		return _data.size();
	}

	void SetSize(size_t size) {
		_data.resize(size);
	}

	void AppendData(const uint8_t *data, size_t size) {
		if (data != nullptr && size != 0) {
			_data.insert(_data.end(), data, data + size);
		}
	}

	void AppendData(const char *data, size_t size) {
		AppendData(reinterpret_cast<const uint8_t *>(data), size);
	}

	void AppendData(const CopyOnWriteBuffer &buffer) {
		AppendData(buffer.data(), buffer.size());
	}

private:
	std::vector<uint8_t> _data;

	};

struct PacketOptions {
	int packet_id = 0;
};

struct SentPacket {
	int packet_id = 0;
	int64_t send_time_ms = 0;
};

class Socket {
public:
	enum Option {
		OPT_DUMMY
	};
};

inline int64_t TimeMillis() {
	return 0;
}

class PacketTransportInternal {
public:
	virtual ~PacketTransportInternal() {
	}

	virtual const std::string &transport_name() const {
		static std::string empty;
		return empty;
	}

	virtual bool writable() const { return false; }
	virtual bool receiving() const { return false; }
	virtual int SendPacket(const char *, size_t, const PacketOptions &, int = 0) { return -1; }
	virtual int SetOption(Socket::Option, int) { return 0; }
	virtual bool GetOption(Socket::Option, int *) { return false; }
	virtual int GetError() { return 0; }

};

class Buffer : public CopyOnWriteBuffer {
public:
	Buffer() {
	}

	explicit Buffer(size_t size) : CopyOnWriteBuffer(size) {
	}

	Buffer(const uint8_t *data, size_t size) : CopyOnWriteBuffer(data, size) {
	}
};

} // namespace rtc

#endif
