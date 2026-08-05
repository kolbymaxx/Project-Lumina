/*
 * DS-K backend adapter — calls into a *local* opa334/darksword-kexploit tree.
 *
 * Default builds do NOT enable this file's success path.
 * Compile with -DKRW_BACKEND_DARKSWORD=1 only on a lab Mac that has:
 *   third_party/darksword-kexploit/  (gitignored clone — see third_party/README.md)
 *
 * Upstream today ships a monolithic src/main.m (binary target darksword-pe),
 * not a stable library ABI. Until callable init/kread symbols are extracted
 * in the local tree, this adapter returns KRW_ERR_NOT_LINKED — it must NOT
 * fabricate kread/kwrite success.
 *
 * Do not reimplement exploit logic from public writeups here.
 */

#include "krw.h"

#include <string.h>

#ifndef KRW_BACKEND_DARKSWORD
#define KRW_BACKEND_DARKSWORD 0
#endif

/* Set by lab Makefile only after a real link against extracted upstream APIs. */
#ifndef DARKSWORD_EXPLOIT_LINKED
#define DARKSWORD_EXPLOIT_LINKED 0
#endif

#if KRW_BACKEND_DARKSWORD

#if DARKSWORD_EXPLOIT_LINKED
/* Declarations would match symbols extracted from the local third_party tree.
 * Intentionally empty until that extraction exists — do not invent prototypes
 * that pretend to wrap news-article pseudocode. */
#error "DARKSWORD_EXPLOIT_LINKED set but no upstream symbols wired — extract from local clone first"
#else

static int g_inited;

int krw_init(void)
{
    /* Tree present or not: without a linked exploit ABI we cannot init. */
    g_inited = 0;
    return KRW_ERR_NOT_LINKED;
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
    memset(out, 0, len);
    return g_inited ? KRW_ERR_IO : KRW_ERR_NOT_LINKED;
}

int kwrite(uint64_t kaddr, const void *in, size_t len)
{
    (void)kaddr;
    (void)in;
    if (in == NULL || len == 0) {
        return KRW_ERR_ARGS;
    }
    /* Never fabricate writes. */
    return KRW_ERR_NOT_LINKED;
}

uint64_t kbase(void)
{
    return 0;
}

uint64_t kslide(void)
{
    return 0;
}

#endif /* !DARKSWORD_EXPLOIT_LINKED */

#endif /* KRW_BACKEND_DARKSWORD */
