#include "nw_tun.h"

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/sockio.h>         // SIOCAIFADDR, SIOCSIFFLAGS, SIOC*IFADDR
#include <net/if.h>             // struct ifreq, struct ifaliasreq, IFF_*
#include <netinet/in.h>
#include <arpa/inet.h>
struct in6_addrlifetime {
    time_t ia6t_expire;
    time_t ia6t_preferred;
    u_int32_t ia6t_vltime;
    u_int32_t ia6t_pltime;
};

struct in6_aliasreq {
    char    ifra_name[IFNAMSIZ];
    struct  sockaddr_in6 ifra_addr;
    struct  sockaddr_in6 ifra_dstaddr;
    struct  sockaddr_in6 ifra_prefixmask;
    int     ifra_flags;
    struct  in6_addrlifetime ifra_lifetime;
};

#ifndef ND6_INFINITE_LIFETIME
#define ND6_INFINITE_LIFETIME 0xffffffff
#endif

#ifndef SIOCAIFADDR_IN6
#define SIOCAIFADDR_IN6 _IOW('i', 26, struct in6_aliasreq)
#endif

// The iOS 5 SDK ships neither <sys/kern_control.h> nor <sys/sys_domain.h>, so we
// declare the kernel-control ABI ourselves. These layouts/values are stable in
// XNU (used by utun since its introduction) — the struct sizes must match the
// kernel exactly because CTLIOCGINFO encodes sizeof() into the ioctl number.

#ifndef PF_SYSTEM
#define PF_SYSTEM 32
#endif
#ifndef AF_SYSTEM
#define AF_SYSTEM 32
#endif
#ifndef SYSPROTO_CONTROL
#define SYSPROTO_CONTROL 2
#endif
#ifndef AF_SYS_CONTROL
#define AF_SYS_CONTROL 2
#endif

#define NW_MAX_KCTL_NAME 96

struct nw_ctl_info {
    u_int32_t ctl_id;
    char      ctl_name[NW_MAX_KCTL_NAME];
};

struct nw_sockaddr_ctl {
    u_char    sc_len;
    u_char    sc_family;     // AF_SYSTEM
    u_int16_t ss_sysaddr;    // AF_SYS_CONTROL
    u_int32_t sc_id;
    u_int32_t sc_unit;
    u_int32_t sc_reserved[5];
};

#define NW_CTLIOCGINFO _IOWR('N', 3, struct nw_ctl_info)

// From the private <net/if_utun.h> (absent from the iOS SDK).
#define NW_UTUN_CONTROL_NAME "com.apple.net.utun_control"
#define NW_UTUN_OPT_IFNAME   2

int nw_tun_open_utun(char *ifname, size_t cap) {
    int fd = socket(PF_SYSTEM, SOCK_DGRAM, SYSPROTO_CONTROL);
    if (fd < 0) return -1;

    struct nw_ctl_info ci;
    memset(&ci, 0, sizeof(ci));
    strlcpy(ci.ctl_name, NW_UTUN_CONTROL_NAME, sizeof(ci.ctl_name));
    if (ioctl(fd, NW_CTLIOCGINFO, &ci) < 0) { int e = errno; close(fd); errno = e; return -1; }

    struct nw_sockaddr_ctl sc;
    memset(&sc, 0, sizeof(sc));
    sc.sc_len     = sizeof(sc);
    sc.sc_family  = AF_SYSTEM;
    sc.ss_sysaddr = AF_SYS_CONTROL;
    sc.sc_id      = ci.ctl_id;
    sc.sc_unit    = 0;   // 0 => kernel assigns the next free utun unit

    if (connect(fd, (struct sockaddr *)&sc, sizeof(sc)) < 0) {
        int e = errno; close(fd); errno = e; return -1;
    }

    if (ifname && cap) {
        socklen_t len = (socklen_t)cap;
        if (getsockopt(fd, SYSPROTO_CONTROL, NW_UTUN_OPT_IFNAME, ifname, &len) < 0)
            strlcpy(ifname, "utun?", cap);
    }
    return fd;
}

int nw_tun_open_dev(char *ifname, size_t cap) {
    for (int i = 0; i < 16; i++) {
        char path[32];
        snprintf(path, sizeof(path), "/dev/tun%d", i);
        int fd = open(path, O_RDWR);
        if (fd >= 0) {
            if (ifname && cap) snprintf(ifname, cap, "tun%d", i);
            return fd;
        }
    }
    return -1;
}

