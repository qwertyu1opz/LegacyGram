// WireGuard handshake (Noise_IKpsk2_25519_ChaChaPoly_BLAKE2s) + transport.
#include "wg.h"
#include "blake2s.h"
#include "chachapoly.h"
#include "x25519.h"
#include "kdf.h"

#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/time.h>

static const char NW_CONSTRUCTION[] = "Noise_IKpsk2_25519_ChaChaPoly_BLAKE2s";
static const char NW_IDENTIFIER[]   = "WireGuard v1 zx2c4 Jason@zx2c4.com";
static const char NW_LABEL_MAC1[]   = "mac1----";

static const uint8_t ZERO_NONCE[12] = {0};

/* ---- little/big-endian helpers ---- */
static void st32le(uint8_t *p, uint32_t v) { p[0]=v; p[1]=v>>8; p[2]=v>>16; p[3]=v>>24; }
static uint32_t ld32le(const uint8_t *p) { return (uint32_t)p[0]|((uint32_t)p[1]<<8)|((uint32_t)p[2]<<16)|((uint32_t)p[3]<<24); }
static void st64le(uint8_t *p, uint64_t v) { int i; for (i=0;i<8;i++) p[i]=(uint8_t)(v>>(8*i)); }
static uint64_t ld64le(const uint8_t *p) { uint64_t v=0; int i; for (i=0;i<8;i++) v|=((uint64_t)p[i])<<(8*i); return v; }

int nw_random(uint8_t *buf, size_t len) {
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd < 0) return -1;
    size_t got = 0;
    while (got < len) {
        ssize_t n = read(fd, buf + got, len - got);
        if (n <= 0) { close(fd); return -1; }
        got += (size_t)n;
    }
    close(fd);
    return 0;
}

/* ---- Noise helpers ---- */
static void mix_hash(uint8_t h[32], const uint8_t *data, size_t len) {
    nw_blake2s_state S;
    nw_blake2s_init(&S, 32);
    nw_blake2s_update(&S, h, 32);
    nw_blake2s_update(&S, data, len);
    nw_blake2s_final(&S, h, 32);
}
static void mix_chain(uint8_t ck[32], const uint8_t *data, size_t len) {
    nw_kdf(ck, NULL, NULL, ck, data, len);          // KDF1
}
static void mac1_key(uint8_t out[32], const uint8_t peer_pub[32]) {
    nw_blake2s_state S;
    nw_blake2s_init(&S, 32);
    nw_blake2s_update(&S, NW_LABEL_MAC1, 8);
    nw_blake2s_update(&S, peer_pub, 32);
    nw_blake2s_final(&S, out, 32);
}
static void tai64n(uint8_t out[12]) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    uint64_t secs = 0x400000000000000aULL + (uint64_t)tv.tv_sec;
    uint32_t nanos = (uint32_t)tv.tv_usec * 1000u;
    int i;
    for (i = 0; i < 8; i++) out[7 - i]  = (uint8_t)(secs  >> (8 * i));
    for (i = 0; i < 4; i++) out[11 - i] = (uint8_t)(nanos >> (8 * i));
}

// ck/h from the protocol constants + the remote static public key.
static void init_state(uint8_t ck[32], uint8_t h[32], const uint8_t remote_static[32]) {
    nw_blake2s(ck, 32, NW_CONSTRUCTION, sizeof(NW_CONSTRUCTION) - 1, NULL, 0);
    memcpy(h, ck, 32);
    mix_hash(h, (const uint8_t *)NW_IDENTIFIER, sizeof(NW_IDENTIFIER) - 1);
    mix_hash(h, remote_static, 32);
}

void nw_handshake_init(nw_handshake *hs, const uint8_t static_private[32],
                       const uint8_t peer_static_public[32], const uint8_t psk[32]) {
    memset(hs, 0, sizeof(*hs));
    if (static_private) memcpy(hs->static_private, static_private, 32);
    else                nw_random(hs->static_private, 32);
    nw_x25519_base(hs->static_public, hs->static_private);
    if (peer_static_public) memcpy(hs->peer_static_public, peer_static_public, 32);
    if (psk) memcpy(hs->psk, psk, 32);
}

