MEMORY
{
    FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 2M
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 8M 
}
ENTRY(Reset_Handler)

SECTIONS
{
    .text :
    {
        KEEP(*(.vectors))
        *(.text*)
        *(.rodata*)
        *(.init*)
        *(.fini*)
        . = ALIGN(4);
    } > FLASH
    
    __exidx_start = .;
    .edidx :
    {
        . = ALIGN(4);
        *(.ARM.exidx*)
    } > FLASH
    __exidx_end = .;

    .copy.table :
    {
      . = ALIGN(4);
      __copy_table_start__ = .;

      LONG (__etext)
      LONG (__data_start__)
      LONG ((__data_end__ - __data_start__) / 4)

      __copy_table_end__ = .;
    } > FLASH

    .zero.table :
    {
      . = ALIGN(4);
      __zero_table_start__ = .;
      __zero_table_end__ = .;
    } > FLASH

    __etext = ALIGN (4);

    .data : AT (__etext)
    {
      __data_start__ = .;
      *(vtable)
      *(.data)
      *(.data.*)

      . = ALIGN(4);
      /* preinit data */
      PROVIDE_HIDDEN (__preinit_array_start = .);
      KEEP(*(.preinit_array))
      PROVIDE_HIDDEN (__preinit_array_end = .);

      . = ALIGN(4);
      /* init data */
      PROVIDE_HIDDEN (__init_array_start = .);
      KEEP(*(SORT(.init_array.*)))
      KEEP(*(.init_array))
      PROVIDE_HIDDEN (__init_array_end = .);

      . = ALIGN(4);
      /* finit data */
      PROVIDE_HIDDEN (__fini_array_start = .);
      KEEP(*(SORT(.fini_array.*)))
      KEEP(*(.fini_array))
      PROVIDE_HIDDEN (__fini_array_end = .);

      KEEP(*(.jcr*))
      . = ALIGN(4);
      /* All data end */
      __data_end__ = .;
    } > RAM

    .bss :
    {
      __bss_start__ = .;
      *(.bss*)
      *(COMMON)
      . = ALIGN(4);
      *(.zenmem*)
      . = ALIGN(4);
      __bss_end__ = .;
    } > RAM

    .heap (COPY):
    {
      __HeapBase = .;
      __end__ = .;
      end = __end__;
      KEEP(*(.heap*))
      __HeapLimit = .;
    } > RAM

    .stack_dummy (COPY):
    {
      KEEP(*(.stack*))
    } > RAM

    __StackTop = ORIGIN(RAM) + LENGTH(RAM);
    __StackLimit = __StackTop - SIZEOF(.stack_dummy);
    PROVIDE(__stack = __StackTop);

    /* Check if data + heap + stack exceeds RAM limit */
    ASSERT(__StackLimit >= __HeapLimit, "region RAM overflowed with stack")
}
