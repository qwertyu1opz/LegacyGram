#ifndef NW_BLAKE2S_H
#define NW_BLAKE2S_H

#include <stddef.h>
#include <stdint.h>

#define NW_BLAKE2S_OUTBYTES   32
#define NW_BLAKE2S_BLOCKBYTES 64
#define NW_BLAKE2S_KEYBYTES   32

typedef struct {
    uint32_t h[8];
    uint32_t t[2];
    uint32_t f[2];
    uint8_t  buf[NW_BLAKE2S_BLOCKBYTES];
    size_t   buflen;
    size_t   outlen;
} nw_blake2s_state;

int nw_blake2s_init(nw_blake2s_state *S, size_t outlen);
int nw_blake2s_init_key(nw_blake2s_state *S, size_t outlen, const void *key, size_t keylen);
int nw_blake2s_update(nw_blake2s_state *S, const void *in, size_t inlen);
int nw_blake2s_final(nw_blake2s_state *S, void *out, size_t outlen);

// One-shot: BLAKE2s(in) -> out[outlen]. key may be NULL/keylen 0.
int nw_blake2s(void *out, size_t outlen, const void *in, size_t inlen,
               const void *key, size_t keylen);

#endif // NW_BLAKE2S_H
