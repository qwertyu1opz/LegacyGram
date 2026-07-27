#ifndef NW_ROUTE_H
#define NW_ROUTE_H

#include <netinet/in.h>

// Discover the current default IPv4 gateway address.
// Returns 0.0.0.0 on failure or if not found.
struct in_addr nw_route_get_default_gateway(void);

// Add a host route (netmask 255.255.255.255) to a destination via a gateway.
// Returns 0 on success, -1 on failure.
int nw_route_add_host(struct in_addr dst, struct in_addr gateway, unsigned ifindex);

// Add a default route (0.0.0.0/0) via a gateway with a specified MTU.
// Returns 0 on success, -1 on failure.
int nw_route_add_default(struct in_addr gateway, int mtu);

// Delete a default route (0.0.0.0/0) via a gateway.
// Returns 0 on success, -1 on failure.
int nw_route_delete_default(struct in_addr gateway);

// Add/delete a per-interface (scoped) default route via a gateway. ifindex from
// if_nametoindex(). Only sockets bound to that interface follow it, so the
// physical link (en0) keeps a working route to the internet even when the global
// default points at the utun. Returns 0 on success, -1 on failure.
int nw_route_add_default_scoped(struct in_addr gateway, unsigned ifindex, int mtu);
int nw_route_delete_default_scoped(struct in_addr gateway, unsigned ifindex);

// Delete a host route.
// Returns 0 on success, -1 on failure.
int nw_route_delete_host(struct in_addr dst, struct in_addr gateway, unsigned ifindex);

// Add/delete an unscoped IPv4 network route through a gateway.
int nw_route_add_network(struct in_addr dst, struct in_addr mask, struct in_addr gateway, int mtu);
int nw_route_delete_network(struct in_addr dst, struct in_addr mask, struct in_addr gateway);

// Dump all active IPv4 routes to stdout.
void nw_route_dump(void);

// Add a default IPv6 route (::/0) via a gateway.
int nw_route_add_default_v6(const char *gateway_v6, const char *ifname);

// Delete a default IPv6 route (::/0) via a gateway.
int nw_route_delete_default_v6(const char *gateway_v6, const char *ifname);

#endif // NW_ROUTE_H
