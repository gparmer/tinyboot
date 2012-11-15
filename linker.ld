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

/*OUTPUT_FORMAT("elf32-i386")
ENTRY(loader)

SECTIONS
{
	. = 0x100000;

	.setup :
	{
		*(.setup)
	}

	. += 0xC0000000;

	.text : AT(ADDR(.text) - 0xC0000000)
	{
		*(.text)
	}

	.data ALIGN (4096) : AT(ADDR(.data) - 0xC0000000)
	{
		*(.data)
		*(.rodata*)
	}

	.bss ALIGN (4096) : AT(ADDR(.bss) - 0xC0000000)
	{
		*(COMMON*)
		*(.bss*)
	}

    end = .; _end = .; __end = .;
}
*/
/*OUTPUT_FORMAT(elf32-i386)
ENTRY (loader)
phys = 0x00100000; 
SECTIONS {
    
    .text phys : AT(phys) {
        code = .; _code = .; __code = .;
        *(.text)
        *(.rodata)
        . = ALIGN(4096);
    }

    .data : AT(phys + (data - code)) {
        data = .; _data = .; __data = .;
        *(.data)
        . = ALIGN(4096);
    }

    .bss : AT(phys + (bss - code)) {
        bss = .; _bss = .; __bss = .;
        *(.bss)
        . = ALIGN(4096);
    }

    end = .; _end = .; __end = .;

    /DISCARD/ : {
        *(.comment)
        *(.eh_frame)
        *(.note.gnu.build-id)
    }
}*/

/*
*SECTIONS
*{
*    . = 0x00100000;
*
*    .text ALIGN (0x1000) :
*    {
*        *(.text)
*    }
*
*    .rodata ALIGN (0x1000) :
*    {
*        *(.rodata*)
*    }
*
*    .data ALIGN (0x1000) :
*    {
*        *(.data)
*    }
*
*    .bss :
*    {
*        sbss = .;
*        *(COMMON)
*        *(.bss)
*        ebss = .;
*    }
*}
**/
