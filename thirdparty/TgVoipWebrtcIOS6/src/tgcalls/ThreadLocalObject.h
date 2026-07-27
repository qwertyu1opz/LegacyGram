#ifndef TGCALLS_THREAD_LOCAL_OBJECT_H
#define TGCALLS_THREAD_LOCAL_OBJECT_H

#include "rtc_base/thread.h"

#include <assert.h>
#include <functional>
#include <memory>

namespace tgcalls {

template <typename T>
class ThreadLocalObject {
public:
	template <
		typename Generator,
		typename = std::enable_if_t<std::is_same<std::shared_ptr<T>, decltype(std::declval<Generator>()())>::value>>
	ThreadLocalObject(rtc::Thread *thread, Generator &&generator) :
	_thread(thread),
	_valueHolder(std::make_unique<ValueHolder>()) {
		assert(_thread != nullptr);
		ValueHolder *valueHolder = _valueHolder.get();
		Generator generatorCopy(std::forward<Generator>(generator));
		_thread->PostTask([valueHolder, generatorCopy]() mutable {
			valueHolder->_value = generatorCopy();
		});
	}

	~ThreadLocalObject() {
		std::shared_ptr<ValueHolder> valueHolder(_valueHolder.release());
		_thread->PostTask([valueHolder](){
			valueHolder->_value.reset();
		});
	}

	template <typename FunctorT>
	void perform(FunctorT &&functor) {
		ValueHolder *valueHolder = _valueHolder.get();
		FunctorT f(std::forward<FunctorT>(functor));
		_thread->PostTask([valueHolder, f]() mutable {
			assert(valueHolder->_value != nullptr);
			f(valueHolder->_value.get());
		});
	}

	T *getSyncAssumingSameThread() {
		assert(_thread->IsCurrent());
		assert(_valueHolder->_value != nullptr);
		return _valueHolder->_value.get();
	}

private:
	struct ValueHolder {
		std::shared_ptr<T> _value;
	};

	rtc::Thread *_thread = nullptr;
	std::unique_ptr<ValueHolder> _valueHolder;

};

} // namespace tgcalls

#endif
