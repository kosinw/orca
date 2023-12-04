.globl _start

_start:
    li x1, 'H'
    li x2, 0x20000
    sb x1, 0(x2)
    li x1, 'E'
    addi x2, x2, 2
    sb x1, 0(x2)
    li x1, 'L'
    addi x2, x2, 2
    sb x1, 0(x2)
    li x1, 'L'
    addi x2, x2, 2
    sb x1, 0(x2)
    li x1, 'O'
    addi x2, x2, 2
    sb x1, 0(x2)
    li x1, ' '
    addi x2, x2, 2
    sb x1, 0(x2)
    li x1, 'W'
    addi x2, x2, 2
    sb x1, 0(x2)
    li x1, 'O'
    addi x2, x2, 2
    sb x1, 0(x2)
    li x1, 'R'
    addi x2, x2, 2
    sb x1, 0(x2)
    li x1, 'L'
    addi x2, x2, 2
    sb x1, 0(x2)
    li x1, 'D'
    addi x2, x2, 2
    sb x1, 0(x2)
halt:
    j halt