/* ---- Initiator ---- */
int nw_wg_create_initiation(nw_handshake *hs, uint32_t local_index, uint8_t out[NW_WG_INIT_SIZE]) {
    uint8_t ck[32], h[32], dh[32], k[32];
    init_state(ck, h, hs->peer_static_public);

    nw_random(hs->ephemeral_private, 32);
    nw_x25519_base(hs->ephemeral_public, hs->ephemeral_private);
    hs->local_index = local_index;

    out[0] = 1;
    // Copy reserved (for WARP: the 3-byte client_id from /reg response, base64-decoded).
    // Vanilla WG uses 00 00 00. Non-zero is required for proper WARP server routing
    // and forwarding; zeroed bytes were an early assumption that has been corrected.
    memcpy(out + 1, hs->reserved, 3);
    st32le(out + 4, local_index);
    memcpy(out + 8, hs->ephemeral_public, 32);

    mix_chain(ck, hs->ephemeral_public, 32);
    mix_hash(h, hs->ephemeral_public, 32);

    nw_x25519(dh, hs->ephemeral_private, hs->peer_static_public);
    nw_kdf(ck, k, NULL, ck, dh, 32);                              // (ck,k)=KDF2
    nw_chacha20poly1305_encrypt(out + 40, hs->static_public, 32, h, 32, k, ZERO_NONCE);
    mix_hash(h, out + 40, 48);

    nw_x25519(dh, hs->static_private, hs->peer_static_public);
    nw_kdf(ck, k, NULL, ck, dh, 32);                              // (ck,k)=KDF2
    uint8_t ts[12];
    tai64n(ts);
    nw_chacha20poly1305_encrypt(out + 88, ts, 12, h, 32, k, ZERO_NONCE);
    mix_hash(h, out + 88, 28);

    uint8_t mk[32];
    mac1_key(mk, hs->peer_static_public);
    nw_blake2s(out + 116, 16, out, 116, mk, 32);                  // mac1
    memset(out + 132, 0, 16);                                     // mac2 = 0

    memcpy(hs->chaining_key, ck, 32);
    memcpy(hs->hash, h, 32);
    return 0;
}

/* ---- Responder ---- */
int nw_wg_consume_initiation(nw_handshake *hs, const uint8_t msg[NW_WG_INIT_SIZE]) {
    uint8_t ck[32], h[32], dh[32], k[32], mk[32], mac1[16];
    if (msg[0] != 1) return -1;

    mac1_key(mk, hs->static_public);
    nw_blake2s(mac1, 16, msg, 116, mk, 32);
    if (memcmp(mac1, msg + 116, 16) != 0) return -2;             // bad mac1

    init_state(ck, h, hs->static_public);

    memcpy(hs->remote_ephemeral, msg + 8, 32);
    mix_chain(ck, hs->remote_ephemeral, 32);
    mix_hash(h, hs->remote_ephemeral, 32);

    nw_x25519(dh, hs->static_private, hs->remote_ephemeral);
    nw_kdf(ck, k, NULL, ck, dh, 32);
    if (nw_chacha20poly1305_decrypt(hs->remote_static, msg + 40, 48, h, 32, k, ZERO_NONCE) != 0)
        return -3;
    mix_hash(h, msg + 40, 48);

    nw_x25519(dh, hs->static_private, hs->remote_static);
    nw_kdf(ck, k, NULL, ck, dh, 32);
    uint8_t ts[12];
    if (nw_chacha20poly1305_decrypt(ts, msg + 88, 28, h, 32, k, ZERO_NONCE) != 0)
        return -4;
    mix_hash(h, msg + 88, 28);

    hs->remote_index = ld32le(msg + 4);
    memcpy(hs->chaining_key, ck, 32);
    memcpy(hs->hash, h, 32);
    return 0;
}

