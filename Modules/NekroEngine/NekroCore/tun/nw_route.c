#include "nw_route.h"

#include <sys/param.h>
#include <sys/sysctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>

// Manually define Darwin/BSD routing socket ABI (absent or private in public iOS SDK)
#ifndef RTM_VERSION
#define RTM_VERSION 5
#endif

#ifndef RTM_ADD
#define RTM_ADD 1
#endif

#ifndef RTM_DELETE
#define RTM_DELETE 2
#endif

#ifndef RTF_UP
#define RTF_UP 0x1
#endif

#ifndef RTF_GATEWAY
#define RTF_GATEWAY 0x2
#endif

#ifndef RTF_HOST
#define RTF_HOST 0x4
#endif

#ifndef RTF_STATIC
#define RTF_STATIC 0x800
#endif

// Darwin scoped routing: when set, the kernel scopes this route to the interface
// in rtm_index. Lets us give en0 its own default route that only en0-bound
// sockets (e.g. iOS's per-interface reachability probe) follow, so Wi-Fi keeps
// "internet" even after the global default is repointed at the utun.
#ifndef RTF_IFSCOPE
#define RTF_IFSCOPE 0x1000000
#endif

#ifndef RTA_DST
#define RTA_DST 0x1
#endif

#ifndef RTA_GATEWAY
#define RTA_GATEWAY 0x2
#endif

#ifndef RTA_NETMASK
#define RTA_NETMASK 0x4
#endif

#ifndef RTAX_DST
#define RTAX_DST 0
#endif

#ifndef RTAX_GATEWAY
#define RTAX_GATEWAY 1
#endif

#ifndef RTAX_NETMASK
#define RTAX_NETMASK 2
#endif

#ifndef RTAX_MAX
#define RTAX_MAX 8
#endif

#ifndef NET_RT_FLAGS
#define NET_RT_FLAGS 2
#endif

struct rt_metrics {
    uint32_t rmx_locks;
    uint32_t rmx_mtu;
    uint32_t rmx_hopcount;
    int32_t  rmx_expire;
    uint32_t rmx_recvpipe;
    uint32_t rmx_sendpipe;
    uint32_t rmx_ssthresh;
    uint32_t rmx_rtt;
    uint32_t rmx_rttvar;
    uint32_t rmx_pksent;
    uint32_t rmx_state;
    uint32_t rmx_filler[3];
};

struct rt_msghdr {
    unsigned short rtm_msglen;
    unsigned char  rtm_version;
    unsigned char  rtm_type;
    unsigned short rtm_index;
    int            rtm_flags;
    int            rtm_addrs;
    pid_t          rtm_pid;
    int            rtm_seq;
    int            rtm_errno;
    int            rtm_use;
    uint32_t       rtm_inits;
    struct rt_metrics rtm_rmx;
};

#define ROUNDUP(a) \
    ((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))

struct in_addr nw_route_get_default_gateway(void) {
    struct in_addr gw = {0};
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_GATEWAY};
    size_t l;
    if (sysctl(mib, 6, NULL, &l, NULL, 0) < 0) return gw;
    char *buf = malloc(l);
    if (!buf) return gw;
    if (sysctl(mib, 6, buf, &l, NULL, 0) < 0) {
        free(buf);
        return gw;
    }
    char *lim = buf + l;
    for (char *next = buf; next < lim; ) {
        struct rt_msghdr *rtm = (struct rt_msghdr *)next;
        next += rtm->rtm_msglen;
        if (rtm->rtm_version != RTM_VERSION) continue;
        
        struct sockaddr *sa = (struct sockaddr *)(rtm + 1);
        struct sockaddr_in *dst = NULL;
        struct sockaddr_in *gateway = NULL;
        
        for (int i = 0; i < RTAX_MAX; i++) {
            if (rtm->rtm_addrs & (1 << i)) {
                if (i == RTAX_DST) dst = (struct sockaddr_in *)sa;
                if (i == RTAX_GATEWAY) gateway = (struct sockaddr_in *)sa;
                sa = (struct sockaddr *)((char *)sa + ROUNDUP(sa->sa_len));
            }
        }
        
        if (dst && dst->sin_addr.s_addr == INADDR_ANY && gateway && gateway->sin_family == AF_INET) {
            gw = gateway->sin_addr;
            break;
        }
    }
    free(buf);
    return gw;
}

