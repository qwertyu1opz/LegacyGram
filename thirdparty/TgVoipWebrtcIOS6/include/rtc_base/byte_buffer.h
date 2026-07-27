#ifndef TGIOS6_RTC_BASE_BYTE_BUFFER_H
#define TGIOS6_RTC_BASE_BYTE_BUFFER_H

#include <stdint.h>
#include <string>
#include <vector>

namespace rtc {

template <class T>
class ArrayView {
public:
	ArrayView(T *data, size_t size) : _data(data), _size(size) {
	}

	T *data() const {
		return _data;
	}

	size_t size() const {
		return _size;
	}

private:
	T *_data;
	size_t _size;
};

class ByteBufferWriter {
public:
	void WriteUInt8(uint8_t value) {
		_data.push_back(value);
	}

	void WriteUInt16(uint16_t value) {
		_data.push_back((uint8_t)(value >> 8));
		_data.push_back((uint8_t)value);
	}

	void WriteUInt32(uint32_t value) {
		_data.push_back((uint8_t)(value >> 24));
		_data.push_back((uint8_t)(value >> 16));
		_data.push_back((uint8_t)(value >> 8));
		_data.push_back((uint8_t)value);
	}

	void WriteString(const std::string &value) {
		_data.insert(_data.end(), value.begin(), value.end());
	}

	void WriteBytes(const uint8_t *data, size_t length) {
		if (data != nullptr && length != 0) {
			_data.insert(_data.end(), data, data + length);
		}
	}

	const char *Data() const {
		return _data.empty() ? nullptr : reinterpret_cast<const char *>(&_data[0]);
	}

	size_t Length() const {
		return _data.size();
	}

private:
	std::vector<uint8_t> _data;
};

class ByteBufferReader {
public:
	ByteBufferReader(const char *data, size_t length) : _data(reinterpret_cast<const uint8_t *>(data)), _length(length), _offset(0) {
	}

	size_t Length() const {
		return _length - _offset;
	}

	const uint8_t *Data() const {
		return _data + _offset;
	}

	void Consume(size_t length) {
		_offset += length;
		if (_offset > _length) {
			_offset = _length;
		}
	}

	bool ReadUInt8(uint8_t *value) {
		if (Length() < 1) return false;
		*value = _data[_offset++];
		return true;
	}

	bool ReadUInt16(uint16_t *value) {
		if (Length() < 2) return false;
		*value = (uint16_t(_data[_offset]) << 8) | uint16_t(_data[_offset + 1]);
		_offset += 2;
		return true;
	}

	bool ReadUInt32(uint32_t *value) {
		if (Length() < 4) return false;
		*value = (uint32_t(_data[_offset]) << 24) | (uint32_t(_data[_offset + 1]) << 16) | (uint32_t(_data[_offset + 2]) << 8) | uint32_t(_data[_offset + 3]);
		_offset += 4;
		return true;
	}

	bool ReadString(std::string *value, size_t length) {
		if (Length() < length) return false;
		value->assign(reinterpret_cast<const char *>(_data + _offset), length);
		_offset += length;
		return true;
	}

	bool ReadBytes(ArrayView<uint8_t> view) {
		if (Length() < view.size()) return false;
		for (size_t i = 0; i < view.size(); i++) {
			view.data()[i] = _data[_offset + i];
		}
		_offset += view.size();
		return true;
	}

private:
	const uint8_t *_data;
	size_t _length;
	size_t _offset;
};

} // namespace rtc

#endif
