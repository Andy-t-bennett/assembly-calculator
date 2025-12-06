.global _start

.data
output: .ascii "0\n"

.text
.align 2

_start:
    cmp x0, #4
    bne error
    
    ldr x9, [x1, #8]
    ldr x10, [x1, #16]
    ldr x11, [x1, #24]
    
    ldrb w12, [x9]
    ldrb w13, [x10]
    ldrb w14, [x11]
    
    sub w12, w12, #48
    sub w14, w14, #48
    
    cmp w13, #43
    beq add_op
    cmp w13, #45
    beq sub_op
    cmp w13, #42
    beq mul_op
    cmp w13, #47
    beq div_op
    b error

add_op:
    add w15, w12, w14
    cmp w15, #0
    bmi print_negative
    b print_positive

sub_op:
    sub w15, w12, w14
    cmp w15, #0
    bmi print_negative
    b print_positive

mul_op:
    mul w15, w12, w14
    cmp w15, #0
    bmi print_negative
    b print_positive

div_op:
    sdiv w15, w12, w14
    cmp w15, #0
    bmi print_negative
    b print_positive

print_positive:
    add w15, w15, #48
    
    adrp x1, output@PAGE
    add x1, x1, output@PAGEOFF
    strb w15, [x1]
    
    mov x0, #1
    mov x2, #2
    mov x16, #4
    svc #0x80
    
    mov x0, #0
    mov x16, #1
    svc #0x80

print_negative:
    neg w15, w15
    add w15, w15, #48
    
    adrp x1, output@PAGE
    add x1, x1, output@PAGEOFF
    
    # ascii value for '-'
    mov w9, #45
    strb w9, [x1]
    strb w15, [x1, #1]
    # ascii value for '\n'
    mov w9, #10
    strb w9, [x1, #2]

    mov x0, #1
    mov x2, #3
    mov x16, #4
    svc #0x80
    
    mov x0, #0
    mov x16, #1
    svc #0x80

error: