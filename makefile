
vip.bin: vip.asm include/bios.inc include/kernel.inc
	asm02 -b -L vip.asm

clean:
	-rm -f *.bin *.lst

