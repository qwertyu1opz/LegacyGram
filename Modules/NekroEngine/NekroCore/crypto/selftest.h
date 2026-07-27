#ifndef NW_SELFTEST_H
#define NW_SELFTEST_H

// Known-answer tests for the crypto primitives. Returns 0 if all pass, else the
// number of failures. verbose prints each vector's PASS/FAIL line.
int nw_crypto_selftest(int verbose);

// Rough on-device benchmark: X25519 ops/sec and ChaCha20-Poly1305 throughput.
void nw_crypto_bench(void);

#endif // NW_SELFTEST_H
