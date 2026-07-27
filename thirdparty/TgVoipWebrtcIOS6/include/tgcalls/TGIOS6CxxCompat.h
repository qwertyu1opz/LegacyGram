#ifndef TGIOS6_CXX_COMPAT_H
#define TGIOS6_CXX_COMPAT_H

#include <memory>
#include <type_traits>
#include <utility>

#if __cplusplus < 201402L
namespace std {

template <class T, class... Args>
std::unique_ptr<T> make_unique(Args&&... args) {
    return std::unique_ptr<T>(new T(std::forward<Args>(args)...));
}

template <bool B, class T = void>
using enable_if_t = typename enable_if<B, T>::type;

} // namespace std
#endif

#endif
