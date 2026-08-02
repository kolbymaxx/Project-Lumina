/* t8027 pre-return cleanup — structure mirrors t8020; literals are TODO.
 * Do not invent addresses. Fill from t8027 SecureROM / SRAM / USB map.
 */
#if 0
    mov x0, sp
    sub sp, sp, 0xA0
    mov x1, sp

stack_clear_loop:
    stp xzr, xzr, [x1], #0x10
    cmp x0, x1
    bne stack_clear_loop

    // stack canary ptr — TODO(t8027)
    // ldr x1, =<TODO_STACK_CANARY_PTR>
    ldr x1, [x1]
    str x1, [sp, #0x18]

    // expected task-tramp LR — TODO(t8027)
    // ldr x1, =<TODO_TASK_TRAMP_LR>
    str x1, [sp, #0x78]

    // stack slot @sp+8 — TODO(t8027)
    // ldr x1, =<TODO_SP8_SLOT>
    str x1, [sp, #0x8]

    // USB base / related — TODO(t8027)
    // ldr x20, =<TODO_USB_BASE>
    // ldr x21, =<TODO_X21>
    mov w24, #1
    mov w25, #0x40
    mov w28, #0x1F
    mov w26, #0xF
#endif
