/* I really want this for the local labels.
 *
 * The major downside is that every register passed as argument requires `<>`:
 * http://stackoverflow.com/questions/19776992/gas-altmacro-macro-with-a-percent-sign-in-a-default-parameter-fails-with-oper/
 */
.altmacro


/* Structural. */

/* Setup a sane initial state.
 *
 * Should be the first thing in every file.
 *
 * Discussion of what is needed exactly: http://stackoverflow.com/a/32509555/895245
 */
.macro BEGIN
    LOCAL after_locals
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
after_locals:
.endm
