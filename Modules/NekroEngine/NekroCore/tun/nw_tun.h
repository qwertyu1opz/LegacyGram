#ifndef NW_TUN_H
#define NW_TUN_H

#include <stddef.h>

// Layer-3 tunnel interface plumbing. Two routes on a jailbroken iOS 5 device:
//
//   1. utun  — the in-kernel control "com.apple.net.utun_control" (introduced
//              around 2011 / iOS 5 era). No third-party kext, but the connect()
//              may be entitlement/permission gated — that's what the probe finds out.
//   2. tun.kext — the classic /dev/tunN character devices that jailbreak OpenVPN
//              used. Needs the "tun" kext loaded, but has no entitlement check.
//
// Both return an open fd (>= 0) on success and write the interface name
// (e.g. "utun0" / "tun0") into ifname. Return -1 on failure (errno is set).

int nw_tun_open_utun(char *ifname, size_t cap);
int nw_tun_open_dev(char *ifname, size_t cap);

// Configure a point-to-point IPv4 address on the interface and bring it UP,
// entirely via ioctl (SIOCAIFADDR / SIOCSIFFLAGS) — the device userland has no
// ifconfig, so the product must do this itself. Returns 0 on success, -1/errno.
int nw_tun_set_ipv4(const char *ifname, const char *local, const char *peer);

// Configure an IPv6 address on the interface and bring it UP,
// entirely via ioctl (SIOCAIFADDR_IN6 / SIOCSIFFLAGS). Returns 0 on success, -1/errno.
int nw_tun_set_ipv6(const char *ifname, const char *local_ip6);

// Set the interface MTU (SIOCSIFMTU). WARP wants ~1280 so the WG-encapsulated
// UDP stays under the path MTU. Returns 0 on success, -1/errno on failure.
int nw_tun_set_mtu(const char *ifname, int mtu);

// Print the interface's flags / inet / peer address back via ioctl (so we can
// confirm config without any external tools). Returns 0 on success.
int nw_tun_report(const char *ifname);

#endif // NW_TUN_H
