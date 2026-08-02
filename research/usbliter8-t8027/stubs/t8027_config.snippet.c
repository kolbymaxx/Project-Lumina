/*
 * TEMPLATE ONLY — no numeric offsets invented.
 * Mirror of upstream t8020_config / t8020_create_* for CPID 0x8027.
 * Fill from t8027 SecureROM + SRAM map before enabling case 0x8027.
 */

#if 0

#include "resources/descriptors_t8027.h" /* TODO: hand-author after layout known */
#include "resources/shellcode_t8027.h"   /* TODO: regenerate from TARGET=t8027 make.sh */
#include "resources/handler_t8027.h"     /* TODO: regenerate from TARGET=t8027 make.sh */

void t8027_create_overwrite(struct t8020_t8006_config *config) {
    uint64_t ov_start = config->ov_start;

    /* TODO(t8027): ROP frame — replace every SET64/SET32/SETMANY address.
     * t8020 baseline listed in docs/research/usbliter8-t8027-bringup.md
     * (do not copy 0x19C0… / 0x10000… / 0x2391… blindly).
     */
    (void)ov_start;
    (void)config;
}

void t8027_create_shellcode(struct t8020_t8006_config *config) {
    /* TODO(t8027): plant shellcode_t8027 + handler_t8027 at shc_base/shc_start */
    (void)config;
}

struct t8020_t8006_config t8027_config = {
    0x8027, /* cpid — identity only; all other fields TODO */
#if PICO_RP2350
    /* TODO: delay */ 0,
#elif PICO_RP2040
    /* TODO: delay */ 0,
#endif
    /* ov_start */ 0, /* TODO */
    /* ov_size  */ 0, /* TODO */
    /* shc_base */ 0, /* TODO */
    /* shc_start */ 0, /* TODO */
    /* shc_size */ 0, /* TODO */
    t8027_create_overwrite,
    t8027_create_shellcode
};

#endif
