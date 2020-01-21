
.altmacro

/* Clear the screen, move to position 0, 0. */
.macro CLEAR
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
.endm

.macro BEGIN
    .code16
    cli
    /* Set %cs to 0. TODO Is that really needed? */
    ljmp $0, $1f
    1:
    xor %ax, %ax
    /* We must zero %ds for any data access. */
    mov %ax, %ds
    /* TODO is it really need to clear all those segment registers, e.g. for BIOS calls? */
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    /* TODO What to move into BP and SP?
     * http://stackoverflow.com/questions/10598802/which-value-should-be-used-for-sp-for-booting-process
     */
    mov %ax, %bp
    /* Automatically disables interrupts until the end of the next instruction. */
    mov %ax, %ss
    /* We should set SP because BIOS calls may depend on that. TODO confirm. */
    mov %bp, %sp
    /* Store the initial dl to load stage 2 later on. */
    mov %dl, initial_dl
    jmp after_locals
    initial_dl: .byte 0
    msg1:
        .asciz "Loading sector 1\n\r"
after_locals:
.endm

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
    push %ax
    mov \c, %al
    mov $0x0E, %ah
    int $0x10
    pop %ax
.endm


/* Print a null terminated string.
 *
 * Use as:
 *
 * ....
 *     PRINT_STRING $s
 *     hlt
 * s:
 *     .asciz "string"
 * ....
 */
.macro PRINT_STRING s
    LOCAL end, loop
    mov s, %si
    mov $0x0e, %ah
    cld
loop:
    lodsb
    or %al, %al
    jz end
    int $0x10
    jmp loop
end:
.endm



/* Load stage2 from disk to memory, and jump to it.
 *
 * To be used when the program does not fit in the 512 bytes.
 *
 * Sample usage:
 *
 * ....
 * STAGE2
 * Stage 2 code here.
 * ....
 */
.macro STAGE2
    mov $1, %al # num sectors to read
    mov $0x02, %ah # Read Sectors when triggering int $0x13
    mov $sector2, %bx # where to write data
    mov $0x0002, %cx # track 0, sector 2
    mov $0x00, %dh # head 0
    mov initial_dl, %dl # drive set at start
    int $0x13 #  Low Level Disk Services
    jmp sector2
    .section .stage2
    sector2:
.endm


.macro OVERWRITE
    mov $1, %al # num sectors to read
    mov $0x02, %ah # Read Sectors when triggering int $0x13
    mov $__start, %bx # where to write data
    mov $0x0003, %cx # track 0, sector 2
    mov $0x00, %dh # head 0
    mov initial_dl, %dl # drive set at start
    int $0x13 #  Low Level Disk Services
    jmp __start
.endm

.macro WAIT2S
    mov $0x86, %ah # Wait when 0x15 is triggered
    /*interval in microseconds */
    mov $0x001E, %cx # MSW
    mov $0x8480, %dx # LSW
    int $0x15
.endm

__start:
    BEGIN
    CLEAR
    PRINT_STRING $msg1
STAGE2
    mov $msg2, %si
    mov $0x0e, %ah
    cld
loop2:
    lodsb
    or %al, %al
    jz end2
    int $0x10
    jmp loop2
end2:
    WAIT2S
    OVERWRITE

msg2:
    .asciz "Loading sector 2 over start\n\r"


