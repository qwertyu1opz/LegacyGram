#include "nw_scope.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <CoreFoundation/CoreFoundation.h>

// The entire SCDynamicStore API is marked __IPHONE_NA in the iOS SDK headers
// (Apple hides it from App Store apps), so <SystemConfiguration/...> refuses to
// compile against it. The symbols ARE exported by the on-device framework —
// configd itself uses them — and we are a jailbreak root tool, not App Store.
// So we declare the ABI ourselves and link -framework SystemConfiguration.
typedef const struct __SCDynamicStore *SCDynamicStoreRef;
typedef struct {
    CFIndex      version;
    void        *info;
    const void *(*retain)(const void *info);
    void        (*release)(const void *info);
    CFStringRef (*copyDescription)(const void *info);
} SCDynamicStoreContext;
typedef void (*SCDynamicStoreCallBack)(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info);

extern SCDynamicStoreRef SCDynamicStoreCreate(CFAllocatorRef allocator, CFStringRef name,
                              SCDynamicStoreCallBack callout, SCDynamicStoreContext *context);
extern CFPropertyListRef SCDynamicStoreCopyValue(SCDynamicStoreRef store, CFStringRef key);
extern CFArrayRef        SCDynamicStoreCopyKeyList(SCDynamicStoreRef store, CFStringRef pattern);
extern Boolean           SCDynamicStoreSetValue(SCDynamicStoreRef store, CFStringRef key, CFPropertyListRef value);
extern Boolean           SCDynamicStoreRemoveValue(SCDynamicStoreRef store, CFStringRef key);

// Schema key strings (the kSCProp* macros are also __IPHONE_NA). These are the
// exact string values those macros expand to.
#define NW_kAddresses    CFSTR("Addresses")
#define NW_kSubnetMasks  CFSTR("SubnetMasks")
#define NW_kRouter       CFSTR("Router")
#define NW_kInterfaceName CFSTR("InterfaceName")
#define NW_kServiceOrder CFSTR("ServiceOrder")

// Our injected service id. IPMonitor keys services by UUID (the real Wi-Fi
// service is e.g. 15A2A2BD-DFCE-49D4-8F90-BC49E2397041), so we use a UUID-shaped
// id too; a non-UUID name ("NekroWARP") is ignored by the primary election.
#define NW_SERVICE_ID "00000000-0000-0000-0000-00004E454B52"  /* ...NEKR */

// A pre-UUID build registered the service under this plain string id. configd
// ignores it for primary election, but it still litters ServiceOrder and the
// per-service state, so we strip it everywhere we touch the store.
#define NW_LEGACY_ID  "NekroWARP"

// ---- small helpers --------------------------------------------------------

static CFStringRef cstr(const char *s) {
    return CFStringCreateWithCString(NULL, s, kCFStringEncodingUTF8);
}

// Remove EVERY occurrence of string `val` from mutable array `arr` (not just the
// first). Returns how many were dropped. Used to keep our id from piling up in
// ServiceOrder across runs that died before restore.
static int array_remove_all(CFMutableArrayRef arr, CFStringRef val) {
    int removed = 0;
    CFIndex i = 0;
    while (i < CFArrayGetCount(arr)) {
        const void *e = CFArrayGetValueAtIndex(arr, i);
        if (CFGetTypeID(e) == CFStringGetTypeID() && CFEqual((CFStringRef)e, val)) {
            CFArrayRemoveValueAtIndex(arr, i);
            removed++;
        } else {
            i++;
        }
    }
    return removed;
}