int nw_wg_create_response(nw_handshake *hs, uint32_t local_index,
                          uint8_t out[NW_WG_RESP_SIZE], nw_transport *t) {
    uint8_t ck[32], h[32], dh[32], k[32], tau[32], mk[32];
    memcpy(ck, hs->chaining_key, 32);
    memcpy(h, hs->hash, 32);

    nw_random(hs->ephemeral_private, 32);
    nw_x25519_base(hs->ephemeral_public, hs->ephemeral_private);
    hs->local_index = local_index;

    out[0] = 2;
    memcpy(out + 1, hs->reserved, 3);
    st32le(out + 4, local_index);
    st32le(out + 8, hs->remote_index);
    memcpy(out + 12, hs->ephemeral_public, 32);

    mix_chain(ck, hs->ephemeral_public, 32);
    mix_hash(h, hs->ephemeral_public, 32);

    nw_x25519(dh, hs->ephemeral_private, hs->remote_ephemeral);   // ee
    mix_chain(ck, dh, 32);
    nw_x25519(dh, hs->ephemeral_private, hs->remote_static);      // se
    mix_chain(ck, dh, 32);

    nw_kdf(ck, tau, k, ck, hs->psk, 32);                          // (ck,tau,k)=KDF3(psk)
    mix_hash(h, tau, 32);

    nw_chacha20poly1305_encrypt(out + 44, NULL, 0, h, 32, k, ZERO_NONCE);  // empty
    mix_hash(h, out + 44, 16);

    mac1_key(mk, hs->remote_static);
    nw_blake2s(out + 60, 16, out, 60, mk, 32);                    // mac1
    memset(out + 76, 0, 16);                                     // mac2 = 0

    // transport keys — responder: (recv, send) = KDF2(ck, empty)
    memset(t, 0, sizeof(*t));
    nw_kdf(t->recv_key, t->send_key, NULL, ck, NULL, 0);
    t->local_index = local_index;
    t->remote_index = hs->remote_index;
    memcpy(t->reserved, hs->reserved, 3);
    return 0;
}

/* ---- Initiator consumes response ---- */
int nw_wg_consume_response(nw_handshake *hs, const uint8_t msg[NW_WG_RESP_SIZE], nw_transport *t) {
    uint8_t ck[32], h[32], dh[32], k[32], tau[32], mk[32], mac1[16], empty[1];
    if (msg[0] != 2) return -1;

    mac1_key(mk, hs->static_public);
    nw_blake2s(mac1, 16, msg, 60, mk, 32);
    if (memcmp(mac1, msg + 60, 16) != 0) return -2;

    memcpy(ck, hs->chaining_key, 32);
    memcpy(h, hs->hash, 32);

    const uint8_t *er = msg + 12;
    mix_chain(ck, er, 32);
    mix_hash(h, er, 32);

    nw_x25519(dh, hs->ephemeral_private, er);                     // ee
    mix_chain(ck, dh, 32);
    nw_x25519(dh, hs->static_private, er);                        // se
    mix_chain(ck, dh, 32);

    nw_kdf(ck, tau, k, ck, hs->psk, 32);                          // KDF3(psk)
    mix_hash(h, tau, 32);

    if (nw_chacha20poly1305_decrypt(empty, msg + 44, 16, h, 32, k, ZERO_NONCE) != 0)
        return -3;
    mix_hash(h, msg + 44, 16);

    hs->remote_index = ld32le(msg + 4);

    // transport keys — initiator: (send, recv) = KDF2(ck, empty)
    memset(t, 0, sizeof(*t));
    nw_kdf(t->send_key, t->recv_key, NULL, ck, NULL, 0);
    t->local_index = hs->local_index;
    t->remote_index = hs->remote_index;
    memcpy(t->reserved, hs->reserved, 3);
    return 0;
}

/* ---- Transport ---- */
int nw_wg_transport_encrypt(nw_transport *t, const uint8_t *plain, size_t plen,
                            uint8_t *out, size_t *outlen) {
    uint8_t nonce[12];
    uint64_t c = t->send_counter++;
    // Use the configured reserved bytes (WARP client_id when provided via registration).
    // This must match what the WARP /reg returned; the server uses it to associate
    // the WireGuard session and forward packets.
    out[0] = 4;
    memcpy(out + 1, t->reserved, 3);
    st32le(out + 4, t->remote_index);
    st64le(out + 8, c);
    memset(nonce, 0, 4);
    st64le(nonce + 4, c);
    nw_chacha20poly1305_encrypt(out + NW_WG_DATA_HDR, plain, plen, NULL, 0, t->send_key, nonce);
    *outlen = NW_WG_DATA_HDR + plen + 16;
    return 0;
}

