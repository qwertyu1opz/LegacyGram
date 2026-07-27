#ifndef TGIOS6_OPENSSL_MODES_H
#define TGIOS6_OPENSSL_MODES_H

#include "openssl/aes.h"
#include <stddef.h>
#include <stdint.h>

typedef void (*block128_f)(const unsigned char in[16], unsigned char out[16], const void *key);

static inline void tgios6_increment_counter(unsigned char counter[16]) {
	for (int i = 15; i >= 0; i--) {
		counter[i]++;
		if (counter[i] != 0) {
			break;
		}
	}
}

static inline void CRYPTO_ctr128_encrypt(
	const unsigned char *in,
	unsigned char *out,
	size_t len,
	const void *key,
	unsigned char ivec[16],
	unsigned char ecount_buf[16],
	unsigned int *num,
	block128_f block) {
	unsigned int n = num != 0 ? *num : 0;
	for (size_t i = 0; i < len; i++) {
		if (n == 0) {
			block(ivec, ecount_buf, key);
			tgios6_increment_counter(ivec);
		}
		out[i] = in[i] ^ ecount_buf[n];
		n = (n + 1) & 0x0f;
	}
	if (num != 0) {
		*num = n;
	}
}

#endif
