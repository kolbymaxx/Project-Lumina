/*
 * Default dispatch: no backend.
 * For DS-K builds, compile krw_backend_darksword.c with
 * -DKRW_BACKEND_DARKSWORD=1 instead of (or not together with) this file.
 */

#include "krw.h"

#include <string.h>

#ifndef KRW_BACKEND_DARKSWORD
#define KRW_BACKEND_DARKSWORD 0
#endif

#if !KRW_BACKEND_DARKSWORD

static int g_inited;

int krw_init(void)
{
    g_inited = 0;
    return KRW_ERR_NO_BACKEND;
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

#endif /* !KRW_BACKEND_DARKSWORD */
