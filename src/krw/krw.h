/*
 * Lumina KRW harness — public API
 *
 * Thin, auditable interface around a future public kexploit backend.
 * No offsets or success claims live here.
 *
 * Target window: iPhone XR (n841) / iOS 18.7.5 (22H311) only for v0.
 */

#ifndef LUMINA_KRW_H
#define LUMINA_KRW_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Return codes: 0 = success; negative = failure (see krw.c). */
#define KRW_OK              0
#define KRW_ERR_NO_BACKEND (-1)
#define KRW_ERR_NOT_INIT   (-2)
#define KRW_ERR_IO         (-3)
#define KRW_ERR_ARGS       (-4)

/*
 * Initialize the active backend.
 * With KRW_BACKEND_NONE (default), returns KRW_ERR_NO_BACKEND.
 */
int krw_init(void);

/* Tear down backend state. Safe to call if init failed. */
void krw_deinit(void);

/*
 * Read `len` bytes from kernel virtual address `kaddr` into `out`.
 * Refuses if not initialized or len == 0 / out == NULL.
 */
int kread(uint64_t kaddr, void *out, size_t len);

/*
 * Write `len` bytes from `in` to kernel virtual address `kaddr`.
 * Lab policy: do not call until a known-stable kread test passes
 * (see test_plan.md). Stub backend always fails.
 */
int kwrite(uint64_t kaddr, const void *in, size_t len);

/*
 * Kernel base (preferred) or 0 if unknown / not initialized.
 * Slide helpers may be added once a backend exists; do not invent slide.
 */
uint64_t kbase(void);

/* Optional: slide = kbase - unslid_base when both are known. Returns 0 if unknown. */
uint64_t kslide(void);

#ifdef __cplusplus
}
#endif

#endif /* LUMINA_KRW_H */
