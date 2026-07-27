#include "kdf.h"
#include "blake2s.h"
#include <string.h>

#define BLK 64

void nw_hmac_blake2s(uint8_t out[32], const uint8_t *key, size_t keylen,
                     const uint8_t *data, size_t datalen) {
    uint8_t k[BLK], ipad[BLK], opad[BLK], inner[32];
    int i;
    memset(k, 0, BLK);
    if (keylen > BLK) nw_blake2s(k, 32, key, keylen, NULL, 0);
    else              memcpy(k, key, keylen);
    for (i = 0; i < BLK; i++) { ipad[i] = k[i] ^ 0x36; opad[i] = k[i] ^ 0x5c; }

    nw_blake2s_state S;
    nw_blake2s_init(&S, 32);
    nw_blake2s_update(&S, ipad, BLK);
    nw_blake2s_update(&S, data, datalen);
    nw_blake2s_final(&S, inner, 32);

    nw_blake2s_init(&S, 32);
    nw_blake2s_update(&S, opad, BLK);
    nw_blake2s_update(&S, inner, 32);
    nw_blake2s_final(&S, out, 32);

    memset(k, 0, BLK); memset(ipad, 0, BLK); memset(opad, 0, BLK);
}

void nw_kdf(uint8_t *out1, uint8_t *out2, uint8_t *out3,
            const uint8_t chaining_key[32],
            const uint8_t *data, size_t datalen) {
    uint8_t t0[32], t1[32], in[33];
    nw_hmac_blake2s(t0, chaining_key, 32, data, datalen);   // PRK

    uint8_t one = 0x1;
    nw_hmac_blake2s(t1, t0, 32, &one, 1);
    if (out1) memcpy(out1, t1, 32);
    if (!out2) { memset(t0, 0, 32); return; }

    memcpy(in, t1, 32); in[32] = 0x2;
    uint8_t t2[32];
    nw_hmac_blake2s(t2, t0, 32, in, 33);
    memcpy(out2, t2, 32);
    if (!out3) { memset(t0, 0, 32); return; }

    memcpy(in, t2, 32); in[32] = 0x3;
    uint8_t t3[32];
    nw_hmac_blake2s(t3, t0, 32, in, 33);
    memcpy(out3, t3, 32);
    memset(t0, 0, 32);
}
