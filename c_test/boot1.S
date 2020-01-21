
.altmacro


/* Convert the low nibble of a r8 reg to ASCII of 8-bit in-place.
 * reg: r8 to be converted
 * Output: stored in reg itself. Letters are uppercase.
 */
.macro HEX_NIBBLE reg
    LOCAL letter, end
    cmp $10, \reg
    jae letter
    add $'0, \reg
    jmp end
letter:
    /* 0x37 == 'A' - 10 */
    add $0x37, \reg
end:
.endm

/* Convert a byte to hex ASCII value.
 * c: r/m8 byte to be converted
 * Output: two ASCII characters, is stored in `ah:al`
 * http://stackoverflow.com/questions/3853730/printing-hexadecimal-digits-with-assembly
 */
.macro HEX c
    mov \c, %al
    mov \c, %ah
    shr $4, %al
    HEX_NIBBLE <%al>
    and $0x0F, %ah
    HEX_NIBBLE <%ah>
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

/* Print a byte as two hexadecimal digits.
 *
 * * reg: 1 byte register.
 */
.macro PRINT_HEX reg=<%al>
    push %ax
    HEX <\reg>
    PUTC <%al>
    PUTC <%ah>
    pop %ax
.endm

/* Print a 16-bit number
 *
 * * in: r/m/imm16
 */
.macro PRINT_WORD_HEX in=<%ax>
    push %ax
    mov \in, %ax
    PRINT_HEX <%ah>
    PRINT_HEX <%al>
    pop %ax
.endm


.code16
__start:
    .equ CODE_SEG, 8
    .equ DATA_SEG, gdt_data - gdt_start
    mov $hello1,%si # point si register to hello label memory location
    call prints
    mov $0x2401,%ax 
	int $0x15
	mov $0x3,%ax
	int $0x10
	cli
	lgdt gdt_pointer
	mov  %cr0,%eax
	or 0x1,%eax
	mov  %eax,%cr0
	jmp $CODE_SEG, $boot2
gdt_start:
	.long 0x0
    .long 0x0
gdt_code:
	.word 0xFFFF
	.word 0x0
	.byte 0x0
	.byte 0b10011010
	.byte 0b11001111
	.byte 0x0
gdt_data:
	.word 0xFFFF
	.word 0x0
	.byte 0x0
	.byte 0b10010010
	.byte 0b11001111
	.byte 0x0
gdt_end:
gdt_pointer:
	.word gdt_end - gdt_start
	.long gdt_start


.code32

boot2:
	mov $DATA_SEG,%ax
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%fs
	mov %ax,%gs
	mov %ax,%ss
	mov $hello2,%esi
    call vga_prints
	cli
	hlt


# assumes pointer to string is in %si
vga_prints:
    mov $0xb8000,%ebx
    cld
.loop_vga_prints:
    lodsb
	or %al,%al
	jz .halt_vga_prints
	or $0x0100,%eax
	movw %ax, (%ebx)
	add $2,%ebx
	jmp .loop_vga_prints
.halt_vga_prints:
	ret




# assumes pointer to string is in %si
prints:
    mov $0x0e, %ah
    cld
.loop_prints:
    lodsb
    or %al, %al
    jz .prints_end
    int $0x10
    jmp .loop_prints
.prints_end:
    ret


hello1:
    .asciz "hello world1"
hello2:
    .asciz "hello world2"