// ifscope: when nonzero, scope the route to that interface index (RTF_IFSCOPE).
static int nw_route_send(int op, int flags, struct in_addr dst, struct in_addr mask, struct in_addr gateway, unsigned ifscope, int mtu) {
    int s = socket(PF_ROUTE, SOCK_RAW, AF_UNSPEC);
    if (s < 0) return -1;

    struct {
        struct rt_msghdr hdr;
        char buf[256];
    } msg;

    memset(&msg, 0, sizeof(msg));
    msg.hdr.rtm_version = RTM_VERSION;
    msg.hdr.rtm_type = op; // RTM_ADD, RTM_DELETE
    msg.hdr.rtm_flags = flags | RTF_UP | RTF_STATIC;
    if (ifscope) {
        msg.hdr.rtm_flags |= RTF_IFSCOPE;
        msg.hdr.rtm_index = (unsigned short)ifscope;
    }
    if (mtu > 0) {
        msg.hdr.rtm_inits |= 0x1; // RTV_MTU = 0x1
        msg.hdr.rtm_rmx.rmx_mtu = (uint32_t)mtu;
    }
    msg.hdr.rtm_addrs = RTA_DST | RTA_GATEWAY | RTA_NETMASK;
    msg.hdr.rtm_seq = 4321;

    char *p = msg.buf;

    // DST
    struct sockaddr_in sa_dst;
    memset(&sa_dst, 0, sizeof(sa_dst));
    sa_dst.sin_len = sizeof(sa_dst);
    sa_dst.sin_family = AF_INET;
    sa_dst.sin_addr = dst;
    memcpy(p, &sa_dst, sizeof(sa_dst));
    p += ROUNDUP(sizeof(sa_dst));

    // GATEWAY
    struct sockaddr_in sa_gw;
    memset(&sa_gw, 0, sizeof(sa_gw));
    sa_gw.sin_len = sizeof(sa_gw);
    sa_gw.sin_family = AF_INET;
    sa_gw.sin_addr = gateway;
    memcpy(p, &sa_gw, sizeof(sa_gw));
    p += ROUNDUP(sizeof(sa_gw));

    // NETMASK
    struct sockaddr_in sa_mask;
    memset(&sa_mask, 0, sizeof(sa_mask));
    sa_mask.sin_len = sizeof(sa_mask);
    sa_mask.sin_family = AF_UNSPEC;
    sa_mask.sin_addr = mask;
    memcpy(p, &sa_mask, sizeof(sa_mask));
    p += ROUNDUP(sizeof(sa_mask));

    msg.hdr.rtm_msglen = p - (char *)&msg;

    ssize_t n = write(s, &msg, msg.hdr.rtm_msglen);
    int err = errno;
    close(s);

    if (n < 0) {
        errno = err;
        return -1;
    }
    return 0;
}

int nw_route_add_host(struct in_addr dst, struct in_addr gateway, unsigned ifindex) {
    struct in_addr mask;
    mask.s_addr = 0xffffffff;
    return nw_route_send(RTM_ADD, RTF_HOST | RTF_GATEWAY, dst, mask, gateway, ifindex, 0);
}

int nw_route_delete_host(struct in_addr dst, struct in_addr gateway, unsigned ifindex) {
    struct in_addr mask;
    mask.s_addr = 0xffffffff;
    return nw_route_send(RTM_DELETE, RTF_HOST | RTF_GATEWAY, dst, mask, gateway, ifindex, 0);
}

int nw_route_add_network(struct in_addr dst, struct in_addr mask, struct in_addr gateway, int mtu) {
    return nw_route_send(RTM_ADD, RTF_GATEWAY, dst, mask, gateway, 0, mtu);
}