// Recursive, stdout, human-readable plist dump for the probe.
static void print_plist(CFTypeRef v, int indent) {
    char pad[64];
    int n = indent * 2; if (n > 62) n = 62;
    memset(pad, ' ', n); pad[n] = '\0';

    if (v == NULL) { printf("%s(null)\n", pad); return; }
    CFTypeID t = CFGetTypeID(v);

    if (t == CFStringGetTypeID()) {
        char buf[512];
        if (CFStringGetCString((CFStringRef)v, buf, sizeof(buf), kCFStringEncodingUTF8))
            printf("%s\"%s\"\n", pad, buf);
        else
            printf("%s<string>\n", pad);
    } else if (t == CFNumberGetTypeID()) {
        long long ll = 0; CFNumberGetValue((CFNumberRef)v, kCFNumberLongLongType, &ll);
        printf("%s%lld\n", pad, ll);
    } else if (t == CFBooleanGetTypeID()) {
        printf("%s%s\n", pad, CFBooleanGetValue((CFBooleanRef)v) ? "true" : "false");
    } else if (t == CFArrayGetTypeID()) {
        CFIndex c = CFArrayGetCount((CFArrayRef)v);
        printf("%s[%ld]\n", pad, (long)c);
        for (CFIndex i = 0; i < c; i++)
            print_plist(CFArrayGetValueAtIndex((CFArrayRef)v, i), indent + 1);
    } else if (t == CFDictionaryGetTypeID()) {
        CFIndex c = CFDictionaryGetCount((CFDictionaryRef)v);
        const void **ks = malloc(sizeof(void*) * c);
        const void **vs = malloc(sizeof(void*) * c);
        CFDictionaryGetKeysAndValues((CFDictionaryRef)v, ks, vs);
        printf("%s{%ld}\n", pad, (long)c);
        for (CFIndex i = 0; i < c; i++) {
            char kb[256];
            if (CFGetTypeID(ks[i]) == CFStringGetTypeID() &&
                CFStringGetCString((CFStringRef)ks[i], kb, sizeof(kb), kCFStringEncodingUTF8))
                printf("%s  %s:\n", pad, kb);
            else
                printf("%s  <key>:\n", pad);
            print_plist(vs[i], indent + 2);
        }
        free(ks); free(vs);
    } else {
        printf("%s<type %lu>\n", pad, (unsigned long)t);
    }
}

static void dump_key(SCDynamicStoreRef store, const char *key) {
    printf("=== %s ===\n", key);
    CFStringRef k = cstr(key);
    CFPropertyListRef v = SCDynamicStoreCopyValue(store, k);
    if (v) { print_plist(v, 1); CFRelease(v); }
    else   { printf("  (absent)\n"); }
    CFRelease(k);
}

// ---- public API -----------------------------------------------------------

int nw_scope_probe(void) {
    SCDynamicStoreRef store = SCDynamicStoreCreate(NULL, CFSTR("NekroWARP"), NULL, NULL);
    if (!store) { fprintf(stderr, "SCDynamicStoreCreate failed\n"); return -1; }

    dump_key(store, "State:/Network/Global/IPv4");
    dump_key(store, "Setup:/Network/Global/IPv4");
    dump_key(store, "State:/Network/Global/DNS");

    // Enumerate every per-service IPv4 state so we can see what configd sees.
    CFStringRef pat = CFSTR("State:/Network/Service/[^/]+/IPv4");
    CFArrayRef keys = SCDynamicStoreCopyKeyList(store, pat);
    if (keys) {
        CFIndex c = CFArrayGetCount(keys);
        printf("=== service IPv4 states (%ld) ===\n", (long)c);
        for (CFIndex i = 0; i < c; i++) {
            char kb[256];
            CFStringRef k = (CFStringRef)CFArrayGetValueAtIndex(keys, i);
            if (CFStringGetCString(k, kb, sizeof(kb), kCFStringEncodingUTF8))
                dump_key(store, kb);
        }
        CFRelease(keys);
    }

    CFRelease(store);
    return 0;
}

