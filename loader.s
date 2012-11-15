.global loader
.section .data

.align 0x1000
_kernel_pd:
   .space 0x1000, 0x00
_kernel_pt:
   .space 0x1000, 0x00
_kernel_low_pt:
   .space 0x1000, 0x00

.set INITSTACKSIZE, 0x10000
initstack:
   .space INITSTACKSIZE, 0x00

_msg_panic:
   .asciz "PANIC!"

.section .text
.code32

.set ALIGN,         1<<0             # align loaded modules on page boundaries
.set MEMINFO,       1<<1             # provide memory map
.set FLAGS,         ALIGN | MEMINFO  # this is the Multiboot 'flag' field
.set MAGIC,         0x1BADB002       # 'magic number' lets bootloader find the header
.set CHECKSUM,      -(MAGIC + FLAGS) # checksum required

.align 4

multiboot_header:
.long MAGIC
.long FLAGS
.long CHECKSUM

.set VIDEO_RAM,     0xB8000          # Video Memory, used to print to the screen.
.set VIDEO_DWORDS,  0x3E8            # The count of DWORDs (!) the screen buffer is large.

loader:
	mov   $(initstack + INITSTACKSIZE), %esp

    subl  $KERNEL_HIGH_VMA, %esp
	call init_boot_paging_ia32

 	addl  $KERNEL_HIGH_VMA, %esp
    mov   %esp, %ebp
    
	mov $VIDEO_RAM, %edi
    mov $VIDEO_DWORDS, %ecx
    mov $0x07200720, %eax
    rep stosl

	#push bootloader params
 	push  %eax
    push  %ebx
	
	call kmain

the_end:
	#shutdown msg
	mov $_msg_panic, %eax
	call boot_print_msg

	cli
	hlt

boot_print_msg:
	push %edx
	push %ebx

	mov $VIDEO_RAM, %edx

	_print_loop:
	   movb (%eax), %bl
	   xorb %bh, %bh
	   cmpb $0x0, %bl
	   je _end_print
	   orw $0x4F00, %bx
	   movw %bx, (%edx)
	   add $0x2, %edx
	   inc %eax
	   jmp _print_loop
	_end_print:

	pop %ebx
	pop %edx

init_boot_paging_ia32:
	push %eax
	push %ebx
	push %edx
	push %ecx

	mov  $_kernel_pd, %eax          # get virtual address of kernel pd
    sub  $KERNEL_HIGH_VMA, %eax     # adjust to physical address

	mov  $_kernel_low_pt, %ebx      # get virtual address of kernel low pt
    sub  $KERNEL_HIGH_VMA, %ebx     # adjust to physical address

  	or   $0x1, %ebx                 # set present flag

	mov  %ebx, (%eax)               # set the pde

	push %eax
    mov  $KERNEL_HIGH_VMA, %eax     # get virtual address offset
    shr  $22,  %eax                 # calculate index in the pd
    mov  $4, %ecx
    mul  %ecx                       # calculate byte offset (4bytes each entry)
    mov  %eax, %edx
    pop  %eax

 	push %eax                       # save the real address for later
    add  %edx, %eax                 # move the pointer in the pd to the correct entry.

    mov  $_kernel_pt, %ebx          # get virtual address of kernel main pt
    sub  $KERNEL_HIGH_VMA, %ebx     # adjust to physical address
    or   $0x1, %ebx                 # mark present
    mov  %ebx, (%eax)               # set the pde

    pop  %ebx                       # pop saved address of the kernel PD

    mov  $0x100000, %ecx            # map the low 1MB

   _idmap_first_mb_loop:
       mov %ecx, %edx              # phys == virt (identity mapping)
       call boot_map_page_ia32     # do the mapping
       sub $0x1000, %ecx           # one page down.
       jnz _idmap_first_mb_loop    # if not zero, continue (DON'T map zero :))

    mov  $KERNEL_BOOT_VMA, %ecx     # this is the _very_ beginning :)
    mov  $_core_end, %eax           # virtual address of end
    sub  $KERNEL_HIGH_VMA, %eax     # now it is physical.


 	_map_kernel:
		mov %ecx, %edx              # phys == virt (identity mapping)
		call boot_map_page_ia32     # do the mapping

		push %ecx
		add $KERNEL_HIGH_VMA, %ecx  # now map the virtual address to the same physical one
		call boot_map_page_ia32     # do it
		pop %ecx

        add $0x1000, %ecx           # on to the next page.
        cmp %eax, %ecx
        jle _map_kernel             # continue untill all the kernel is mapped.

    mov  %ebx, %cr3                 # use the kernel pd
    mov  %cr0, %eax                 # get the current cr0 value
    or   $(1 << 31), %eax           # enable paging
    mov  %eax, %cr0                 # now re-set the cr0 register.

	pop  %ecx
    pop  %edx
    pop  %ebx
    pop  %eax

    ret

boot_map_page_ia32:
	# ebx: physical addr of kernel PD
	# ecx: the virtual address to map
	# edx: the physical address to map to
	push %eax
	push %ebx
	push %ecx
	push %edx

	push %edx                       # push physical address
	push %ecx                       # push virtual address

	mov  %ecx, %eax
	shr  $22, %eax
	mov  $4, %ecx
	mul  %ecx                       # now we have the offset in eax
	add  %eax, %ebx                 # now ebx points to the phys addr of a pt if present
	mov  (%ebx), %eax

  	mov  %eax, %ecx
    and  $0x1, %ecx                 # check present flag
    cmp  $0x0, %ecx
    je the_end                      # if zero, PANIC!

	and  $0xFFFFF000, %eax          # clear off possible flags from the PDE.

 	pop  %edx                       # the virtual address.

    push %eax
    mov  %edx, %eax
    shr  $0xC, %eax                 # shift right to discard non-significant bits.
    and  $0x3FF, %eax               # and away not-relevant bits on the left.
    mov  $0x4, %ecx                 # each entry is 4 bytes
    mul  %ecx
    mov  %eax, %ebx                 # now in ebx: the offset into the PT for the PTE.
    pop  %eax

    pop  %edx                       # the phsyical target address

    add  %ebx, %eax                 # add offset to pt. this is the final location now.

   	or   $0x1, %edx                 # mark present...
    mov  %edx, (%eax)               # and insert into pt.

    pop %edx
	pop %ecx
    pop %ebx
    pop %eax
    ret
