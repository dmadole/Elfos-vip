# RCA VIP Loader for Elf/OS

This Elf/OS program loads a VIP ROM image and optionally a program image to RAM and runs them.

To be useful, this needs to be run on a machine with minimal compatible hardware with the VIP, namely an 1861 video generation that is on port 1 and VIP keypads on port 2. The latter means that your disk controller needs to either not be on port 2, or you need port group support, with the keypads in a different group than the disk controller.

Currently I run this on the 1802/Mini with the as-yet experimental Pixie Video card and an even more experimental keypad interface.

When run with no command line argument, it just starts the monitor ROM. When given a filename argument, it loads that binary image to RAM at 0000 and runs it as the monitor ROM on the VIP would.