int nw_route_delete_network(struct in_addr dst, struct in_addr mask, struct in_addr gateway) {
    return nw_route_send(RTM_DELETE, RTF_GATEWAY, dst, mask, gateway, 0, 0);
}

int nw_route_add_default(struct in_addr gateway, int mtu) {
    struct in_addr dst = {0};
    struct in_addr mask = {0};
    return nw_route_send(RTM_ADD, RTF_GATEWAY, dst, mask, gateway, 0, mtu);
}

int nw_route_delete_default(struct in_addr gateway) {
    struct in_addr dst = {0};
    struct in_addr mask = {0};
    return nw_route_send(RTM_DELETE, RTF_GATEWAY, dst, mask, gateway, 0, 0);
}

// Per-interface (scoped) default route. ifindex comes from if_nametoindex().
int nw_route_add_default_scoped(struct in_addr gateway, unsigned ifindex, int mtu) {
    struct in_addr dst = {0};
    struct in_addr mask = {0};
    return nw_route_send(RTM_ADD, RTF_GATEWAY, dst, mask, gateway, ifindex, mtu);
}

int nw_route_delete_default_scoped(struct in_addr gateway, unsigned ifindex) {
    struct in_addr dst = {0};
    struct in_addr mask = {0};
    return nw_route_send(RTM_DELETE, RTF_GATEWAY, dst, mask, gateway, ifindex, 0);
}

void nw_route_dump(void) {
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_DUMP, 0};
    size_t l;
    if (sysctl(mib, 6, NULL, &l, NULL, 0) < 0) {
        perror("sysctl size");
        return;
    }
    char *buf = malloc(l);
    if (!buf) return;
    if (sysctl(mib, 6, buf, &l, NULL, 0) < 0) {
        perror("sysctl dump");
        free(buf);
        return;
    }
    printf("Routing Table:\n");
    printf("%-18s %-18s %-10s %-6s\n", "Destination", "Gateway", "Flags", "IfIdx");
    
    char *lim = buf + l;
    for (char *next = buf; next < lim; ) {
        struct rt_msghdr *rtm = (struct rt_msghdr *)next;
        next += rtm->rtm_msglen;
        if (rtm->rtm_version != RTM_VERSION) continue;
        
        struct sockaddr *sa = (struct sockaddr *)(rtm + 1);
        struct sockaddr_in *dst = NULL;
        struct sockaddr_in *gateway = NULL;
        
        for (int i = 0; i < RTAX_MAX; i++) {
            if (rtm->rtm_addrs & (1 << i)) {
                if (i == RTAX_DST) dst = (struct sockaddr_in *)sa;
                if (i == RTAX_GATEWAY) gateway = (struct sockaddr_in *)sa;
                sa = (struct sockaddr *)((char *)sa + ROUNDUP(sa->sa_len));
            }
        }
        
        char dst_str[32] = "default";
        char gw_str[32] = "*";
        
        if (dst && dst->sin_addr.s_addr != INADDR_ANY) {
            snprintf(dst_str, sizeof(dst_str), "%s", inet_ntoa(dst->sin_addr));
        }
        if (gateway && gateway->sin_family == AF_INET) {
            snprintf(gw_str, sizeof(gw_str), "%s", inet_ntoa(gateway->sin_addr));
        } else if (gateway && gateway->sin_family == 18) { // AF_LINK = 18 on Darwin
            snprintf(gw_str, sizeof(gw_str), "link");
        } else if (gateway) {
            snprintf(gw_str, sizeof(gw_str), "fam:%d", gateway->sin_family);
        }
        
        printf("%-18s %-18s 0x%-8x %-6d\n", dst_str, gw_str, rtm->rtm_flags, rtm->rtm_index);
    }
    free(buf);
}

