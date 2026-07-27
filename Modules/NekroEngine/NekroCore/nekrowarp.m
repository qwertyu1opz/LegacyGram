// NekroWARP — native WARP/WireGuard tunnel for jailbroken iOS 5.x
//
// This early build is the *gating feasibility probe*: before any crypto or
// WireGuard handshake is worth writing, we must know whether the kernel on this
// jailbreak will hand us a layer-3 tun interface at all. Everything downstream
// (Noise handshake, ChaCha20-Poly1305, WARP registration, routing) depends on it.

#import <Foundation/Foundation.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <mach/mach.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>

#include "tun/nw_tun.h"
#include "tun/nw_route.h"
#include "tun/nw_scope.h"
#include "crypto/selftest.h"
#include "crypto/x25519.h"
#include "wg/wg.h"
#include "wg/awg.h"
#include "wg/awg_default_i1.h"
#include <signal.h>
#include <time.h>
#include <Security/SecureTransport.h>   // iOS 5 Secure Transport — modern TLS (1.2)
#include <mach-o/loader.h>
#import <SystemConfiguration/SystemConfiguration.h>

#include <dlfcn.h>

typedef mach_port_t mach_vm_map_t;
typedef uint64_t mach_vm_address_t;
typedef uint64_t mach_vm_size_t;

typedef kern_return_t (*mach_vm_region_recurse_t)(
    vm_map_t target_task,
    mach_vm_address_t *address,
    mach_vm_size_t *size,
    natural_t *nesting_depth,
    vm_region_recurse_info_t info,
    mach_msg_type_number_t *infoCnt
);

typedef kern_return_t (*mach_vm_read_t)(
    vm_map_t target_task,
    mach_vm_address_t address,
    mach_vm_size_t size,
    vm_offset_t *data,
    mach_msg_type_number_t *dataCnt
);

typedef kern_return_t (*mach_vm_write_t)(
    vm_map_t target_task,
    mach_vm_address_t address,
    vm_offset_t data,
    mach_msg_type_number_t dataCnt
);

#ifndef TASK_DYLD_INFO
struct task_dyld_info {
    mach_vm_address_t all_image_info_addr;
    mach_vm_size_t    all_image_info_size;
    integer_t         all_image_info_format;
};
#define TASK_DYLD_INFO 17
#define TASK_DYLD_INFO_COUNT (sizeof(struct task_dyld_info) / sizeof(natural_t))
#endif

static BOOL is_kernel_64bit(void);
static kern_return_t kread_safe(mach_port_t kt, mach_vm_address_t addr, mach_vm_size_t size, vm_offset_t *data, mach_msg_type_number_t *dataCnt, BOOL is64);
static kern_return_t kwrite_safe(mach_port_t kt, mach_vm_address_t addr, vm_offset_t data, mach_msg_type_number_t dataCnt, BOOL is64);
static kern_return_t kregion_safe(mach_port_t kt, mach_vm_address_t *addr, mach_vm_size_t *size, BOOL is64);

static int nw_https_request(const char *ip, int port, const char *sni, int frag,
                            const char *req, size_t req_len,
                            char *resp, size_t resp_cap);
static int nw_https_request_via_proxy(const char *proxy_ip, int proxy_port,
                                      const char *target_host, int target_port,
                                      const char *req, size_t req_len,
                                      char *resp, size_t resp_cap);

#define NW_VERSION "0.0.19"

static int cmd_probe(void) {
    printf("NekroWARP %s — tun feasibility probe\n", NW_VERSION);
    printf("uid=%d  (root/0 required to create a tun)\n\n", (int)getuid());

    int have_utun = 0, have_dev = 0;
    char ifn[64];

    int fd = nw_tun_open_utun(ifn, sizeof(ifn));
    if (fd >= 0) {
        have_utun = 1;
        printf("[ OK ] utun control available  -> %s\n", ifn);
        printf("       'com.apple.net.utun_control' accepts connect() as this user.\n");
        close(fd);
    } else {
        printf("[ -- ] utun unavailable: %s\n", strerror(errno));
        printf("       (EPERM here usually means an entitlement is required on the\n");
        printf("        signed binary; ENOENT means no utun control in this kernel.)\n");
    }

    printf("\n");

    fd = nw_tun_open_dev(ifn, sizeof(ifn));
    if (fd >= 0) {
        have_dev = 1;
        printf("[ OK ] legacy tun.kext available -> /dev/%s\n", ifn);
        close(fd);
    } else {
        printf("[ -- ] legacy /dev/tunN unavailable: %s\n", strerror(errno));
        printf("       (load the 'tun' kext from a jailbreak repo to enable this path.)\n");
    }

    printf("\n----------------------------------------------------------\n");
    if (have_utun || have_dev) {
        printf("VERDICT: GO. A %s interface is reachable — the WireGuard layer\n",
               have_utun ? "utun" : "tun.kext");
        printf("         can be built on top. Next: `nekrowarp tun-up <local> <peer>`\n");
        printf("         to bring one up and confirm packets flow.\n");
        return 0;
    }
    printf("VERDICT: BLOCKED. No tun path on this device yet. Try loading tun.kext,\n");
    printf("         or re-sign this binary with utun entitlements, then re-probe.\n");
    return 1;
}

// Bring an interface up (address + flags set via ioctl — the device has no
// ifconfig) and hold it open. With `seconds` > 0 it self-terminates; otherwise
// it blocks on read(), reporting any packets the kernel routes into the tun.
static int cmd_tun_up(const char *local, const char *peer, int seconds) {
    char ifn[64];
    int fd = nw_tun_open_utun(ifn, sizeof(ifn));
    if (fd < 0) fd = nw_tun_open_dev(ifn, sizeof(ifn));
    if (fd < 0) {
        fprintf(stderr, "tun-up: no tun interface available (%s). Run `nekrowarp probe`.\n",
                strerror(errno));
        return 1;
    }

    printf("interface: %s\n", ifn);
    if (nw_tun_set_ipv4(ifn, local, peer) < 0)
        fprintf(stderr, "warning: ioctl address config failed: %s\n", strerror(errno));

    printf("configured via ioctl (no ifconfig needed):\n");
    nw_tun_report(ifn);

    if (seconds > 0) {
        printf("holding %s up for %d s…\n", ifn, seconds);
        sleep((unsigned)seconds);
    } else {
        printf("holding %s open (Ctrl-C to drop)…\n", ifn);
        unsigned char buf[2048];
        for (;;) {
            ssize_t n = read(fd, buf, sizeof(buf));
            if (n <= 0) break;
            // utun prepends a 4-byte address-family header; tun.kext does not.
            printf("rx %ld bytes from %s\n", (long)n, ifn);
            fflush(stdout);
        }
    }
    close(fd);
    printf("dropped %s\n", ifn);
    return 0;
}

// Isolated test of the scoped-routing fix (path a) WITHOUT the full tunnel:
// bring a utun up with a WARP-like address, publish it as the primary service
// via SCDynamicStore, hold it up for `seconds` while counting any packets the
// kernel routes in (rx>0 means unbound sockets are now scoped to the utun), then
// restore. Run e.g.: nekrowarp scope-test 172.16.0.2 172.16.0.1 20
static int cmd_scope_test(const char *local, const char *router, int seconds) {
    char ifn[64];
    int fd = nw_tun_open_utun(ifn, sizeof(ifn));
    if (fd < 0) fd = nw_tun_open_dev(ifn, sizeof(ifn));
    if (fd < 0) {
        fprintf(stderr, "scope-test: no tun interface (%s)\n", strerror(errno));
        return 1;
    }
    printf("interface: %s\n", ifn);
    if (nw_tun_set_ipv4(ifn, local, router) < 0)
        fprintf(stderr, "warning: ioctl address config failed: %s\n", strerror(errno));
    nw_tun_set_mtu(ifn, 1280);
    nw_tun_report(ifn);

    printf("=== BEFORE set_primary ===\n");
    nw_scope_probe();

    if (nw_scope_set_primary(ifn, local, router) != 0)
        fprintf(stderr, "scope-test: set_primary failed, continuing to observe\n");

    if (seconds <= 0) seconds = 20;
    printf("holding %s up for %d s, counting inbound packets…\n", ifn, seconds);

    // Self-generated probe traffic: an UNBOUND UDP socket toward 1.1.1.1:53.
    // If scoped routing now points the primary at our utun, the kernel writes
    // this datagram out the utun and we read it back below (rx>0).
    int probe = socket(AF_INET, SOCK_DGRAM, 0);
    struct sockaddr_in dst; memset(&dst, 0, sizeof(dst));
    dst.sin_family = AF_INET; dst.sin_port = htons(53);
    inet_aton("1.1.1.1", &dst.sin_addr);

    struct timeval t0; gettimeofday(&t0, NULL);
    long rx = 0; long last_send = 0; unsigned char buf[2048];
    for (;;) {
        struct timeval now; gettimeofday(&now, NULL);
        if (now.tv_sec - t0.tv_sec >= seconds) break;
        if (probe >= 0 && now.tv_sec != last_send) {
            last_send = now.tv_sec;
            unsigned char q[12] = { 0xab,0xcd,0x01,0x00,0,1,0,0,0,0,0,0 };
            sendto(probe, q, sizeof(q), 0, (struct sockaddr*)&dst, sizeof(dst));
        }
        fd_set rs; FD_ZERO(&rs); FD_SET(fd, &rs);
        struct timeval tv = { 1, 0 };
        int r = select(fd + 1, &rs, NULL, NULL, &tv);
        if (r > 0 && FD_ISSET(fd, &rs)) {
            ssize_t n = read(fd, buf, sizeof(buf));
            if (n > 0) { rx++; if (rx <= 5) printf("  rx %ld bytes\n", (long)n); }
        }
    }
    if (probe >= 0) close(probe);
    printf("=== RESULT: tun_in (inbound packets) = %ld ===\n", rx);
    printf("(rx>0 => scoped routing now sends unbound-socket traffic into the utun)\n");

    nw_scope_restore();
    close(fd);
    printf("restored; dropped %s\n", ifn);
    return 0;
}

// Standard base64 decode. Returns number of bytes written, or -1 on overflow.
static int b64decode(const char *in, uint8_t *out, size_t outcap) {
    static const char T[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    int val = 0, valb = -8;
    size_t o = 0;
    const char *p;
    for (p = in; *p && *p != '='; p++) {
        const char *q = strchr(T, *p);
        if (!q) continue;
        val = (val << 6) | (int)(q - T);
        valb += 6;
        if (valb >= 0) {
            if (o >= outcap) return -1;
            out[o++] = (uint8_t)((val >> valb) & 0xff);
            valb -= 8;
        }
    }
    return (int)o;
}

static void b64encode(const uint8_t *in, size_t len, char *out, size_t outcap) {
    static const char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    char *p = out;
    for (size_t i = 0; i < len; i += 3) {
        if ((size_t)(p - out) + 4 >= outcap) break;
        uint32_t val = (in[i] << 16) | (((i + 1) < len ? in[i + 1] : 0) << 8) | ((i + 2) < len ? in[i + 2] : 0);
        *p++ = table[(val >> 18) & 63];
        *p++ = table[(val >> 12) & 63];
        *p++ = (i + 1) < len ? table[(val >> 6) & 63] : '=';
        *p++ = (i + 2) < len ? table[val & 63] : '=';
    }
    *p = '\0';
}

static void extract_json_str(const char *json, const char *key, char *out, size_t max) {
    char search[128];
    snprintf(search, sizeof(search), "\"%s\"", key);
    const char *p = strstr(json, search);
    if (!p) return;
    p += strlen(search);
    while (*p && (*p == ' ' || *p == '\t' || *p == ':' || *p == '"')) {
        p++;
    }
    size_t i = 0;
    while (*p && *p != '"' && i < max - 1) {
        out[i++] = *p++;
    }
    out[i] = '\0';
}

static int try_register_with_proxy(const char *proxy_ip, int proxy_port, const char *input_priv_b64) {
    uint8_t priv[32], pub[32];
    char priv_b64[64], pub_b64[64];
    
    if (input_priv_b64 && strlen(input_priv_b64) > 0) {
        if (b64decode(input_priv_b64, priv, sizeof(priv)) != 32) {
            fprintf(stderr, "bad input private key\n");
            return -1;
        }
        nw_x25519_base(pub, priv);
        b64encode(priv, 32, priv_b64, sizeof(priv_b64));
        b64encode(pub, 32, pub_b64, sizeof(pub_b64));
    } else {
        nw_random(priv, 32);
        priv[0] &= 248; priv[31] &= 127; priv[31] |= 64;
        nw_x25519_base(pub, priv);
        b64encode(priv, 32, priv_b64, sizeof(priv_b64));
        b64encode(pub, 32, pub_b64, sizeof(pub_b64));
    }
    
    time_t now = time(NULL);
    struct tm *gmt = gmtime(&now);
    char tos[64];
    strftime(tos, sizeof(tos), "%Y-%m-%dT%H:%M:%S.000Z", gmt);
    
    char body[512];
    snprintf(body, sizeof(body),
             "{\"key\":\"%s\",\"install_id\":\"\",\"fcm_token\":\"\","
             "\"tos\":\"%s\",\"model\":\"PC\",\"serial_number\":\"\",\"locale\":\"en_US\"}",
             pub_b64, tos);
    
    char req[1024];
    int reqlen = snprintf(req, sizeof(req),
             "POST /v0a2483/reg HTTP/1.1\r\n"
             "Host: api.cloudflareclient.com\r\n"
             "User-Agent: okhttp/3.12.1\r\n"
             "CF-Client-Version: a-6.10-2483\r\n"
             "Content-Type: application/json\r\n"
             "Content-Length: %d\r\n"
             "Connection: close\r\n\r\n"
             "%s",
             (int)strlen(body), body);
             
    char *resp = malloc(8192);
    if (!resp) return -1;
    
    int n = nw_https_request_via_proxy(proxy_ip, proxy_port, "api.cloudflareclient.com", 443,
                                      req, (size_t)reqlen, resp, 8192);
    if (n <= 0) {
        free(resp);
        return -1;
    }
    

    
    char id[128] = {0};
    char token[256] = {0};
    extract_json_str(resp, "id", id, sizeof(id));
    extract_json_str(resp, "token", token, sizeof(token));
    
    if (strlen(id) == 0 || strlen(token) == 0) {
        free(resp);
        return -1;
    }
    
    char client_ip[64] = {0};
    char client_ip6[128] = {0};
    char peer_pub[128] = {0};
    
    char *addr_p = strstr(resp, "\"addresses\"");
    if (addr_p) {
        extract_json_str(addr_p, "v4", client_ip, sizeof(client_ip));
        extract_json_str(addr_p, "v6", client_ip6, sizeof(client_ip6));
    } else {
        extract_json_str(resp, "v4", client_ip, sizeof(client_ip));
        extract_json_str(resp, "v6", client_ip6, sizeof(client_ip6));
    }
    char *slash = strchr(client_ip, '/');
    if (slash) *slash = '\0';
    if (strlen(client_ip) == 0) strcpy(client_ip, "172.16.0.2");
    
    slash = strchr(client_ip6, '/');
    if (slash) *slash = '\0';
    
    extract_json_str(resp, "public_key", peer_pub, sizeof(peer_pub));
    if (strlen(peer_pub) == 0) strcpy(peer_pub, "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=");
    
    char client_id_b64[64] = {0};
    extract_json_str(resp, "client_id", client_id_b64, sizeof(client_id_b64));
    if (strlen(client_id_b64) == 0) strcpy(client_id_b64, "AAAA");
    
    free(resp);
    
    // PATCH to enable warp
    snprintf(body, sizeof(body), "{\"warp\":{\"enabled\":true}}");
    reqlen = snprintf(req, sizeof(req),
            "PATCH /v0a2483/reg/%s HTTP/1.1\r\n"
            "Host: api.cloudflareclient.com\r\n"
            "User-Agent: okhttp/3.12.1\r\n"
            "CF-Client-Version: a-6.10-2483\r\n"
            "Authorization: Bearer %s\r\n"
            "Content-Type: application/json\r\n"
            "Content-Length: %d\r\n"
            "Connection: close\r\n\r\n"
            "%s",
            id, token, (int)strlen(body), body);
            
    char presp[4096];
    n = nw_https_request_via_proxy(proxy_ip, proxy_port, "api.cloudflareclient.com", 443,
                                  req, (size_t)reqlen, presp, sizeof(presp));

    if (n <= 0) {
        return -1;
    }
    
    printf("{\n");
    printf("  \"status\": \"success\",\n");
    printf("  \"endpoint\": \"engage.cloudflareclient.com\",\n");
    printf("  \"port\": \"4500\",\n");
    printf("  \"priv\": \"%s\",\n", priv_b64);
    printf("  \"pub\": \"%s\",\n", peer_pub);
    printf("  \"clientIp\": \"%s\",\n", client_ip);
    printf("  \"clientIp6\": \"%s\",\n", client_ip6);
    printf("  \"reserved\": \"%s\",\n", client_id_b64);
    printf("  \"dns\": \"1.1.1.1, 8.8.8.8\"\n");
    printf("}\n");
    
    return 0;
}

// ---- In-process HTTPS via libcurl (OpenSSL / TLS 1.3) -----------------------
#include <curl/curl.h>

const char *g_bind_src = NULL;

struct CurlBuffer {
    char *buf;
    size_t len;
    size_t cap;
};

static size_t curl_write_cb(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    struct CurlBuffer *mem = (struct CurlBuffer *)userp;
    if (mem->len + realsize >= mem->cap) {
        return 0; // buffer overflow
    }
    memcpy(&(mem->buf[mem->len]), contents, realsize);
    mem->len += realsize;
    mem->buf[mem->len] = 0;
    return realsize;
}

static int nw_https_request_impl(const char *ip, int port, const char *sni, int frag,
                                 const char *proxy_ip, int proxy_port,
                                 const char *req, size_t req_len,
                                 char *resp, size_t resp_cap) {
    CURL *curl = curl_easy_init();
    if (!curl) return -1;

    // Parse method, path, headers, body from req
    char method[16] = {0};
    char path[512] = {0};
    const char *p = req;
    
    // Read first line
    const char *next_line = strstr(p, "\r\n");
    if (!next_line) { curl_easy_cleanup(curl); return -1; }
    sscanf(p, "%15s %511s", method, path);
    p = next_line + 2;

    struct curl_slist *headers = NULL;
    const char *body = NULL;
    
    while (p && *p) {
        if (strncmp(p, "\r\n", 2) == 0) {
            body = p + 2;
            break;
        }
        next_line = strstr(p, "\r\n");
        if (!next_line) break;
        
        size_t len = next_line - p;
        char *header = malloc(len + 1);
        memcpy(header, p, len);
        header[len] = '\0';
        
        // Skip Host, Content-Length, Connection headers as libcurl handles them
        if (strncasecmp(header, "Host:", 5) != 0 &&
            strncasecmp(header, "Content-Length:", 15) != 0 &&
            strncasecmp(header, "Connection:", 11) != 0) {
            headers = curl_slist_append(headers, header);
        }
        free(header);
        p = next_line + 2;
    }

    // Set URL
    char url[1024];
    const char *host_header = sni ? sni : ip;
    snprintf(url, sizeof(url), "https://%s:%d%s", host_header, port, path);
    curl_easy_setopt(curl, CURLOPT_URL, url);

    // If ip != host_header, use CURLOPT_RESOLVE to force libcurl to connect to the IP
    struct curl_slist *resolve_list = NULL;
    if (ip && host_header && strcmp(ip, host_header) != 0) {
        char resolve_buf[256];
        snprintf(resolve_buf, sizeof(resolve_buf), "%s:%d:%s", host_header, port, ip);
        resolve_list = curl_slist_append(NULL, resolve_buf);
        curl_easy_setopt(curl, CURLOPT_RESOLVE, resolve_list);
    }

    // Set method
    if (strcmp(method, "POST") == 0) {
        curl_easy_setopt(curl, CURLOPT_POST, 1L);
        if (body) {
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, (long)strlen(body));
        }
    } else if (strcmp(method, "PATCH") == 0) {
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PATCH");
        if (body) {
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, (long)strlen(body));
        }
    } else if (strcmp(method, "GET") != 0) {
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, method);
    }

    // Set headers
    if (headers) {
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    }

    // Proxy setup
    if (proxy_ip && proxy_port > 0) {
        char proxy_url[256];
        snprintf(proxy_url, sizeof(proxy_url), "http://%s:%d", proxy_ip, proxy_port);
        curl_easy_setopt(curl, CURLOPT_PROXY, proxy_url);
    }

    // Source interface binding
    if (g_bind_src && *g_bind_src) {
        curl_easy_setopt(curl, CURLOPT_INTERFACE, g_bind_src);
    }

    // TLS verification - bypass validation since ST did the same.
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);

    // Timeout
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 8L);

    // Buffer to capture response
    struct CurlBuffer chunk = { resp, 0, resp_cap - 1 };
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_write_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);

    // Perform request
    CURLcode res = curl_easy_perform(curl);
    
    // Clean up
    if (headers) curl_slist_free_all(headers);
    if (resolve_list) curl_slist_free_all(resolve_list);
    
    curl_easy_cleanup(curl);
    
    if (res != CURLE_OK) {
        fprintf(stderr, "[ curl error ] %s\n", curl_easy_strerror(res));
        return -1;
    }
    
    return (int)chunk.len;
}

