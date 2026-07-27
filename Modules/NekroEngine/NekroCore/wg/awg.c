// AmneziaWG obfuscation: junk packets + signature packets.
//
// Against a vanilla Cloudflare WARP edge the active, useful parameters are the
// Jc junk packets and the I1 signature packet — both are extra UDP datagrams
// the edge silently drops, so the real WireGuard handshake/transport is left
// untouched while the on-the-wire flow no longer fingerprints as WireGuard.
#include "awg.h"

#include <string.h>
#include <strings.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>

void nw_awg_defaults(nw_awg *a) {
    memset(a, 0, sizeof(*a));
    a->h1 = 1; a->h2 = 2; a->h3 = 3; a->h4 = 4;
}

int nw_awg_active(const nw_awg *a) {
    if (a->jc > 0) return 1;
    if (a->s1 || a->s2 || a->s3 || a->s4) return 1;
    if (a->h1 != 1 || a->h2 != 2 || a->h3 != 3 || a->h4 != 4) return 1;
    for (int i = 0; i < 5; i++) if (a->ipkt[i][0]) return 1;
    return 0;
}

int nw_awg_set(nw_awg *a, const char *key, const char *val) {
    if (!key || !val) return 0;
    if (strcasecmp(key, "jc") == 0)        { a->jc = atoi(val);   return 1; }
    if (strcasecmp(key, "jmin") == 0)      { a->jmin = atoi(val); return 1; }
    if (strcasecmp(key, "jmax") == 0)      { a->jmax = atoi(val); return 1; }
    if (strcasecmp(key, "s1") == 0)        { a->s1 = atoi(val);   return 1; }
    if (strcasecmp(key, "s2") == 0)        { a->s2 = atoi(val);   return 1; }
    if (strcasecmp(key, "s3") == 0)        { a->s3 = atoi(val);   return 1; }
    if (strcasecmp(key, "s4") == 0)        { a->s4 = atoi(val);   return 1; }
    if (strcasecmp(key, "h1") == 0)        { a->h1 = atoi(val);   return 1; }
    if (strcasecmp(key, "h2") == 0)        { a->h2 = atoi(val);   return 1; }
    if (strcasecmp(key, "h3") == 0)        { a->h3 = atoi(val);   return 1; }
    if (strcasecmp(key, "h4") == 0)        { a->h4 = atoi(val);   return 1; }
    if ((key[0] == 'i' || key[0] == 'I') && key[1] >= '1' && key[1] <= '5' && key[2] == '\0') {
        int idx = key[1] - '1';
        // The portal shows unset I2..I5 as the grey placeholder "<b 0x1A2B3C>";
        // treat that sentinel (and an empty string) as "no packet".
        if (val[0] == '\0' || strcasecmp(val, "<b 0x1A2B3C>") == 0) { a->ipkt[idx][0] = '\0'; return 1; }
        strncpy(a->ipkt[idx], val, sizeof(a->ipkt[idx]) - 1);
        a->ipkt[idx][sizeof(a->ipkt[idx]) - 1] = '\0';
        return 1;
    }
    return 0;
}

static int hexval(int c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static int fill_random(uint8_t *buf, int n) {
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd < 0) return -1;
    int got = 0;
    while (got < n) {
        ssize_t r = read(fd, buf + got, n - got);
        if (r <= 0) { close(fd); return -1; }
        got += (int)r;
    }
    close(fd);
    return 0;
}

int nw_awg_build_packet(const char *tags, uint8_t *out, int cap) {
    if (!tags || !*tags) return -1;
    static uint32_t counter = 0;
    int len = 0;
    const char *p = tags;
    while (*p) {
        if (*p != '<') { p++; continue; }
        p++; // past '<'
        while (*p == ' ') p++;
        char kind = *p ? *p++ : '\0';
        while (*p == ' ') p++;
        if (kind == 'b' || kind == 'B') {
            // optional 0x prefix, then hex digit pairs until '>'
            if (p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) p += 2;
            while (*p && *p != '>') {
                int hi = hexval((unsigned char)*p);
                if (hi < 0) { p++; continue; }
                p++;
                int lo = hexval((unsigned char)*p);
                if (lo < 0) break;
                p++;
                if (len < cap) out[len++] = (uint8_t)((hi << 4) | lo);
            }
        } else if (kind == 'r' || kind == 'R') {
            int n = atoi(p);
            while (*p && *p != '>') p++;
            if (n < 0) n = 0;
            if (n > cap - len) n = cap - len;
            if (n > 0 && fill_random(out + len, n) == 0) len += n;
        } else if (kind == 'c' || kind == 'C') {
            uint32_t v = counter++;
            for (int i = 0; i < 4 && len < cap; i++) out[len++] = (uint8_t)(v >> (8 * i));
        } else if (kind == 't' || kind == 'T') {
            uint32_t v = (uint32_t)time(NULL);
            for (int i = 0; i < 4 && len < cap; i++) out[len++] = (uint8_t)(v >> (8 * i));
        }
        while (*p && *p != '>') p++;
        if (*p == '>') p++;
    }
    return len;
}

int nw_awg_send_signature(int s, const struct sockaddr *dst, socklen_t dlen, const nw_awg *a) {
    int sent = 0;
    uint8_t buf[4096]; // I-packets can be large (reference I1 = 1200 bytes)
    for (int i = 0; i < 5; i++) {
        if (!a->ipkt[i][0]) continue;
        int n = nw_awg_build_packet(a->ipkt[i], buf, sizeof(buf));
        if (n > 0 && sendto(s, buf, n, 0, dst, dlen) >= 0) {
            sent++;
            printf("[AWG] sent I%d signature packet (%d bytes)\n", i + 1, n);
        }
    }
    return sent;
}

int nw_awg_send_junk(int s, const struct sockaddr *dst, socklen_t dlen, const nw_awg *a) {
    if (a->jc <= 0) return 0;
    int lo = a->jmin > 0 ? a->jmin : 0;
    int hi = a->jmax > lo ? a->jmax : lo;
    if (hi <= 0) hi = lo = 64; // sane fallback if only Jc was given
    uint8_t buf[2048];
    int sent = 0;
    for (int i = 0; i < a->jc; i++) {
        int span = hi - lo;
        uint32_t r = 0;
        if (span > 0) fill_random((uint8_t *)&r, sizeof(r));
        int n = lo + (span > 0 ? (int)(r % (uint32_t)(span + 1)) : 0);
        if (n <= 0) n = lo > 0 ? lo : 64;
        if (n > (int)sizeof(buf)) n = sizeof(buf);
        if (fill_random(buf, n) != 0) continue;
        if (sendto(s, buf, n, 0, dst, dlen) >= 0) sent++;
    }
    if (sent) printf("[AWG] sent %d junk packet(s) [%d..%d bytes]\n", sent, lo, hi);
    return sent;
}
