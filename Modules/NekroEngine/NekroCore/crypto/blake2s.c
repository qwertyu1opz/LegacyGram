// BLAKE2s (RFC 7693) — reference implementation, public-domain style.
#include "blake2s.h"
#include <string.h>

static const uint32_t blake2s_IV[8] = {
    0x6A09E667UL, 0xBB67AE85UL, 0x3C6EF372UL, 0xA54FF53AUL,
    0x510E527FUL, 0x9B05688CUL, 0x1F83D9ABUL, 0x5BE0CD19UL
};

static const uint8_t blake2s_sigma[10][16] = {
    {  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15 },
    { 14, 10,  4,  8,  9, 15, 13,  6,  1, 12,  0,  2, 11,  7,  5,  3 },
    { 11,  8, 12,  0,  5,  2, 15, 13, 10, 14,  3,  6,  7,  1,  9,  4 },
    {  7,  9,  3,  1, 13, 12, 11, 14,  2,  6,  5, 10,  4,  0, 15,  8 },
    {  9,  0,  5,  7,  2,  4, 10, 15, 14,  1, 11, 12,  6,  8,  3, 13 },
    {  2, 12,  6, 10,  0, 11,  8,  3,  4, 13,  7,  5, 15, 14,  1,  9 },
    { 12,  5,  1, 15, 14, 13,  4, 10,  0,  7,  6,  3,  9,  2,  8, 11 },
    { 13, 11,  7, 14, 12,  1,  3,  9,  5,  0, 15,  4,  8,  6,  2, 10 },
    {  6, 15, 14,  9, 11,  3,  0,  8, 12,  2, 13,  7,  1,  4, 10,  5 },
    { 10,  2,  8,  4,  7,  6,  1,  5, 15, 11,  9, 14,  3, 12, 13,  0 }
};

static uint32_t load32(const void *src) {
    const uint8_t *p = (const uint8_t *)src;
    return ((uint32_t)p[0]) | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}
static void store32(void *dst, uint32_t w) {
    uint8_t *p = (uint8_t *)dst;
    p[0] = (uint8_t)w;       p[1] = (uint8_t)(w >> 8);
    p[2] = (uint8_t)(w >> 16); p[3] = (uint8_t)(w >> 24);
}
static uint32_t rotr32(uint32_t w, unsigned c) { return (w >> c) | (w << (32 - c)); }

static void blake2s_increment_counter(nw_blake2s_state *S, uint32_t inc) {
    S->t[0] += inc;
    S->t[1] += (S->t[0] < inc);
}

static void blake2s_compress(nw_blake2s_state *S, const uint8_t block[64]) {
    uint32_t m[16], v[16];
    int i;
    for (i = 0; i < 16; i++) m[i] = load32(block + i * 4);
    for (i = 0; i < 8; i++)  v[i] = S->h[i];
    v[8]  = blake2s_IV[0]; v[9]  = blake2s_IV[1];
    v[10] = blake2s_IV[2]; v[11] = blake2s_IV[3];
    v[12] = S->t[0] ^ blake2s_IV[4]; v[13] = S->t[1] ^ blake2s_IV[5];
    v[14] = S->f[0] ^ blake2s_IV[6]; v[15] = S->f[1] ^ blake2s_IV[7];

#define G(r,i,a,b,c,d) do {                                  \
        a = a + b + m[blake2s_sigma[r][2*i+0]];              \
        d = rotr32(d ^ a, 16);                               \
        c = c + d;                                           \
        b = rotr32(b ^ c, 12);                               \
        a = a + b + m[blake2s_sigma[r][2*i+1]];              \
        d = rotr32(d ^ a, 8);                                \
        c = c + d;                                           \
        b = rotr32(b ^ c, 7);                                \
    } while (0)
