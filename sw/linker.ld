MEMORY
{
  rom (r) : ORIGIN = 0x00000000, LENGTH = 0x00020000
  ram (rw) : ORIGIN = 0x00000000, LENGTH = 0x00020000
  video_ram (rw) : ORIGIN = 0x00020000, LENGTH = 0x00010000
}

ENTRY(_start)

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
  } > ram
  . = ALIGN(32);

  . = 0x00020000;
  PROVIDE(. = __stack0);

    /DISCARD/ : {
        *(.riscv.attributes)
    }
}