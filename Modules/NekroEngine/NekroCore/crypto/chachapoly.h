#ifndef NW_CHACHAPOLY_H
#define NW_CHACHAPOLY_H

#include <stddef.h>
#include <stdint.h>

// ChaCha20-Poly1305 AEAD (RFC 8439), 256-bit key, 96-bit nonce.
// encrypt: writes plen ciphertext bytes + 16-byte tag to out (needs plen+16).
// decrypt: clen = ciphertext+tag; writes clen-16 plaintext to out. Returns 0 on
//          success, -1 on auth failure (constant-time tag compare).
int nw_chacha20poly1305_encrypt(uint8_t *out,
                                const uint8_t *plain, size_t plen,
                                const uint8_t *aad, size_t aadlen,
                                const uint8_t key[32], const uint8_t nonce[12]);
int nw_chacha20poly1305_decrypt(uint8_t *out,
                                const uint8_t *cipher, size_t clen,
                                const uint8_t *aad, size_t aadlen,
                                const uint8_t key[32], const uint8_t nonce[12]);

// Raw ChaCha20 keystream XOR (RFC 8439), exposed for tests/benchmarks.
void nw_chacha20_xor(uint8_t *out, const uint8_t *in, size_t len,
                     const uint8_t key[32], const uint8_t nonce[12], uint32_t counter);

#endif // NW_CHACHAPOLY_H
