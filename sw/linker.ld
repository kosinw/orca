MEMORY
{
  rom (r) : ORIGIN = 0x00000000, LENGTH = 0x00020000
  ram (rw) : ORIGIN = 0x00000000, LENGTH = 0x00020000
  video_ram (rw) : ORIGIN = 0x00020000, LENGTH = 0x00010000
}

SECTIONS
{
  .text :
  {
    /* Your program code goes here */
    *(.text)
  } > rom

  .bss :
  {
    /* Uninitialized data goes here */
    *(.bss)
  } > ram

  .video_data :
  {
    /* Video RAM data goes here */
    *(.video_data)
  } > video_ram
}