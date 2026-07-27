#ifndef NW_SCOPE_H
#define NW_SCOPE_H

// SystemConfiguration / SCDynamicStore based primary-interface override.
//
// Background: on iOS 5 (net.inet.ip.scopedroute=1, and that sysctl is locked
// EPERM), an unbound socket is scoped to whatever interface configd/IPMonitor
// has elected as the *primary* service, NOT to whatever default route we add by
// hand. So a userspace utun + global default route never captures app traffic
// (tun_in stays 0). The non-kernel fix is to make configd elect our utun as the
// primary service, which is exactly what NetworkExtension does internally.
//
// All operations here are reversible (a reboot also fully restores state).

// Read-only: print the current dynamic-store routing picture — primary
// interface/service/router under State:/Network/Global/IPv4, the configured
// ServiceOrder, and any per-service IPv4 state entries. Runs without a tunnel.
// Returns 0 on success, -1 if the store could not be opened.
int nw_scope_probe(void);

// Publish a NekroWARP IPv4 service bound to `ifname` (e.g. "utun1") with the
// given tunnel `addr` and `router`, and assert PrimaryRank=First so IPMonitor
// elects it as the primary service. Saves prior ServiceOrder for restore.
// Returns 0 on success, -1 on failure.
int nw_scope_set_primary(const char *ifname, const char *addr, const char *router);

// Remove the published NekroWARP service and restore the saved ServiceOrder.
// Safe to call even if nw_scope_set_primary was never run. Returns 0/-1.
int nw_scope_restore(void);

// Dynamically set system DNS servers in SCDynamicStore (configd) for Cocoa apps.
int nw_scope_set_dns(const char *dns_servers_csv);

// Restore original system DNS servers in SCDynamicStore (configd).
int nw_scope_restore_dns(void);

#endif // NW_SCOPE_H
