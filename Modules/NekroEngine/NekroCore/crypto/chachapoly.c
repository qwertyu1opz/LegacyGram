// ChaCha20 (RFC 8439) + Poly1305 (poly1305-donna 32-bit) + AEAD construction.
#include "chachapoly.h"
#include <string.h>

static uint32_t load32le(const uint8_t *p) {
    return ((uint32_t)p[0]) | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}
static void store32le(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8);
    p[2] = (uint8_t)(v >> 16); p[3] = (uint8_t)(v >> 24);
}
static uint32_t rotl32(uint32_t x, int n) { return (x << n) | (x >> (32 - n)); }

#define QR(a,b,c,d)                       \
    a += b; d ^= a; d = rotl32(d, 16);    \
    c += d; b ^= c; b = rotl32(b, 12);    \
    a += b; d ^= a; d = rotl32(d, 8);     \
    c += d; b ^= c; b = rotl32(b, 7);

static void chacha20_block(uint32_t out[16], const uint32_t in[16]) {
    int i;
    for (i = 0; i < 16; i++) out[i] = in[i];
    for (i = 0; i < 10; i++) {
        QR(out[0], out[4], out[ 8], out[12])
        QR(out[1], out[5], out[ 9], out[13])
        QR(out[2], out[6], out[10], out[14])
        QR(out[3], out[7], out[11], out[15])
        QR(out[0], out[5], out[10], out[15])
        QR(out[1], out[6], out[11], out[12])
        QR(out[2], out[7], out[ 8], out[13])
        QR(out[3], out[4], out[ 9], out[14])
    }
    for (i = 0; i < 16; i++) out[i] += in[i];
}

void nw_chacha20_xor(uint8_t *out, const uint8_t *in, size_t len,
                     const uint8_t key[32], const uint8_t nonce[12], uint32_t counter) {
    uint32_t st[16], blk[16];
    int i;
    st[0] = 0x61707865; st[1] = 0x3320646e; st[2] = 0x79622d32; st[3] = 0x6b206574;
    for (i = 0; i < 8; i++) st[4 + i] = load32le(key + 4 * i);
    st[12] = counter;
    st[13] = load32le(nonce + 0);
    st[14] = load32le(nonce + 4);
    st[15] = load32le(nonce + 8);

    while (len > 0) {
        chacha20_block(blk, st);
        size_t n = len < 64 ? len : 64;
        for (i = 0; (size_t)i < n; i++) {
            uint8_t ks = (uint8_t)(blk[i >> 2] >> (8 * (i & 3)));
            out[i] = in[i] ^ ks;
        }
        st[12]++;
        in += n; out += n; len -= n;
    }
}

/* ---- Poly1305 (donna, 32-bit) ---- */

typedef struct {
    uint32_t r[5], h[5], pad[4];
    size_t   leftover;
    uint8_t  buffer[16];
    uint8_t  final;
} poly1305_ctx;

static void poly1305_init(poly1305_ctx *st, const uint8_t key[32]) {
    st->r[0] = (load32le(&key[0])     ) & 0x3ffffff;
    st->r[1] = (load32le(&key[3]) >> 2) & 0x3ffff03;
    st->r[2] = (load32le(&key[6]) >> 4) & 0x3ffc0ff;
    st->r[3] = (load32le(&key[9]) >> 6) & 0x3f03fff;
    st->r[4] = (load32le(&key[12])>> 8) & 0x00fffff;
    st->h[0] = st->h[1] = st->h[2] = st->h[3] = st->h[4] = 0;
    st->pad[0] = load32le(&key[16]); st->pad[1] = load32le(&key[20]);
    st->pad[2] = load32le(&key[24]); st->pad[3] = load32le(&key[28]);
    st->leftover = 0; st->final = 0;
}

