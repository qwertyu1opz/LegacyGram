#ifndef NW_WG_H
#define NW_WG_H

#include <stddef.h>
#include <stdint.h>

// WireGuard (Noise_IKpsk2_25519_ChaChaPoly_BLAKE2s) handshake + transport.
// Message sizes (no cookie path beyond zeroed mac2 for now):
#define NW_WG_INIT_SIZE  148   // handshake initiation
#define NW_WG_RESP_SIZE   92   // handshake response
#define NW_WG_DATA_HDR    16   // type(1)+res(3)+receiver(4)+counter(8)

typedef struct {
    uint8_t  static_private[32];
    uint8_t  static_public[32];
    uint8_t  peer_static_public[32];
    uint8_t  psk[32];                 // all-zero if unused

    // live handshake state
    uint8_t  hash[32];
    uint8_t  chaining_key[32];
    uint8_t  ephemeral_private[32];
    uint8_t  ephemeral_public[32];
    uint8_t  remote_ephemeral[32];    // responder: initiator's ephemeral
    uint8_t  remote_static[32];       // responder: learned initiator static
    uint32_t local_index;
    uint32_t remote_index;
    uint8_t  reserved[3]; // Used for Cloudflare WARP Client ID
} nw_handshake;

typedef struct {
    uint8_t  send_key[32];
    uint8_t  recv_key[32];
    uint64_t send_counter;
    uint64_t recv_counter;
    uint32_t local_index;
    uint32_t remote_index;
    uint8_t  reserved[3];   // WARP client_id (from registration) copied here for data packets
} nw_transport;

// Fill 32 random bytes (from /dev/urandom). Returns 0 on success.
int nw_random(uint8_t *buf, size_t len);

// Initialise our identity. If static_private is NULL a fresh key is generated.
void nw_handshake_init(nw_handshake *hs,
                       const uint8_t static_private[32],
                       const uint8_t peer_static_public[32],
                       const uint8_t psk[32]);

// Initiator: build a 148-byte initiation into out. local_index identifies us.
int nw_wg_create_initiation(nw_handshake *hs, uint32_t local_index, uint8_t out[NW_WG_INIT_SIZE]);

// Responder: consume a 148-byte initiation (verifies mac1). Learns the peer's
// static public + ephemeral; leaves hs ready for create_response.
int nw_wg_consume_initiation(nw_handshake *hs, const uint8_t msg[NW_WG_INIT_SIZE]);

// Responder: build a 92-byte response and derive transport keys.
int nw_wg_create_response(nw_handshake *hs, uint32_t local_index,
                          uint8_t out[NW_WG_RESP_SIZE], nw_transport *t);

// Initiator: consume the 92-byte response and derive transport keys.
int nw_wg_consume_response(nw_handshake *hs, const uint8_t msg[NW_WG_RESP_SIZE], nw_transport *t);

// Transport data (type 4). encrypt: out needs NW_WG_DATA_HDR+plen+16 bytes.
int nw_wg_transport_encrypt(nw_transport *t, const uint8_t *plain, size_t plen,
                            uint8_t *out, size_t *outlen);
int nw_wg_transport_decrypt(nw_transport *t, const uint8_t *msg, size_t mlen,
                            uint8_t *out, size_t *outlen);

// In-process initiator<->responder handshake + data round-trip. 0 = all pass.
int nw_wg_selftest(int verbose);

#endif // NW_WG_H
