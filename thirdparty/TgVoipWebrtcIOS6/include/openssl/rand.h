#ifndef TGIOS6_OPENSSL_RAND_H
#define TGIOS6_OPENSSL_RAND_H

#include <Security/SecRandom.h>

static inline int RAND_bytes(unsigned char *buf, int num) {
	return SecRandomCopyBytes(kSecRandomDefault, (size_t)num, buf) == 0 ? 1 : 0;
}

#endif
