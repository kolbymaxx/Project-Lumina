/*
 * PPL observational stubs — A12 / 22H311
 *
 * Call only after a demonstrated KRW backend exists.
 * These APIs intentionally cannot claim a bypass.
 */

#ifndef LUMINA_PPL_OBSERVE_H
#define LUMINA_PPL_OBSERVE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define PPL_OBS_OK           0
#define PPL_OBS_ERR_NO_KRW  (-1)
#define PPL_OBS_ERR_BLOCKED (-2)
#define PPL_OBS_ERR_ARGS    (-3)

/* Returns PPL_OBS_ERR_NO_KRW until a real KRW backend is wired. */
int ppl_observe_init(void);

void ppl_observe_deinit(void);

/*
 * RO: copy a small researcher-selected region described in session notes.
 * Stub always fails. Never used to assert bypass.
 */
int ppl_observe_read(uint64_t kaddr, void *out, uint64_t len);

/* Always fails — writes into PPL-protected state are out of scope for stubs. */
int ppl_observe_forbidden_write(uint64_t kaddr, const void *in, uint64_t len);

#ifdef __cplusplus
}
#endif

#endif /* LUMINA_PPL_OBSERVE_H */