int nw_scope_set_primary(const char *ifname, const char *addr, const char *router) {
    SCDynamicStoreRef store = SCDynamicStoreCreate(NULL, CFSTR("NekroWARP"), NULL, NULL);
    if (!store) { fprintf(stderr, "SCDynamicStoreCreate failed\n"); return -1; }

    int rc = -1;
    CFStringRef cf_if   = cstr(ifname);
    CFStringRef cf_addr = cstr(addr);
    CFStringRef cf_rtr  = cstr(router);
    // /24 so the WARP gateway (e.g. 172.16.0.1) is on-link for the default
    // route IPMonitor installs; a /32 would leave the router unreachable.
    CFStringRef mask    = CFSTR("255.255.255.0");

    CFStringRef addrs[1] = { cf_addr };
    CFStringRef masks[1] = { mask };
    CFArrayRef  cf_addrs = CFArrayCreate(NULL, (const void**)addrs, 1, &kCFTypeArrayCallBacks);
    CFArrayRef  cf_masks = CFArrayCreate(NULL, (const void**)masks, 1, &kCFTypeArrayCallBacks);

    // Build State:/Network/Service/NekroWARP/IPv4 with PrimaryRank=First so
    // IPMonitor elects this service ahead of Wi-Fi/cellular.
    const void *ipk[] = { NW_kAddresses, NW_kSubnetMasks,
                          NW_kRouter,    NW_kInterfaceName,
                          CFSTR("PrimaryRank") };
    const void *ipv[] = { cf_addrs, cf_masks, cf_rtr, cf_if, CFSTR("First") };
    CFDictionaryRef ip4 = CFDictionaryCreate(NULL, ipk, ipv, 5,
                              &kCFTypeDictionaryKeyCallBacks,
                              &kCFTypeDictionaryValueCallBacks);

    // Drop the legacy string-id service first so it can't shadow or duplicate us.
    SCDynamicStoreRemoveValue(store, CFSTR("State:/Network/Service/" NW_LEGACY_ID "/IPv4"));

    CFStringRef svc_ip4_key = cstr("State:/Network/Service/" NW_SERVICE_ID "/IPv4");
    Boolean ok1 = SCDynamicStoreSetValue(store, svc_ip4_key, ip4);

    // IPMonitor installs a service's DEFAULT ROUTE only if the service has a full
    // Setup CONFIG (ConfigMethod), not just State. A State-only service becomes
    // "PrimaryInterface" in the UI but IPMonitor keeps routing the default via en0
    // (its DHCP service), which is exactly what we saw. So publish a Setup IPv4
    // entity too, ConfigMethod=Manual, with OverridePrimary=1 to force IPMonitor
    // to elect us primary AND install our default route (dropping en0's) — the way
    // a VPN service does, instead of us fighting the route table.
    int one = 1;
    CFNumberRef cf_one = CFNumberCreate(NULL, kCFNumberIntType, &one);
    const void *spk[] = { CFSTR("ConfigMethod"), NW_kAddresses, NW_kSubnetMasks,
                          NW_kRouter, CFSTR("OverridePrimary") };
    const void *spv[] = { CFSTR("Manual"), cf_addrs, cf_masks, cf_rtr, cf_one };
    CFDictionaryRef setup_ip4 = CFDictionaryCreate(NULL, spk, spv, 5,
                              &kCFTypeDictionaryKeyCallBacks,
                              &kCFTypeDictionaryValueCallBacks);
    CFStringRef setup_svc_key = cstr("Setup:/Network/Service/" NW_SERVICE_ID "/IPv4");
    Boolean ok1b = SCDynamicStoreSetValue(store, setup_svc_key, setup_ip4);
    CFRelease(setup_ip4); CFRelease(cf_one);

    // Mark the interface as IPv4-capable so the service is considered "up".
    CFStringRef if_ip4_key = CFStringCreateWithFormat(NULL, NULL,
                                 CFSTR("State:/Network/Interface/%@/IPv4"), cf_if);
    CFDictionaryRef empty = CFDictionaryCreate(NULL, NULL, NULL, 0,
                                &kCFTypeDictionaryKeyCallBacks,
                                &kCFTypeDictionaryValueCallBacks);
    Boolean ok2 = SCDynamicStoreSetValue(store, if_ip4_key, empty);

    // Prepend our service to Setup:/Network/Global/IPv4 ServiceOrder. restore
    // undoes this by stripping our id from the live order, so no snapshot needed.
    Boolean ok3 = TRUE;
    CFStringRef setup_key = CFSTR("Setup:/Network/Global/IPv4");
    CFDictionaryRef setup = SCDynamicStoreCopyValue(store, setup_key);
    CFMutableArrayRef order = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    if (setup) {
        CFArrayRef cur = CFDictionaryGetValue(setup, NW_kServiceOrder);
        if (cur)
            CFArrayAppendArray(order, cur, CFRangeMake(0, CFArrayGetCount(cur)));
    }
    // Strip any stale instances of our id (or the legacy one) a crashed prior run
    // left behind, so re-running set_primary can't grow ServiceOrder unbounded.
    array_remove_all(order, CFSTR(NW_SERVICE_ID));
    array_remove_all(order, CFSTR(NW_LEGACY_ID));
    CFArrayInsertValueAtIndex(order, 0, CFSTR(NW_SERVICE_ID));
    CFMutableDictionaryRef setup_m = setup
        ? CFDictionaryCreateMutableCopy(NULL, 0, setup)
        : CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks,
                                    &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(setup_m, NW_kServiceOrder, order);
    ok3 = SCDynamicStoreSetValue(store, setup_key, setup_m);

    printf("nw_scope_set_primary(%s): svc=%d setup=%d if=%d order=%d\n",
           ifname, ok1, ok1b, ok2, ok3);
    rc = (ok1 && ok1b && ok2 && ok3) ? 0 : -1;

    // Immediate read-back so we can see whether IPMonitor re-elected our service
    // as primary (PrimaryInterface should flip to the utun). Give configd a beat.
    usleep(400000);
    printf("--- post-set State:/Network/Global/IPv4 ---\n");
    dump_key(store, "State:/Network/Global/IPv4");

    if (setup) CFRelease(setup);
    CFRelease(setup_m); CFRelease(order);
    CFRelease(empty); CFRelease(if_ip4_key);
    CFRelease(ip4); CFRelease(svc_ip4_key); CFRelease(setup_svc_key);
    CFRelease(cf_addrs); CFRelease(cf_masks);
    CFRelease(cf_if); CFRelease(cf_addr); CFRelease(cf_rtr);
    CFRelease(store);
    return rc;
}