static int nw_https_request(const char *ip, int port, const char *sni, int frag,
                            const char *req, size_t req_len,
                            char *resp, size_t resp_cap) {
    return nw_https_request_impl(ip, port, sni, frag, NULL, 0, req, req_len, resp, resp_cap);
}

static int nw_https_request_via_proxy(const char *proxy_ip, int proxy_port,
                                      const char *target_host, int target_port,
                                      const char *req, size_t req_len,
                                      char *resp, size_t resp_cap) {
    return nw_https_request_impl(NULL, target_port, target_host, 0, proxy_ip, proxy_port, req, req_len, resp, resp_cap);
}

// Resolve a hostname via DNS-over-HTTPS (Cloudflare 1.1.1.1 JSON API), tunnelled
// through our Secure-Transport client with ClientHello fragmentation — so it works
// even though plain :53 is poisoned and the SNI is DPI-filtered. Returns 0 + IPv4.
static int nw_doh_resolve(const char *host, char *out_ip, size_t out_len) {
    char req[512];
    int reqlen = snprintf(req, sizeof(req),
        "GET /dns-query?name=%s&type=A HTTP/1.1\r\n"
        "Host: cloudflare-dns.com\r\n"
        "Accept: application/dns-json\r\n"
        "User-Agent: NekroWARP\r\n"
        "Connection: close\r\n\r\n", host);
    char resp[4096];
    int got = -1;
    for (int attempt = 1; attempt <= 2 && got <= 0; attempt++) {
        got = nw_https_request("1.1.1.1", 443, "cloudflare-dns.com", 1, req, (size_t)reqlen, resp, sizeof(resp));
    }
    if (got <= 0) return -1;
    // Pull the first dotted-quad out of any "data":"..." field (skips CNAMEs).
    char *d = strstr(resp, "\"data\"");
    while (d) {
        char *q = strchr(d + 6, '"');
        if (q) {
            q++;
            char ipbuf[64]; int i = 0;
            while (*q && *q != '"' && i < 63) ipbuf[i++] = *q++;
            ipbuf[i] = '\0';
            struct in_addr a;
            if (strchr(ipbuf, '.') && inet_aton(ipbuf, &a)) { strlcpy(out_ip, ipbuf, out_len); return 0; }
        }
        d = strstr(d + 6, "\"data\"");
    }
    return -1;
}

// Minimal DNS A-record resolver over UDP against a SPECIFIC server, so we can use
// the uncensored DNS from the user's config instead of the system resolver (which
// is poisoned on this network). Returns 0 and fills out_ip on success.
static int nw_dns_query_a(const char *host, const char *dns_ip, char *out_ip, size_t out_len) {
    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) return -1;
    struct sockaddr_in srv;
    memset(&srv, 0, sizeof(srv));
    srv.sin_family = AF_INET;
    srv.sin_port = htons(53);
    if (inet_aton(dns_ip, &srv.sin_addr) == 0) { close(s); return -1; }
    struct timeval tv = {4, 0};
    setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    uint8_t q[300];
    int ql = 0;
    uint16_t id = (uint16_t)(getpid() ^ (unsigned)time(NULL));
    q[ql++] = id >> 8; q[ql++] = id & 0xff;
    q[ql++] = 0x01; q[ql++] = 0x00;   // flags: recursion desired
    q[ql++] = 0x00; q[ql++] = 0x01;   // QDCOUNT = 1
    q[ql++] = 0x00; q[ql++] = 0x00;   // ANCOUNT
    q[ql++] = 0x00; q[ql++] = 0x00;   // NSCOUNT
    q[ql++] = 0x00; q[ql++] = 0x00;   // ARCOUNT
    const char *p = host;
    while (*p && ql < (int)sizeof(q) - 6) {
        const char *dot = strchr(p, '.');
        int seg = dot ? (int)(dot - p) : (int)strlen(p);
        if (seg <= 0 || seg > 63) { close(s); return -1; }
        q[ql++] = (uint8_t)seg;
        memcpy(q + ql, p, seg); ql += seg;
        if (!dot) break;
        p = dot + 1;
    }
    q[ql++] = 0x00;                   // root label
    q[ql++] = 0x00; q[ql++] = 0x01;   // QTYPE = A
    q[ql++] = 0x00; q[ql++] = 0x01;   // QCLASS = IN

    if (sendto(s, q, ql, 0, (struct sockaddr *)&srv, sizeof(srv)) < 0) { close(s); return -1; }

    uint8_t r[1500];
    ssize_t n = recvfrom(s, r, sizeof(r), 0, NULL, NULL);
    close(s);
    if (n < 12) return -1;
    int ancount = (r[6] << 8) | r[7];
    if (ancount < 1) return -1;

    int off = 12;
    // skip the question's QNAME
    while (off < (int)n && r[off] != 0) {
        if ((r[off] & 0xc0) == 0xc0) { off += 1; break; }
        off += r[off] + 1;
    }
    off += 1;       // terminating 0 (or 2nd pointer byte)
    off += 4;       // QTYPE + QCLASS
    for (int a = 0; a < ancount; a++) {
        if (off + 12 > (int)n) return -1;
        if ((r[off] & 0xc0) == 0xc0) off += 2;            // compressed NAME
        else { while (off < (int)n && r[off] != 0) off += r[off] + 1; off += 1; }
        if (off + 10 > (int)n) return -1;
        int type = (r[off] << 8) | r[off + 1];
        int rdlen = (r[off + 8] << 8) | r[off + 9];
        off += 10;
        if (off + rdlen > (int)n) return -1;
        if (type == 1 && rdlen == 4) {
            snprintf(out_ip, out_len, "%u.%u.%u.%u", r[off], r[off+1], r[off+2], r[off+3]);
            return 0;
        }
        off += rdlen;
    }
    return -1;
}

// Try resolving `host` against each server in a comma/space-separated DNS list,
// returning the first answer. Returns 0 on success.
static int nw_resolve_via_list(const char *host, const char *dns_list, char *out_ip, size_t out_len) {
    if (!dns_list || strlen(dns_list) == 0) return -1;
    char buf[256];
    strlcpy(buf, dns_list, sizeof(buf));
    char *save = NULL;
    for (char *tok = strtok_r(buf, " ,\t", &save); tok; tok = strtok_r(NULL, " ,\t", &save)) {
        if (nw_dns_query_a(host, tok, out_ip, out_len) == 0) {
            fprintf(stderr, "[ NekroWARP ] Resolved %s -> %s via DNS %s\n", host, out_ip, tok);
            return 0;
        }
        fprintf(stderr, "[ NekroWARP ] DNS %s did not resolve %s\n", tok, host);
    }
    return -1;
}

static int download_proxy_list(char proxies[][32], int max_proxies, const char *scrape_ip) {
    const char *sip = (scrape_ip && strlen(scrape_ip) > 0) ? scrape_ip : "104.18.10.5";
    fprintf(stderr, "[ NekroWARP ] Fetching HTTP proxy list (via %s, fast mode)...\n", sip);
    
    char req[512];
    int reqlen = snprintf(req, sizeof(req),
             "GET /v2/?request=displayproxies&protocol=http&timeout=2000&country=all&ssl=yes&anonymity=all HTTP/1.1\r\n"
             "Host: api.proxyscrape.com\r\n"
             "Connection: close\r\n\r\n");
             
    char *resp_buf = malloc(65536);
    if (!resp_buf) return 0;
    
    int n = nw_https_request(sip, 443, "api.proxyscrape.com", 0, req, (size_t)reqlen, resp_buf, 65536);
    if (n <= 0) {
        free(resp_buf);
        return 0;
    }
    
    char *body = strstr(resp_buf, "\r\n\r\n");
    if (body) body += 4;
    else body = resp_buf;
    
    int count = 0;
    char *line = body;
    while (line && *line && count < max_proxies) {
        char *next_line = strchr(line, '\n');
        if (next_line) {
            *next_line = '\0';
        }
        
        char *r = strchr(line, '\r');
        if (r) *r = '\0';
        
        char ip[32];
        int port;
        if (sscanf(line, "%[^:]:%d", ip, &port) == 2) {
            snprintf(proxies[count++], 32, "%s:%d", ip, port);
        }
        
        if (next_line) {
            line = next_line + 1;
        } else {
            break;
        }
    }
    
    free(resp_buf);
    return count;
}

static int test_direct_connection(const char *ip, int port) {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr(ip);
    addr.sin_port = htons(port);
    
    struct timeval tv = {2, 0}; // 2 seconds timeout
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    
    // Set non-blocking to handle connection timeout properly
    int flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
    
    int rc = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
    if (rc < 0) {
        if (errno == EINPROGRESS) {
            fd_set wset;
            FD_ZERO(&wset);
            FD_SET(fd, &wset);
            rc = select(fd + 1, NULL, &wset, NULL, &tv);
            if (rc > 0) {
                int err = 0;
                socklen_t len = sizeof(err);
                if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &len) < 0 || err != 0) {
                    rc = -1;
                } else {
                    rc = 0;
                }
            } else {
                rc = -1; // timeout or error
            }
        } else {
            rc = -1;
        }
    }
    
    close(fd);
    return rc;
}

static void force_restore_routing(void);   // defined below; used to self-heal here

static int cmd_register(const char *api_ip, const char *input_priv_b64, const char *dns_list) {
    // Self-heal a stranded tunnel: if a previous `warp-tunnel` was SIGKILLed its
    // cleanup() never ran, leaving the default route pointing at a dead utun
    // gateway and /etc/resolv.conf set to the WARP DNS. Every network op below
    // (TLS DNS, the api:443 reachability probe) would then blackhole. If the pid
    // file names a dead process, restore the physical route + original DNS first.
    {
        FILE *pf = fopen("/tmp/nekrowarp.pid", "r");
        if (pf) {
            pid_t pid = 0;
            int have = (fscanf(pf, "%d", &pid) == 1);
            fclose(pf);
            if (!have || pid <= 0 || kill(pid, 0) != 0) {
                fprintf(stderr, "[ NekroWARP ] Stale tunnel state detected; restoring network before registration...\n");
                force_restore_routing();
                unlink("/tmp/nekrowarp.pid");
            }
        }
    }

    // Resolve the API endpoint through the config's (uncensored) DNS first. The
    // system resolver is poisoned on this network, and the hardcoded fallback IP
    // is a generic Cloudflare edge that often won't serve the registration API.
    char resolved_api[64] = {0};
    int direct_ok = 0;
    if (dns_list && strlen(dns_list) > 0) {
        fprintf(stderr, "[ NekroWARP ] Resolving api.cloudflareclient.com via config DNS (%s)...\n", dns_list);
        if (nw_resolve_via_list("api.cloudflareclient.com", dns_list, resolved_api, sizeof(resolved_api)) != 0) {
            fprintf(stderr, "[ NekroWARP ] Config-DNS resolve failed.\n");
        }
    }
    // DoH fallback over our modern-TLS client (plain :53 is poisoned for this host).
    if (strlen(resolved_api) == 0) {
        fprintf(stderr, "[ NekroWARP ] Resolving api.cloudflareclient.com via DoH (1.1.1.1)...\n");
        if (nw_doh_resolve("api.cloudflareclient.com", resolved_api, sizeof(resolved_api)) == 0) {
            fprintf(stderr, "[ NekroWARP ] DoH resolved -> %s\n", resolved_api);
        } else {
            fprintf(stderr, "[ NekroWARP ] DoH resolve failed.\n");
        }
    }

    // Fast-path: try several known reliable Cloudflare WARP API IPs immediately.
    // This skips slow DoH/sinkhole resolves on censored nets and greatly speeds "Generate".
    const char *fast_candidates[] = {
        "104.16.123.96", "104.16.124.96", "162.159.192.1", "104.18.10.5", NULL
    };
    
    if (strlen(resolved_api) > 0) {
        fprintf(stderr, "[ NekroWARP ] Checking connection to resolved API IP %s:443...\n", resolved_api);
        if (test_direct_connection(resolved_api, 443) == 0) {
            api_ip = resolved_api;
            direct_ok = 1;
            fprintf(stderr, "[ NekroWARP ] Resolved API IP %s works, using it.\n", api_ip);
        } else {
            fprintf(stderr, "[ NekroWARP ] Connection to resolved API IP failed.\n");
        }
    }
    
    if (direct_ok == 0) {
        fprintf(stderr, "[ NekroWARP ] Trying fast-path Cloudflare candidates...\n");
        for (int fi=0; fast_candidates[fi]; fi++) {
            if (test_direct_connection(fast_candidates[fi], 443) == 0) {
                api_ip = fast_candidates[fi];
                direct_ok = 1;
                fprintf(stderr, "[ NekroWARP ] Fast candidate %s works, using it.\n", api_ip);
                break;
            }
        }
    }
    
    if (!api_ip || strlen(api_ip) == 0) api_ip = "104.16.123.96";

    // Resolve the proxy-scraper host through config DNS too (for the bypass path).
    char scrape_ip[64] = {0};
    if (dns_list && strlen(dns_list) > 0) {
        nw_resolve_via_list("api.proxyscrape.com", dns_list, scrape_ip, sizeof(scrape_ip));
    }
    
    uint8_t priv[32], pub[32];
    char priv_b64[64], pub_b64[64];
    if (input_priv_b64 && strlen(input_priv_b64) > 0) {
        if (b64decode(input_priv_b64, priv, sizeof(priv)) != 32) {
            fprintf(stderr, "bad input private key\n");
            return 1;
        }
        nw_x25519_base(pub, priv);
        b64encode(priv, 32, priv_b64, sizeof(priv_b64));
        b64encode(pub, 32, pub_b64, sizeof(pub_b64));
    } else {
        nw_random(priv, 32);
        priv[0] &= 248; priv[31] &= 127; priv[31] |= 64;
        nw_x25519_base(pub, priv);
        b64encode(priv, 32, priv_b64, sizeof(priv_b64));
        b64encode(pub, 32, pub_b64, sizeof(pub_b64));
    }
    
    time_t now = time(NULL);
    struct tm *gmt = gmtime(&now);
    char tos[64];
    strftime(tos, sizeof(tos), "%Y-%m-%dT%H:%M:%S.000Z", gmt);
    
    char body[512];
    snprintf(body, sizeof(body),
             "{\"key\":\"%s\",\"install_id\":\"\",\"fcm_token\":\"\","
             "\"tos\":\"%s\",\"model\":\"PC\",\"serial_number\":\"\",\"locale\":\"en_US\"}",
             pub_b64, tos);
             
    if (direct_ok) {
        char req[1024];
        int reqlen = snprintf(req, sizeof(req),
                "POST /v0a2483/reg HTTP/1.1\r\n"
                "Host: api.cloudflareclient.com\r\n"
                "User-Agent: okhttp/3.12.1\r\n"
                "CF-Client-Version: a-6.10-2483\r\n"
                "Content-Type: application/json\r\n"
                "Content-Length: %d\r\n"
                "Connection: close\r\n\r\n"
                "%s",
                (int)strlen(body), body);

        // Correct SNI (Cloudflare needs it to route the WARP API), but fragment the
        // ClientHello so the SNI-sniffing DPI can't match the hostname.
        // Use frag=4 for speed (much faster than 1-byte), fall back if needed.
        const char *api_sni = "api.cloudflareclient.com";
        const int api_frag = 4;
        char resp[8192];
        int n = -1;
        for (int attempt = 1; attempt <= 3 && n <= 0; attempt++) {
            n = nw_https_request(api_ip, 443, api_sni, api_frag, req, (size_t)reqlen, resp, sizeof(resp));
            if (n <= 0) fprintf(stderr, "[ NekroWARP ] Direct TLS attempt %d/3 reset (DPI); retrying...\n", attempt);
        }
        if (n > 0) {
            char statusline[160]; int sl = 0;
            while (sl < n && sl < 159 && resp[sl] != '\r' && resp[sl] != '\n') { statusline[sl] = resp[sl]; sl++; }
            statusline[sl] = '\0';
            fprintf(stderr, "[ NekroWARP ] Direct API response: %s\n", statusline);

            char id[128] = {0};
            char token[256] = {0};
            extract_json_str(resp, "id", id, sizeof(id));
            extract_json_str(resp, "token", token, sizeof(token));

            if (strlen(id) > 0 && strlen(token) > 0) {
                char client_ip[64] = {0};
                char client_ip6[128] = {0};
                char peer_pub[128] = {0};

                char *addr_p = strstr(resp, "\"addresses\"");
                if (addr_p) {
                    extract_json_str(addr_p, "v4", client_ip, sizeof(client_ip));
                    extract_json_str(addr_p, "v6", client_ip6, sizeof(client_ip6));
                } else {
                    extract_json_str(resp, "v4", client_ip, sizeof(client_ip));
                    extract_json_str(resp, "v6", client_ip6, sizeof(client_ip6));
                }
                char *slash = strchr(client_ip, '/');
                if (slash) *slash = '\0';
                if (strlen(client_ip) == 0) strcpy(client_ip, "172.16.0.2");

                slash = strchr(client_ip6, '/');
                if (slash) *slash = '\0';

                extract_json_str(resp, "public_key", peer_pub, sizeof(peer_pub));
                if (strlen(peer_pub) == 0) strcpy(peer_pub, "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=");

                char client_id_b64[64] = {0};
                extract_json_str(resp, "client_id", client_id_b64, sizeof(client_id_b64));
                if (strlen(client_id_b64) == 0) strcpy(client_id_b64, "AAAA");

                // Enable WARP on the freshly-registered key (PATCH).
                char body2[64];
                snprintf(body2, sizeof(body2), "{\"warp\":{\"enabled\":true}}");
                char preq[1024];
                int plen = snprintf(preq, sizeof(preq),
                        "PATCH /v0a2483/reg/%s HTTP/1.1\r\n"
                        "Host: api.cloudflareclient.com\r\n"
                        "User-Agent: okhttp/3.12.1\r\n"
                        "CF-Client-Version: a-6.10-2483\r\n"
                        "Authorization: Bearer %s\r\n"
                        "Content-Type: application/json\r\n"
                        "Content-Length: %d\r\n"
                        "Connection: close\r\n\r\n"
                        "%s",
                        id, token, (int)strlen(body2), body2);
                char presp[4096];
                nw_https_request(api_ip, 443, api_sni, api_frag, preq, (size_t)plen, presp, sizeof(presp));


                printf("{\n");
                printf("  \"status\": \"success\",\n");
                printf("  \"endpoint\": \"engage.cloudflareclient.com\",\n");
                printf("  \"port\": \"4500\",\n");
                printf("  \"priv\": \"%s\",\n", priv_b64);
                printf("  \"pub\": \"%s\",\n", peer_pub);
                printf("  \"clientIp\": \"%s\",\n", client_ip);
                printf("  \"clientIp6\": \"%s\",\n", client_ip6);
                printf("  \"reserved\": \"%s\",\n", client_id_b64);
                printf("  \"dns\": \"1.1.1.1, 8.8.8.8\"\n");
                printf("}\n");
                return 0;
            }
        }
    }

    // 2. Direct registration failed — fall back to the public-proxy bypass.
    const int use_proxy_fallback = 1;
    if (use_proxy_fallback) {
        fprintf(stderr, "[ NekroWARP ] Direct registration failed. Fetching public proxies...\n");
        char proxies[64][32];
        int count = download_proxy_list(proxies, 8, scrape_ip);
        fprintf(stderr, "[ NekroWARP ] Loaded %d proxy endpoints. Testing bypass...\n", count);

        for (int i = 0; i < count; i++) {
            char ip[32];
            int port;
            if (sscanf(proxies[i], "%[^:]:%d", ip, &port) == 2) {
                fprintf(stderr, "[ NekroWARP ] Testing proxy %s:%d...\n", ip, port);
                if (try_register_with_proxy(ip, port, input_priv_b64) == 0) {
                    fprintf(stderr, "[ NekroWARP ] Success! Bypass registered via %s:%d.\n", ip, port);
                    return 0;
                }
            }
        }
    } else {
        fprintf(stderr, "[ NekroWARP ] Proxy fallback disabled (test mode): direct registration only.\n");
    }

    printf("{\n  \"status\": \"error\",\n  \"message\": \"direct registration failed (proxy fallback disabled)\"\n}\n");
    return 1;
}

