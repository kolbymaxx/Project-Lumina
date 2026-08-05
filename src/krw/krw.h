/*
 * Lumina KRW harness — public API (DS-K integration surface)
 *
 * No offsets or success claims live here.
 * Default backend: none. DarkSword adapter: krw_backend_darksword.c
 */

#ifndef LUMINA_KRW_H
#define LUMINA_KRW_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define KRW_OK               0
#define KRW_ERR_NO_BACKEND  (-1)
#define KRW_ERR_NOT_INIT    (-2)
#define KRW_ERR_IO          (-3)
#define KRW_ERR_ARGS        (-4)
#define KRW_ERR_NOT_LINKED  (-5) /* DS-K tree/ABI not linked — not a fake success */
#define KRW_ERR_OFFSETS     (-6) /* reserved for backend that detects bad build tables */

int krw_init(void);
void krw_deinit(void);
int kread(uint64_t kaddr, void *out, size_t len);
int kwrite(uint64_t kaddr, const void *in, size_t len);
uint64_t kbase(void);
uint64_t kslide(void);

#ifdef __cplusplus
}
#endif

#endif /* LUMINA_KRW_H */
