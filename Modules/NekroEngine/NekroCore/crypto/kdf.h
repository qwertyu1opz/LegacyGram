#ifndef NW_KDF_H
#define NW_KDF_H

#include <stddef.h>
#include <stdint.h>

// HMAC-BLAKE2s-256 (block size 64), as WireGuard uses inside its KDF.
void nw_hmac_blake2s(uint8_t out[32], const uint8_t *key, size_t keylen,
                     const uint8_t *data, size_t datalen);

// WireGuard's HKDF (RFC 5869 with BLAKE2s). Derives up to three 32-byte outputs
// from a chaining key + input keying material. Pass NULL for outputs you don't need.
void nw_kdf(uint8_t *out1, uint8_t *out2, uint8_t *out3,
            const uint8_t chaining_key[32],
            const uint8_t *data, size_t datalen);

#endif // NW_KDF_H