#define ROUND(r) do {                              \
        G(r,0,v[ 0],v[ 4],v[ 8],v[12]);            \
        G(r,1,v[ 1],v[ 5],v[ 9],v[13]);            \
        G(r,2,v[ 2],v[ 6],v[10],v[14]);            \
        G(r,3,v[ 3],v[ 7],v[11],v[15]);            \
        G(r,4,v[ 0],v[ 5],v[10],v[15]);            \
        G(r,5,v[ 1],v[ 6],v[11],v[12]);            \
        G(r,6,v[ 2],v[ 7],v[ 8],v[13]);            \
        G(r,7,v[ 3],v[ 4],v[ 9],v[14]);            \
    } while (0)
    for (i = 0; i < 10; i++) ROUND(i);
    for (i = 0; i < 8; i++) S->h[i] ^= v[i] ^ v[i + 8];
#undef G
#undef ROUND
}

int nw_blake2s_init(nw_blake2s_state *S, size_t outlen) {
    int i;
    if (outlen == 0 || outlen > NW_BLAKE2S_OUTBYTES) return -1;
    memset(S, 0, sizeof(*S));
    for (i = 0; i < 8; i++) S->h[i] = blake2s_IV[i];
    S->h[0] ^= 0x01010000UL ^ (uint32_t)outlen;   // depth=1, fanout=1, keylen=0
    S->outlen = outlen;
    return 0;
}

int nw_blake2s_init_key(nw_blake2s_state *S, size_t outlen, const void *key, size_t keylen) {
    int i;
    if (outlen == 0 || outlen > NW_BLAKE2S_OUTBYTES) return -1;
    if (keylen > NW_BLAKE2S_KEYBYTES) return -1;
    memset(S, 0, sizeof(*S));
    for (i = 0; i < 8; i++) S->h[i] = blake2s_IV[i];
    S->h[0] ^= 0x01010000UL ^ ((uint32_t)keylen << 8) ^ (uint32_t)outlen;
    S->outlen = outlen;
    if (keylen) {
        uint8_t block[NW_BLAKE2S_BLOCKBYTES];
        memset(block, 0, sizeof(block));
        memcpy(block, key, keylen);
        nw_blake2s_update(S, block, sizeof(block));
        memset(block, 0, sizeof(block));
    }
    return 0;
}

int nw_blake2s_update(nw_blake2s_state *S, const void *in, size_t inlen) {
    const uint8_t *pin = (const uint8_t *)in;
    if (inlen == 0) return 0;
    size_t left = S->buflen;
    size_t fill = NW_BLAKE2S_BLOCKBYTES - left;
    if (inlen > fill) {
        S->buflen = 0;
        memcpy(S->buf + left, pin, fill);
        blake2s_increment_counter(S, NW_BLAKE2S_BLOCKBYTES);
        blake2s_compress(S, S->buf);
        pin += fill; inlen -= fill;
        while (inlen > NW_BLAKE2S_BLOCKBYTES) {
            blake2s_increment_counter(S, NW_BLAKE2S_BLOCKBYTES);
            blake2s_compress(S, pin);
            pin += NW_BLAKE2S_BLOCKBYTES; inlen -= NW_BLAKE2S_BLOCKBYTES;
        }
    }
    memcpy(S->buf + S->buflen, pin, inlen);
    S->buflen += inlen;
    return 0;
}

int nw_blake2s_final(nw_blake2s_state *S, void *out, size_t outlen) {
    uint8_t buffer[NW_BLAKE2S_OUTBYTES];
    int i;
    if (outlen < S->outlen) return -1;
    memset(buffer, 0, sizeof(buffer));
    blake2s_increment_counter(S, (uint32_t)S->buflen);
    S->f[0] = (uint32_t)-1;   // last block
    memset(S->buf + S->buflen, 0, NW_BLAKE2S_BLOCKBYTES - S->buflen);
    blake2s_compress(S, S->buf);
    for (i = 0; i < 8; i++) store32(buffer + i * 4, S->h[i]);
    memcpy(out, buffer, S->outlen);
    memset(buffer, 0, sizeof(buffer));
    return 0;
}

int nw_blake2s(void *out, size_t outlen, const void *in, size_t inlen,
               const void *key, size_t keylen) {
    nw_blake2s_state S;
    if (key && keylen) { if (nw_blake2s_init_key(&S, outlen, key, keylen)) return -1; }
    else               { if (nw_blake2s_init(&S, outlen)) return -1; }
    nw_blake2s_update(&S, in, inlen);
    return nw_blake2s_final(&S, out, outlen);
}
