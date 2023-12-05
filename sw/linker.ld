ENTRY(_start)

MEMORY
{
  rom (r) : ORIGIN = 0x00000000,   LENGTH = 0x00020000
  ram (rw) : ORIGIN = 0x00000000,  LENGTH = 0x00020000
}

SECTIONS
{
  . = 0x00000000;
  .text :
  {
    /* Your program code goes here */
    *(.text)
  } > rom
  . = ALIGN(32);

  .bss :
  {
    /* Uninitialized data goes here */
    *(.bss)
  } > ram
  . = ALIGN(32);

  .data :
  {
    *(.data)
    *(COMMON)
  } > ram
  . = ALIGN(32);

    /DISCARD/ : {
        *(.riscv.attributes)
    }

  . = 0x00020000;
  PROVIDE(__stack0 = .);
}