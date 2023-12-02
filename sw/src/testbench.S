.globl _start
.attribute arch, rv32i

.section .text
_start:
    auipc x3, 203
    lui x4, 19
    jal x30, .L1
    li x1, 0xDEADBEEF
    li x2, 0xCAFEBABE
.L1:
    jalr .L2
    li x3, 0x1BADB002
    li x4, 0x2BADB002
.L2:
    lb x1, hello_world
    lh x2, hello_world
    lw x3, hello_world
    lbu x4, hello_world
    lhu x5, hello_world

.section .rodata
hello_world:
    .string "HELLO, WORLD!\n"