#ifndef TGIOS6_OPENSSL_AES_H
#define TGIOS6_OPENSSL_AES_H

#include <CommonCrypto/CommonCryptor.h>
#include <stdint.h>
#include <string.h>

#define AES_BLOCK_SIZE 16

typedef struct AES_KEY {
	unsigned char key[32];
	size_t keyLength;
} AES_KEY;

static inline int AES_set_encrypt_key(const unsigned char *userKey, const int bits, AES_KEY *key) {
	if (key == 0 || userKey == 0 || bits <= 0 || bits > 256) {
		return -1;
	}
	key->keyLength = (size_t)(bits / 8);
	memcpy(key->key, userKey, key->keyLength);
	return 0;
}

static inline void AES_encrypt(const unsigned char *in, unsigned char *out, const AES_KEY *key) {
	size_t moved = 0;
	CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode,
		key->key, key->keyLength,
		0,
		in, AES_BLOCK_SIZE,
		out, AES_BLOCK_SIZE,
		&moved);
}

#endif
