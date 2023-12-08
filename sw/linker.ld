ENTRY(_start)

SECTIONS
{
  . = 0x00000000;
  .text :
  {
    /* Your program code goes here */
    *(.text.boot)
    *(.text)
  }
  . = ALIGN(32);

  .bss :
  {
    /* Uninitialized data goes here */
    *(.bss)
  }
  . = ALIGN(32);

  .data :
  {
    *(.rodata)
    *(.data)
    *(.sdata)
    *(COMMON)
  }
  . = ALIGN(32);

    /DISCARD/ : {
        *(.riscv.attributes)
        *(.eh_frame_hdr)
        *(.eh_frame)
        *(.comment)
    }

  . = 0x00010000;
  PROVIDE(__stack0 = .);
}