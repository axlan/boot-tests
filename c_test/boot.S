
/* Helpers */

/* Structural. */

/* Print a 8 bit ASCII value at current cursor position.
 *
 * * `c`: r/m/imm8 ASCII value to be printed.
 *
 * Usage:
 *
 * ....
 * PUTC $'a
 * ....
 *
 * prints `a` to the screen.
 */
.macro PUTC c=$0x20
    push %ax # store %ax on stack
    mov \c, %al # character to print
    mov $0x0E, %ah # set interrupt to Write Character in TTY Mode
    int $0x10 # trigger bios interupt to print char
    pop %ax # restore %ax
.endm


/* VGA */

/* Print a NULL terminated string to position 0 in VGA.
 *
 * s: 32-bit register or memory containing the address of the string to print.
 *
 * Clobbers: none.
 *
 * Uses and updates vga_current_line to decide the current line.
 * Loops around the to the top.
 */
.macro VGA_PRINT_STRING s
    mov \s, %ecx
    mov vga_current_line, %eax
    mov $0, %edx
    /* Number of horizontal lines. */
    mov $25, %ebx
    div %ebx
    mov %edx, %eax
    /* 160 == 80 * 2 == line width * bytes per character on screen */
    mov $160, %edx
    mul %edx
    /* 0xb8000 == magic video memory address which shows on the screen. */
    lea 0xb8000(%eax), %edx
    /* White on black. */
    mov $0x0f, %ah
vga_print_loop:
    mov (%ecx), %al
    cmp $0, %al
    je vga_print_end
    mov %ax, (%edx)
    add $1, %ecx
    add $2, %edx
    jmp vga_print_loop
vga_print_end:
    incl vga_current_line
.endm


/* Enter protected mode. Use the simplest GDT possible. */
.macro PROTECTED_MODE
    /* Must come before they are used. */
    .equ CODE_SEG, 8
    .equ DATA_SEG, gdt_data - gdt_start

    /* Tell the processor where our Global Descriptor Table is in memory. */
    lgdt gdt_descriptor

    /* Set PE (Protection Enable) bit in CR0 (Control Register 0),
     * effectively entering protected mode.
     */
    mov %cr0, %eax
    orl $0x1, %eax
    mov %eax, %cr0

    ljmp $CODE_SEG, $protected_mode
/* Our GDT contains:
 *
 * * a null entry to fill the unusable entry 0:
 * http://stackoverflow.com/questions/33198282/why-have-the-first-segment-descriptor-of-the-global-descriptor-table-contain-onl
 * * a code and data. Both are necessary, because:
 * +
 * --
 * ** it is impossible to write to the code segment
 * ** it is impossible execute the data segment
 * --
 * +
 * Both start at 0 and span the entire memory,
 * allowing us to access anything without problems.
 *
 * A real OS might have 2 extra segments: user data and code.
 *
 * This is the case for the Linux kernel.
 *
 * This is better than modifying the privilege bit of the GDT
 * as we'd have to reload it several times, losing cache.
 */
gdt_start:
gdt_null:
    .long 0x0
    .long 0x0
gdt_code:
    .word 0xffff
    .word 0x0
    .byte 0x0
    .byte 0b10011010
    .byte 0b11001111
    .byte 0x0
gdt_data:
    .word 0xffff
    .word 0x0
    .byte 0x0
    .byte 0b10010010
    .byte 0b11001111
    .byte 0x0
gdt_end:
gdt_descriptor:
    .word gdt_end - gdt_start
    .long gdt_start
vga_current_line:
    .long 0
.code32
protected_mode:
    /* Setup the other segments.
     * Those movs are mandatory because they update the descriptor cache:
     * http://wiki.osdev.org/Descriptor_Cache
     */
    mov $DATA_SEG, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss
    /* TODO detect the last memory address available properly.
     * It depends on how much RAM we have.
     */
    mov $0X7000, %ebp
    mov %ebp, %esp
.endm

__start:
    .code16 # use 16 bit instructions
    cli # disable interrupts
    /* Set %cs to 0. TODO Is that really needed? */
    ljmp $0, $1f # dummy jump to next instruction
    1:
    xor %ax, %ax # set ax to 0
    /* We must zero %ds for any data access. */
    mov %ax, %ds
    /* TODO is it really need to clear all those segment registers, e.g. for BIOS calls? */
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    /* TODO What to move into BP and SP?
     * http://stackoverflow.com/questions/10598802/which-value-should-be-used-for-sp-for-booting-process
     */
    mov %ax, %bp # The stack frame, usually treated as an offset from the stack segment SS
    /* Automatically disables interrupts until the end of the next instruction. */
    mov %ax, %ss
    /* We should set SP because BIOS calls may depend on that. TODO confirm. */
    mov %bp, %sp # This is the stack pointer, offset usually from the stack segment SS
    /* Store the initial dl to load stage 2 later on. */
    mov %dl, initial_dl
    jmp clear
    initial_dl: .byte 0
    
clear:
    mov $0x0600, %ax
    mov $0x7, %bh
    mov $0x0, %cx
    mov $0x184f, %dx
    int $0x10
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0, %dh
    mov $0, %dl
    int $0x10

    PUTC $'a

load_next_sectors:
/*
AH = 02h   Read disk sectors
    Entry:
        ES:BX   Buffer address
        DL      Drive number (80h-81h)
        DH      Head number (0-15)
        CH      Track number (0-1023) Put the two high-order bits (8 and 9) in the high-order bits of CL
        CL      Sector number (1-17)
        AL      Number of sectors (1-80h for read) (1-79h for long read, includes ECC)
    Exit:
        AL      Number of sectors transferred
*/
/* Defined in the linker script. */
    mov $__stage2_nsectors, %al # num sectors to read
    mov $0x02, %ah # Read Sectors when triggering int $0x13
    mov $sector2, %bx # where to write data
    mov $0x0002, %cx # track 0, sector 2
    mov $0x00, %dh # head 0
    mov initial_dl, %dl # drive set at start
    int $0x13 #  Low Level Disk Services
    PROTECTED_MODE
    jmp sector2 # jump to loaded data
.section .stage2
sector2:
    incl vga_current_line
    VGA_PRINT_STRING $message
    mov $__stack_top , %esp
	call kmain
	cli
    hlt
message:
    .asciz "hello world"
