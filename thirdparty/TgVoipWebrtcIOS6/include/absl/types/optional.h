#ifndef TGIOS6_ABSL_TYPES_OPTIONAL_H
#define TGIOS6_ABSL_TYPES_OPTIONAL_H

#include <new>
#include <utility>

namespace absl {

struct nullopt_t {
	explicit nullopt_t(int) {
	}
};

static const nullopt_t nullopt(0);

template <class T>
class optional {
public:
	optional() : _has(false) {
	}

	optional(nullopt_t) : _has(false) {
	}

	optional(const T &value) : _has(true) {
		new (&_storage) T(value);
	}

	optional(T &&value) : _has(true) {
		new (&_storage) T(std::move(value));
	}

	optional(const optional &other) : _has(other._has) {
		if (_has) {
			new (&_storage) T(other.value());
		}
	}

	optional(optional &&other) : _has(other._has) {
		if (_has) {
			new (&_storage) T(std::move(other.value()));
		}
	}

	~optional() {
		reset();
	}

	optional &operator=(nullopt_t) {
		reset();
		return *this;
	}

	optional &operator=(const optional &other) {
		if (this != &other) {
			reset();
			_has = other._has;
			if (_has) {
				new (&_storage) T(other.value());
			}
		}
		return *this;
	}

	explicit operator bool() const {
		return _has;
	}

	bool has_value() const {
		return _has;
	}

	T &value() {
		return *reinterpret_cast<T *>(&_storage);
	}

	const T &value() const {
		return *reinterpret_cast<const T *>(&_storage);
	}

	T &operator*() {
		return value();
	}

	const T &operator*() const {
		return value();
	}

	T *operator->() {
		return &value();
	}

	const T *operator->() const {
		return &value();
	}

private:
	void reset() {
		if (_has) {
			value().~T();
			_has = false;
		}
	}

	bool _has;
	typename std::aligned_storage<sizeof(T), alignof(T)>::type _storage;
};

} // namespace absl

#endif