static void poly1305_blocks(poly1305_ctx *st, const uint8_t *m, size_t bytes) {
    const uint32_t hibit = st->final ? 0 : (1UL << 24);
    uint32_t r0 = st->r[0], r1 = st->r[1], r2 = st->r[2], r3 = st->r[3], r4 = st->r[4];
    uint32_t s1 = r1 * 5, s2 = r2 * 5, s3 = r3 * 5, s4 = r4 * 5;
    uint32_t h0 = st->h[0], h1 = st->h[1], h2 = st->h[2], h3 = st->h[3], h4 = st->h[4];

    while (bytes >= 16) {
        uint64_t d0, d1, d2, d3, d4;
        uint32_t c;
        h0 += (load32le(m + 0)     ) & 0x3ffffff;
        h1 += (load32le(m + 3) >> 2) & 0x3ffffff;
        h2 += (load32le(m + 6) >> 4) & 0x3ffffff;
        h3 += (load32le(m + 9) >> 6) & 0x3ffffff;
        h4 += (load32le(m + 12)>> 8) | hibit;

        d0 = (uint64_t)h0*r0 + (uint64_t)h1*s4 + (uint64_t)h2*s3 + (uint64_t)h3*s2 + (uint64_t)h4*s1;
        d1 = (uint64_t)h0*r1 + (uint64_t)h1*r0 + (uint64_t)h2*s4 + (uint64_t)h3*s3 + (uint64_t)h4*s2;
        d2 = (uint64_t)h0*r2 + (uint64_t)h1*r1 + (uint64_t)h2*r0 + (uint64_t)h3*s4 + (uint64_t)h4*s3;
        d3 = (uint64_t)h0*r3 + (uint64_t)h1*r2 + (uint64_t)h2*r1 + (uint64_t)h3*r0 + (uint64_t)h4*s4;
        d4 = (uint64_t)h0*r4 + (uint64_t)h1*r3 + (uint64_t)h2*r2 + (uint64_t)h3*r1 + (uint64_t)h4*r0;

        c = (uint32_t)(d0 >> 26); h0 = (uint32_t)d0 & 0x3ffffff; d1 += c;
        c = (uint32_t)(d1 >> 26); h1 = (uint32_t)d1 & 0x3ffffff; d2 += c;
        c = (uint32_t)(d2 >> 26); h2 = (uint32_t)d2 & 0x3ffffff; d3 += c;
        c = (uint32_t)(d3 >> 26); h3 = (uint32_t)d3 & 0x3ffffff; d4 += c;
        c = (uint32_t)(d4 >> 26); h4 = (uint32_t)d4 & 0x3ffffff; h0 += c * 5;
        c = h0 >> 26;             h0 = h0 & 0x3ffffff;           h1 += c;

        m += 16; bytes -= 16;
    }
    st->h[0] = h0; st->h[1] = h1; st->h[2] = h2; st->h[3] = h3; st->h[4] = h4;
}

static void poly1305_update(poly1305_ctx *st, const uint8_t *m, size_t bytes) {
    size_t i;
    if (st->leftover) {
        size_t want = 16 - st->leftover;
        if (want > bytes) want = bytes;
        for (i = 0; i < want; i++) st->buffer[st->leftover + i] = m[i];
        bytes -= want; m += want; st->leftover += want;
        if (st->leftover < 16) return;
        poly1305_blocks(st, st->buffer, 16);
        st->leftover = 0;
    }
    if (bytes >= 16) {
        size_t want = bytes & ~(size_t)15;
        poly1305_blocks(st, m, want);
        m += want; bytes -= want;
    }
    if (bytes) {
        for (i = 0; i < bytes; i++) st->buffer[st->leftover + i] = m[i];
        st->leftover += bytes;
    }
}