int nw_scope_restore(void) {
    SCDynamicStoreRef store = SCDynamicStoreCreate(NULL, CFSTR("NekroWARP"), NULL, NULL);
    if (!store) { fprintf(stderr, "SCDynamicStoreCreate failed\n"); return -1; }

    // Drop our service state plus the legacy string-id service a pre-UUID build
    // may have left behind.
    CFStringRef svc_ip4_key = cstr("State:/Network/Service/" NW_SERVICE_ID "/IPv4");
    SCDynamicStoreRemoveValue(store, svc_ip4_key);
    CFRelease(svc_ip4_key);
    // Also drop the Setup config entity (ConfigMethod/OverridePrimary) we publish
    // in set_primary, else IPMonitor keeps our service configured after stop.
    SCDynamicStoreRemoveValue(store, CFSTR("Setup:/Network/Service/" NW_SERVICE_ID "/IPv4"));
    SCDynamicStoreRemoveValue(store, CFSTR("State:/Network/Service/" NW_LEGACY_ID "/IPv4"));

    // Strip EVERY occurrence of our id (and the legacy id) from the LIVE
    // ServiceOrder. Editing the current store value — rather than replaying an
    // in-memory snapshot — makes restore idempotent and self-healing: it works
    // even from a fresh process whose set_primary never ran (e.g. cleaning up
    // after a crash), and it can never re-inject dupes. We only remove our own
    // entries, so every real service keeps its original position.
    CFStringRef setup_key = CFSTR("Setup:/Network/Global/IPv4");
    CFDictionaryRef setup = SCDynamicStoreCopyValue(store, setup_key);
    if (setup) {
        CFMutableDictionaryRef m = CFDictionaryCreateMutableCopy(NULL, 0, setup);
        CFArrayRef cur = CFDictionaryGetValue(m, NW_kServiceOrder);
        if (cur) {
            CFMutableArrayRef nm = CFArrayCreateMutableCopy(NULL, 0, cur);
            int n = array_remove_all(nm, CFSTR(NW_SERVICE_ID));
            n   += array_remove_all(nm, CFSTR(NW_LEGACY_ID));
            CFDictionarySetValue(m, NW_kServiceOrder, nm);
            CFRelease(nm);
            if (n) printf("nw_scope_restore: dropped %d stale ServiceOrder entr%s\n",
                          n, n == 1 ? "y" : "ies");
        }
        SCDynamicStoreSetValue(store, setup_key, m);
        CFRelease(m);
        CFRelease(setup);
    }

    printf("nw_scope_restore: done\n");
    CFRelease(store);
    return 0;
}

