#ifndef TGIOS6_OPENSSL_SHA_H
#define TGIOS6_OPENSSL_SHA_H

#include <CommonCrypto/CommonDigest.h>

#define SHA256_DIGEST_LENGTH CC_SHA256_DIGEST_LENGTH

typedef CC_SHA256_CTX SHA256_CTX;

static inline int SHA256_Init(SHA256_CTX *context) {
	return CC_SHA256_Init(context);
}

static inline int SHA256_Update(SHA256_CTX *context, const void *data, size_t length) {
	return CC_SHA256_Update(context, data, (CC_LONG)length);
}

static inline int SHA256_Final(unsigned char *digest, SHA256_CTX *context) {
	return CC_SHA256_Final(digest, context);
}

#endif