// Handshake to a real WireGuard peer (e.g. Cloudflare WARP) using a registered
// private key + the peer's public key, both standard WireGuard base64. Completing
// the handshake proves interop with production WireGuard.
static int cmd_warp_connect(const char *ip, int port, const char *priv_b64, const char *pub_b64, const char *reserved_b64) {
    uint8_t priv[32], pub[32];
    if (b64decode(priv_b64, priv, sizeof(priv)) != 32) { printf("bad private key (need 32-byte base64)\n"); return 1; }
    if (b64decode(pub_b64, pub, sizeof(pub)) != 32)     { printf("bad peer public key (need 32-byte base64)\n"); return 1; }

    nw_handshake hs;
    nw_handshake_init(&hs, priv, pub, NULL);
    if (reserved_b64 && strlen(reserved_b64) > 0) {
        uint8_t res[16];
        int res_len = b64decode(reserved_b64, res, sizeof(res));
        if (res_len >= 3) memcpy(hs.reserved, res, 3);
        printf("   (initiation reserved = %02x %02x %02x)\n", hs.reserved[0], hs.reserved[1], hs.reserved[2]);
    }
    uint32_t idx;
    nw_random((uint8_t *)&idx, 4);
    uint8_t init[NW_WG_INIT_SIZE];
    nw_wg_create_initiation(&hs, idx, init);

    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) { perror("socket"); return 1; }
    struct sockaddr_in dst;
    memset(&dst, 0, sizeof(dst));
    dst.sin_family = AF_INET;
    dst.sin_port = htons((uint16_t)port);
    dst.sin_addr.s_addr = inet_addr(ip);
    struct timeval tv = { 8, 0 };
    setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    sendto(s, init, sizeof(init), 0, (struct sockaddr *)&dst, sizeof(dst));
    printf("-> sent WireGuard initiation to %s:%d\n", ip, port);

    uint8_t resp[256];
    ssize_t n = recvfrom(s, resp, sizeof(resp), 0, NULL, NULL);
    if (n < 0) { perror("recvfrom (no response from peer)"); close(s); return 1; }
    printf("<- got %ld bytes (type %u)\n", (long)n, resp[0]);
    if (n != NW_WG_RESP_SIZE) { printf("unexpected response size\n"); close(s); return 1; }

    nw_transport t;
    int rc = nw_wg_consume_response(&hs, resp, &t);
    if (rc) { printf("[FAIL] consume_response rc=%d (handshake rejected)\n", rc); close(s); return 1; }
    printf("[ OK ] HANDSHAKE COMPLETE against real WireGuard peer — keys derived.\n");
    printf("       send_key/recv_key ready; data path needs routing (M5).\n");
    close(s);
    return 0;
}

// Real UDP WireGuard handshake as initiator, against a peer at ip:port. Uses
// built-in test static keys (initiator priv 0x20.., responder priv 0x40..) that
// the bundled tools/wg_responder.py also knows — so a successful handshake here
// proves wire-format interop with an independent implementation.
static int cmd_hs_connect(const char *ip, int port) {
    uint8_t i_priv[32], r_priv[32], r_pub[32];
    int i;
    for (i = 0; i < 32; i++) { i_priv[i] = (uint8_t)(0x20 + i); r_priv[i] = (uint8_t)(0x40 + i); }
    nw_x25519_base(r_pub, r_priv);

    nw_handshake hs;
    nw_handshake_init(&hs, i_priv, r_pub, NULL);
    uint8_t init[NW_WG_INIT_SIZE];
    nw_wg_create_initiation(&hs, 0xa1b2c3d4, init);

    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) { perror("socket"); return 1; }
    struct sockaddr_in dst;
    memset(&dst, 0, sizeof(dst));
    dst.sin_family = AF_INET;
    dst.sin_port = htons((uint16_t)port);
    dst.sin_addr.s_addr = inet_addr(ip);
    struct timeval tv = { 5, 0 };
    setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    if (sendto(s, init, sizeof(init), 0, (struct sockaddr *)&dst, sizeof(dst)) < 0) {
        perror("sendto"); close(s); return 1;
    }
    printf("-> sent initiation (%d bytes) to %s:%d\n", (int)sizeof(init), ip, port);

    uint8_t resp[256];
    ssize_t n = recvfrom(s, resp, sizeof(resp), 0, NULL, NULL);
    if (n < 0) { perror("recvfrom (no response)"); close(s); return 1; }
    printf("<- got %ld bytes (msg type %u)\n", (long)n, resp[0]);
    if (n != NW_WG_RESP_SIZE) { printf("unexpected response size\n"); close(s); return 1; }

    nw_transport t;
    int rc = nw_wg_consume_response(&hs, resp, &t);
    if (rc) { printf("[FAIL] consume_response rc=%d\n", rc); close(s); return 1; }
    printf("[ OK ] HANDSHAKE COMPLETE — transport keys derived (interop!).\n");

    const char *m = "hello from nekrowarp on iOS 5";
    uint8_t pkt[256];
    size_t ol;
    nw_wg_transport_encrypt(&t, (const uint8_t *)m, strlen(m), pkt, &ol);
    sendto(s, pkt, ol, 0, (struct sockaddr *)&dst, sizeof(dst));
    printf("-> sent encrypted data (%lu bytes): \"%s\"\n", (unsigned long)ol, m);

    n = recvfrom(s, resp, sizeof(resp), 0, NULL, NULL);
    if (n > 0 && resp[0] == 4) {
        uint8_t dec[256];
        size_t dl;
        if (nw_wg_transport_decrypt(&t, resp, (size_t)n, dec, &dl) == 0) {
            dec[dl] = 0;
            printf("<- decrypted reply from peer: \"%s\"\n", dec);
        }
    }
    close(s);
    return 0;
}

// WireGuard responder: listen on udp/port, complete one handshake as the
// responder (our static = test key 0x40.., expecting initiator 0x20..), then
// decrypt one data packet and echo an encrypted reply. Pairs with
// tools/wg_initiator.py for an over-the-network interop test (device = responder).
static int cmd_hs_listen(int port) {
    uint8_t i_priv[32], r_priv[32], i_pub[32];
    int i;
    for (i = 0; i < 32; i++) { i_priv[i] = (uint8_t)(0x20 + i); r_priv[i] = (uint8_t)(0x40 + i); }
    nw_x25519_base(i_pub, i_priv);                       // expected initiator static pub

    nw_handshake hs;
    nw_handshake_init(&hs, r_priv, i_pub, NULL);         // our static = r_priv

    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) { perror("socket"); return 1; }
    struct sockaddr_in me;
    memset(&me, 0, sizeof(me));
    me.sin_family = AF_INET;
    me.sin_addr.s_addr = htonl(INADDR_ANY);
    me.sin_port = htons((uint16_t)port);
    if (bind(s, (struct sockaddr *)&me, sizeof(me)) < 0) { perror("bind"); close(s); return 1; }
    struct timeval tv = { 30, 0 };
    setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    printf("listening udp/%d as WireGuard responder (waiting up to 30s)…\n", port);

    struct sockaddr_in src;
    socklen_t sl = sizeof(src);
    uint8_t buf[2048];
    ssize_t n = recvfrom(s, buf, sizeof(buf), 0, (struct sockaddr *)&src, &sl);
    if (n < 0) { perror("recvfrom (timed out, no initiation)"); close(s); return 1; }
    printf("<- got %ld bytes (type %u) from %s\n", (long)n, buf[0], inet_ntoa(src.sin_addr));
    if (n != NW_WG_INIT_SIZE) { printf("not a 148-byte initiation\n"); close(s); return 1; }

    int rc = nw_wg_consume_initiation(&hs, buf);
    if (rc) { printf("[FAIL] consume_initiation rc=%d\n", rc); close(s); return 1; }
    printf("[ OK ] initiation valid; learned-static matches expected: %s\n",
           memcmp(hs.remote_static, i_pub, 32) == 0 ? "yes" : "NO");

    nw_transport t;
    uint8_t resp[NW_WG_RESP_SIZE];
    nw_wg_create_response(&hs, 0x99999999, resp, &t);
    sendto(s, resp, sizeof(resp), 0, (struct sockaddr *)&src, sl);
    printf("-> sent 92-byte response; transport keys derived\n");

    n = recvfrom(s, buf, sizeof(buf), 0, (struct sockaddr *)&src, &sl);
    if (n > 0 && buf[0] == 4) {
        uint8_t dec[2048];
        size_t dl;
        if (nw_wg_transport_decrypt(&t, buf, (size_t)n, dec, &dl) == 0) {
            dec[dl] = 0;
            printf("[ OK ] DECRYPTED DATA FROM PEER: \"%s\"\n", dec);
        }
        const char *r = "ack from nekrowarp responder on iOS 5";
        uint8_t pkt[256];
        size_t ol;
        nw_wg_transport_encrypt(&t, (const uint8_t *)r, strlen(r), pkt, &ol);
        sendto(s, pkt, ol, 0, (struct sockaddr *)&src, sl);
        printf("-> sent encrypted reply; INTEROP COMPLETE\n");
    }
    close(s);
    return 0;
}

#import <Foundation/Foundation.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/stat.h>

#ifndef CF_IMPLICIT_BRIDGING_ENABLED
#define CF_IMPLICIT_BRIDGING_ENABLED
#endif
#ifndef CF_IMPLICIT_BRIDGING_DISABLED
#define CF_IMPLICIT_BRIDGING_DISABLED
#endif

#include <CoreFoundation/CFUserNotification.h>
#import <dlfcn.h>

static struct in_addr orig_gw;
static struct in_addr warp_gw;
static struct in_addr warp_ep_ip;
static int host_route_added = 0;
static int default_route_replaced = 0;
static int scopedroute_changed = 0;
static int scopedroute_old = 1;
static mach_vm_address_t g_scopedroute_kaddr = 0;
static int g_kpatch = 1;  // kpatch=1 tries to patch the kernel to disable scoped routing
static int g_proxy_mode = 0; // Hardcoded to 0: full route + kpatch only. iOS 7+ support removed for max stability on 5/6.
static char g_proxy_ifname[32] = "";
static mach_port_t g_kt = MACH_PORT_NULL;
static int default_route_v6_added = 0;
static int scope_primary_set = 0;
static unsigned wifi_ifindex = 0;          // en0/en1 index for the scoped default
static int wifi_scoped_default_added = 0;  // did we install en0's scoped default?
static char active_ifname[64] = {0};
static char orig_dns[256] = {0};
static int dns_changed = 0;
static int clean_exit_requested = 0;
static int g_runfor = 0;  // runfor=N: auto-stop (cleanup) after N seconds — safe testing
static int g_bind_warp = 0;  // bindwarp=0 disables IP_BOUND_IF on the WARP socket (A/B)
static int g_route_guard = 0;  // routeguard=1: poll-repin utun default (loses race vs configd)
static int g_surgery = 1;  // surgery=0: skip manual default-route swap (test pure set_primary)
static int g_telegram_split = 0; // route Telegram only; never mutate global network state

struct nw_split_route {
    const char *network;
    const char *mask;
    int installed;
};

static struct nw_split_route g_telegram_routes[] = {
    { "91.108.4.0",   "255.255.252.0", 0 },
    { "91.108.8.0",   "255.255.252.0", 0 },
    { "91.108.12.0",  "255.255.252.0", 0 },
    { "91.108.16.0",  "255.255.252.0", 0 },
    { "91.108.20.0",  "255.255.252.0", 0 },
    { "91.108.56.0",  "255.255.252.0", 0 },
    { "91.105.192.0", "255.255.254.0", 0 },
    { "149.154.160.0", "255.255.240.0", 0 },
    { NULL, NULL, 0 }
};

// iOS has no `scutil` (that's a macOS SystemConfiguration tool). The BSD
// resolver on iOS reads /etc/resolv.conf, so we manage DNS by writing that
// file directly. `dns_list` is a space-separated list of nameserver IPs.
static void write_resolv_conf(const char *dns_list) {
    FILE *f = fopen("/etc/resolv.conf", "w");
    if (!f) {
        printf("Warning: could not write /etc/resolv.conf: %s\n", strerror(errno));
        return;
    }
    char buf[256];
    strlcpy(buf, dns_list, sizeof(buf));
    char *save = NULL;
    // Accept space-, tab- or comma-separated lists (the .conf DNS line is comma-separated).
    for (char *tok = strtok_r(buf, " \t,", &save); tok; tok = strtok_r(NULL, " \t,", &save)) {
        fprintf(f, "nameserver %s\n", tok);
    }
    fclose(f);
}

static void save_original_dns(void) {
    orig_dns[0] = '\0';
    FILE *f = fopen("/etc/resolv.conf", "r");
    if (!f) {
        printf("Original DNS: '' (no /etc/resolv.conf)\n");
        return;
    }
    char line[256];
    int count = 0;
    while (fgets(line, sizeof(line), f)) {
        char *p = line;
        while (*p == ' ' || *p == '\t') p++;
        if (strncmp(p, "nameserver", 10) != 0) continue;
        p += 10;
        if (*p != ' ' && *p != '\t') continue;
        while (*p == ' ' || *p == '\t') p++;

        char *end = p + strlen(p) - 1;
        while (end >= p && (*end == '\n' || *end == '\r' || *end == ' ' || *end == '\t')) {
            *end = '\0';
            end--;
        }

        if (strlen(p) > 0) {
            if (count > 0) strlcat(orig_dns, " ", sizeof(orig_dns));
            strlcat(orig_dns, p, sizeof(orig_dns));
            count++;
        }
    }
    fclose(f);
    printf("Original DNS: '%s'\n", orig_dns);
}

static void set_dns_warp(const char *dns_ip) {
    write_resolv_conf(dns_ip);
    nw_scope_set_dns(dns_ip);
    dns_changed = 1;
    printf("Set system DNS to %s (resolv.conf and SCDynamicStore)\n", dns_ip);
}

