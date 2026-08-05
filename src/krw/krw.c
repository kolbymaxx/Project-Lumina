/*
 * Lumina KRW harness — stub backend
 *
 * Default build has no live exploit. Integrating a public kexploit must:
 *   1) Live under research/kexploit/<name>/ with LICENSE + attribution
 *   2) Provide a real backend behind a compile flag (never invent offsets)
 *   3) Remain out of boot/
 *
 * See README.md and docs/KRW.md.
 */

#include "krw.h"

#include <string.h>

#ifndef KRW_BACKEND_NONE
#define KRW_BACKEND_NONE 1
#endif

static int g_inited;

int krw_init(void)
{
#if KRW_BACKEND_NONE
    g_inited = 0;
    return KRW_ERR_NO_BACKEND;
#else
#error "No non-stub KRW backend is implemented for 22H311 yet."
#endif
}

void krw_deinit(void)
{
    g_inited = 0;
}

int kread(uint64_t kaddr, void *out, size_t len)
{
    (void)kaddr;
    if (out == NULL || len == 0) {
        return KRW_ERR_ARGS;
    }
    if (!g_inited) {
        memset(out, 0, len);
        return KRW_ERR_NOT_INIT;
    }
    return KRW_ERR_NO_BACKEND;
}

int kwrite(uint64_t kaddr, const void *in, size_t len)
{
    (void)kaddr;
    (void)in;
    if (in == NULL || len == 0) {
        return KRW_ERR_ARGS;
    }
    if (!g_inited) {
        return KRW_ERR_NOT_INIT;
    }
    /* Policy: stub never writes. */
    return KRW_ERR_NO_BACKEND;
}

uint64_t kbase(void)
{
    return 0;
}

uint64_t kslide(void)
{
    return 0;
}
