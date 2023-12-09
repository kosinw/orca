.section .text.boot

.globl __stack0
.equ __stack0, 0x10000

.globl _start
_start:
    la sp, __stack0
    call main
spin:
    j spin

.global __mulsi3
__mulsi3:
    mv     a2, a0
    li     a0, 0
.L1:
    andi   a3, a1, 1
    beqz   a3, .L2
    add    a0, a0, a2
.L2:
    srli   a1, a1, 1
    slli   a2, a2, 1
    bnez   a1, .L1
    ret