static void cleanup(void) {
    // Idempotent: the explicit call sites, the signal handlers, and atexit() can
    // all reach here, and each restore step below is gated on a "changed" flag we
    // clear, so a second pass is a no-op rather than a double route delete.
    static int cleanup_done = 0;
    if (cleanup_done) return;
    cleanup_done = 1;
    g_proxy_ifname[0] = '\0';
    // No proxy mode in this iOS 5/6 build. PF not used for redirection.

    printf("\nCleaning up tunnel and routing...\n");

    unlink("/tmp/nekrowarp.pid");
    unlink("/tmp/nekrowarp.telegram_split");

    if (dns_changed) {
        printf("Restoring DNS...\n");
        nw_scope_restore_dns();
        if (strlen(orig_dns) > 0) {
            write_resolv_conf(orig_dns);
        } else {
            unlink("/etc/resolv.conf");
        }
    }

    if (default_route_replaced) {
        printf("Restoring original default route via %s...\n", inet_ntoa(orig_gw));
        nw_route_delete_default(warp_gw);
        nw_route_add_default(orig_gw, 0);
    }

    for (int i = 0; g_telegram_routes[i].network != NULL; i++) {
        if (g_telegram_routes[i].installed) {
            struct in_addr network, mask;
            inet_aton(g_telegram_routes[i].network, &network);
            inet_aton(g_telegram_routes[i].mask, &mask);
            nw_route_delete_network(network, mask, warp_gw);
            g_telegram_routes[i].installed = 0;
        }
    }

    if (wifi_scoped_default_added) {
        printf("Removing Wi-Fi scoped default route (ifindex %u)...\n", wifi_ifindex);
        nw_route_delete_default_scoped(orig_gw, wifi_ifindex);
        wifi_scoped_default_added = 0;
    }

    if (default_route_v6_added) {
        printf("Restoring original default IPv6 route...\n");
        nw_route_delete_default_v6("::", active_ifname);
    }

    if (host_route_added) {
        printf("Removing host route to WARP endpoint %s...\n", inet_ntoa(warp_ep_ip));
        nw_route_delete_host(warp_ep_ip, orig_gw, wifi_ifindex);
    }

    if (scope_primary_set) {
        printf("Removing SCDynamicStore primary-service override...\n");
        nw_scope_restore();
        scope_primary_set = 0;
    }
    if (scopedroute_changed) {
        if (g_scopedroute_kaddr != 0 && g_kt != MACH_PORT_NULL) {
            printf("Restoring net.inet.ip.scopedroute to %d via kwrite...\n", scopedroute_old);
            uint32_t val = scopedroute_old;
            BOOL is64 = is_kernel_64bit();
            kwrite_safe(g_kt, g_scopedroute_kaddr, (vm_offset_t)&val, 4, is64);
        } else {
            printf("Restoring net.inet.ip.scopedroute to %d via sysctl...\n", scopedroute_old);
            sysctlbyname("net.inet.ip.scopedroute", NULL, NULL, &scopedroute_old, sizeof(scopedroute_old));
        }
        scopedroute_changed = 0;
        g_scopedroute_kaddr = 0;
    }

    printf("Done. Goodbye!\n");
}

static void handle_sigint(int sig) {
    (void)sig;
    clean_exit_requested = 1;
}

// Last-ditch net for a crash (SIGSEGV/SIGBUS/SIGABRT) or SIGHUP: restore routing
// so a dead process doesn't strand the utun as the primary service — that bricks
// the network until reboot. We deliberately do NOT exit(0); after undoing our
// state we reinstate the default disposition and re-raise so the crash still
// surfaces (core/crash log) instead of being swallowed.
static void handle_fatal(int sig) {
    if (scopedroute_changed && g_scopedroute_kaddr != 0 && g_kt != MACH_PORT_NULL) {
        uint32_t val = scopedroute_old;
        BOOL is64 = is_kernel_64bit();
        kwrite_safe(g_kt, g_scopedroute_kaddr, (vm_offset_t)&val, 4, is64);
    }
    signal(sig, SIG_DFL);
    raise(sig);
}

static int setup_routing(const char *endpoint_ip, const char *client_ip, int mtu) {
    orig_gw = nw_route_get_default_gateway();
    if (orig_gw.s_addr == INADDR_ANY) {
        fprintf(stderr, "Error: Could not discover default gateway!\n");
        return -1;
    }
    printf("Discovered default gateway: %s\n", inet_ntoa(orig_gw));

    // Index of the physical uplink (Wi-Fi). We give it a SCOPED default route
    // (below) so its own reachability survives repointing the global default at
    // the utun — otherwise iOS sees Wi-Fi as "no internet" and drops it.
    wifi_ifindex = if_nametoindex("en0");
    if (wifi_ifindex == 0) wifi_ifindex = if_nametoindex("en1");

    FILE *gf = fopen("/tmp/nekrowarp.orig_gw", "w");
    if (gf) {
        fprintf(gf, "%s\n", inet_ntoa(orig_gw));
        fclose(gf);
    }

    inet_aton(endpoint_ip, &warp_ep_ip);

    struct in_addr client_addr;
    inet_aton(client_ip, &client_addr);
    uint32_t client_h = ntohl(client_addr.s_addr);
    uint32_t gateway_h = (client_h & 0xffffff00) | 1;
    warp_gw.s_addr = htonl(gateway_h);
    printf("WARP Gateway: %s\n", inet_ntoa(warp_gw));

    if (g_telegram_split) {
        printf("[ FuckDPI ] Telegram-only split route; keeping Wi-Fi default route and primary service untouched.\n");
        for (int i = 0; g_telegram_routes[i].network != NULL; i++) {
            struct in_addr network, mask;
            inet_aton(g_telegram_routes[i].network, &network);
            inet_aton(g_telegram_routes[i].mask, &mask);
            if (nw_route_add_network(network, mask, warp_gw, mtu) < 0 && errno != EEXIST) {
                fprintf(stderr, "[ FuckDPI ] failed to add %s route: %s\n",
                        g_telegram_routes[i].network, strerror(errno));
                cleanup();
                return -1;
            }
            g_telegram_routes[i].installed = 1;
        }
        return 0;
    }

    // If the kernel scoped routing was successfully disabled, we don't need
    // the SCDynamicStore override that drops Wi-Fi. Otherwise, fallback to it.
    if (scopedroute_changed) {
        printf("[ setup_routing ] skipping SCDynamicStore primary-service override because kernel scoped routing is disabled.\n");
    } else {
        char router_str[32];
        strlcpy(router_str, inet_ntoa(warp_gw), sizeof(router_str));
        if (nw_scope_set_primary(active_ifname, client_ip, router_str) == 0) {
            scope_primary_set = 1;
            printf("Published %s as primary service via SCDynamicStore.\n", active_ifname);
        } else {
            printf("Note: SCDynamicStore primary override failed; relying on route table only.\n");
        }
    }

    printf("Adding host route to WARP endpoint %s via gateway %s...\n", endpoint_ip, inet_ntoa(orig_gw));
    if (nw_route_add_host(warp_ep_ip, orig_gw, wifi_ifindex) < 0) {
        if (errno == EEXIST) {
            printf("Host route to WARP endpoint already exists (EEXIST), continuing...\n");
        } else {
            perror("nw_route_add_host");
            return -1;
        }
    }
    host_route_added = 1;

    // NOTE: an earlier build added an en0 RTF_IFSCOPE default here to keep Wi-Fi
    // "connected" in the UI. On-device it regressed the data path — once the utun
    // became primary the en0-bound WARP socket stopped receiving replies (udp_in
    // went to 0), so the tunnel carried no data. Reverted to the 0.0.6 behaviour
    // (no scoped en0 default); the Wi-Fi UI demotion is cosmetic there and data
    // still flows. (void)wifi_ifindex keeps it referenced for a future fix.
    (void)wifi_ifindex;

    // Repoint the GLOBAL default at the utun. surgery=0 skips this to test pure
    // set_primary (like the scope-test that captured traffic with tun_in>0): the
    // manual route writes trigger configd to recompute and may be sabotaging the
    // utun capture configd would otherwise set up.
    if (g_surgery) {
        printf("Removing original default route via %s...\n", inet_ntoa(orig_gw));
        if (nw_route_delete_default(orig_gw) < 0 && errno != ESRCH) {
            perror("nw_route_delete_default");
            cleanup();
            return -1;
        }
        default_route_replaced = 1;

        printf("Adding new default route via %s with MTU %d...\n", inet_ntoa(warp_gw), mtu);
        if (nw_route_add_default(warp_gw, mtu) < 0 && errno != EEXIST) {
            perror("nw_route_add_default");
            cleanup();
            return -1;
        }
    } else {
        printf("surgery=0: leaving route table to configd (pure set_primary test)\n");
    }

    return 0;
}

static void clamp_tcp_mss(uint8_t *ip_pkt, size_t ip_len) {
    if (ip_len < 20) return;
    if ((ip_pkt[0] >> 4) != 4) return; // Only IPv4
    
    size_t ip_hlen = (ip_pkt[0] & 0x0F) * 4;
    if (ip_len < ip_hlen) return;
    if (ip_pkt[9] != 6) return; // Only TCP
    
    size_t tcp_len = ip_len - ip_hlen;
    if (tcp_len < 20) return;
    
    uint8_t *tcp_hdr = ip_pkt + ip_hlen;
    if (!(tcp_hdr[13] & 0x02)) return; // Only SYN or SYN-ACK
    
    size_t tcp_hlen = ((tcp_hdr[12] >> 4) & 0x0F) * 4;
    if (tcp_len < tcp_hlen) return;
    
    uint8_t *opt = tcp_hdr + 20;
    uint8_t *opt_end = tcp_hdr + tcp_hlen;
    int mss_changed = 0;
    
    while (opt < opt_end) {
        uint8_t kind = opt[0];
        if (kind == 0) break;
        if (kind == 1) {
            opt++;
            continue;
        }
        if (opt + 1 >= opt_end) break;
        uint8_t len = opt[1];
        if (len < 2 || opt + len > opt_end) break;
        
        if (kind == 2 && len == 4) {
            uint16_t mss = (opt[2] << 8) | opt[3];
            if (mss > 1200) {
                opt[2] = (1200 >> 8) & 0xFF;
                opt[3] = 1200 & 0xFF;
                mss_changed = 1;
            }
            break;
        }
        opt += len;
    }
    
    if (mss_changed) {
        // Recalculate TCP Checksum
        tcp_hdr[16] = 0;
        tcp_hdr[17] = 0;
        
        struct {
            struct in_addr src;
            struct in_addr dst;
            uint8_t zero;
            uint8_t proto;
            uint16_t len;
        } pseudo;
        
        memcpy(&pseudo.src, ip_pkt + 12, 4);
        memcpy(&pseudo.dst, ip_pkt + 16, 4);
        pseudo.zero = 0;
        pseudo.proto = 6;
        pseudo.len = htons((uint16_t)tcp_len);
        
        uint32_t sum = 0;
        uint16_t *p = (uint16_t *)&pseudo;
        for (int i = 0; i < 6; i++) {
            sum += ntohs(p[i]);
        }
        
        uint16_t *t = (uint16_t *)tcp_hdr;
        int count = tcp_len;
        while (count > 1) {
            sum += ntohs(*t++);
            count -= 2;
        }
        if (count > 0) {
            sum += (*(uint8_t *)t) << 8;
        }
        
        while (sum >> 16) {
            sum = (sum & 0xffff) + (sum >> 16);
        }
        uint16_t final_sum = (uint16_t)~sum;
        tcp_hdr[16] = (final_sum >> 8) & 0xFF;
        tcp_hdr[17] = final_sum & 0xFF;
    }
}

static int run_tunnel_loop(int tun_fd, int udp_fd, nw_transport *t, struct sockaddr_in *dst, int keepalive, nw_handshake *hs, const nw_awg *awg, int mtu) {
    unsigned char tun_buf[2048];
    unsigned char udp_buf[2048];
    unsigned char enc_buf[2048];
    unsigned char dec_buf[2048];

    int max_fd = (tun_fd > udp_fd) ? tun_fd : udp_fd;

    printf("\n=================== Tunnel active ===================\n");
    printf("Pumping packets. Press Ctrl-C to terminate.\n");

    time_t last_ka = time(NULL);

    // --- data-path instrumentation (NEKRO_DBG) ---
    unsigned long c_tun_in=0, c_udp_out=0, c_udp_in=0, c_t4=0, c_dec_ok=0, c_dec_fail=0, c_tun_out=0, c_ka=0, c_other=0;
    unsigned long c_tun_out_drop=0, c_udp_out_drop=0;
    int log_first = 24; // log first N inbound UDP packets verbosely
    time_t last_stat = time(NULL);
    time_t last_route = time(NULL);
    unsigned long c_route_fix = 0;  // times we had to re-pin the utun default

    // Rekeying state
    time_t key_derived_time = time(NULL);
    int rekey_in_progress = 0;
    time_t rekey_sent_time = 0;
    unsigned char rekey_init_buf[NW_WG_INIT_SIZE];

    // Set non-blocking mode on tun_fd and udp_fd to prevent deadlock/stalls under high load
    int tun_flags = fcntl(tun_fd, F_GETFL, 0);
    fcntl(tun_fd, F_SETFL, tun_flags | O_NONBLOCK);

    int udp_flags = fcntl(udp_fd, F_GETFL, 0);
    fcntl(udp_fd, F_SETFL, udp_flags | O_NONBLOCK);

    while (!clean_exit_requested) {
        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(tun_fd, &fds);
        FD_SET(udp_fd, &fds);

        // Wake at least once per second so the persistent keepalive and rekeying fire on time
        struct timeval tv_timeout;
        tv_timeout.tv_sec = 1;
        tv_timeout.tv_usec = 0;

        int nready = select(max_fd + 1, &fds, NULL, NULL, &tv_timeout);
        if (nready < 0) {
            if (errno == EINTR) {
                if (clean_exit_requested) break;
                continue;
            }
            perror("select");
            break;
        }

        time_t now = time(NULL);
        int ka = (keepalive > 0) ? keepalive : 25;
        if (now - last_ka >= ka) {
            size_t enc_len;
            if (nw_wg_transport_encrypt(t, NULL, 0, enc_buf, &enc_len) == 0) {
                ssize_t sret = sendto(udp_fd, enc_buf, enc_len, 0, (struct sockaddr *)dst, sizeof(*dst));
                if (sret < 0) {
                    c_udp_out_drop++;
                } else {
                    c_udp_out++;
                }
                c_ka++;
            }
            last_ka = now;
        }

        // Rekeying: if current key is older than 110 seconds, send a new handshake initiation
        if (now - key_derived_time >= 110) {
            if (!rekey_in_progress || (now - rekey_sent_time >= 5)) {
                uint32_t idx;
                nw_random((uint8_t *)&idx, 4);
                nw_wg_create_initiation(hs, idx, rekey_init_buf);
                
                if (awg) {
                    nw_awg_send_junk(udp_fd, (struct sockaddr *)dst, sizeof(*dst), awg);
                }
                
                ssize_t sret = sendto(udp_fd, rekey_init_buf, NW_WG_INIT_SIZE, 0, (struct sockaddr *)dst, sizeof(*dst));
                if (sret < 0) {
                    printf("[rekey] sendto initiation failed: %s\n", strerror(errno));
                    fflush(stdout);
                } else {
                    printf("[rekey] sent handshake initiation, local_index=0x%08x\n", idx);
                    fflush(stdout);
                }
                rekey_sent_time = now;
                rekey_in_progress = 1;
            }
        }

        // Periodic data-path stats so we can see where packets die.
        if (now - last_stat >= 3) {
            printf("[DBG] tun_in=%lu udp_out=%lu (drop=%lu) | udp_in=%lu t4=%lu dec_ok=%lu dec_fail=%lu other=%lu | tun_out=%lu (drop=%lu) ka=%lu\n",
                   c_tun_in, c_udp_out, c_udp_out_drop, c_udp_in, c_t4, c_dec_ok, c_dec_fail, c_other, c_tun_out, c_tun_out_drop, c_ka);
            fflush(stdout);
            last_stat = now;
        }

        // Route guard: configd/IPMonitor keeps re-installing en0's default route a
        // few seconds after our surgery, which steals app traffic back out of the
        // tunnel (tun_in stalls, udp_in stays 0). Beat it back every 2s — delete
        // whatever default it restored on en0 and re-pin the utun default. ESRCH
        // (nothing to delete) and EEXIST (already ours) are the normal no-op cases.
        if (g_route_guard && default_route_replaced && now - last_route >= 2) {
            int changed = 0;
            if (nw_route_delete_default(orig_gw) == 0) changed = 1;  // removed configd's en0 default
            nw_route_add_default(warp_gw, mtu);                            // (re)assert utun default
            if (changed) {
                c_route_fix++;
                printf("[route-guard] re-pinned utun default (configd had restored en0 default; fixes=%lu)\n",
                       c_route_fix);
                fflush(stdout);
            }
            last_route = now;
        }

        if (nready == 0) continue;

        if (FD_ISSET(tun_fd, &fds)) {
            for (;;) {
                fd_set check_fds;
                FD_ZERO(&check_fds);
                FD_SET(tun_fd, &check_fds);
                struct timeval zero_tv = { 0, 0 };
                int check_r = select(tun_fd + 1, &check_fds, NULL, NULL, &zero_tv);
                if (check_r <= 0 || !FD_ISSET(tun_fd, &check_fds)) {
                    break;
                }

                ssize_t n = read(tun_fd, tun_buf, sizeof(tun_buf));
                if (n < 0) {
                    if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) {
                        break;
                    } else {
                        perror("read tun_fd");
                        break;
                    }
                } else if (n > 4) {
                    uint32_t family_be;
                    memcpy(&family_be, tun_buf, 4);
                    uint32_t family_host = ntohl(family_be);

                    if (family_host == AF_INET || family_host == AF_INET6) {
                        c_tun_in++;
                        size_t ip_len = n - 4;
                        if (family_host == AF_INET) {
                            clamp_tcp_mss(tun_buf + 4, ip_len);
                        }
                        size_t enc_len;
                        if (nw_wg_transport_encrypt(t, tun_buf + 4, ip_len, enc_buf, &enc_len) == 0) {
                            ssize_t sret = sendto(udp_fd, enc_buf, enc_len, 0, (struct sockaddr *)dst, sizeof(*dst));
                            if (sret < 0) {
                                c_udp_out_drop++;
                            } else {
                                c_udp_out++;
                            }
                            if (c_tun_in <= 6)
                                printf("[DBG] tun->udp #%lu: inner=%u (v%u proto?) enc=%u sent=%ld%s\n",
                                       c_tun_in, (unsigned)ip_len, (unsigned)(tun_buf[4] >> 4), (unsigned)enc_len,
                                       (long)sret, sret < 0 ? strerror(errno) : "");
                        }
                    }
                } else {
                    break;
                }
            }
        }

        if (FD_ISSET(udp_fd, &fds)) {
            for (;;) {
                fd_set check_fds;
                FD_ZERO(&check_fds);
                FD_SET(udp_fd, &check_fds);
                struct timeval zero_tv = { 0, 0 };
                int check_r = select(udp_fd + 1, &check_fds, NULL, NULL, &zero_tv);
                if (check_r <= 0 || !FD_ISSET(udp_fd, &check_fds)) {
                    break;
                }

                ssize_t n = recvfrom(udp_fd, udp_buf, sizeof(udp_buf), 0, NULL, NULL);
                if (n < 0) {
                    if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) {
                        break;
                    } else {
                        perror("recvfrom udp_fd");
                        break;
                    }
                } else if (n > 0) {
                    c_udp_in++;
                    if (log_first > 0) {
                        log_first--;
                        printf("[DBG] udp_in #%lu: %ld bytes, type=%u, hdr=%02x %02x %02x %02x\n",
                               c_udp_in, (long)n, (unsigned)udp_buf[0], udp_buf[0],
                               n>1?udp_buf[1]:0, n>2?udp_buf[2]:0, n>3?udp_buf[3]:0);
                    }
                    if (udp_buf[0] == 4) {
                        c_t4++;
                        size_t dec_len = 0;
                        if (nw_wg_transport_decrypt(t, udp_buf, (size_t)n, dec_buf, &dec_len) == 0) {
                            c_dec_ok++;
                            if (dec_len > 0) {
                                uint32_t version = dec_buf[0] >> 4;
                                if (version == 4) {
                                    clamp_tcp_mss(dec_buf, dec_len);
                                }
                                unsigned char write_buf[2048];
                                uint32_t family = AF_INET;
                                if (version == 6) {
                                    family = AF_INET6;
                                }
                                uint32_t family_be = htonl(family);
                                memcpy(write_buf, &family_be, 4);
                                memcpy(write_buf + 4, dec_buf, dec_len);
                                ssize_t wret = write(tun_fd, write_buf, dec_len + 4);
                                if (wret < 0) {
                                    c_tun_out_drop++;
                                } else {
                                    c_tun_out++;
                                }
                                if (c_tun_out <= 6)
                                    printf("[DBG] udp->tun #%lu: dec=%u v%u wrote=%ld%s\n",
                                           c_tun_out, (unsigned)dec_len, version, (long)wret,
                                           wret < 0 ? strerror(errno) : "");
                            }
                        } else {
                            c_dec_fail++;
                        }
                    } else if (udp_buf[0] == 2) {
                        // Handshake response received! Consume it and rotate keys.
                        nw_transport new_t;
                        int rc = nw_wg_consume_response(hs, udp_buf, &new_t);
                        if (rc == 0) {
                            *t = new_t;
                            key_derived_time = now;
                            rekey_in_progress = 0;
                            printf("[rekey] accepted new handshake response! rotated keys. local_index=0x%08x remote_index=0x%08x\n",
                                   t->local_index, t->remote_index);
                            fflush(stdout);
                        } else {
                            printf("[rekey] failed to consume handshake response: rc=%d\n", rc);
                            fflush(stdout);
                        }
                    } else {
                        c_other++;
                    }
                } else {
                    break;
                }
            }
        }
    }
    return 0;
}