static void nw_set_sin(struct sockaddr *sa, const char *ip) {
    struct sockaddr_in *sin = (struct sockaddr_in *)sa;
    sin->sin_len = sizeof(*sin);
    sin->sin_family = AF_INET;
    inet_aton(ip, &sin->sin_addr);
}

int nw_tun_set_ipv4(const char *ifname, const char *local, const char *peer) {
    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) return -1;

    struct ifaliasreq ifra;
    memset(&ifra, 0, sizeof(ifra));
    strlcpy(ifra.ifra_name, ifname, sizeof(ifra.ifra_name));
    nw_set_sin(&ifra.ifra_addr, local);        // our address
    nw_set_sin(&ifra.ifra_broadaddr, peer);    // PTP destination (dstaddr)
    nw_set_sin(&ifra.ifra_mask, "255.255.255.255");

    if (ioctl(s, SIOCAIFADDR, &ifra) < 0) { int e = errno; close(s); errno = e; return -1; }

    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));
    strlcpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name));
    if (ioctl(s, SIOCGIFFLAGS, &ifr) >= 0) {
        ifr.ifr_flags |= (IFF_UP | IFF_RUNNING);
        ioctl(s, SIOCSIFFLAGS, &ifr);
    }
    close(s);
    return 0;
}

int nw_tun_set_mtu(const char *ifname, int mtu) {
    if (mtu <= 0) return 0;
    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) return -1;

    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));
    strlcpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name));
    ifr.ifr_mtu = mtu;
    if (ioctl(s, SIOCSIFMTU, &ifr) < 0) { int e = errno; close(s); errno = e; return -1; }
    close(s);
    return 0;
}

int nw_tun_report(const char *ifname) {
    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) return -1;

    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));
    strlcpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name));
    if (ioctl(s, SIOCGIFFLAGS, &ifr) == 0) {
        int fl = ifr.ifr_flags & 0xffff;
        printf("  flags=0x%x %s%s\n", (unsigned)fl,
               (fl & IFF_UP) ? "UP " : "", (fl & IFF_RUNNING) ? "RUNNING" : "");
    }
    memset(&ifr, 0, sizeof(ifr));
    strlcpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name));
    ifr.ifr_addr.sa_family = AF_INET;
    if (ioctl(s, SIOCGIFADDR, &ifr) == 0)
        printf("  inet %s\n", inet_ntoa(((struct sockaddr_in *)&ifr.ifr_addr)->sin_addr));

    memset(&ifr, 0, sizeof(ifr));
    strlcpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name));
    ifr.ifr_addr.sa_family = AF_INET;
    if (ioctl(s, SIOCGIFDSTADDR, &ifr) == 0)
        printf("  --> %s (peer)\n", inet_ntoa(((struct sockaddr_in *)&ifr.ifr_dstaddr)->sin_addr));

    close(s);
    return 0;
}

int nw_tun_set_ipv6(const char *ifname, const char *local_ip6) {
    int s = socket(AF_INET6, SOCK_DGRAM, 0);
    if (s < 0) return -1;

    struct in6_aliasreq ifra6;
    memset(&ifra6, 0, sizeof(ifra6));
    strlcpy(ifra6.ifra_name, ifname, sizeof(ifra6.ifra_name));

    ifra6.ifra_addr.sin6_len = sizeof(struct sockaddr_in6);
    ifra6.ifra_addr.sin6_family = AF_INET6;
    if (inet_pton(AF_INET6, local_ip6, &ifra6.ifra_addr.sin6_addr) != 1) {
        int e = errno; close(s); errno = e; return -1;
    }

    ifra6.ifra_prefixmask.sin6_len = sizeof(struct sockaddr_in6);
    ifra6.ifra_prefixmask.sin6_family = AF_INET6;
    memset(&ifra6.ifra_prefixmask.sin6_addr, 0xff, sizeof(struct in6_addr));

    ifra6.ifra_lifetime.ia6t_vltime = ND6_INFINITE_LIFETIME;
    ifra6.ifra_lifetime.ia6t_pltime = ND6_INFINITE_LIFETIME;

    if (ioctl(s, SIOCAIFADDR_IN6, &ifra6) < 0) {
        int e = errno; close(s); errno = e; return -1;
    }

    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));
    strlcpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name));
    if (ioctl(s, SIOCGIFFLAGS, &ifr) >= 0) {
        ifr.ifr_flags |= (IFF_UP | IFF_RUNNING);
        ioctl(s, SIOCSIFFLAGS, &ifr);
    }

    close(s);
    return 0;
}
