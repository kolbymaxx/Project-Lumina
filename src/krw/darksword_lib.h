/*
 * Thin C API over patched opa334/darksword-kexploit (local third_party only).
 * Requires -DLUMINA_DSK_LIBRARY=1 when compiling upstream main.m.
 */

#ifndef LUMINA_DARKSWORD_LIB_H
#define LUMINA_DARKSWORD_LIB_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Runs upstream PE path (darksword_cli_main). 0 = completed without FAILURE. */
int dsk_exploit_run(void);

/* Early KRW primitives (valid only after successful dsk_exploit_run). */
int dsk_early_kread(uint64_t kaddr, void *out, size_t len);
int dsk_early_kwrite(uint64_t kaddr, const void *in, size_t len);

uint64_t dsk_kernel_base(void);
uint64_t dsk_kernel_slide(void);

int dsk_is_ready(void);

#ifdef __cplusplus
}
#endif

#endif /* LUMINA_DARKSWORD_LIB_H */
