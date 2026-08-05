/*
 * Offsets — iPhone XR (n841) / iOS 18.7.5 (22H311)
 *
 * POLICY: every field stays TODO until filled from:
 *   (a) a public table that explicitly lists this build, with citation, or
 *   (b) derivation notes against our hashed kernelcache.payload, or
 *   (c) remains TODO with the symbol / field name only.
 *
 * Never invent immediates. Never copy offsets from a different build
 * without re-deriving and documenting the delta.
 *
 * Kernelcache identity: see docs/BUILD_22H311.md
 */

#ifndef LUMINA_OFFSETS_N841_22H311_H
#define LUMINA_OFFSETS_N841_22H311_H

#include <stdint.h>

/* Build guard — bump only when this header is verified for another build. */
#define LUMINA_OFFSETS_PRODUCT   "n841"
#define LUMINA_OFFSETS_IOS       "18.7.5"
#define LUMINA_OFFSETS_BUILD     "22H311"

/*
 * Placeholder type: uint64_t with sentinel 0 means "unset".
 * Callers must treat 0 as invalid until a backend documents otherwise.
 */

/* Kernel / slide */
/* TODO verify */ static const uint64_t off_kernel_base_unslid = 0; /* symbol: kernel base / FILESET */
/* TODO verify */ static const uint64_t off_kernproc = 0;           /* symbol: kernproc */
/* TODO verify */ static const uint64_t off_allproc = 0;            /* symbol: allproc */

/* proc / task (names only until derived) */
/* TODO verify */ static const uint64_t off_proc_pid = 0;           /* field: proc::p_pid */
/* TODO verify */ static const uint64_t off_proc_task = 0;          /* field: proc::task (or equiv) */
/* TODO verify */ static const uint64_t off_proc_p_fd = 0;          /* field: proc::p_fd */

/* vm_map / pmap — PPL-relevant; do not assume 16.x dmaFail layouts */
/* TODO verify */ static const uint64_t off_task_map = 0;           /* field: task::map */
/* TODO verify */ static const uint64_t off_vm_map_pmap = 0;        /* field: vm_map::pmap */

/*
 * Exploit-specific gadgets / structure deltas for a chosen public kexploit
 * belong in a dedicated header next to that backend, still marked TODO until
 * verified on 22H311. Do not invent DarkSword/ClearSword immediates here:
 * those PE CVEs are patched on 18.7.2 (see docs/KRW.md).
 */

#endif /* LUMINA_OFFSETS_N841_22H311_H */
