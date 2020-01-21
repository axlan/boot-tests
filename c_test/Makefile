
all: boot.img

GAS ?= gcc
LD ?= ld

boot.o: boot.S
	$(GAS) -m32 -c -ggdb3 -o '$@' '$<'

boot.img: boot.o linker.ld
	#$(LD) -melf_i386 -nostdlib -o 'boot.elf' -T 'linker.ld' 'boot.o'
	g++ -c -ggdb3 -m32 -ffreestanding -fno-PIE -nostartfiles -nostdlib -o main.o -std=c++11 kmain.cpp
	ld -m elf_i386 -nostdlib -o boot.elf -T linker.ld boot.o main.o
	objcopy -O binary 'boot.elf' 'boot.img'


run: boot.img
	qemu-system-i386 -drive 'file=boot.img,format=raw'
