# Studio II Loader for Elf/OS

This program loads Studio II cartridge image files (.st2 files) as supported
by the [Emma 02 Emulator](https://www.emma02.hobby-site.com/) Under Elf/OS,
relocating the code to $0000 and running it.

To be useful, this needs to be run on a machine with minimal compatible 
hardware with the Studio II, namely an 1861 video generation that is on
port 1 and Studio II keypads on port 2. The latter means that your disk
controller needs to either not be on port 2, or you need port group support,
with the keypads in a different group than the disk controller.

Currently I run this on the 1802/Mini with the as-yet experimental Pixie
Video card and an even more experimental keypad interface.

