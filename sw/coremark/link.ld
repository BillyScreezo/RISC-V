OUTPUT_FORMAT("elf32-littleriscv")
ENTRY(_start)

MEMORY
{
  RAM (RWX) : ORIGIN = 0, LENGTH = 64K
}

SECTIONS
{
  .text :
  {
    *(.text)
  } > RAM
  .rodata :
  {
    *(.rodata .rodata.*)
    . = ALIGN(4);
  } > RAM
  .data :
  {
    __DATA_BEGIN__ = .;
    *(.data .data.*)
  } > RAM
  /* We want the small data sections together, so single-instruction offsets
     can access them all, and initialized data all before uninitialized, so
     we can shorten the on-disk segment size.  */
  .sdata :
  {
    __SDATA_BEGIN__ = .;
    *(.sdata .sdata.*)
  } > RAM
  __bss_start = .;
  .bss :
  {
   *(.bss .bss.*)
   *(.sbss .sbss.*)
   *(COMMON)
   /* Align here to ensure that the .bss section occupies space up to
      _end.  Align after .bss to ensure correct alignment even if the
      .bss section disappears because there are no input sections.
      FIXME: Why do we need it? When there is no .bss section, we do not
      pad the .data section.  */
   . = ALIGN(. != 0 ? 32 / 8 : 1);
  } > RAM
  __BSS_END__ = .;
    __global_pointer$ = MIN(__SDATA_BEGIN__ + 0x800,
                MAX(__DATA_BEGIN__ + 0x800, __BSS_END__ - 0x800));
  _end = .; PROVIDE(end = .);

  PROVIDE(__stack_top = ORIGIN(RAM) + LENGTH(RAM));
}