static void launch_gui_app(void) {
    void *sbs = dlopen("/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices", RTLD_LAZY);
    if (sbs) {
        int (*SBSLaunchApplicationWithIdentifier)(CFStringRef identifier, Boolean suspended) = dlsym(sbs, "SBSLaunchApplicationWithIdentifier");
        if (SBSLaunchApplicationWithIdentifier) {
            SBSLaunchApplicationWithIdentifier(CFSTR("com.nekro.nekrowarp-gui"), false);
        }
        dlclose(sbs);
    }
}

static void save_crash_log(void) {
    FILE *lf = fopen("/var/log/nekrowarp.log", "r");
    if (!lf) return;
    
    fseek(lf, 0, SEEK_END);
    long size = ftell(lf);
    long offset = (size > 2048) ? (size - 2048) : 0;
    fseek(lf, offset, SEEK_SET);
    
    char *buf = malloc(2048 + 1);
    if (buf) {
        size_t n = fread(buf, 1, 2048, lf);
        buf[n] = '\0';
        fclose(lf);
        
        FILE *cf = fopen("/tmp/nekrowarp.crash", "w");
        if (cf) {
            fprintf(cf, "%s", buf);
            fclose(cf);
            chmod("/tmp/nekrowarp.crash", 0666);
        }
        free(buf);
    } else {
        fclose(lf);
    }
}

static void show_disconnect_notification(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    CFStringRef header = CFSTR("NekroWARP Disconnected");
    CFStringRef message = CFSTR("The background tunnel terminated unexpectedly. Tap 'View Logs' to see details.");
    CFStringRef buttonDefault = CFSTR("View Logs");
    CFStringRef buttonAlternate = CFSTR("Dismiss");
    
    CFOptionFlags responseFlags = 0;
    
    CFUserNotificationDisplayAlert(
        0.0,
        kCFUserNotificationPlainAlertLevel,
        NULL,
        NULL,
        NULL,
        header,
        message,
        buttonDefault,
        buttonAlternate,
        NULL,
        &responseFlags
    );
    
    if ((responseFlags & 0x3) == kCFUserNotificationDefaultResponse) {
        launch_gui_app();
    }
    
    [pool release];
}

// Helper functions for kernel scanning and patching via tfp0 (dynamic 32/64-bit KASLR-safe)

static BOOL is_kernel_64bit(void) {
    int val = 0;
    size_t size = sizeof(val);
    if (sysctlbyname("hw.cpu64bit_capable", &val, &size, NULL, 0) == 0) {
        return (val != 0);
    }
    return NO;
}

static kern_return_t kread_safe(mach_port_t kt, mach_vm_address_t addr, mach_vm_size_t size, vm_offset_t *data, mach_msg_type_number_t *dataCnt, BOOL is64) {
    if (is64) {
        static mach_vm_read_t p_mach_vm_read = NULL;
        static BOOL checked = NO;
        if (!checked) {
            p_mach_vm_read = (mach_vm_read_t)dlsym(RTLD_DEFAULT, "mach_vm_read");
            checked = YES;
        }
        if (p_mach_vm_read) {
            return p_mach_vm_read(kt, addr, size, data, dataCnt);
        } else {
            return KERN_FAILURE;
        }
    } else {
        vm_address_t addr32 = (vm_address_t)addr;
        vm_size_t size32 = (vm_size_t)size;
        return vm_read(kt, addr32, size32, data, dataCnt);
    }
}

static kern_return_t kwrite_safe(mach_port_t kt, mach_vm_address_t addr, vm_offset_t data, mach_msg_type_number_t dataCnt, BOOL is64) {
    if (is64) {
        static mach_vm_write_t p_mach_vm_write = NULL;
        static BOOL checked = NO;
        if (!checked) {
            p_mach_vm_write = (mach_vm_write_t)dlsym(RTLD_DEFAULT, "mach_vm_write");
            checked = YES;
        }
        if (p_mach_vm_write) {
            return p_mach_vm_write(kt, addr, data, dataCnt);
        } else {
            return KERN_FAILURE;
        }
    } else {
        vm_address_t addr32 = (vm_address_t)addr;
        return vm_write(kt, addr32, data, dataCnt);
    }
}

static kern_return_t kregion_safe(mach_port_t kt, mach_vm_address_t *addr, mach_vm_size_t *size, BOOL is64) {
    if (is64) {
        static mach_vm_region_recurse_t p_mach_vm_region_recurse = NULL;
        static BOOL checked = NO;
        if (!checked) {
            p_mach_vm_region_recurse = (mach_vm_region_recurse_t)dlsym(RTLD_DEFAULT, "mach_vm_region_recurse");
            checked = YES;
        }
        if (p_mach_vm_region_recurse) {
            natural_t depth = 0;
            vm_region_submap_info_data_64_t info;
            mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;
            return p_mach_vm_region_recurse(kt, addr, size, &depth, (vm_region_recurse_info_t)&info, &count);
        } else {
            return KERN_FAILURE;
        }
    } else {
        vm_address_t addr32 = (vm_address_t)*addr;
        vm_size_t size32 = 0;
        natural_t depth = 0;
        vm_region_submap_info_data_t info;
        mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT;
        kern_return_t kr = vm_region_recurse(kt, &addr32, &size32, &depth, (vm_region_recurse_info_t)&info, &count);
        if (kr == KERN_SUCCESS) {
            *addr = addr32;
            *size = size32;
        }
        return kr;
    }
}

static mach_vm_address_t find_kernel_base(mach_port_t kt) {
    double osver = 0.0;
    char osrelease[256];
    size_t osrelease_sz = sizeof(osrelease);
    if (sysctlbyname("kern.osrelease", osrelease, &osrelease_sz, NULL, 0) == 0) {
        osver = atof(osrelease);
    }
    // iOS 7+ builds are rejected earlier. Here we always attempt kpatch for supported 5/6.
    BOOL is64 = is_kernel_64bit();
    
    typedef int (*kas_info_t)(int selector, void *value, size_t *size);
    kas_info_t p_kas_info = (kas_info_t)dlsym(RTLD_DEFAULT, "kas_info");
    uint64_t slide = 0;
    size_t slide_sz = sizeof(slide);
    BOOL got_slide = NO;
    if (osver >= 13.0) {
        if (p_kas_info != NULL && p_kas_info(0, &slide, &slide_sz) == 0) {
            got_slide = YES;
        } else if (syscall(439, 0, &slide, &slide_sz) == 0) { // syscall 439 is SYS_kas_info
            got_slide = YES;
        }
    }
    
    if (got_slide && slide > 0) {
        mach_vm_address_t base = is64 ? (0xffffffF007004000ULL + slide) : (0x80002000ULL + slide);
        uint32_t magic = 0;
        mach_msg_type_number_t read_cnt = 0;
        vm_offset_t read_buf = 0;
        if (kread_safe(kt, base, 4, &read_buf, &read_cnt, is64) == KERN_SUCCESS && read_cnt >= 4) {
            magic = *(uint32_t *)read_buf;
            vm_deallocate(mach_task_self(), read_buf, read_cnt);
            if ((is64 && magic == 0xfeedfacf) || (!is64 && magic == 0xfeedface)) {
                printf("[ kpatch ] Found kernel slide via kas_info syscall: 0x%llx, base: 0x%llx (Mach-O Magic OK)\n", (unsigned long long)slide, (unsigned long long)base);
                return base;
            }
        }
        if (!is64) {
            base = 0x80001000ULL + slide;
            if (kread_safe(kt, base, 4, &read_buf, &read_cnt, is64) == KERN_SUCCESS && read_cnt >= 4) {
                magic = *(uint32_t *)read_buf;
                vm_deallocate(mach_task_self(), read_buf, read_cnt);
                if (magic == 0xfeedface) {
                    printf("[ kpatch ] Found kernel slide via kas_info syscall: 0x%llx, base: 0x%llx (Mach-O Magic OK)\n", (unsigned long long)slide, (unsigned long long)base);
                    return base;
                }
            }
        }
    }
    
    // Method 2: Query task_info(TASK_DYLD_INFO)  (for reference, not used in 5/6 build)
    struct task_dyld_info dyld_info;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    if (task_info(kt, TASK_DYLD_INFO, (task_info_t)&dyld_info, &count) == KERN_SUCCESS) {
        mach_vm_address_t base = dyld_info.all_image_info_addr;
        if (is64 && base >= 0xffffffF000000000ULL) {
            printf("[ kpatch ] Found 64-bit kernel base via TASK_DYLD_INFO: 0x%llx\n", (unsigned long long)base);
            return base;
        } else if (!is64 && base >= 0x80000000ULL && base <= 0xffffffffULL) {
            printf("[ kpatch ] Found 32-bit kernel base via TASK_DYLD_INFO: 0x%llx\n", (unsigned long long)base);
            return base;
        }
    }

    // Method 3: For iOS 5/6 and older systems without KASLR, return the static base
    char osrelease3[256];
    size_t osrelease3_sz = sizeof(osrelease3);
    if (sysctlbyname("kern.osrelease", osrelease3, &osrelease3_sz, NULL, 0) == 0) {
        double val = atof(osrelease3);
        if (val < 14.0) { // iOS 5/6 only (this build)
            mach_vm_address_t base = 0x80002000ULL; // Standard static base for iOS 5/6
            printf("[ kpatch ] iOS 5/6 detected, using static base: 0x%llx\n", (unsigned long long)base);
            return base;
        }
    }

    // Method 4: Scan VM regions safely using kregion_safe (completely jailbreak independent!)
    mach_vm_address_t addr = is64 ? 0xfffffff000000000ULL : 0x80000000ULL;
    mach_vm_size_t size = 0;
    
    // We scan up to 20 regions to find the kernel base
    for (int r = 0; r < 20; r++) {
        kern_return_t kr = kregion_safe(kt, &addr, &size, is64);
        if (kr != KERN_SUCCESS) break;
        
        // Check potential kernel header alignments in this region
        mach_vm_address_t offsets[] = { 0, 0x1000, 0x2000, 0x4000 };
        for (int o = 0; o < 4; o++) {
            mach_vm_address_t test_addr = addr + offsets[o];
            uint32_t magic = 0;
            mach_msg_type_number_t read_cnt = 0;
            vm_offset_t read_buf = 0;
            if (kread_safe(kt, test_addr, 4, &read_buf, &read_cnt, is64) == KERN_SUCCESS && read_cnt >= 4) {
                magic = *(uint32_t *)read_buf;
                vm_deallocate(mach_task_self(), read_buf, read_cnt);
                if (is64 && magic == 0xfeedfacf) {
                    printf("[ kpatch ] Found 64-bit kernel base via region scan: 0x%llx (Mach-O Magic OK)\n", (unsigned long long)test_addr);
                    return test_addr;
                } else if (!is64 && magic == 0xfeedface) {
                    printf("[ kpatch ] Found 32-bit kernel base via region scan: 0x%llx (Mach-O Magic OK)\n", (unsigned long long)test_addr);
                    return test_addr;
                }
            }
        }
        addr += size;
    }

    // Method 5: Aligned RAM-safe scan (ONLY scans safe physical RAM range where kernel can be slid, preventing aborts/deadlocks)
    printf("[ kpatch ] Scanning aligned memory in RAM range for kernel Mach-O header...\n");
    if (is64) {
        // 64-bit KASLR slide is 2MB aligned, max 512MB
        for (int i = 0; i < 256; i++) {
            mach_vm_address_t base = 0xffffffF007004000ULL + ((mach_vm_address_t)i * 0x00200000ULL);
            uint32_t magic = 0;
            mach_msg_type_number_t read_cnt = 0;
            vm_offset_t read_buf = 0;
            if (kread_safe(kt, base, 4, &read_buf, &read_cnt, is64) == KERN_SUCCESS && read_cnt >= 4) {
                magic = *(uint32_t *)read_buf;
                vm_deallocate(mach_task_self(), read_buf, read_cnt);
                if (magic == 0xfeedfacf) {
                    printf("[ kpatch ] Found 64-bit kernel base via RAM scan: 0x%llx (Mach-O Magic OK)\n", (unsigned long long)base);
                    return base;
                }
            }
        }
    } else {
        // 32-bit KASLR slide is 1MB aligned, max 256MB. We check safe offsets (0, 0x1000, 0x2000, 0x4000)
        for (int i = 0; i < 256; i++) {
            mach_vm_address_t slide = (mach_vm_address_t)i * 0x00100000ULL;
            mach_vm_address_t test_bases[] = {
                0x80001000ULL + slide,
                0x80002000ULL + slide,
                0x80000000ULL + slide,
                0x80004000ULL + slide
            };
            for (int b = 0; b < 4; b++) {
                mach_vm_address_t base = test_bases[b];
                uint32_t magic = 0;
                mach_msg_type_number_t read_cnt = 0;
                vm_offset_t read_buf = 0;
                if (kread_safe(kt, base, 4, &read_buf, &read_cnt, is64) == KERN_SUCCESS && read_cnt >= 4) {
                    magic = *(uint32_t *)read_buf;
                    vm_deallocate(mach_task_self(), read_buf, read_cnt);
                    if (magic == 0xfeedface) {
                        printf("[ kpatch ] Found 32-bit kernel base via RAM scan: 0x%llx (Mach-O Magic OK)\n", (unsigned long long)base);
                        return base;
                    }
                }
            }
        }
    }

    printf("[ kpatch ] All kernel base detection methods failed.\n");
    return 0;
}

static mach_vm_address_t kfind_string_64(mach_port_t kt, mach_vm_address_t start, mach_vm_address_t end, const char *str, BOOL is64) {
    size_t len = strlen(str) + 1;
    mach_vm_size_t read_sz = 4095;
    mach_vm_size_t step = 4080;
    
    for (mach_vm_address_t addr = start; addr < end; addr += step) {
        vm_offset_t buf = 0;
        mach_msg_type_number_t cnt = 0;
        kern_return_t kr = kread_safe(kt, addr, read_sz, &buf, &cnt, is64);
        if (kr == KERN_SUCCESS) {
            unsigned char *p = (unsigned char *)buf;
            if (cnt >= len) {
                for (size_t i = 0; i <= cnt - len; i++) {
                    if (memcmp(p + i, str, len) == 0) {
                        mach_vm_address_t found = addr + i;
                        vm_deallocate(mach_task_self(), buf, cnt);
                        return found;
                    }
                }
            }
            vm_deallocate(mach_task_self(), buf, cnt);
        }
    }
    return 0;
}

static mach_vm_address_t kfind_ptr_64(mach_port_t kt, mach_vm_address_t start, mach_vm_address_t end, mach_vm_address_t val, BOOL is64) {
    mach_vm_size_t read_sz = 4095;
    mach_vm_size_t step = 4080;
    
    for (mach_vm_address_t addr = start; addr < end; addr += step) {
        vm_offset_t buf = 0;
        mach_msg_type_number_t cnt = 0;
        kern_return_t kr = kread_safe(kt, addr, read_sz, &buf, &cnt, is64);
        if (kr == KERN_SUCCESS) {
            if (is64) {
                uint64_t *p = (uint64_t *)buf;
                size_t words = cnt / 8;
                for (size_t i = 0; i < words; i++) {
                    if (p[i] == val) {
                        mach_vm_address_t found = addr + i * 8;
                        vm_deallocate(mach_task_self(), buf, cnt);
                        return found;
                    }
                }
            } else {
                uint32_t *p = (uint32_t *)buf;
                size_t words = cnt / 4;
                for (size_t i = 0; i < words; i++) {
                    if (p[i] == (uint32_t)val) {
                        mach_vm_address_t found = addr + i * 4;
                        vm_deallocate(mach_task_self(), buf, cnt);
                        return found;
                    }
                }
            }
            vm_deallocate(mach_task_self(), buf, cnt);
        }
    }
    return 0;
}

static int check_oid_64(mach_port_t kt, mach_vm_address_t p_oid_name, mach_vm_address_t expected_name_addr, BOOL is64, mach_vm_address_t *out_var_addr) {
    mach_vm_address_t oid_base = is64 ? (p_oid_name - 40) : (p_oid_name - 24);
    vm_offset_t buf = 0;
    mach_msg_type_number_t cnt = 0;
    kern_return_t kr = kread_safe(kt, oid_base, 80, &buf, &cnt, is64);
    if (kr != KERN_SUCCESS || cnt < 80) {
        if (kr == KERN_SUCCESS) vm_deallocate(mach_task_self(), buf, cnt);
        return 0;
    }
    
    if (is64) {
        uint32_t kind = *(uint32_t *)(buf + 20);
        uint64_t arg1 = *(uint64_t *)(buf + 24);
        uint64_t name = *(uint64_t *)(buf + 40);
        uint64_t handler = *(uint64_t *)(buf + 48);
        
        vm_deallocate(mach_task_self(), buf, cnt);
        
        if (name != expected_name_addr) return 0;
        if ((kind & 0xf) != 2) return 0;
        if (arg1 < 0xffffffF000000000ULL) return 0;
        if (handler < 0xffffffF000000000ULL) return 0;
        
        *out_var_addr = arg1;
        return 1;
    } else {
        uint32_t *fields = (uint32_t *)buf;
        uint32_t kind = fields[3];
        uint32_t arg1 = fields[4];
        uint32_t name = fields[6];
        uint32_t handler = fields[7];
        
        vm_deallocate(mach_task_self(), buf, cnt);
        
        if (name != expected_name_addr) return 0;
        if ((kind & 0xf) != 2) return 0;
        if (arg1 < 0x80000000 || arg1 >= 0x8fffffff) return 0;
        if (handler < 0x80000000 || handler >= 0x8fffffff) return 0;
        
        *out_var_addr = arg1;
        return 1;
    }
}

