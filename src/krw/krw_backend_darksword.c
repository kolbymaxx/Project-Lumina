/*
 * DS-K backend — real link to local third_party via darksword_lib.
 *
 * Build the Lumina app target with:
 *   -DKRW_BACKEND_DARKSWORD=1 -DDARKSWORD_EXPLOIT_LINKED=1 -DLUMINA_DSK_LIBRARY=1
 * and compile third_party/darksword-kexploit/src/main.m + darksword_lib.m.
 *
 * Never fabricates successful kread/kwrite.
 */

#include "krw.h"

#if KRW_BACKEND_DARKSWORD && DARKSWORD_EXPLOIT_LINKED

#include "darksword_lib.h"

#include <stdio.h>
#include <string.h>

static int g_inited;

int krw_init(void)
{
    printf("[*] krw_init: starting DS-K (darksword)…\n");
    fflush(stdout);
    int rc = dsk_exploit_run();
    if (rc != 0) {
        g_inited = 0;
        printf("[-] krw_init: dsk_exploit_run => %d\n", rc);
        fflush(stdout);
        return KRW_ERR_IO;
    }
    if (!dsk_is_ready() || dsk_kernel_base() == 0) {
        g_inited = 0;
        return KRW_ERR_IO;
    }
    g_inited = 1;
    printf("[+] krw_init: ready base=%#llx slide=%#llx\n",
           (unsigned long long)dsk_kernel_base(),
           (unsigned long long)dsk_kernel_slide());
    fflush(stdout);
    return KRW_OK;
}

void krw_deinit(void)
{
    g_inited = 0;
}

int kread(uint64_t kaddr, void *out, size_t len)
{
    if (out == NULL || len == 0) {
        return KRW_ERR_ARGS;
    }
    if (!g_inited) {
        memset(out, 0, len);
        return KRW_ERR_NOT_INIT;
    }
    if (dsk_early_kread(kaddr, out, len) != 0) {
        return KRW_ERR_IO;
    }
    return KRW_OK;
}

int kwrite(uint64_t kaddr, const void *in, size_t len)
{
    if (in == NULL || len == 0) {
        return KRW_ERR_ARGS;
    }
    if (!g_inited) {
        return KRW_ERR_NOT_INIT;
    }
    if (dsk_early_kwrite(kaddr, in, len) != 0) {
        return KRW_ERR_IO;
    }
    return KRW_OK;
}

uint64_t kbase(void)
{
    return g_inited ? dsk_kernel_base() : 0;
}

uint64_t kslide(void)
{
    return g_inited ? dsk_kernel_slide() : 0;
}

#elif KRW_BACKEND_DARKSWORD && !DARKSWORD_EXPLOIT_LINKED

#include <string.h>

int krw_init(void) { return KRW_ERR_NOT_LINKED; }
void krw_deinit(void) {}
int kread(uint64_t kaddr, void *out, size_t len)
{
    (void)kaddr;
    if (out && len) memset(out, 0, len);
    return KRW_ERR_NOT_LINKED;
}
int kwrite(uint64_t kaddr, const void *in, size_t len)
{
    (void)kaddr;
    (void)in;
    (void)len;
    return KRW_ERR_NOT_LINKED;
}
uint64_t kbase(void) { return 0; }
uint64_t kslide(void) { return 0; }

#endif
