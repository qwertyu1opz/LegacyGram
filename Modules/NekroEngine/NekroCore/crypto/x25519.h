#ifndef NW_X25519_H
#define NW_X25519_H

#include <stdint.h>

// X25519 (RFC 7748). q = scalar(n) * point(p). 32-byte little-endian buffers.
// Returns 0. Derived from the TweetNaCl curve25519 implementation (public domain).
int nw_x25519(uint8_t q[32], const uint8_t n[32], const uint8_t p[32]);

// q = n * basepoint (9). The public key for private scalar n.
int nw_x25519_base(uint8_t q[32], const uint8_t n[32]);

#endif // NW_X25519_H
