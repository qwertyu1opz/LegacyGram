#ifndef TGIOS6_ABSL_TYPES_VARIANT_H
#define TGIOS6_ABSL_TYPES_VARIANT_H

#include <new>
#include <type_traits>
#include <utility>

namespace absl {

namespace tgios6_variant {

template <class T, class... Ts>
struct max_size;

template <class T>
struct max_size<T> {
	static const size_t value = sizeof(T);
};

template <class T, class U, class... Ts>
struct max_size<T, U, Ts...> {
	static const size_t next = max_size<U, Ts...>::value;
	static const size_t value = sizeof(T) > next ? sizeof(T) : next;
};

template <class T, class... Ts>
struct max_align;

template <class T>
struct max_align<T> {
	static const size_t value = alignof(T);
};

template <class T, class U, class... Ts>
struct max_align<T, U, Ts...> {
	static const size_t next = max_align<U, Ts...>::value;
	static const size_t value = alignof(T) > next ? alignof(T) : next;
};

template <class Target, class Current, class... Rest>
struct index_of {
	static const int tail = index_of<Target, Rest...>::value;
	static const int value = std::is_same<Target, Current>::value ? 0 : (tail < 0 ? -1 : 1 + tail);
};

template <class Target, class Current>
struct index_of<Target, Current> {
	static const int value = std::is_same<Target, Current>::value ? 0 : -1;
};

template <int Index, class... Ts>
struct destroyer;

template <int Index, class T, class... Rest>
struct destroyer<Index, T, Rest...> {
	static void destroy(int active, void *storage) {
		if (active == Index) {
			reinterpret_cast<T *>(storage)->~T();
		} else {
			destroyer<Index + 1, Rest...>::destroy(active, storage);
		}
	}
};

template <int Index>
struct destroyer<Index> {
	static void destroy(int, void *) {
	}
};

template <int Index, class... Ts>
struct copier;

template <int Index, class T, class... Rest>
struct copier<Index, T, Rest...> {
	static void copy(int active, const void *from, void *to) {
		if (active == Index) {
			new (to) T(*reinterpret_cast<const T *>(from));
		} else {
			copier<Index + 1, Rest...>::copy(active, from, to);
		}
	}
};

template <int Index>
struct copier<Index> {
	static void copy(int, const void *, void *) {
	}
};

} // namespace tgios6_variant

template <class... Ts>
class variant {
public:
	variant() : _active(-1) {
	}

	template <class T>
	variant(const T &value) : _active(-1) {
		setValue(value);
	}

	template <class T>
	variant(T &&value) : _active(-1) {
		setValue(std::forward<T>(value));
	}

	variant(const variant &other) : _active(other._active) {
		tgios6_variant::copier<0, Ts...>::copy(other._active, &other._storage, &_storage);
	}

	~variant() {
		reset();
	}

	variant &operator=(const variant &other) {
		if (this != &other) {
			reset();
			_active = other._active;
			tgios6_variant::copier<0, Ts...>::copy(other._active, &other._storage, &_storage);
		}
		return *this;
	}

	template <class T>
	variant &operator=(T &&value) {
		setValue(std::forward<T>(value));
		return *this;
	}

	int index() const {
		return _active;
	}

	template <class T>
	T *get_if() {
		return _active == tgios6_variant::index_of<T, Ts...>::value
			? reinterpret_cast<T *>(&_storage)
			: nullptr;
	}

	template <class T>
	const T *get_if() const {
		return _active == tgios6_variant::index_of<T, Ts...>::value
			? reinterpret_cast<const T *>(&_storage)
			: nullptr;
	}

private:
	template <class T>
	void setValue(T &&value) {
		reset();
		typedef typename std::decay<T>::type Decayed;
		_active = tgios6_variant::index_of<Decayed, Ts...>::value;
		static_assert(tgios6_variant::index_of<Decayed, Ts...>::value >= 0, "type is not in absl::variant");
		new (&_storage) Decayed(std::forward<T>(value));
	}

	void reset() {
		if (_active >= 0) {
			tgios6_variant::destroyer<0, Ts...>::destroy(_active, &_storage);
			_active = -1;
		}
	}

	int _active;
	typename std::aligned_storage<
		tgios6_variant::max_size<Ts...>::value,
		tgios6_variant::max_align<Ts...>::value>::type _storage;
};

template <class T, class... Ts>
T *get_if(variant<Ts...> *value) {
	return value ? value->template get_if<T>() : nullptr;
}

template <class T, class... Ts>
const T *get_if(const variant<Ts...> *value) {
	return value ? value->template get_if<T>() : nullptr;
}

} // namespace absl

#endif
