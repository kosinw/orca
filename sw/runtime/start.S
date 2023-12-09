.section .text.boot

.globl __stack0
.equ __stack0, 0x10000

.globl _start
_start:
    la sp, __stack0
    call main
spin:
    j spin