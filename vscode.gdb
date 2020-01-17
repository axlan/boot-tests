target remote | qemu-system-i386 -drive 'file=bios_hello_world.img,format=raw' -gdb stdio -smp 2 -S
set architecture i8086
break *0x7c00
continue
