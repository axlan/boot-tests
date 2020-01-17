.POSIX:

COMMON ?= common.h
ELF_EXT = .elf
LD ?= ld
LINKER_SCRIPT ?= linker.ld
# Use gcc so that the preprocessor will run first.
GAS ?= gcc
GAS_EXT ?= .S
NASM_EXT ?= .asm
OBJ_EXT ?= .o
OUT_EXT ?= .img
QEMU ?= qemu-system-i386 -drive 'file=$(RUN_FILE),format=raw' -serial mon:stdio -smp 2
RUN ?= bios_hello_world
RUN_ARGS ?= -soundhw pcspk
TMP_EXT ?= .tmp

OUTS := $(sort $(foreach IN_EXT,$(NASM_EXT) $(GAS_EXT),$(patsubst %$(IN_EXT),%$(OUT_EXT),$(wildcard *$(IN_EXT)))))
RUN_FILE := $(RUN)$(OUT_EXT)

.PRECIOUS: %$(OBJ_EXT)
.PHONY: all clean doc run

all: $(OUTS)

%$(OUT_EXT): %$(OBJ_EXT) $(LINKER_SCRIPT)
	$(LD) -melf_i386  -nostdlib -o '$(@:$(OUT_EXT)=$(ELF_EXT))' -T '$(LINKER_SCRIPT)' '$<'
	objcopy -O binary '$(@:$(OUT_EXT)=.elf)' '$@'

%$(OBJ_EXT): %$(GAS_EXT) $(COMMON)
	$(GAS) -m32 -c -ggdb3 -o '$@' '$<'

%$(OUT_EXT): %$(NASM_EXT)
	nasm -f bin -o '$@' '$<'

# So that directories without a common.h can reuse this.
$(COMMON):

clean:
	rm -fr '$(DOC_OUT)' *$(ELF_EXT) *$(OBJ_EXT) *$(OUT_EXT) *$(TMP_EXT)

run: $(RUN_FILE)
	$(QEMU) $(RUN_ARGS)

debug: $(RUN_FILE)
	$(QEMU) -S -s &
	gdb -quiet -x gdb.gdb '$(<:$(OUT_EXT)=$(ELF_EXT))'