int nw_scope_set_dns(const char *dns_servers_csv) {
    SCDynamicStoreRef store = SCDynamicStoreCreate(NULL, CFSTR("NekroWARP"), NULL, NULL);
    if (!store) { fprintf(stderr, "SCDynamicStoreCreate failed\n"); return -1; }

    // 1. Get primary service ID from State:/Network/Global/IPv4
    CFStringRef primary_svc_id = NULL;
    CFDictionaryRef global_ip4 = SCDynamicStoreCopyValue(store, CFSTR("State:/Network/Global/IPv4"));
    if (global_ip4) {
        primary_svc_id = CFDictionaryGetValue(global_ip4, CFSTR("PrimaryService"));
        if (primary_svc_id) CFRetain(primary_svc_id);
        CFRelease(global_ip4);
    }

    // 2. Parse DNS servers CSV into CFArray of CFStringRefs
    CFMutableArrayRef addrs = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    char buf[512];
    strlcpy(buf, dns_servers_csv, sizeof(buf));
    char *save = NULL;
    for (char *tok = strtok_r(buf, " \t,", &save); tok; tok = strtok_r(NULL, " \t,", &save)) {
        if (strlen(tok) > 0) {
            CFStringRef cf_tok = cstr(tok);
            CFArrayAppendValue(addrs, cf_tok);
            CFRelease(cf_tok);
        }
    }

    CFDictionaryRef dns_dict = CFDictionaryCreate(NULL,
        (const void *[]){ CFSTR("ServerAddresses") },
        (const void *[]){ addrs },
        1,
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks);
    CFRelease(addrs);

    // 3. Backup the original DNS settings
    CFStringRef backup_key = CFSTR("State:/Network/Service/" NW_SERVICE_ID "/DNS_Backup");
    CFStringRef backup_global_key = CFSTR("State:/Network/Service/" NW_SERVICE_ID "/DNS_Backup_Global");
    CFStringRef service_dns_key = NULL;

    if (primary_svc_id) {
        service_dns_key = CFStringCreateWithFormat(NULL, NULL, CFSTR("State:/Network/Service/%@/DNS"), primary_svc_id);
        CFDictionaryRef orig_service_dns = SCDynamicStoreCopyValue(store, service_dns_key);
        if (orig_service_dns) {
            SCDynamicStoreSetValue(store, backup_key, orig_service_dns);
            CFRelease(orig_service_dns);
        } else {
            // Store an empty dict to mark we need to remove it later
            CFDictionaryRef empty = CFDictionaryCreate(NULL, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            SCDynamicStoreSetValue(store, backup_key, empty);
            CFRelease(empty);
        }
    }

    // Backup global DNS
    CFDictionaryRef orig_global_dns = SCDynamicStoreCopyValue(store, CFSTR("State:/Network/Global/DNS"));
    if (orig_global_dns) {
        SCDynamicStoreSetValue(store, backup_global_key, orig_global_dns);
        CFRelease(orig_global_dns);
    }

    // 4. Write new DNS settings
    if (service_dns_key) {
        SCDynamicStoreSetValue(store, service_dns_key, dns_dict);
        CFRelease(service_dns_key);
    }
    SCDynamicStoreSetValue(store, CFSTR("State:/Network/Global/DNS"), dns_dict);
    CFRelease(dns_dict);

    if (primary_svc_id) CFRelease(primary_svc_id);
    CFRelease(store);
    return 0;
}

int nw_scope_restore_dns(void) {
    SCDynamicStoreRef store = SCDynamicStoreCreate(NULL, CFSTR("NekroWARP"), NULL, NULL);
    if (!store) { fprintf(stderr, "SCDynamicStoreCreate failed\n"); return -1; }

    CFStringRef backup_key = CFSTR("State:/Network/Service/" NW_SERVICE_ID "/DNS_Backup");
    CFStringRef backup_global_key = CFSTR("State:/Network/Service/" NW_SERVICE_ID "/DNS_Backup_Global");

    CFStringRef primary_svc_id = NULL;
    CFDictionaryRef global_ip4 = SCDynamicStoreCopyValue(store, CFSTR("State:/Network/Global/IPv4"));
    if (global_ip4) {
        primary_svc_id = CFDictionaryGetValue(global_ip4, CFSTR("PrimaryService"));
        if (primary_svc_id) CFRetain(primary_svc_id);
        CFRelease(global_ip4);
    }

    // Restore service DNS
    if (primary_svc_id) {
        CFStringRef service_dns_key = CFStringCreateWithFormat(NULL, NULL, CFSTR("State:/Network/Service/%@/DNS"), primary_svc_id);
        CFDictionaryRef orig_dns = SCDynamicStoreCopyValue(store, backup_key);
        if (orig_dns) {
            if (CFDictionaryGetCount(orig_dns) > 0) {
                SCDynamicStoreSetValue(store, service_dns_key, orig_dns);
            } else {
                SCDynamicStoreRemoveValue(store, service_dns_key);
            }
            CFRelease(orig_dns);
        }
        CFRelease(service_dns_key);
        CFRelease(primary_svc_id);
    }

    // Restore global DNS
    CFDictionaryRef orig_global_dns = SCDynamicStoreCopyValue(store, backup_global_key);
    if (orig_global_dns) {
        SCDynamicStoreSetValue(store, CFSTR("State:/Network/Global/DNS"), orig_global_dns);
        CFRelease(orig_global_dns);
    } else {
        SCDynamicStoreRemoveValue(store, CFSTR("State:/Network/Global/DNS"));
    }

    SCDynamicStoreRemoveValue(store, backup_key);
    SCDynamicStoreRemoveValue(store, backup_global_key);

    CFRelease(store);
    return 0;
}

