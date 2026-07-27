#include "selftest.h"
#include "blake2s.h"
#include "chachapoly.h"
#include "x25519.h"
#include "kdf.h"

#include <stdio.h>
#include <string.h>
#include <sys/time.h>

static int hexcmp(const char *label, const uint8_t *got, const uint8_t *want,
                  size_t n, int verbose) {
    int ok = (memcmp(got, want, n) == 0);
    if (verbose) {
        printf("  [%s] %s\n", ok ? "PASS" : "FAIL", label);
        if (!ok) {
            size_t i;
            printf("        got : "); for (i = 0; i < n; i++) printf("%02x", got[i]);  printf("\n");
            printf("        want: "); for (i = 0; i < n; i++) printf("%02x", want[i]); printf("\n");
        }
    }
    return ok ? 0 : 1;
}

int nw_crypto_selftest(int verbose) {
    int fails = 0;

    // --- BLAKE2s("abc") (RFC 7693) ---
    {
        static const uint8_t want[32] = {
            0x50,0x8c,0x5e,0x8c,0x32,0x7c,0x14,0xe2,0xe1,0xa7,0x2b,0xa3,0x4e,0xeb,0x45,0x2f,
            0x37,0x45,0x8b,0x20,0x9e,0xd6,0x3a,0x29,0x4d,0x99,0x9b,0x4c,0x86,0x67,0x59,0x82 };
        uint8_t out[32];
        nw_blake2s(out, 32, (const uint8_t *)"abc", 3, NULL, 0);
        fails += hexcmp("BLAKE2s(\"abc\")", out, want, 32, verbose);
    }

    // --- ChaCha20-Poly1305 AEAD (RFC 8439 §2.8.2) ---
    {
        static const uint8_t key[32] = {
            0x80,0x81,0x82,0x83,0x84,0x85,0x86,0x87,0x88,0x89,0x8a,0x8b,0x8c,0x8d,0x8e,0x8f,
            0x90,0x91,0x92,0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9a,0x9b,0x9c,0x9d,0x9e,0x9f };
        static const uint8_t nonce[12] = {
            0x07,0x00,0x00,0x00,0x40,0x41,0x42,0x43,0x44,0x45,0x46,0x47 };
        static const uint8_t aad[12] = {
            0x50,0x51,0x52,0x53,0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7 };
        static const char *pt =
            "Ladies and Gentlemen of the class of '99: If I could offer you "
            "only one tip for the future, sunscreen would be it.";
        static const uint8_t want_ct[114] = {
            0xd3,0x1a,0x8d,0x34,0x64,0x8e,0x60,0xdb,0x7b,0x86,0xaf,0xbc,0x53,0xef,0x7e,0xc2,
            0xa4,0xad,0xed,0x51,0x29,0x6e,0x08,0xfe,0xa9,0xe2,0xb5,0xa7,0x36,0xee,0x62,0xd6,
            0x3d,0xbe,0xa4,0x5e,0x8c,0xa9,0x67,0x12,0x82,0xfa,0xfb,0x69,0xda,0x92,0x72,0x8b,
            0x1a,0x71,0xde,0x0a,0x9e,0x06,0x0b,0x29,0x05,0xd6,0xa5,0xb6,0x7e,0xcd,0x3b,0x36,
            0x92,0xdd,0xbd,0x7f,0x2d,0x77,0x8b,0x8c,0x98,0x03,0xae,0xe3,0x28,0x09,0x1b,0x58,
            0xfa,0xb3,0x24,0xe4,0xfa,0xd6,0x75,0x94,0x55,0x85,0x80,0x8b,0x48,0x31,0xd7,0xbc,
            0x3f,0xf4,0xde,0xf0,0x8e,0x4b,0x7a,0x9d,0xe5,0x76,0xd2,0x65,0x86,0xce,0xc6,0x4b,
            0x61,0x16 };
        static const uint8_t want_tag[16] = {
            0x1a,0xe1,0x0b,0x59,0x4f,0x09,0xe2,0x6a,0x7e,0x90,0x2e,0xcb,0xd0,0x60,0x06,0x91 };
        size_t plen = strlen(pt);
        uint8_t ct[114 + 16], dec[114];
        nw_chacha20poly1305_encrypt(ct, (const uint8_t *)pt, plen, aad, sizeof(aad), key, nonce);
        fails += hexcmp("ChaCha20Poly1305 ciphertext", ct, want_ct, plen, verbose);
        fails += hexcmp("ChaCha20Poly1305 tag", ct + plen, want_tag, 16, verbose);

        int rc = nw_chacha20poly1305_decrypt(dec, ct, plen + 16, aad, sizeof(aad), key, nonce);
        int ok = (rc == 0) && (memcmp(dec, pt, plen) == 0);
        if (verbose) printf("  [%s] ChaCha20Poly1305 decrypt round-trip\n", ok ? "PASS" : "FAIL");
        if (!ok) fails++;

        // tampered tag must fail
        ct[plen + 16 - 1] ^= 0x01;
        rc = nw_chacha20poly1305_decrypt(dec, ct, plen + 16, aad, sizeof(aad), key, nonce);
        if (verbose) printf("  [%s] ChaCha20Poly1305 rejects tampered tag\n", rc != 0 ? "PASS" : "FAIL");
        if (rc == 0) fails++;
    }

    // --- X25519 (RFC 7748 §5.2, vector 1) ---
    {
        static const uint8_t scalar[32] = {
            0xa5,0x46,0xe3,0x6b,0xf0,0x52,0x7c,0x9d,0x3b,0x16,0x15,0x4b,0x82,0x46,0x5e,0xdd,
            0x62,0x14,0x4c,0x0a,0xc1,0xfc,0x5a,0x18,0x50,0x6a,0x22,0x44,0xba,0x44,0x9a,0xc4 };
        static const uint8_t upoint[32] = {
            0xe6,0xdb,0x68,0x67,0x58,0x30,0x30,0xdb,0x35,0x94,0xc1,0xa4,0x24,0xb1,0x5f,0x7c,
            0x72,0x66,0x24,0xec,0x26,0xb3,0x35,0x3b,0x10,0xa9,0x03,0xa6,0xd0,0xab,0x1c,0x4c };
        static const uint8_t want[32] = {
            0xc3,0xda,0x55,0x37,0x9d,0xe9,0xc6,0x90,0x8e,0x94,0xea,0x4d,0xf2,0x8d,0x08,0x4f,
            0x32,0xec,0xcf,0x03,0x49,0x1c,0x71,0xf7,0x54,0xb4,0x07,0x55,0x77,0xa2,0x85,0x52 };
        uint8_t out[32];
        nw_x25519(out, scalar, upoint);
        fails += hexcmp("X25519 (RFC 7748 v1)", out, want, 32, verbose);
    }

    // --- X25519 DH agreement: a*B(b) == b*B(a) ---
    {
        uint8_t a[32], b[32], pa[32], pb[32], sa[32], sb[32];
        int i;
        for (i = 0; i < 32; i++) { a[i] = (uint8_t)(i + 1); b[i] = (uint8_t)(200 - i); }
        nw_x25519_base(pa, a); nw_x25519_base(pb, b);
        nw_x25519(sa, a, pb);  nw_x25519(sb, b, pa);
        int ok = (memcmp(sa, sb, 32) == 0);
        if (verbose) printf("  [%s] X25519 DH agreement (shared secret matches)\n", ok ? "PASS" : "FAIL");
        if (!ok) fails++;
    }

    // --- KDF determinism / non-degeneracy (full vector validated end-to-end in M3) ---
    {
        uint8_t ck[32], o1[32], o2[32], o1b[32];
        int i, ok;
        for (i = 0; i < 32; i++) ck[i] = (uint8_t)i;
        nw_kdf(o1, o2, NULL, ck, (const uint8_t *)"nekro", 5);
        nw_kdf(o1b, NULL, NULL, ck, (const uint8_t *)"nekro", 5);
        ok = (memcmp(o1, o1b, 32) == 0) && (memcmp(o1, o2, 32) != 0);
        if (verbose) printf("  [%s] KDF deterministic and distinct outputs\n", ok ? "PASS" : "FAIL");
        if (!ok) fails++;
    }

    if (verbose) printf("%s: %d failure(s)\n", fails ? "SELFTEST FAILED" : "SELFTEST OK", fails);
    return fails;
}

