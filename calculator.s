global _start
.align 2

_start:
    ldr x0, [sp]
    cmp x0, #4
    b.ne error

    ldr x9, [sp, #16]
    ldr x10, [sp, #24]
    ldr x11, [sp, #32]

error:
    mov x0, #0            
    mov x16, #1           
    svc #0x80
