target remote | qemu-system-i386 -drive 'file=c_test/boot.img,format=raw' -gdb stdio -S
set architecture i8086
break *0x7c00
continue