int nw_wg_transport_decrypt(nw_transport *t, const uint8_t *msg, size_t mlen,
                            uint8_t *out, size_t *outlen) {
    uint8_t nonce[12];
    if (msg[0] != 4 || mlen < NW_WG_DATA_HDR + 16) return -1;
    uint64_t c = ld64le(msg + 8);
    memset(nonce, 0, 4);
    st64le(nonce + 4, c);
    size_t clen = mlen - NW_WG_DATA_HDR;
    if (nw_chacha20poly1305_decrypt(out, msg + NW_WG_DATA_HDR, clen, NULL, 0, t->recv_key, nonce) != 0)
        return -2;
    (void)t->recv_counter;            // replay window: M5
    *outlen = clen - 16;
    return 0;
}

/* ---- In-process self-test: full A<->B handshake + data both ways ---- */
int nw_wg_selftest(int verbose) {
    int fails = 0;
    nw_handshake A, B;            // A = initiator, B = responder
    nw_transport tA, tB;
    uint8_t init[NW_WG_INIT_SIZE], resp[NW_WG_RESP_SIZE];

    // Two static identities; each knows the other's static public.
    uint8_t a_priv[32], b_priv[32], a_pub[32], b_pub[32];
    nw_random(a_priv, 32); nw_random(b_priv, 32);
    nw_x25519_base(a_pub, a_priv); nw_x25519_base(b_pub, b_priv);

    nw_handshake_init(&A, a_priv, b_pub, NULL);   // initiator -> responder static = b_pub
    nw_handshake_init(&B, b_priv, a_pub, NULL);   // responder identity

    int rc;
    rc = nw_wg_create_initiation(&A, 0x11111111, init);
    if (verbose) printf("  [%s] create_initiation\n", rc == 0 ? "PASS" : "FAIL");
    if (rc) fails++;

    rc = nw_wg_consume_initiation(&B, init);
    if (verbose) printf("  [%s] consume_initiation (mac1 + decrypt static/timestamp)\n", rc == 0 ? "PASS" : "FAIL");
    if (rc) fails++;

    int learned = (memcmp(B.remote_static, a_pub, 32) == 0);
    if (verbose) printf("  [%s] responder learned initiator static pubkey\n", learned ? "PASS" : "FAIL");
    if (!learned) fails++;

    rc = nw_wg_create_response(&B, 0x22222222, resp, &tB);
    if (verbose) printf("  [%s] create_response\n", rc == 0 ? "PASS" : "FAIL");
    if (rc) fails++;

    rc = nw_wg_consume_response(&A, resp, &tA);
    if (verbose) printf("  [%s] consume_response\n", rc == 0 ? "PASS" : "FAIL");
    if (rc) fails++;

    int keys_ok = (memcmp(tA.send_key, tB.recv_key, 32) == 0) &&
                  (memcmp(tA.recv_key, tB.send_key, 32) == 0);
    if (verbose) printf("  [%s] transport keys agree (A.send==B.recv, A.recv==B.send)\n", keys_ok ? "PASS" : "FAIL");
    if (!keys_ok) fails++;

    // Data A -> B
    {
        const char *pt = "the quick brown fox over WireGuard";
        uint8_t pkt[128], dec[128];
        size_t pl = strlen(pt), ol = 0, dl = 0;
        nw_wg_transport_encrypt(&tA, (const uint8_t *)pt, pl, pkt, &ol);
        rc = nw_wg_transport_decrypt(&tB, pkt, ol, dec, &dl);
        int ok = (rc == 0) && (dl == pl) && (memcmp(dec, pt, pl) == 0);
        if (verbose) printf("  [%s] data A->B round-trip\n", ok ? "PASS" : "FAIL");
        if (!ok) fails++;
    }
    // Data B -> A
    {
        const char *pt = "and the reply travels back";
        uint8_t pkt[128], dec[128];
        size_t pl = strlen(pt), ol = 0, dl = 0;
        nw_wg_transport_encrypt(&tB, (const uint8_t *)pt, pl, pkt, &ol);
        rc = nw_wg_transport_decrypt(&tA, pkt, ol, dec, &dl);
        int ok = (rc == 0) && (dl == pl) && (memcmp(dec, pt, pl) == 0);
        if (verbose) printf("  [%s] data B->A round-trip\n", ok ? "PASS" : "FAIL");
        if (!ok) fails++;
    }

    if (verbose) printf("%s: %d failure(s)\n", fails ? "HANDSHAKE SELFTEST FAILED" : "HANDSHAKE SELFTEST OK", fails);
    return fails;
}