static int nw_route_send_v6(int op, int flags, struct in6_addr dst, int prefix_len, struct in6_addr gateway, const char *ifname) {
    int s = socket(PF_ROUTE, SOCK_RAW, AF_UNSPEC);
    if (s < 0) return -1;

    struct {
        struct rt_msghdr hdr;
        char buf[512];
    } msg;

    memset(&msg, 0, sizeof(msg));
    msg.hdr.rtm_version = RTM_VERSION;
    msg.hdr.rtm_type = op; // RTM_ADD, RTM_DELETE
    msg.hdr.rtm_flags = flags | RTF_UP | RTF_STATIC;
    msg.hdr.rtm_addrs = RTA_DST | RTA_GATEWAY | RTA_NETMASK;
    msg.hdr.rtm_seq = 4322;

    char *p = msg.buf;

    // DST (sockaddr_in6)
    struct sockaddr_in6 sa_dst;
    memset(&sa_dst, 0, sizeof(sa_dst));
    sa_dst.sin6_len = sizeof(sa_dst);
    sa_dst.sin6_family = AF_INET6;
    sa_dst.sin6_addr = dst;
    memcpy(p, &sa_dst, sizeof(sa_dst));
    p += ROUNDUP(sizeof(sa_dst));

    // GATEWAY (sockaddr_dl for interface route, or sockaddr_in6)
    if (ifname && strlen(ifname) > 0 && IN6_IS_ADDR_UNSPECIFIED(&gateway)) {
        struct sockaddr_dl sa_gw_dl;
        memset(&sa_gw_dl, 0, sizeof(sa_gw_dl));
        sa_gw_dl.sdl_len = sizeof(sa_gw_dl);
        sa_gw_dl.sdl_family = AF_LINK;
        sa_gw_dl.sdl_index = if_nametoindex(ifname);
        memcpy(p, &sa_gw_dl, sizeof(sa_gw_dl));
        p += ROUNDUP(sizeof(sa_gw_dl));
    } else {
        struct sockaddr_in6 sa_gw;
        memset(&sa_gw, 0, sizeof(sa_gw));
        sa_gw.sin6_len = sizeof(sa_gw);
        sa_gw.sin6_family = AF_INET6;
        sa_gw.sin6_addr = gateway;
        if (ifname && strlen(ifname) > 0) {
            sa_gw.sin6_scope_id = if_nametoindex(ifname);
        }
        memcpy(p, &sa_gw, sizeof(sa_gw));
        p += ROUNDUP(sizeof(sa_gw));
    }

    // NETMASK (sockaddr_in6)
    struct sockaddr_in6 sa_mask;
    memset(&sa_mask, 0, sizeof(sa_mask));
    sa_mask.sin6_len = sizeof(sa_mask);
    sa_mask.sin6_family = AF_INET6;
    
    for (int i = 0; i < prefix_len / 8; i++) {
        sa_mask.sin6_addr.s6_addr[i] = 0xff;
    }
    if (prefix_len % 8) {
        sa_mask.sin6_addr.s6_addr[prefix_len / 8] = (0xff << (8 - (prefix_len % 8))) & 0xff;
    }
    
    memcpy(p, &sa_mask, sizeof(sa_mask));
    p += ROUNDUP(sizeof(sa_mask));

    msg.hdr.rtm_msglen = p - (char *)&msg;

    ssize_t n = write(s, &msg, msg.hdr.rtm_msglen);
    int err = errno;
    close(s);

    if (n < 0) {
        errno = err;
        return -1;
    }
    return 0;
}

int nw_route_add_default_v6(const char *gateway_v6, const char *ifname) {
    struct in6_addr dst;
    memset(&dst, 0, sizeof(dst)); // ::/0
    
    struct in6_addr gw;
    if (inet_pton(AF_INET6, gateway_v6, &gw) != 1) return -1;
    
    return nw_route_send_v6(RTM_ADD, RTF_GATEWAY, dst, 0, gw, ifname);
}

int nw_route_delete_default_v6(const char *gateway_v6, const char *ifname) {
    struct in6_addr dst;
    memset(&dst, 0, sizeof(dst)); // ::/0
    
    struct in6_addr gw;
    if (inet_pton(AF_INET6, gateway_v6, &gw) != 1) return -1;
    
    return nw_route_send_v6(RTM_DELETE, RTF_GATEWAY, dst, 0, gw, ifname);
}
