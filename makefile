
st2.bin: st2.asm include/bios.inc include/kernel.inc
	asm02 -b -L st2.asm

clean:
	-rm -f *.bin *.lst