static double now_sec(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec / 1e6;
}

void nw_crypto_bench(void) {
    // X25519
    {
        uint8_t k[32], p[32];
        int i;
        for (i = 0; i < 32; i++) { k[i] = (uint8_t)(i + 1); p[i] = 9 * (i == 0); }
        const int N = 200;
        double t0 = now_sec();
        for (i = 0; i < N; i++) { nw_x25519(p, k, p); k[0] += 1; }
        double dt = now_sec() - t0;
        printf("X25519:            %d ops in %.3f s  = %.1f ops/s (%.1f ms/op)\n",
               N, dt, N / dt, dt / N * 1000.0);
    }
    // ChaCha20-Poly1305
    {
        static uint8_t buf[16384];
        uint8_t key[32] = {1}, nonce[12] = {2}, out[16384 + 16];
        int i;
        const int N = 256;            // 256 * 16 KiB = 4 MiB
        memset(buf, 0xab, sizeof(buf));
        double t0 = now_sec();
        for (i = 0; i < N; i++)
            nw_chacha20poly1305_encrypt(out, buf, sizeof(buf), NULL, 0, key, nonce);
        double dt = now_sec() - t0;
        double mib = (double)N * sizeof(buf) / (1024.0 * 1024.0);
        printf("ChaCha20-Poly1305: %.1f MiB in %.3f s  = %.2f MiB/s\n", mib, dt, mib / dt);
    }
}
