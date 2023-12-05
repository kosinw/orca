.text
.globl _start
_start:
    la      a0, hello_world
    la      a1, 0x20000

copy_loop:
    lb      t0, 0(a0)
    beqz    t0, done
    sb      t0, 0(a1)
    addi    a0, a0, 1
    addi    a1, a1, 1
    j       copy_loop

done:
    j       done

.data
hello_world:
    .string "Hello, world!"