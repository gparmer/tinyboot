OUTPUT_FORMAT(elf32-i386)
ENTRY(loader)
KERNEL_BOOT_VMA = 0x00100000;
KERNEL_HIGH_VMA = 0xC0000000;

SECTIONS{
   . = KERNEL_BOOT_VMA;

   .boot :{ 
       */boot.o (.text)
   }  
 	
. += KERNEL_HIGH_VMA;
   _core_start = .;

 .text ALIGN(0x1000) : AT(ADDR(.text) - KERNEL_HIGH_VMA) {
       _core_code = .;
       *(EXCLUDE_FILE (*/boot.o) .text)

       /* all readonly data is merged with this section, too */
       *(.rodata*)
   }

   .data ALIGN (0x1000) : AT(ADDR(.data) - KERNEL_HIGH_VMA) {
       _core_data = .;
       *(.data)
   }

  .bss ALIGN (0x1000) : AT(ADDR(.bss) - KERNEL_HIGH_VMA) {
       _core_bss = .;
       *(COMMON)
       *(.bss)
       . = ALIGN(4096);
       _core_ebss = .;
   }

   /* 4K alignment is guaranteed! */
   _core_end = .;

    end = .; _end = .; __end = .;
}