static void poly1305_finish(poly1305_ctx *st, uint8_t mac[16]) {
    uint32_t h0, h1, h2, h3, h4, c;
    uint32_t g0, g1, g2, g3, g4, mask;
    uint64_t f;

    if (st->leftover) {
        size_t i = st->leftover;
        st->buffer[i++] = 1;
        for (; i < 16; i++) st->buffer[i] = 0;
        st->final = 1;
        poly1305_blocks(st, st->buffer, 16);
    }

    h0 = st->h[0]; h1 = st->h[1]; h2 = st->h[2]; h3 = st->h[3]; h4 = st->h[4];
    c = h1 >> 26; h1 &= 0x3ffffff; h2 += c;
    c = h2 >> 26; h2 &= 0x3ffffff; h3 += c;
    c = h3 >> 26; h3 &= 0x3ffffff; h4 += c;
    c = h4 >> 26; h4 &= 0x3ffffff; h0 += c * 5;
    c = h0 >> 26; h0 &= 0x3ffffff; h1 += c;

    g0 = h0 + 5; c = g0 >> 26; g0 &= 0x3ffffff;
    g1 = h1 + c; c = g1 >> 26; g1 &= 0x3ffffff;
    g2 = h2 + c; c = g2 >> 26; g2 &= 0x3ffffff;
    g3 = h3 + c; c = g3 >> 26; g3 &= 0x3ffffff;
    g4 = h4 + c - (1UL << 26);

    mask = (g4 >> 31) - 1;             // 0xffffffff if g >= p else 0
    g0 &= mask; g1 &= mask; g2 &= mask; g3 &= mask; g4 &= mask;
    mask = ~mask;
    h0 = (h0 & mask) | g0; h1 = (h1 & mask) | g1; h2 = (h2 & mask) | g2;
    h3 = (h3 & mask) | g3; h4 = (h4 & mask) | g4;

    h0 = (h0 | (h1 << 26)) & 0xffffffff;
    h1 = ((h1 >> 6) | (h2 << 20)) & 0xffffffff;
    h2 = ((h2 >> 12) | (h3 << 14)) & 0xffffffff;
    h3 = ((h3 >> 18) | (h4 << 8)) & 0xffffffff;

    f = (uint64_t)h0 + st->pad[0];                 h0 = (uint32_t)f;
    f = (uint64_t)h1 + st->pad[1] + (f >> 32);     h1 = (uint32_t)f;
    f = (uint64_t)h2 + st->pad[2] + (f >> 32);     h2 = (uint32_t)f;
    f = (uint64_t)h3 + st->pad[3] + (f >> 32);     h3 = (uint32_t)f;

    store32le(mac + 0, h0); store32le(mac + 4, h1);
    store32le(mac + 8, h2); store32le(mac + 12, h3);
}

/* ---- AEAD (RFC 8439 §2.8) ---- */

static void poly_pad16(poly1305_ctx *st, size_t len) {
    static const uint8_t zero[16] = {0};
    if (len % 16) poly1305_update(st, zero, 16 - (len % 16));
}

static void aead_mac(uint8_t tag[16], const uint8_t *aad, size_t aadlen,
                     const uint8_t *ct, size_t ctlen,
                     const uint8_t key[32], const uint8_t nonce[12]) {
    uint8_t polykey[32], zero[32], lenblk[16];
    memset(zero, 0, sizeof(zero));
    nw_chacha20_xor(polykey, zero, 32, key, nonce, 0);   // block 0 -> one-time key

    poly1305_ctx st;
    poly1305_init(&st, polykey);
    poly1305_update(&st, aad, aadlen); poly_pad16(&st, aadlen);
    poly1305_update(&st, ct, ctlen);   poly_pad16(&st, ctlen);
    store32le(lenblk + 0, (uint32_t)aadlen);
    store32le(lenblk + 4, (uint32_t)((uint64_t)aadlen >> 32));
    store32le(lenblk + 8, (uint32_t)ctlen);
    store32le(lenblk + 12, (uint32_t)((uint64_t)ctlen >> 32));
    poly1305_update(&st, lenblk, 16);
    poly1305_finish(&st, tag);
    memset(polykey, 0, sizeof(polykey));
}

int nw_chacha20poly1305_encrypt(uint8_t *out,
                                const uint8_t *plain, size_t plen,
                                const uint8_t *aad, size_t aadlen,
                                const uint8_t key[32], const uint8_t nonce[12]) {
    nw_chacha20_xor(out, plain, plen, key, nonce, 1);    // data starts at counter 1
    aead_mac(out + plen, aad, aadlen, out, plen, key, nonce);
    return 0;
}

int nw_chacha20poly1305_decrypt(uint8_t *out,
                                const uint8_t *cipher, size_t clen,
                                const uint8_t *aad, size_t aadlen,
                                const uint8_t key[32], const uint8_t nonce[12]) {
    if (clen < 16) return -1;
    size_t plen = clen - 16;
    uint8_t tag[16];
    uint8_t diff = 0;
    int i;
    aead_mac(tag, aad, aadlen, cipher, plen, key, nonce);
    for (i = 0; i < 16; i++) diff |= tag[i] ^ cipher[plen + i];
    if (diff) return -1;
    nw_chacha20_xor(out, cipher, plen, key, nonce, 1);
    return 0;
}
