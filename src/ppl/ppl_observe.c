#include "ppl_observe.h"

#include <stddef.h>
#include <string.h>

int ppl_observe_init(void)
{
    /* Requires demonstrated KRW — not present for 22H311 in this tree. */
    return PPL_OBS_ERR_NO_KRW;
}

void ppl_observe_deinit(void)
{
}

int ppl_observe_read(uint64_t kaddr, void *out, uint64_t len)
{
    (void)kaddr;
    if (out == NULL || len == 0) {
        return PPL_OBS_ERR_ARGS;
    }
    memset(out, 0, (size_t)len);
    return PPL_OBS_ERR_NO_KRW;
}

int ppl_observe_forbidden_write(uint64_t kaddr, const void *in, uint64_t len)
{
    (void)kaddr;
    (void)in;
    (void)len;
    return PPL_OBS_ERR_BLOCKED;
}
