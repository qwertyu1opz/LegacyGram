#ifndef NW_AWG_H
#define NW_AWG_H

#include <stdint.h>
#include <sys/socket.h>

// AmneziaWG obfuscation parameters.
//
// The reference WARP portal that works through DPI is AmneziaWG, not vanilla
// WireGuard: the handshake slips through but the censor fingerprints and drops
// the steady WireGuard transport flow ("connected, no internet"). AmneziaWG
// defeats that with Jc junk packets + the I1 signature packet.
//
// Defaults below == vanilla WireGuard (no-op), so a profile that omits these
// behaves exactly as before. Crucially, H1..H4 = 1/2/3/4 and S1..S4 = 0 keep
// the on-wire protocol byte-identical to stock WireGuard — the ONLY values a
// real Cloudflare WARP edge accepts. Non-default H*/S* are stored and applied
// faithfully but only make sense against an actual AmneziaWG server.
typedef struct {
    int  jc;              // # of junk packets emitted before each handshake init
    int  jmin, jmax;      // junk packet size range, bytes
    int  s1, s2, s3, s4;  // junk prepended to init/response/cookie/transport (0 = none)
    int  h1, h2, h3, h4;  // message-type magic headers (1/2/3/4 = vanilla)
    char ipkt[5][4096];   // I1..I5 signature-packet tag strings ("" = unset).
                          // Large: the reference I1 is a 1200-byte packet (~2.4k hex).
} nw_awg;

// jc/jmin/jmax/s* = 0, h1..h4 = 1..4, ipkt all empty.
void nw_awg_defaults(nw_awg *a);

// Apply one "key=value" token. Recognised keys (case-insensitive):
//   jc jmin jmax s1 s2 s3 s4 h1 h2 h3 h4 i1 i2 i3 i4 i5
// Returns 1 if the key was recognised and stored, 0 otherwise.
int nw_awg_set(nw_awg *a, const char *key, const char *val);

// True if any obfuscation differs from the vanilla default.
int nw_awg_active(const nw_awg *a);

// Build raw bytes from an AmneziaWG packet-tag string into out[cap].
// Supported tags (whitespace-separated, may repeat/concatenate):
//   <b 0xHEX>  literal bytes from hex     <r N>  N random bytes
//   <c>        4-byte LE rolling counter  <t>    4-byte LE unix timestamp
// Returns bytes written (<= cap), or -1 on a malformed/empty string.
int nw_awg_build_packet(const char *tags, uint8_t *out, int cap);

// Emit the I1..I5 signature packets once (call right after the socket is
// pointed at the peer, before the first handshake). Returns packets sent.
int nw_awg_send_signature(int s, const struct sockaddr *dst, socklen_t dlen, const nw_awg *a);

// Emit `jc` junk packets of random size in [jmin, jmax]. Call before each
// handshake-initiation send. No-op when jc <= 0. Returns packets sent.
int nw_awg_send_junk(int s, const struct sockaddr *dst, socklen_t dlen, const nw_awg *a);

#endif // NW_AWG_H