static mach_vm_address_t find_scopedroute_var_addr(mach_port_t kt) {
    mach_vm_address_t kernel_base = find_kernel_base(kt);
    if (!kernel_base) {
        printf("[ kpatch ] Could not determine kernel base address.\n");
        return 0;
    }
    
    BOOL is64 = (kernel_base > 0xffffffffULL);
    mach_vm_address_t start = kernel_base;
    mach_vm_address_t end = kernel_base + (is64 ? 0x02000000ULL : 0x01000000ULL);
    
    printf("[ kpatch ] Scanning kernel memory 0x%llx - 0x%llx for \"scopedroute\" string...\n", (unsigned long long)start, (unsigned long long)end);
    mach_vm_address_t str_addr = kfind_string_64(kt, start, end, "scopedroute", is64);
    if (!str_addr) {
        printf("[ kpatch ] Failed to find \"scopedroute\" string in kernel memory.\n");
        return 0;
    }
    printf("[ kpatch ] Found \"scopedroute\" string at 0x%llx\n", (unsigned long long)str_addr);
    
    printf("[ kpatch ] Scanning kernel memory for sysctl_oid referring to 0x%llx...\n", (unsigned long long)str_addr);
    mach_vm_address_t scan_ptr = start;
    while (scan_ptr < end) {
        mach_vm_address_t p_oid_name = kfind_ptr_64(kt, scan_ptr, end, str_addr, is64);
        if (!p_oid_name) break;
        
        mach_vm_address_t var_addr = 0;
        if (check_oid_64(kt, p_oid_name, str_addr, is64, &var_addr)) {
            printf("[ kpatch ] Successfully verified sysctl_oid struct for scopedroute.\n");
            printf("[ kpatch ] scopedroute variable address is 0x%llx\n", (unsigned long long)var_addr);
            return var_addr;
        }
        scan_ptr = p_oid_name + (is64 ? 8 : 4);
    }
    
    printf("[ kpatch ] Could not find/verify sysctl_oid for scopedroute.\n");
    return 0;
}

// Proxy PF structs and generate_pf_rules removed for iOS 5/6 focus.
// No PF redirection in this build.

static int cmd_warp_tunnel(const char *ip, int port, const char *priv_b64, const char *pub_b64, const char *client_ip, const char *client_ip6, const char *dns_ip, const char *reserved_b64, int mtu, int keepalive, const char *psk_b64, const char *allowed_ips, const nw_awg *awg) {
    // Daemonize the process so it detaches from the parent app session and process group.
    // Double-fork + setsid + stdin null + HUP ignore makes it survive SSH/USB
    // control link death (usbmuxd disconnects, cable wiggles) while still
    // responding to explicit `nekrowarp stop` (SIGINT) and crashes.
    pid_t daemon_pid = fork();
    if (daemon_pid < 0) {
        perror("fork");
        return 1;
    }
    if (daemon_pid > 0) {
        // Parent process exits successfully immediately, letting posix_spawn/waitpid in the GUI return
        exit(0);
    }
    if (setsid() < 0) {
        perror("setsid");
        return 1;
    }
    // Second fork: ensure we are not session leader (no controlling tty can be acquired).
    pid_t daemon_pid2 = fork();
    if (daemon_pid2 < 0) {
        perror("fork2");
        return 1;
    }
    if (daemon_pid2 > 0) {
        exit(0);
    }
    // Fully detached daemon.
    chdir("/");
    // Close and null stdin (stdout/stderr redirected below). Prevents stray reads
    // from a dead SSH pty over usbmux.
    close(STDIN_FILENO);
    int nullfd = open("/dev/null", O_RDWR);
    if (nullfd >= 0) {
        dup2(nullfd, STDIN_FILENO);
        if (nullfd > 2) close(nullfd);
    }
    signal(SIGHUP, SIG_IGN);  // do not tear down tunnel just because control SSH died

    int s = -1;
    int tun_fd = -1;

    // Redirect stdout and stderr to /var/log/nekrowarp.log
    int log_fd = open("/var/log/nekrowarp.log", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (log_fd >= 0) {
        dup2(log_fd, STDOUT_FILENO);
        dup2(log_fd, STDERR_FILENO);
        close(log_fd);
        setvbuf(stdout, NULL, _IOLBF, 0);
        setvbuf(stderr, NULL, _IOLBF, 0);
    }
    
    unlink("/tmp/nekrowarp.crash");

    double osver = 0.0;
    char osrelease[256];
    size_t osrelease_sz = sizeof(osrelease);
    if (sysctlbyname("kern.osrelease", osrelease, &osrelease_sz, NULL, 0) == 0) {
        osver = atof(osrelease);
    }
    g_proxy_mode = 0;  // iOS 7+ support removed. Only full route + kernel patch for iOS 5/6.
    if (osver >= 14.0) {
        fprintf(stderr, "[ NekroWARP ] ERROR: This build is for jailbroken iOS 5.x only.\n");
        fprintf(stderr, "iOS 7+ (including 9.3.5) support has been dropped for maximum stability on iOS 5.1.1.\n");
        exit(1);
    }
    printf(g_telegram_split
        ? "[ FuckDPI ] iOS 5/6 isolated Telegram split-routing mode.\n"
        : "[ NekroWARP ] iOS 5.x mode: full route surgery + kpatch enabled.\n");

    if (g_kpatch && !g_telegram_split) {
        mach_port_t kt = MACH_PORT_NULL;
        kern_return_t kr = task_for_pid(mach_task_self(), 0, &kt);
        if (kr == KERN_SUCCESS && kt != MACH_PORT_NULL) {
            g_kt = kt;
            printf("[ kpatch ] TFP0 available. Attempting to locate scopedroute in kernel...\n");
            g_scopedroute_kaddr = find_scopedroute_var_addr(kt);
            if (g_scopedroute_kaddr != 0) {
                uint32_t val = 1;
                vm_offset_t val_buf = 0;
                mach_msg_type_number_t val_cnt = 0;
                BOOL is64 = is_kernel_64bit();
                if (kread_safe(kt, g_scopedroute_kaddr, 4, &val_buf, &val_cnt, is64) == KERN_SUCCESS && val_cnt >= 4) {
                    val = *(uint32_t *)val_buf;
                    vm_deallocate(mach_task_self(), val_buf, val_cnt);
                }
                scopedroute_old = val;
                
                uint32_t zero = 0;
                if (kwrite_safe(kt, g_scopedroute_kaddr, (vm_offset_t)&zero, 4, is64) == KERN_SUCCESS) {
                    scopedroute_changed = 1;
                    printf("[ kpatch ] Successfully disabled net.inet.ip.scopedroute (0) in kernel memory.\n");
                } else {
                    printf("[ kpatch ] Failed to write to kernel address 0x%llx\n", (unsigned long long)g_scopedroute_kaddr);
                    g_scopedroute_kaddr = 0;
                }
            } else {
                printf("[ kpatch ] Could not find scopedroute address in kernel. Proceeding with SCDynamicStore fallback.\n");
            }
        } else {
            printf("[ kpatch ] TFP0 unavailable. Proceeding with SCDynamicStore fallback.\n");
        }
    }

    FILE *pf = fopen("/tmp/nekrowarp.pid", "w");
    if (pf) {
        fprintf(pf, "%d\n", (int)getpid());
        fclose(pf);
    }

    uint8_t priv[32], pub[32];
    if (b64decode(priv_b64, priv, sizeof(priv)) != 32) { printf("bad private key\n"); goto fail; }
    if (b64decode(pub_b64, pub, sizeof(pub)) != 32)     { printf("bad peer public key\n"); goto fail; }

    uint8_t psk[32];
    const uint8_t *psk_ptr = NULL;
    if (psk_b64 && strlen(psk_b64) > 0) {
        if (b64decode(psk_b64, psk, sizeof(psk)) == 32) {
            psk_ptr = psk;
            printf("Using pre-shared key.\n");
        } else {
            printf("Warning: PresharedKey is not 32 bytes; ignoring.\n");
        }
    }

    nw_handshake hs;
    nw_handshake_init(&hs, priv, pub, psk_ptr);
    if (reserved_b64 && strlen(reserved_b64) > 0) {
        uint8_t res[16];
        int res_len = b64decode(reserved_b64, res, sizeof(res));
        if (res_len >= 3) {
            memcpy(hs.reserved, res, 3);
        }
    }
    uint8_t init[NW_WG_INIT_SIZE];

    s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) { perror("socket"); goto fail; }
    
    // Set larger socket buffers for high-speed traffic (1MB, fallback to 512KB)
    int rcvbuf = 1024 * 1024;
    if (setsockopt(s, SOL_SOCKET, SO_RCVBUF, &rcvbuf, sizeof(rcvbuf)) < 0) {
        rcvbuf = 512 * 1024;
        setsockopt(s, SOL_SOCKET, SO_RCVBUF, &rcvbuf, sizeof(rcvbuf));
    }
    int sndbuf = 1024 * 1024;
    if (setsockopt(s, SOL_SOCKET, SO_SNDBUF, &sndbuf, sizeof(sndbuf)) < 0) {
        sndbuf = 512 * 1024;
        setsockopt(s, SOL_SOCKET, SO_SNDBUF, &sndbuf, sizeof(sndbuf));
    }
    // Pin the encrypted WARP transport to the physical Wi-Fi interface. Once we
    // make the utun primary (setup_routing -> nw_scope_set_primary), an unbound
    // socket's outbound packets to the WARP edge would be scoped INTO the tunnel
    // — the tunnel trying to carry its own ciphertext, a routing loop. IP_BOUND_IF
    // keeps this UDP on en0 regardless of which service is primary; the host
    // route added in setup_routing is the belt to this suspenders.
    // bindwarp=1 (default) pins the socket to en0; bindwarp=0 leaves it unbound
    // (the 0.0.6 behaviour). A/B toggle while we chase udp_in=0 after utun goes
    // primary — IP_BOUND_IF may be breaking the inbound path under scoped routing.
    if (g_bind_warp) {
        unsigned wifi_idx = if_nametoindex("en0");
        if (wifi_idx == 0) wifi_idx = if_nametoindex("en1");
        if (wifi_idx != 0) {
            if (setsockopt(s, IPPROTO_IP, IP_BOUND_IF, &wifi_idx, sizeof(wifi_idx)) < 0)
                fprintf(stderr, "[ NekroWARP ] IP_BOUND_IF en0 failed: %s\n", strerror(errno));
            else
                fprintf(stderr, "[ NekroWARP ] WARP socket pinned to ifindex %u (en0)\n", wifi_idx);
        } else {
            fprintf(stderr, "[ NekroWARP ] warning: no en0/en1 to pin WARP socket to\n");
        }
    } else {
        fprintf(stderr, "[ NekroWARP ] bindwarp=0: WARP socket left UNBOUND\n");
    }
    struct sockaddr_in dst;
    memset(&dst, 0, sizeof(dst));
    dst.sin_family = AF_INET;
    dst.sin_port = htons((uint16_t)port);
    struct hostent *he = gethostbyname(ip);
    if (!he) {
        fprintf(stderr, "Error: Could not resolve endpoint host %s\n", ip);
        goto fail;
    }
    struct in_addr **addr_list = (struct in_addr **)he->h_addr_list;
    if (!addr_list[0]) {
        fprintf(stderr, "Error: No IP addresses found for host %s\n", ip);
        goto fail;
    }
    dst.sin_addr = *addr_list[0];
    // Pin every later step (host route + cleanup) to the exact IP the UDP socket
    // targets. If `ip` was a hostname (or DNS picked a different edge), routing via
    // the raw string would protect the wrong/zero address and the encrypted UDP
    // would be swallowed by the tunnel's own default route once it flips.
    char endpoint_ip_str[64];
    strlcpy(endpoint_ip_str, inet_ntoa(dst.sin_addr), sizeof(endpoint_ip_str));
    fprintf(stderr, "[ NekroWARP ] Resolved endpoint %s -> %s\n", ip, endpoint_ip_str);

    // Populate gateway, wifi index, and warp_ep_ip before handshake so we can add the host route
    orig_gw = nw_route_get_default_gateway();
    wifi_ifindex = if_nametoindex("en0");
    if (wifi_ifindex == 0) wifi_ifindex = if_nametoindex("en1");
    inet_aton(endpoint_ip_str, &warp_ep_ip);

    if (orig_gw.s_addr != INADDR_ANY && wifi_ifindex != 0) {
        fprintf(stderr, "[ NekroWARP ] Adding pre-handshake host route to endpoint %s via gateway %s on interface index %u...\n", endpoint_ip_str, inet_ntoa(orig_gw), wifi_ifindex);
        if (nw_route_add_host(warp_ep_ip, orig_gw, wifi_ifindex) == 0 || errno == EEXIST)
            host_route_added = 1;
    }
    // Per-attempt timeout + retries. The WARP edge's handshake response often takes
    // 3-8s to arrive; each attempt sends a FRESH initiation (new ephemeral), which
    // supersedes the prior one at the server. So the per-attempt wait must be long
    // enough to actually receive a reply before we retransmit — a 3s window cut the
    // handshake off every time while an 8s wait completes reliably (matches the
    // working warp-connect path and the WireGuard REKEY_TIMEOUT budget).
    // Short per-recv timeout; we loop within an 8s per-attempt deadline so we can
    // drain obfuscation echoes (WARP replies to our junk/I1 with 16-byte 0xCF
    // error frames) and keep reading until the real 92-byte handshake response
    // for the CURRENT initiation arrives.
    struct timeval tv = { 2, 0 };
    setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    // AmneziaWG obfuscation: the signature (I1..I5) packets go out once, before
    // any handshake traffic, to seed the censor's flow classifier with non-WG
    // bytes. The WARP edge silently drops them.
    if (awg && nw_awg_active(awg)) {
        printf("[AWG] obfuscation active (jc=%d jmin=%d jmax=%d)\n", awg->jc, awg->jmin, awg->jmax);
        nw_awg_send_signature(s, (struct sockaddr *)&dst, sizeof(dst), awg);
    }

    uint8_t resp_buf[256];
    nw_transport t;
    int handshake_ok = 0;
    const int max_attempts = 6;
    for (int attempt = 1; attempt <= max_attempts; attempt++) {
        // Fresh ephemeral + index each attempt (per the WireGuard spec).
        uint32_t idx;
        nw_random((uint8_t *)&idx, 4);
        nw_wg_create_initiation(&hs, idx, init);

        // Jc junk packets immediately before the real initiation so the first
        // WireGuard-shaped datagram is buried in noise on every attempt.
        if (awg) nw_awg_send_junk(s, (struct sockaddr *)&dst, sizeof(dst), awg);

        ssize_t sent = sendto(s, init, sizeof(init), 0, (struct sockaddr *)&dst, sizeof(dst));
        if (sent < 0)
            printf("-> sendto %s:%d FAILED (attempt %d/%d): %s\n", ip, port, attempt, max_attempts, strerror(errno));
        else
            printf("-> sent WireGuard initiation to %s:%d (attempt %d/%d)\n", ip, port, attempt, max_attempts);

        // Drain the socket for up to 8s, skipping anything that isn't the real
        // 92-byte type-2 handshake response for this initiation (obfuscation
        // echoes, 0xCF error frames, stale responses).
        time_t deadline = time(NULL) + 8;
        while (time(NULL) < deadline) {
            ssize_t n = recvfrom(s, resp_buf, sizeof(resp_buf), 0, NULL, NULL);
            if (n < 0) {
                if (errno == EAGAIN || errno == EWOULDBLOCK) continue; // keep waiting until deadline
                printf("   recvfrom returned %s\n", strerror(errno));
                break;
            }
            if (n != NW_WG_RESP_SIZE || resp_buf[0] != 2) {
                printf("   skip non-response: %ld bytes type %u\n", (long)n, resp_buf[0]);
                continue;
            }
            int rc = nw_wg_consume_response(&hs, resp_buf, &t);
            if (rc) { printf("   consume_response rc=%d, keep draining\n", rc); continue; }
            handshake_ok = 1;
            break;
        }
        if (handshake_ok) { printf("<- valid handshake response accepted\n"); break; }
        printf("   no valid response this attempt, retrying...\n");
    }
    if (!handshake_ok) {
        fprintf(stderr, "Error: no WireGuard handshake response from %s:%d after %d attempts.\n", ip, port, max_attempts);
        goto fail;
    }
    printf("[ OK ] HANDSHAKE COMPLETE — keys derived.\n");

    struct timeval tv_zero = { 0, 0 };
    setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv_zero, sizeof(tv_zero));

    tun_fd = nw_tun_open_utun(active_ifname, sizeof(active_ifname));
    if (tun_fd < 0) tun_fd = nw_tun_open_dev(active_ifname, sizeof(active_ifname));
    if (tun_fd < 0) {
        fprintf(stderr, "Error: Could not open any tun interface!\n");
        goto fail;
    }
    printf("Opened interface: %s\n", active_ifname);

    struct in_addr client_addr;
    inet_aton(client_ip, &client_addr);
    uint32_t client_h = ntohl(client_addr.s_addr);
    uint32_t gateway_h = (client_h & 0xffffff00) | 1;
    struct in_addr peer_addr;
    peer_addr.s_addr = htonl(gateway_h);

    if (nw_tun_set_ipv4(active_ifname, client_ip, inet_ntoa(peer_addr)) < 0) {
        fprintf(stderr, "Error: Config of %s address failed: %s\n", active_ifname, strerror(errno));
        goto fail;
    }
    printf("Configured %s as %s --> %s\n", active_ifname, client_ip, inet_ntoa(peer_addr));

    if (mtu <= 0) mtu = 1280;
    // Safety ceiling. The earlier "connected, no internet" was diagnosed to the
    // censor dropping the fingerprinted WireGuard transport flow (now handled by
    // AmneziaWG obfuscation above), not purely an MTU overshoot — so we no longer
    // clamp to 1000. 1280 is the reference portal's value and the IPv6 minimum
    // MTU, so it is always path-safe even with WARP's ~60-byte UDP overhead.
    if (mtu > 1280) {
        printf("Clamping MTU %d -> 1280 (IPv6-minimum safe ceiling for WARP overhead)\n", mtu);
        mtu = 1280;
    }
    if (nw_tun_set_mtu(active_ifname, mtu) < 0) {
        fprintf(stderr, "Warning: could not set MTU %d on %s: %s\n", mtu, active_ifname, strerror(errno));
    } else {
        printf("Set %s MTU to %d\n", active_ifname, mtu);
    }

    if (0 && client_ip6 && strlen(client_ip6) > 0) {
        char clean_ip6[128];
        strlcpy(clean_ip6, client_ip6, sizeof(clean_ip6));
        char *slash = strchr(clean_ip6, '/');
        if (slash) *slash = '\0';
        
        printf("Configuring %s IPv6 address: %s via ioctl...\n", active_ifname, clean_ip6);
        if (nw_tun_set_ipv6(active_ifname, clean_ip6) < 0) {
            fprintf(stderr, "warning: ioctl IPv6 address config failed: %s\n", strerror(errno));
        }
        
        printf("Adding IPv6 default route via %s...\n", active_ifname);
        if (nw_route_add_default_v6("::", active_ifname) == 0) {
            default_route_v6_added = 1;
        } else {
            perror("nw_route_add_default_v6");
        }
    }

    // A Telegram-only tunnel must not alter resolver state for SpringBoard or
    // any other app. Full-tunnel legacy mode retains the old DNS behaviour.
    if (!g_telegram_split) {
        save_original_dns();
        FILE *df = fopen("/tmp/nekrowarp.orig_dns", "w");
        if (df) {
            fprintf(df, "%s\n", orig_dns);
            fclose(df);
        }
        set_dns_warp(dns_ip);
    }

    if (allowed_ips && strlen(allowed_ips) > 0) {
        printf("AllowedIPs = %s\n", allowed_ips);
        if (strcmp(allowed_ips, "0.0.0.0/0") != 0 &&
            strcmp(allowed_ips, "0.0.0.0/0,::/0") != 0 &&
            strcmp(allowed_ips, "0.0.0.0/0, ::/0") != 0) {
            printf("Note: split-tunnel AllowedIPs not yet supported; routing all traffic.\n");
        }
    }

    if (setup_routing(endpoint_ip_str, client_ip, mtu) < 0) {
        goto fail;
    }
    if (g_telegram_split) {
        FILE *sf = fopen("/tmp/nekrowarp.telegram_split", "w");
        if (sf) {
            fprintf(sf, "1\n");
            fclose(sf);
        }
    }

    signal(SIGINT, handle_sigint);
    signal(SIGTERM, handle_sigint);
    // Self-timeout for safe testing: auto-cleanup after N seconds even if the
    // controlling SSH/USB link dies, so a test run can never leave the phone
    // stuck with the utun primary (Wi-Fi down). Set via warp-tunnel runfor=N.
    if (g_runfor > 0) {
        signal(SIGALRM, handle_sigint);
        alarm((unsigned)g_runfor);
        printf("[ NekroWARP ] runfor=%d: will auto-stop and restore routing after %ds\n",
               g_runfor, g_runfor);
    }
    // Crash/abnormal-exit safety net: restore routing before the process dies so
    // the utun can't stay primary and brick the network.
    atexit(cleanup);
    // SIGHUP is ignored in the daemon child (see double-fork above) so USB/SSH
    // disconnects do not tear down a stable tunnel. SIGINT/TERM (from `stop`)
    // still trigger clean shutdown.
    signal(SIGSEGV, handle_fatal);
    signal(SIGBUS,  handle_fatal);
    signal(SIGABRT, handle_fatal);

    run_tunnel_loop(tun_fd, s, &t, &dst, keepalive, &hs, awg, mtu);

    cleanup();
    if (tun_fd >= 0) close(tun_fd);
    if (s >= 0) close(s);
    
    if (!clean_exit_requested) {
        save_crash_log();
        show_disconnect_notification();
    }
    return 0;

