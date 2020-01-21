
all: chain_boot.img

#PAYLOAD=/home/axlan/src/mkernel/grub.img
PAYLOAD=../bios_hello_world.img

GAS ?= gcc
LD ?= ld

chain_boot.o: chain_boot.S
	$(GAS) -m32 -c -ggdb3 -o '$@' '$<'

chain_boot.img: chain_boot.o linker.ld
	$(LD) -melf_i386 -nostdlib -o 'chain_boot.elf' -T 'linker.ld' 'chain_boot.o'
	objcopy -O binary 'chain_boot.elf' 'chain_boot.img'
	cat $(PAYLOAD) >> chain_boot.img


run: chain_boot.img
	qemu-system-i386 -drive 'file=chain_boot.img,format=raw'

clean:
	rm -f chain_boot.img chain_boot.elf chain_boot.o