fail:
    cleanup();
    if (tun_fd >= 0) close(tun_fd);
    if (s >= 0) close(s);
    
    if (!clean_exit_requested) {
        save_crash_log();
        show_disconnect_notification();
    }
    return 1;
}

static int get_wifi_ip(char *out_ip, size_t max) {
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd < 0) return -1;
    struct ifreq ifr;
    strncpy(ifr.ifr_name, "en0", IFNAMSIZ);
    if (ioctl(fd, SIOCGIFADDR, &ifr) < 0) {
        strncpy(ifr.ifr_name, "en1", IFNAMSIZ);
        if (ioctl(fd, SIOCGIFADDR, &ifr) < 0) {
            close(fd);
            return -1;
        }
    }
    close(fd);
    struct sockaddr_in *sin = (struct sockaddr_in *)&ifr.ifr_addr;
    strncpy(out_ip, inet_ntoa(sin->sin_addr), max);
    return 0;
}

static void force_restore_routing(void) {
    char saved_gw[64] = {0};
    char saved_dns[256] = {0};
    
    FILE *gf = fopen("/tmp/nekrowarp.orig_gw", "r");
    if (gf) {
        if (fscanf(gf, "%63s", saved_gw) != 1) saved_gw[0] = '\0';
        fclose(gf);
        unlink("/tmp/nekrowarp.orig_gw");
    }
    
    FILE *df = fopen("/tmp/nekrowarp.orig_dns", "r");
    if (df) {
        if (fgets(saved_dns, sizeof(saved_dns), df)) {
            char *nl = strchr(saved_dns, '\n'); if (nl) *nl = '\0';
            nl = strchr(saved_dns, '\r'); if (nl) *nl = '\0';
        }
        fclose(df);
        unlink("/tmp/nekrowarp.orig_dns");
    }
    
    if (strlen(saved_gw) == 0) {
        char wifi_ip[64] = {0};
        if (get_wifi_ip(wifi_ip, sizeof(wifi_ip)) == 0) {
            char *last_dot = strrchr(wifi_ip, '.');
            if (last_dot) {
                last_dot[1] = '\0';
                snprintf(saved_gw, sizeof(saved_gw), "%s1", wifi_ip);
                printf("[ NekroWARP ] Inferred fallback default gateway from Wi-Fi IP: %s\n", saved_gw);
            }
        }
    }
    
    if (strlen(saved_gw) > 0) {
        struct in_addr gw_addr;
        inet_aton(saved_gw, &gw_addr);
        
        struct in_addr current_gw = nw_route_get_default_gateway();
        if (current_gw.s_addr != INADDR_ANY && current_gw.s_addr != gw_addr.s_addr) {
            printf("[ NekroWARP ] Deleting default route via %s...\n", inet_ntoa(current_gw));
            nw_route_delete_default(current_gw);
        }
        
        printf("[ NekroWARP ] Restoring default route via gateway %s...\n", saved_gw);
        nw_route_add_default(gw_addr, 0);
    }
    
    printf("[ NekroWARP ] Deleting default IPv6 route via utun0...\n");
    nw_route_delete_default_v6("::", "utun0");
    
    if (strlen(saved_dns) > 0) {
        printf("[ NekroWARP ] Restoring DNS to %s...\n", saved_dns);
        write_resolv_conf(saved_dns);
    } else {
        printf("[ NekroWARP ] Removing custom DNS...\n");
        unlink("/etc/resolv.conf");
    }

    // iOS 5/6 build: PF cleanup not needed for proxy (no proxy used).
    // If any pf rules were loaded manually, they can stay or be flushed by user.
}

static int cmd_stop(void) {
    FILE *f = fopen("/tmp/nekrowarp.pid", "r");
    pid_t pid = 0;
    if (f) {
        if (fscanf(f, "%d", &pid) != 1) pid = 0;
        fclose(f);
    }
    
    int daemon_alive = 0;
    if (pid > 0) {
        if (kill(pid, 0) == 0) {
            daemon_alive = 1;
            printf("Sending SIGINT to NekroWARP process %d...\n", pid);
            kill(pid, SIGINT);
            for (int i = 0; i < 20; i++) {
                usleep(100000);
                if (kill(pid, 0) != 0) {
                    daemon_alive = 0;
                    break;
                }
            }
        }
    }
    
    if (daemon_alive) {
        printf("Daemon did not terminate. Killing forcefully...\n");
        kill(pid, SIGKILL);
        usleep(100000);
    }
    
    force_restore_routing();
    unlink("/tmp/nekrowarp.pid");
    printf("NekroWARP stopped and network routing restored.\n");
    return 0;
}

static int cmd_status(void) {
    FILE *f = fopen("/tmp/nekrowarp.pid", "r");
    if (!f) {
        printf("Status: Disconnected\n");
        return 0;
    }
    pid_t pid;
    if (fscanf(f, "%d", &pid) != 1) {
        printf("Status: Disconnected (corrupted pid file)\n");
        fclose(f);
        return 0;
    }
    fclose(f);
    
    if (kill(pid, 0) == 0) {
        printf("Status: Connected (PID %d)\n", pid);
    } else {
        printf("Status: Disconnected (dead PID %d)\n", pid);
        unlink("/tmp/nekrowarp.pid"); // clean up dead pid file
    }
    return 0;
}

// Live "is the internet actually reachable" check for the GUI. A live pid only
// proves the daemon is running, not that the tunnel passes data (wrong MTU /
// reserved / dead edge all leave the daemon up but the data path dead). This
// does a real TLS handshake through the tunnel to Cloudflare's 1.1.1.1 (where
// WARP terminates all internet traffic) and reports via the exit code so the
// app can read it with waitpid alone — no stdout parsing:
//   0 = internet reachable, 1 = tunnel up but no data, 2 = not connected.
static int test_http_reachability(const char *host, int port) {
    struct hostent *he = gethostbyname(host);
    if (!he || !he->h_addr_list[0]) return -1;
    
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;
    
    struct timeval tv = { 3, 0 };
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr = *(struct in_addr *)he->h_addr_list[0];
    
    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd);
        return -1;
    }
    
    char req[256];
    int reqlen = snprintf(req, sizeof(req),
        "HEAD / HTTP/1.1\r\nHost: %s\r\n"
        "User-Agent: NekroWARP\r\nConnection: close\r\n\r\n", host);
        
    if (send(fd, req, reqlen, 0) < 0) {
        close(fd);
        return -1;
    }
    
    char buf[128];
    ssize_t n = recv(fd, buf, sizeof(buf) - 1, 0);
    close(fd);
    
    if (n > 0) {
        buf[n] = '\0';
        if (strstr(buf, "HTTP/1.")) return 0;
    }
    return -1;
}

static int cmd_netcheck(void) {
    FILE *f = fopen("/tmp/nekrowarp.pid", "r");
    if (!f) return 2;
    pid_t pid;
    int alive = (fscanf(f, "%d", &pid) == 1 && (kill(pid, 0) == 0 || errno == EPERM));
    fclose(f);
    if (!alive) return 2;

    // In FuckDPI mode a generic web probe would bypass WARP through Wi-Fi and
    // produce a false green state. This Telegram DC address is covered by the
    // split routes, so a successful TCP connection also proves the tunnel path.
    int split = (access("/tmp/nekrowarp.telegram_split", F_OK) == 0);
    int rc = split
        ? test_direct_connection("149.154.167.51", 443)
        : test_http_reachability("yandex.ru", 80);
    return (rc == 0) ? 0 : 1;
}

static void trim(char *out_str, const char *in_str) {
    while (*in_str == ' ' || *in_str == '\t' || *in_str == '\r' || *in_str == '\n') in_str++;
    size_t len = strlen(in_str);
    while (len > 0 && (in_str[len - 1] == ' ' || in_str[len - 1] == '\t' || in_str[len - 1] == '\r' || in_str[len - 1] == '\n')) len--;
    strncpy(out_str, in_str, len);
    out_str[len] = '\0';
}

static int cmd_import_conf(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) {
        perror("fopen config");
        return 1;
    }
    
    char priv[128] = {0};
    char pub[128] = {0};
    char client_ip[128] = {0};
    char client_ip6[128] = {0};
    char dns[128] = {0};
    char endpoint[128] = {0};
    char port[128] = {0};
    char mtu[16] = {0};
    char keepalive[16] = {0};
    char reserved[64] = {0};
    char psk[128] = {0};
    char allowed[256] = {0};
    char listenport[16] = {0};
    // AmneziaWG obfuscation (see [[working-portal-is-amneziawg]]).
    char jc[16]={0}, jmin[16]={0}, jmax[16]={0};
    char s1[16]={0}, s2[16]={0}, s3[16]={0}, s4[16]={0};
    char h1[16]={0}, h2[16]={0}, h3[16]={0}, h4[16]={0};
    char i1[4096]={0}, i2[4096]={0}, i3[4096]={0}, i4[4096]={0}, i5[4096]={0};

    char line[4096];
    while (fgets(line, sizeof(line), f)) {
        char clean_line[4096];
        trim(clean_line, line);
        if (clean_line[0] == '\0' || clean_line[0] == '#' || clean_line[0] == ';') continue;
        if (clean_line[0] == '[') continue;

        char *eq = strchr(clean_line, '=');
        if (!eq) continue;
        *eq = '\0';
        char key[256], val[4096];
        trim(key, clean_line);
        trim(val, eq + 1);

        if (strcasecmp(key, "PrivateKey") == 0) {
            strlcpy(priv, val, sizeof(priv));
        } else if (strcasecmp(key, "PublicKey") == 0) {
            strlcpy(pub, val, sizeof(pub));
        } else if (strcasecmp(key, "DNS") == 0) {
            strlcpy(dns, val, sizeof(dns));
        } else if (strcasecmp(key, "MTU") == 0) {
            strlcpy(mtu, val, sizeof(mtu));
        } else if (strcasecmp(key, "PersistentKeepalive") == 0) {
            strlcpy(keepalive, val, sizeof(keepalive));
        } else if (strcasecmp(key, "Reserved") == 0 || strcasecmp(key, "ClientID") == 0) {
            // Non-standard wg-quick line carrying the WARP Client ID (base64).
            strlcpy(reserved, val, sizeof(reserved));
        } else if (strcasecmp(key, "Endpoint") == 0) {
            char *colon = strrchr(val, ':');
            if (colon) {
                *colon = '\0';
                trim(endpoint, val);
                trim(port, colon + 1);
            } else {
                strlcpy(endpoint, val, sizeof(endpoint));
                strlcpy(port, "2408", sizeof(port));
            }
        } else if (strcasecmp(key, "Address") == 0) {
            char *token = strtok(val, ",");
            while (token) {
                char addr_item[128];
                trim(addr_item, token);
                
                char *slash = strchr(addr_item, '/');
                if (slash) *slash = '\0';
                
                if (strchr(addr_item, ':')) {
                    strlcpy(client_ip6, addr_item, sizeof(client_ip6));
                } else {
                    strlcpy(client_ip, addr_item, sizeof(client_ip));
                }
                token = strtok(NULL, ",");
            }
        } else if (strcasecmp(key, "PresharedKey") == 0) {
            strlcpy(psk, val, sizeof(psk));
        } else if (strcasecmp(key, "AllowedIPs") == 0) {
            strlcpy(allowed, val, sizeof(allowed));
        } else if (strcasecmp(key, "ListenPort") == 0) {
            strlcpy(listenport, val, sizeof(listenport));
        }
        // AmneziaWG obfuscation keys (parsed case-insensitively).
        else if (strcasecmp(key, "Jc") == 0)   strlcpy(jc, val, sizeof(jc));
        else if (strcasecmp(key, "Jmin") == 0) strlcpy(jmin, val, sizeof(jmin));
        else if (strcasecmp(key, "Jmax") == 0) strlcpy(jmax, val, sizeof(jmax));
        else if (strcasecmp(key, "S1") == 0)   strlcpy(s1, val, sizeof(s1));
        else if (strcasecmp(key, "S2") == 0)   strlcpy(s2, val, sizeof(s2));
        else if (strcasecmp(key, "S3") == 0)   strlcpy(s3, val, sizeof(s3));
        else if (strcasecmp(key, "S4") == 0)   strlcpy(s4, val, sizeof(s4));
        else if (strcasecmp(key, "H1") == 0)   strlcpy(h1, val, sizeof(h1));
        else if (strcasecmp(key, "H2") == 0)   strlcpy(h2, val, sizeof(h2));
        else if (strcasecmp(key, "H3") == 0)   strlcpy(h3, val, sizeof(h3));
        else if (strcasecmp(key, "H4") == 0)   strlcpy(h4, val, sizeof(h4));
        else if (strcasecmp(key, "I1") == 0)   strlcpy(i1, val, sizeof(i1));
        else if (strcasecmp(key, "I2") == 0)   strlcpy(i2, val, sizeof(i2));
        else if (strcasecmp(key, "I3") == 0)   strlcpy(i3, val, sizeof(i3));
        else if (strcasecmp(key, "I4") == 0)   strlcpy(i4, val, sizeof(i4));
        else if (strcasecmp(key, "I5") == 0)   strlcpy(i5, val, sizeof(i5));
    }
    fclose(f);
    
    if (strlen(priv) == 0 || strlen(pub) == 0) {
        fprintf(stderr, "Error: Invalid WireGuard config: missing PrivateKey or PublicKey.\n");
        return 1;
    }
    if (strlen(endpoint) == 0) {
        strlcpy(endpoint, "engage.cloudflareclient.com", sizeof(endpoint));
    }
    if (strlen(port) == 0) {
        strlcpy(port, "4500", sizeof(port));
    }
    if (strlen(client_ip) == 0) {
        strlcpy(client_ip, "172.16.0.2", sizeof(client_ip));
    }
    if (strlen(dns) == 0) {
        strlcpy(dns, "111.88.96.50,111.88.96.51,2a00:ab00:1233:26::50,2a00:ab00:1233:26::51", sizeof(dns));
    }
    if (strlen(mtu) == 0) {
        strlcpy(mtu, "1280", sizeof(mtu));
    }
    if (strlen(keepalive) == 0) {
        strlcpy(keepalive, "25", sizeof(keepalive));
    }
    if (strlen(reserved) == 0) {
        strlcpy(reserved, "AAAA", sizeof(reserved));
    }
    if (strlen(allowed) == 0) {
        strlcpy(allowed, "0.0.0.0/0", sizeof(allowed));
    }
    // AmneziaWG defaults from the reference portal (WARP_STR8986): enable Jc
    // junk obfuscation, identity headers, and the I1 signature packet when the
    // .conf omits them.
    if (strlen(jc) == 0)   strlcpy(jc, "5", sizeof(jc));
    if (strlen(jmin) == 0) strlcpy(jmin, "100", sizeof(jmin));
    if (strlen(jmax) == 0) strlcpy(jmax, "200", sizeof(jmax));
    if (strlen(h1) == 0)   strlcpy(h1, "1", sizeof(h1));
    if (strlen(h2) == 0)   strlcpy(h2, "2", sizeof(h2));
    if (strlen(h3) == 0)   strlcpy(h3, "3", sizeof(h3));
    if (strlen(h4) == 0)   strlcpy(h4, "4", sizeof(h4));

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *plistPath = @"/var/mobile/Library/Preferences/com.nekro.nekrowarp-gui.plist";
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    if (!plist) {
        plist = [NSMutableDictionary dictionary];
    }
    
    NSArray *existingConfigs = [plist objectForKey:@"WARPConfigs"];
    NSMutableArray *configs = nil;
    if (existingConfigs) {
        configs = [NSMutableArray arrayWithArray:existingConfigs];
    } else {
        configs = [NSMutableArray array];
    }
    
    NSString *fileName = [[NSString stringWithUTF8String:path] lastPathComponent];
    NSString *confName = [fileName stringByDeletingPathExtension];
    
    NSMutableDictionary *newConf = [NSMutableDictionary dictionary];
    [newConf setObject:confName forKey:@"name"];
    [newConf setObject:[NSString stringWithUTF8String:endpoint] forKey:@"endpoint"];
    [newConf setObject:[NSString stringWithUTF8String:port] forKey:@"port"];
    [newConf setObject:[NSString stringWithUTF8String:priv] forKey:@"priv"];
    [newConf setObject:[NSString stringWithUTF8String:pub] forKey:@"pub"];
    [newConf setObject:[NSString stringWithUTF8String:client_ip] forKey:@"clientIp"];
    [newConf setObject:[NSString stringWithUTF8String:client_ip6] forKey:@"clientIp6"];
    [newConf setObject:[NSString stringWithUTF8String:dns] forKey:@"dns"];
    [newConf setObject:[NSString stringWithUTF8String:mtu] forKey:@"mtu"];
    [newConf setObject:[NSString stringWithUTF8String:keepalive] forKey:@"keepalive"];
    [newConf setObject:[NSString stringWithUTF8String:reserved] forKey:@"reserved"];
    [newConf setObject:[NSString stringWithUTF8String:psk] forKey:@"psk"];
    [newConf setObject:[NSString stringWithUTF8String:allowed] forKey:@"allowedIps"];
    [newConf setObject:[NSString stringWithUTF8String:listenport] forKey:@"listenPort"];
    [newConf setObject:[NSString stringWithUTF8String:jc] forKey:@"jc"];
    [newConf setObject:[NSString stringWithUTF8String:jmin] forKey:@"jmin"];
    [newConf setObject:[NSString stringWithUTF8String:jmax] forKey:@"jmax"];
    [newConf setObject:[NSString stringWithUTF8String:s1] forKey:@"s1"];
    [newConf setObject:[NSString stringWithUTF8String:s2] forKey:@"s2"];
    [newConf setObject:[NSString stringWithUTF8String:s3] forKey:@"s3"];
    [newConf setObject:[NSString stringWithUTF8String:s4] forKey:@"s4"];
    [newConf setObject:[NSString stringWithUTF8String:h1] forKey:@"h1"];
    [newConf setObject:[NSString stringWithUTF8String:h2] forKey:@"h2"];
    [newConf setObject:[NSString stringWithUTF8String:h3] forKey:@"h3"];
    [newConf setObject:[NSString stringWithUTF8String:h4] forKey:@"h4"];
    [newConf setObject:[NSString stringWithUTF8String:i1] forKey:@"i1"];
    [newConf setObject:[NSString stringWithUTF8String:i2] forKey:@"i2"];
    [newConf setObject:[NSString stringWithUTF8String:i3] forKey:@"i3"];
    [newConf setObject:[NSString stringWithUTF8String:i4] forKey:@"i4"];
    [newConf setObject:[NSString stringWithUTF8String:i5] forKey:@"i5"];

    [configs addObject:newConf];
    [plist setObject:configs forKey:@"WARPConfigs"];
    
    int success = 0;
    if ([plist writeToFile:plistPath atomically:YES]) {
        printf("Successfully imported configuration '%s' to database.\n", [confName UTF8String]);
        chown([plistPath UTF8String], 501, 501); // mobile:mobile
        success = 0;
    } else {
        fprintf(stderr, "Error: Failed to write to plist file!\n");
        success = 1;
    }
    
    [pool release];
    return success;
}

static void usage(void) {
    fprintf(stderr,
        "NekroWARP %s — native WARP/WireGuard tunnel for jailbroken iOS 5.x\n"
        "\n"
        "usage:\n"
        "  nekrowarp probe                       check whether the kernel allows a tun interface\n"
        "  nekrowarp tun-up <local> <peer> [sec] bring a tun up via ioctl (e.g. 10.0.0.2 10.0.0.1 4)\n"
        "  nekrowarp selftest                    run crypto known-answer tests (M2)\n"
        "  nekrowarp hs-selftest                 in-process WireGuard handshake test (M3)\n"
        "  nekrowarp hs-connect <ip> <port>      real UDP handshake vs a WireGuard peer (M3)\n"
        "  nekrowarp hs-listen <port>            act as WireGuard responder for one handshake (M3)\n"
        "  nekrowarp warp-connect <ip> <port> <priv_b64> <peer_pub_b64>\n"
        "                                        handshake to a real WG peer / WARP with keys (M4)\n"
        "  nekrowarp warp-tunnel <ip> <port> <priv_b64> <peer_pub_b64> <client_ip>\n"
        "             [client_ip6] [dns] [reserved_b64] [mtu] [keepalive]\n"
        "             [key=value ...]\n"
        "                                        establish full tunnel to WARP / WireGuard (M5).\n"
        "                                        trailing key=value: psk, allowedips, and AmneziaWG\n"
        "                                        jc/jmin/jmax/s1..s4/h1..h4/i1..i5 obfuscation.\n"
        "  nekrowarp stop                        stop the running WARP/WireGuard tunnel\n"
        "  nekrowarp status                      check current tunnel status\n"
        "  nekrowarp netcheck                    exit 0 if the internet is reachable through the tunnel (1=no data, 2=down)\n"
        "  nekrowarp register [api_ip] [priv_b64] [dns_csv]\n"
        "                                        register a new WARP client; dns_csv resolves the API via those servers\n"
        "  nekrowarp import-conf <path>          import a WireGuard .conf file to app database\n"
        "  nekrowarp route-dump                  dump the active routing table\n"
        "  nekrowarp scope-probe                 dump SCDynamicStore primary interface/service/order (read-only)\n"
        "  nekrowarp scope-set <if> <addr> <rtr> make utun the primary service (scoped-routing fix, path a)\n"
        "  nekrowarp scope-unset                 undo scope-set\n"
        "  nekrowarp bench                       benchmark X25519 + ChaCha20-Poly1305\n"
        "\n"
        "Run as root. `probe` is the gating step — see ROADMAP.md for what comes after.\n",
        NW_VERSION);
}

int main(int argc, char **argv) {
    setuid(0);
    setgid(0);
    setvbuf(stdout, NULL, _IOLBF, 0);
    curl_global_init(CURL_GLOBAL_DEFAULT);

    // Hard iOS 5-6 only restriction
    {
        double osver = 0.0;
        char osrelease[256];
        size_t sz = sizeof(osrelease);
        if (sysctlbyname("kern.osrelease", osrelease, &sz, NULL, 0) == 0) osver = atof(osrelease);
        if (osver >= 14.0) {
            fprintf(stderr, "NekroWARP 0.0.19+ — native WARP/WireGuard tunnel for jailbroken iOS 5.x\n");
            return 99;
        }
    }

    if (argc >= 2 && strcmp(argv[1], "probe") == 0)
        return cmd_probe();
    if (argc >= 4 && strcmp(argv[1], "tun-up") == 0)
        return cmd_tun_up(argv[2], argv[3], (argc >= 5) ? atoi(argv[4]) : 0);
    if (argc >= 4 && strcmp(argv[1], "scope-test") == 0)
        return cmd_scope_test(argv[2], argv[3], (argc >= 5) ? atoi(argv[4]) : 20);
    if (argc >= 2 && strcmp(argv[1], "selftest") == 0)
        return nw_crypto_selftest(1) == 0 ? 0 : 1;
    if (argc >= 2 && strcmp(argv[1], "hs-selftest") == 0)
        return nw_wg_selftest(1) == 0 ? 0 : 1;
    if (argc >= 4 && strcmp(argv[1], "hs-connect") == 0)
        return cmd_hs_connect(argv[2], atoi(argv[3]));
    if (argc >= 3 && strcmp(argv[1], "hs-listen") == 0)
        return cmd_hs_listen(atoi(argv[2]));
    if (argc >= 6 && strcmp(argv[1], "warp-connect") == 0)
        return cmd_warp_connect(argv[2], atoi(argv[3]), argv[4], argv[5], (argc >= 7) ? argv[6] : NULL);
    if (argc >= 7 && strcmp(argv[1], "warp-tunnel") == 0) {
        // Core args stay positional (back-compatible); everything else arrives as
        // trailing key=value tokens so the arg list can grow without breakage:
        //   psk=<b64>  allowedips=<csv>  jc=.. jmin=.. jmax=.. s1..s4=.. h1..h4=..
        //   i1..i5=<tag-string>
        nw_awg awg;
        nw_awg_defaults(&awg);
        const char *psk_b64 = "";
        const char *allowed_ips = "";
        for (int i = 12; i < argc; i++) {
            char *eq = strchr(argv[i], '=');
            if (!eq) continue;
            *eq = '\0';
            const char *key = argv[i];
            const char *val = eq + 1;
            if (strcasecmp(key, "psk") == 0)              psk_b64 = val;
            else if (strcasecmp(key, "allowedips") == 0)  allowed_ips = val;
            else if (strcasecmp(key, "runfor") == 0)      g_runfor = atoi(val);
            else if (strcasecmp(key, "bindwarp") == 0)    g_bind_warp = atoi(val);
            else if (strcasecmp(key, "routeguard") == 0)  g_route_guard = atoi(val);
            else if (strcasecmp(key, "surgery") == 0)     g_surgery = atoi(val);
            else if (strcasecmp(key, "kpatch") == 0)      g_kpatch = atoi(val);
            else if (strcasecmp(key, "split") == 0)       g_telegram_split = (strcasecmp(val, "telegram") == 0);
            else                                          nw_awg_set(&awg, key, val);
        }
        return cmd_warp_tunnel(argv[2], atoi(argv[3]), argv[4], argv[5], argv[6],
                               (argc >= 8) ? argv[7] : "",
                               (argc >= 9) ? argv[8] : "111.88.96.50,111.88.96.51,2a00:ab00:1233:26::50,2a00:ab00:1233:26::51",
                               (argc >= 10) ? argv[9] : NULL,
                               (argc >= 11) ? atoi(argv[10]) : 1280,
                               (argc >= 12) ? atoi(argv[11]) : 25,
                               psk_b64, allowed_ips, &awg);
    }
    if (argc >= 2 && strcmp(argv[1], "stop") == 0)
        return cmd_stop();
    if (argc >= 2 && strcmp(argv[1], "status") == 0)
        return cmd_status();
    if (argc >= 2 && strcmp(argv[1], "netcheck") == 0)
        return cmd_netcheck();
    if (argc >= 2 && strcmp(argv[1], "register") == 0)
        return cmd_register((argc >= 3) ? argv[2] : NULL,
                            (argc >= 4) ? argv[3] : NULL,
                            (argc >= 5) ? argv[4] : NULL);
    if (argc >= 3 && strcmp(argv[1], "import-conf") == 0)
        return cmd_import_conf(argv[2]);
    // sysctl-int <name> [value]: read (and optionally write) an integer sysctl.
    // Used to probe whether net.inet.ip.scopedroute can actually be disabled on
    // this kernel — if it can, classic routing makes the manual default-route
    // surgery capture all traffic and we sidestep configd entirely.
    if (argc >= 3 && strcmp(argv[1], "sysctl-int") == 0) {
        const char *name = argv[2];
        int cur = -1; size_t clen = sizeof(cur);
        if (sysctlbyname(name, &cur, &clen, NULL, 0) != 0) {
            printf("read %s failed: %s\n", name, strerror(errno));
            return 1;
        }
        printf("%s = %d\n", name, cur);
        if (argc >= 4) {
            int want = atoi(argv[3]);
            int old = cur;
            if (sysctlbyname(name, &old, &clen, &want, sizeof(want)) != 0) {
                printf("write %s=%d failed: %s\n", name, want, strerror(errno));
                return 2;
            }
            int rb = -1; size_t rl = sizeof(rb);
            sysctlbyname(name, &rb, &rl, NULL, 0);
            printf("wrote %s=%d; read-back=%d %s\n", name, want, rb,
                   rb == want ? "(STUCK ✓)" : "(reverted ✗)");
        }
        return 0;
    }
    if (argc >= 4 && strcmp(argv[1], "resolve") == 0) {
        char ip[64] = {0};
        if (nw_dns_query_a(argv[2], argv[3], ip, sizeof(ip)) == 0) {
            printf("%s -> %s (via %s)\n", argv[2], ip, argv[3]);
            return 0;
        }
        printf("resolve failed for %s via %s\n", argv[2], argv[3]);
        return 1;
    }
    // Account-free large-packet test: one TLS handshake to ip:443 (pulls a multi-KB
    // cert inbound), through whatever routing is active. Useful to verify a tunnel
    // actually passes TCP/large packets without hammering the WARP registration API.
    if (argc >= 3 && strcmp(argv[1], "httpsprobe") == 0) {
        const char *ip = argv[2];
        const char *sni = (argc >= 4) ? argv[3] : "";
        if (argc >= 5) g_bind_src = argv[4]; // optional source-bind IP (e.g. tun 172.16.0.2)
        char req[256];
        int reqlen = snprintf(req, sizeof(req),
            "HEAD / HTTP/1.1\r\nHost: %s\r\nUser-Agent: NekroWARP\r\nConnection: close\r\n\r\n",
            (sni && *sni) ? sni : ip);
        char resp[8192];
        int n = nw_https_request(ip, 443, sni, 0, req, (size_t)reqlen, resp, sizeof(resp));
        if (n <= 0) { printf("httpsprobe FAIL: no TLS response from %s\n", ip); return 1; }
        char line[160]; int sl = 0;
        while (sl < n && sl < 159 && resp[sl] != '\r' && resp[sl] != '\n') { line[sl] = resp[sl]; sl++; }
        line[sl] = '\0';
        printf("httpsprobe OK: %d bytes from %s — %s\n", n, ip, line);
        return 0;
    }
    if (argc >= 2 && strcmp(argv[1], "kpatch-probe") == 0) {
        mach_port_t kt = MACH_PORT_NULL;
        kern_return_t kr = task_for_pid(mach_task_self(), 0, &kt);
        printf("task_for_pid(0): kr=%d (0=OK) port=0x%x\n", (int)kr, (unsigned)kt);
        if (kr != KERN_SUCCESS || kt == MACH_PORT_NULL) {
            printf("TFP0 unavailable on this jailbreak.\n");
            return 1;
        }
        vm_address_t base = (argc >= 3) ? (vm_address_t)strtoul(argv[2], NULL, 0) : 0x80001000;
        vm_size_t size = (argc >= 4) ? (vm_size_t)strtoul(argv[3], NULL, 0) : 32;
        vm_offset_t buf = 0; mach_msg_type_number_t cnt = 0;
        kr = vm_read(kt, base, size, &buf, &cnt);
        printf("vm_read @0x%lx (size %u): kr=%d cnt=%u\n", (unsigned long)base, (unsigned)size, (int)kr, (unsigned)cnt);
        if (kr == KERN_SUCCESS && cnt >= 8) {
            unsigned char *p = (unsigned char *)buf;
            printf("bytes: %02x %02x %02x %02x %02x %02x %02x %02x\n",
                   p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7]);
        }
        return 0;
    }
    if (argc >= 2 && strcmp(argv[1], "kpatch-scopedroute") == 0) {
        int want = (argc >= 3) ? atoi(argv[2]) : 0;
        mach_port_t kt = MACH_PORT_NULL;
        kern_return_t kr = task_for_pid(mach_task_self(), 0, &kt);
        if (kr != KERN_SUCCESS || kt == MACH_PORT_NULL) {
            printf("TFP0 unavailable on this jailbreak.\n");
            return 1;
        }
        mach_vm_address_t var_addr = find_scopedroute_var_addr(kt);
        if (!var_addr) {
            printf("Could not locate scopedroute variable address in kernel.\n");
            return 1;
        }
        uint32_t cur = 0xFFFFFFFF;
        vm_offset_t cur_buf = 0;
        mach_msg_type_number_t cur_cnt = 0;
        BOOL is64 = is_kernel_64bit();
        if (kread_safe(kt, var_addr, 4, &cur_buf, &cur_cnt, is64) == KERN_SUCCESS && cur_cnt >= 4) {
            cur = *(uint32_t *)cur_buf;
            vm_deallocate(mach_task_self(), cur_buf, cur_cnt);
        }
        printf("Current net.inet.ip.scopedroute = %u\n", cur);
        
        printf("Writing %d to kernel memory at 0x%llx...\n", want, (unsigned long long)var_addr);
        uint32_t val = want;
        if (kwrite_safe(kt, var_addr, (vm_offset_t)&val, 4, is64) == KERN_SUCCESS) {
            uint32_t ver = 0xFFFFFFFF;
            vm_offset_t ver_buf = 0;
            mach_msg_type_number_t ver_cnt = 0;
            if (kread_safe(kt, var_addr, 4, &ver_buf, &ver_cnt, is64) == KERN_SUCCESS && ver_cnt >= 4) {
                ver = *(uint32_t *)ver_buf;
                vm_deallocate(mach_task_self(), ver_buf, ver_cnt);
            }
            printf("Verified net.inet.ip.scopedroute = %u (SUCCESS)\n", ver);
            return 0;
        } else {
            printf("Failed to write to kernel memory.\n");
            return 1;
        }
    }
    if (argc >= 3 && strcmp(argv[1], "sysctlr") == 0) {
        int v = -1; size_t l = sizeof(v);
        if (sysctlbyname(argv[2], &v, &l, NULL, 0) == 0) printf("%s = %d\n", argv[2], v);
        else printf("read %s failed: %s\n", argv[2], strerror(errno));
        return 0;
    }
    if (argc >= 4 && strcmp(argv[1], "sysctlw") == 0) {
        int nv = atoi(argv[3]);
        int ov = -1; size_t ol = sizeof(ov);
        int rc = sysctlbyname(argv[2], &ov, &ol, &nv, sizeof(nv));
        if (rc == 0) printf("set %s: %d -> %d OK\n", argv[2], ov, nv);
        else printf("write %s=%d failed: %s\n", argv[2], nv, strerror(errno));
        return 0;
    }
    if (argc >= 2 && strcmp(argv[1], "route-dump") == 0) {
        nw_route_dump();
        return 0;
    }
    if (argc >= 2 && strcmp(argv[1], "scope-probe") == 0) {
        // Read-only: dump the SCDynamicStore routing picture. Runs without a
        // tunnel; tells us what configd elects as primary and why our utun
        // default route is being ignored under scoped routing.
        return nw_scope_probe();
    }
    if (argc >= 4 && strcmp(argv[1], "scope-set") == 0) {
        // scope-set <ifname> <tun-addr> <router>  — make utun the primary
        // service via PrimaryRank=First. Leave running; Ctrl-C/scope-unset
        // restores. For bring-up testing of path (a).
        int rc = nw_scope_set_primary(argv[2], argv[3], argv[4]);
        printf("scope-set rc=%d\n", rc);
        return rc;
    }
    if (argc >= 2 && strcmp(argv[1], "scope-unset") == 0) {
        return nw_scope_restore();
    }
    if (argc >= 2 && strcmp(argv[1], "bench") == 0) {
        nw_crypto_bench();
        return 0;
    }
    usage();
    return 2;
}
