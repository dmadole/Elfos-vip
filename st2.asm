;  Copyright 2021, David S. Madole <david@madole.net>
;
;  This program is free software: you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program.  If not, see <https://www.gnu.org/licenses/>.


            ; Include kernal API entry points

#include include/bios.inc
#include include/kernel.inc


            ; Hardware definitions for keypad port

#define EXP_PORT 5
#define KEYS_GROUP 1
#define KEYS_PORT 2


            ; Executable program header

            org   2000h - 6
            dw    start
            dw    end-start
            dw    start

start:      org   2000h
            br    main


            ; Build information

            db    9+80h                 ; month
            db    28                    ; day
            dw    2022                  ; year
            dw    1                     ; build

            db    'See github.com/dmadole/Elfos-st2 for more info',0


           ; Main code starts here, check provided argument

main:       req                         ; turn off in case already on

skpspac:    lda   ra                    ; skip any leading spaces, copy rom
            lbz   copyrom               ;  if no filename chars found
            sdi   ' '
            lbdf  skpspac

            ghi   ra                    ; save pointer to position
            phi   rf
            glo   ra
            plo   rf

            dec   rf                    ; adjust to first character

skpname:    lda   ra                    ; skip any non-space characters,
            lbz   endname               ;  if end then go copy rom
            sdi   ' '
            lbnf  skpname

            dec   ra                    ; zero terminate over first space
            ldi   0                     ;  character
            str   ra


            ; We have a filename at this point so open the file to read
            ; the cartridge image in.

endname:    plo   r7                    ; set flags to zero

            ldi   high fildes           ; get pointer to file descriptor
            phi   rd
            ldi   low fildes
            plo   rd

            sep   scall                 ; open file for read
            dw    o_open
            lbnf  opened

            sep   scall                 ; fail if unable to open
            dw    o_inmsg
            db    'Unable to open input file',13,10,0

            sep   sret                  ; and return


            ; Seek to offset 0040h in the file which is where the page
            ; mapping table starts which tells what memory page to load the
            ; consecutive page images in the file into.

opened:     ldi   0                     ; seek from beginning of file
            plo   rc

            phi   r8                    ; clear offset except low byte
            plo   r8
            phi   r7

            ldi   40h                   ; offset to page table
            plo   r7

            sep   scall                 ; seek to page table
            dw    o_seek


            ; Read the page table into memory so we can walk through it.

            ldi   high pages            ; pointer to page table buffer
            phi   rf                    ;  and save an extra copy to rb
            phi   rb
            ldi   low pages
            plo   rf
            plo   rb

            ldi   high 10h              ; length of page table to read
            phi   rc
            ldi   low 10h
            plo   rc

            sep   scall                 ; read page table to buffer
            dw    o_read


            ; Seek to 0100h in the file which is where cartridge data starts.

            ldi   0                     ; seek from beginning
            plo   rc

            phi   r8                    ; zero except for page byte
            plo   r8
            plo   r7

            ldi   1                     ; set offset to one page
            phi   r7

            sep   scall                 ; seek on file
            dw    o_seek


            ; If the page table is empty, just copy the ROM image and run.

            lda   rb                    ; if page table not empty, read it
            lbnz  getpage

            ldi   high 2048             ; if empty then get rom length
            phi   rf
            ldi   low 2048
            plo   rf

            lbr   copyrom               ; and just go copy the rom


            ; Walk through the page table, loading each page from the file
            ; until we get to a zero page specifier, making the end.

getpage:    adi   high rom              ; get rom page address to load to
            phi   rf
            ldi   low rom
            plo   rf

            ldi   1                     ; read one page
            phi   rc
            ldi   0
            plo   rc

            sep   scall                 ; read from file
            dw    o_read

            lda   rb                    ; if another page to read, do it
            lbnz  getpage


            ; The RF register will be left pointing just past the last page
            ; loaded, subtract the start from it to get the length.

            glo   rf                    ; get length of image to copy
            smi   low rom
            plo   rf
            ghi   rf
            smbi  high rom
            phi   rf


            ; Copy the ROM image to memory at 0000h which will destroy 
            ; Elf/OS in the process, so there is no coming back.

copyrom:    ldi   high rom              ; get pointer to start of image
            phi   r7
            ldi   low rom
            plo   r7

            ldi   0                     ; get pointer to start of memory
            phi   r8
            plo   r8

romloop:    lda   r7                    ; copy one byte of rom image
            str   r8
            inc   r8

            dec   rf                    ; loop until all bytes are copied
            glo   rf
            lbnz  romloop
            ghi   rf
            lbnz  romloop


            ; Now setup registers to simulate a hard reset which will
            ; jump to 0000h and start the ROM.

            phi   r0                    ; clear r0 which will be new pc
            plo   r0

            sex   r3                    ; inline arguments for next opcodes

            out   EXP_PORT              ; set port expander to group 1
            db    KEYS_GROUP

            ret                         ; set p=0 and x=0 to run rom image
            db    0


            ; File descriptor for loading cartridge data

fildes:     db    0,0,0,0               ; file descriptor with dta just past
            dw    1000h+rom             ;  the rom image included below
            db    0,0
            db    0
            db    0,0,0,0
            dw    0,0
            db    0,0,0,0


            ; Buffer for loading page mapping table

pages:      db    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


            ; Copy of the built-in ROM from the Studio II

rom:        db    090h,0b1h,0b4h,0a5h,0abh,0f8h,008h,0b2h
            db    0b6h,0b8h,0f8h,01ch,0a1h,0f8h,0bfh,0a2h
            db    0f8h,06bh,0a4h,0f8h,003h,0b5h,0d4h,07ah
            db    042h,0f6h,042h,070h,022h,078h,022h,073h
            db    0c0h,000h,023h,07eh,052h,019h,0f8h,009h
            db    0b0h,0f8h,0d0h,0a8h,08bh,0a0h,0e2h,020h
            db    0a0h,0e2h,020h,0a0h,0e2h,020h,0a0h,080h
            db    020h,0a0h,03ch,02fh,020h,0a0h,034h,03ch
            db    028h,008h,032h,047h,0ffh,001h,058h,088h
            db    0fbh,0cdh,03ah,040h,008h,032h,017h,07bh
            db    030h,018h,019h,089h,0aeh,093h,0beh,099h
            db    0eeh,0f4h,056h,0f6h,0e6h,0f4h,0b9h,056h
            db    045h,0f2h,056h,0d4h,000h,000h,0e2h,022h
            db    069h,012h,0d4h,096h,0b7h,094h,0bch,045h
            db    0ach,0afh,0f6h,0f6h,0f6h,0f6h,032h,094h
            db    0f9h,0e0h,0ach,08fh,0fah,00fh,0f9h,0c0h
            db    0a6h,005h,0f6h,0f6h,0f6h,0f6h,0f9h,0c0h
            db    0a7h,04ch,0b3h,08ch,0fch,00fh,0ach,04ch
            db    0a3h,0d3h,030h,06bh,08fh,0fah,00fh,0b3h
            db    045h,030h,090h,022h,0e2h,0f8h,0d3h,073h
            db    045h,0f9h,0f0h,052h,0e6h,047h,0d2h,056h
            db    0f8h,0cbh,0a6h,091h,07eh,056h,0d4h,086h
            db    0fbh,0c0h,03ah,052h,042h,0b5h,042h,0a5h
            db    0d4h,045h,056h,0d4h,064h,00ah,001h,006h
            db    03ah,0c7h,015h,0d4h,006h,03ah,0c2h,005h
            db    0a5h,0d4h,015h,085h,022h,052h,095h,022h
            db    052h,025h,045h,0a5h,086h,0fah,00fh,0b5h
            db    0d4h,086h,0fah,00fh,0bah,045h,0aah,0d4h
            db    000h,000h,000h,000h,000h,002h,000h,002h
            db    000h,002h,000h,002h,000h,002h,001h,002h
            db    000h,0d2h,0cah,0bfh,0c4h,04eh,0b9h,03dh
            db    09bh,056h,0d9h,0e5h,0afh,0bfh,000h,0a4h
            db    0f8h,0c9h,0a7h,007h,0feh,0feh,0feh,0feh
            db    0a6h,0f8h,0d0h,0e7h,0f4h,0a7h,0f8h,002h
            db    0bch,0f8h,092h,0ach,0dch,010h,00fh,0bdh
            db    0dch,008h,00fh,0fah,00fh,0aeh,00fh,0fah
            db    080h,0beh,007h,0adh,025h,045h,0f6h,033h
            db    04eh,0f6h,033h,049h,0f6h,033h,03dh,0f6h
            db    033h,0bch,0f8h,010h,0afh,091h,056h,016h
            db    02fh,08fh,03ah,035h,0d4h,0e6h,08eh,032h
            db    03ch,04ah,0f3h,056h,016h,016h,02eh,030h
            db    03eh,0f8h,0cch,0afh,00fh,0bdh,09dh,0fbh
            db    002h,032h,063h,09dh,0fbh,008h,032h,06dh
            db    09dh,0fbh,004h,032h,097h,09dh,0fbh,006h
            db    032h,072h,0d4h,007h,0ffh,008h,057h,0dch
            db    018h,093h,0f5h,05fh,0d4h,007h,0fch,008h
            db    030h,066h,08eh,032h,0f9h,006h,0f6h,056h
            db    03bh,081h,09eh,03ah,081h,0f8h,080h,0beh
            db    01dh,016h,006h,076h,056h,03bh,093h,026h
            db    006h,0f9h,080h,056h,016h,09eh,032h,093h
            db    091h,0beh,01dh,016h,02eh,030h,072h,08eh
            db    032h,0f9h,006h,0feh,056h,03bh,0a5h,09eh
            db    032h,0a5h,091h,0beh,02dh,016h,006h,07eh
            db    056h,03bh,0b8h,026h,006h,0f9h,001h,056h
            db    016h,09eh,03ah,0b8h,0f8h,080h,0beh,02dh
            db    016h,02eh,030h,097h,093h,0bch,0f8h,0ebh
            db    0ach,091h,0afh,09eh,032h,0d4h,02dh,08eh
            db    032h,0e1h,0dch,01dh,0dch,08dh,0fch,007h
            db    0adh,02eh,030h,0c7h,08eh,032h,0e1h,0dch
            db    02dh,0dch,08dh,0fch,009h,0adh,02eh,030h
            db    0d4h,08fh,03ah,0e6h,015h,0d4h,005h,0a5h
            db    0d4h,016h,0d3h,0f8h,009h,0bdh,0edh,006h
            db    0f2h,032h,0f4h,0afh,006h,0f3h,05dh,030h
            db    0e9h,0dch,020h,00fh,0ffh,001h,05fh,0dch
            db    008h,00fh,0fah,00fh,05fh,09eh,0f1h,05fh
            db    08dh,057h,0d4h,022h,0f9h,023h,0c3h,0c0h
            db    02fh,01ah,025h,01fh,038h,023h,027h,033h
            db    029h,02bh,060h,020h,020h,020h,070h,0f0h
            db    010h,070h,010h,0f0h,080h,0f0h,010h,0f0h
            db    080h,0f0h,090h,0f0h,090h,0f0h,010h,0f0h
            db    090h,090h,090h,0f0h,010h,010h,010h,010h
            db    0a0h,0a0h,0f0h,020h,020h,086h,0fah,00fh
            db    032h,047h,0e6h,045h,0f4h,056h,0d4h,006h
            db    0ffh,001h,03ah,0e1h,015h,0d4h,045h,0e6h
            db    0f3h,032h,04dh,015h,015h,0d4h,096h,0bch
            db    007h,0ach,045h,0f6h,033h,09bh,0f6h,033h
            db    06ah,0f6h,033h,06dh,0f6h,033h,070h,007h
            db    030h,04fh,00ch,056h,0d4h,006h,05ch,0d4h
            db    0e6h,006h,0bfh,091h,0beh,0f8h,0bch,0aeh
            db    02ch,01ch,091h,05ch,00eh,0f5h,03bh,087h
            db    056h,00ch,0fch,001h,05ch,030h,07ch,04eh
            db    0f6h,03bh,079h,09fh,056h,08ch,057h,0d4h
            db    0efh,0d3h,096h,0bfh,087h,0e3h,0f4h,0afh
            db    013h,030h,090h,006h,057h,0d4h,023h,036h
            db    0e2h,070h,09eh,0c0h,045h,0a3h,00ah,056h
            db    0d4h,006h,05ah,0d4h,04ah,056h,0d4h,006h
            db    05ah,01ah,0d4h,006h,0aah,0d4h,006h,0fah
            db    00fh,056h,0e6h,08ah,0f1h,0aah,0d4h,0f8h
            db    0cbh,0a7h,086h,0fah,00fh,0afh,0fbh,00fh
            db    03ah,0cch,007h,0afh,0e2h,022h,08fh,052h
            db    062h,0f8h,0cah,0a6h,006h,032h,0dbh,036h
            db    0ddh,015h,0d4h,03fh,0d9h,08fh,057h,030h
            db    0e2h,056h,005h,0a5h,0d4h,045h,05ah,022h
            db    0e2h,086h,0fah,00fh,052h,08ah,0f4h,0aah
            db    012h,0d4h,091h,05ah,08ah,02ah,03ah,0f2h
            db    0d4h,06dh,002h,06eh,00ah,03eh,0fdh,0c0h
            db    06dh,004h,0a9h,0ffh,002h,0f2h,0a8h,09fh
            db    002h,0f2h,000h,066h,0a8h,0d2h,0b2h,0f8h
            db    0b1h,015h,0b3h,011h,0b1h,004h,0b1h,004h
            db    0b1h,001h,0b1h,002h,0b1h,005h,0b0h,005h
            db    0a3h,02bh,069h,004h,079h,0ffh,0e4h,039h
            db    024h,014h,000h,003h,003h,080h,018h,018h
            db    018h,018h,018h,018h,018h,018h,0e8h,03ah
            db    013h,03ch,0e8h,03ch,0c0h,060h,00fh,022h
            db    0f9h,070h,03fh,0c0h,069h,002h,06ch,006h
            db    060h,07fh,022h,09eh,023h,054h,06ch,006h
            db    0e2h,023h,054h,0c0h,06ch,008h,060h,020h
            db    022h,09eh,0c0h,069h,003h,0a8h,0d3h,0b0h
            db    003h,013h,04eh,08bh,0ffh,008h,0abh,0d4h
            db    069h,004h,089h,0a4h,023h,088h,062h,082h
            db    093h,028h,0e0h,060h,002h,06ch,006h,023h
            db    096h,0e4h,0e2h,0e2h,0e2h,0e2h,0e2h,0e2h
            db    070h,077h,023h,096h,0e4h,0e8h,087h,0c0h
            db    062h,080h,082h,0a4h,093h,022h,0c0h,023h
            db    088h,083h,014h,093h,024h,0c0h,0a2h,010h
            db    093h,022h,0f3h,0b6h,0f3h,0a6h,0f3h,0b3h
            db    072h,0ffh,0c0h,06ah,001h,023h,068h,06ah
            db    000h,023h,068h,06eh,07fh,03eh,0adh,0c0h
            db    06ah,001h,023h,0b9h,06ah,000h,023h,0b9h
            db    0c0h,023h,088h,083h,015h,04bh,0b8h,023h
            db    03dh,013h,0c1h,04ah,0c8h,003h,0cbh,0c0h
            db    003h,0ceh,0c0h,036h,0cbh,0d4h,037h,0ceh
            db    0d4h,023h,068h,023h,08fh,023h,068h,0c0h
            db    0d2h,0e3h,0d4h,0e3h,0d6h,0e3h,0d8h,0e3h
            db    06bh,000h,0c0h,022h,00bh,0c0h,061h,0d1h
            db    069h,001h,0f2h,0ach,092h,014h,0e8h,0f0h
            db    070h,0eah,0c0h,000h,022h,00bh,092h,011h
            db    023h,0d1h,061h,064h,023h,0b9h,017h,0f8h
            db    06ah,001h,0d1h,00eh,0d2h,039h,0d3h,08bh
            db    0d4h,08dh,0d5h,08fh,014h,000h,069h,002h
            db    068h,000h,06dh,004h,0e8h,014h,06ah,001h
            db    0d2h,037h,06ah,000h,025h,006h,014h,014h
            db    04bh,010h,05bh,005h,014h,033h,06eh,008h
            db    03eh,028h,038h,02eh,0e8h,02eh,024h,06fh
            db    0e2h,014h,014h,068h,0ffh,014h,012h,0e8h
            db    039h,069h,002h,060h,082h,0a8h,030h,06dh
            db    004h,023h,0c3h,06ah,000h,025h,006h,014h
            db    043h,05bh,005h,014h,043h,04bh,058h,0fbh
            db    0afh,024h,06fh,0e2h,0e8h,056h,070h,041h
            db    0b0h,000h,06dh,008h,0a8h,030h,0fch,0ach
            db    04ch,05ch,024h,071h,0e2h,0e8h,067h,0d5h
            db    06bh,014h,05eh,0d0h,05eh,014h,06bh,09bh
            db    0c1h,063h,001h,083h,0c2h,043h,08ah,063h
            db    005h,08ch,035h,04bh,085h,04ch,08ah,07ch
            db    002h,0e2h,06ch,008h,0c0h,07ch,008h,0e2h
            db    06ch,002h,0c0h,016h,003h,015h,013h,06dh
            db    004h,023h,0c3h,0a8h,0d0h,0b8h,083h,0b0h
            db    005h,023h,0a3h,067h,015h,06eh,030h,03eh
            db    09fh,06dh,003h,066h,00ch,064h,0ffh,065h
            db    0ffh,077h,0ffh,037h,0afh,013h,0bfh,068h
            db    000h,0a8h,082h,060h,003h,0c2h,003h,0f2h
            db    0afh,088h,024h,070h,0b5h,069h,000h,062h
            db    084h,023h,072h,03fh,0cdh,076h,0ffh,06fh
            db    020h,036h,0cdh,014h,0f9h,06ah,001h,025h
            db    006h,014h,0e1h,09bh,021h,044h,0e1h,06dh
            db    002h,082h,083h,042h,0f5h,064h,000h,014h
            db    0e1h,06ah,000h,025h,006h,014h,0c3h,09bh
            db    021h,045h,0c3h,06dh,002h,082h,083h,042h
            db    0f5h,065h,000h,014h,0c3h,096h,011h,023h
            db    0d1h,069h,000h,0e8h,09dh,014h,09dh,042h
            db    0b5h,042h,0a5h,015h,015h,0d4h,06bh,00ah
            db    07bh,0ffh,0dfh,00fh,03bh,008h,0c0h,06dh
            db    002h,004h,0ffh,0a5h,0e3h,060h,008h,023h
            db    0e6h,0a8h,0d0h,0b1h,009h,0b7h,0b2h,0b1h
            db    007h,0b0h,008h,0a5h,0ebh,069h,000h,025h
            db    0d9h,025h,0d9h,064h,00ah,067h,012h,065h
            db    078h,063h,020h,068h,020h,06dh,020h,066h
            db    006h,060h,00ah,0a8h,081h,06ah,001h,0d0h
            db    04bh,06ah,000h,0d0h,047h,015h,03dh,0b0h
            db    001h,015h,04dh,0b0h,003h,06ah,001h,0d2h
            db    085h,0d8h,089h,06ah,000h,0d4h,0b3h,0d6h
            db    0b3h,03eh,061h,045h,061h,075h,0ffh,06eh
            db    03ch,03fh,04dh,073h,0ffh,090h,080h,015h
            db    077h,06dh,002h,088h,005h,04bh,073h,078h
            db    0feh,015h,075h,078h,002h,088h,004h,033h
            db    08dh,061h,001h,023h,08fh,063h,010h,035h
            db    08dh,023h,068h,013h,0bfh,060h,000h,015h
            db    053h,060h,00ah,015h,053h,069h,001h,06ch
            db    002h,025h,0cbh,098h,0f1h,003h,063h,047h
            db    0adh,096h,0c1h,069h,000h,0a8h,081h,0f2h
            db    0a6h,0cbh,0ffh,082h,0b2h,042h,04dh,025h
            db    0cbh,077h,0ffh,015h,04dh,025h,0fah,067h
            db    012h,015h,04dh,09bh,0c1h,05ch,004h,015h
            db    0c5h,054h,015h,015h,059h,074h,001h,069h
            db    001h,025h,0cbh,015h,059h,044h,0c3h,074h
            db    0ffh,015h,0bfh,0e8h,0cdh,0e2h,005h,0e0h
            db    0e8h,0d3h,0c0h,068h,01ah,06dh,004h,015h
            db    0d2h,0e0h,0e4h,0e8h,0ddh,079h,001h,0c0h
            db    03ch,0e0h,0d4h,000h,040h,080h,0c0h,004h
            db    044h,084h,0c4h,0b4h,0fch,0b4h,030h,0b4h
            db    0fch,0b4h,010h,0bah,0feh,0bah,038h,0bah
            db    0feh,0bah,062h,004h,056h,004h,062h,006h
            db    092h,061h,0c0h,064h,000h,0a8h,0dbh,0b0h
            db    005h,027h,041h,074h,001h,054h,00bh,016h
            db    01bh,066h,001h,026h,029h,066h,000h,026h
            db    029h,016h,009h,023h,068h,06ah,001h,023h
            db    068h,0a7h,086h,067h,09bh,026h,094h,013h
            db    0bfh,067h,07dh,046h,02fh,067h,079h,0a7h
            db    090h,027h,04eh,077h,001h,062h,070h,094h
            db    028h,060h,001h,027h,046h,023h,075h,0a8h
            db    0dbh,0b0h,005h,023h,0a3h,096h,0a1h,027h
            db    041h,0a8h,020h,0b0h,080h,0a8h,0d2h,0b8h
            db    0f8h,0b0h,001h,023h,044h,066h,000h,069h
            db    001h,0a8h,0d9h,0b0h,004h,0a7h,054h,0e0h
            db    0e4h,0a7h,058h,060h,00ah,023h,0e6h,0a8h
            db    060h,060h,00ah,0b1h,001h,070h,06bh,026h
            db    0beh,051h,000h,026h,0b1h,051h,00ah,016h
            db    09bh,086h,014h,026h,0beh,086h,014h,051h
            db    000h,026h,0b1h,056h,00ah,016h,0a9h,06fh
            db    05fh,03fh,089h,027h,041h,096h,011h,023h
            db    08fh,0c0h,067h,0c1h,027h,04eh,077h,001h
            db    027h,04eh,0c0h,0a7h,068h,066h,014h,026h
            db    092h,060h,004h,022h,0f9h,070h,0a3h,016h
            db    087h,0a7h,072h,066h,00fh,026h,092h,016h
            db    087h,0a7h,07ch,026h,092h,06fh,03fh,03fh
            db    0b7h,0a7h,07ch,026h,092h,0c0h,069h,000h
            db    0a8h,0d0h,0b8h,008h,0b8h,006h,0b8h,006h
            db    0b8h,000h,0b0h,038h,0a7h,062h,0e0h,0e4h
            db    065h,018h,0e8h,0d4h,055h,018h,06ch,008h
            db    055h,000h,06ch,002h,03fh,0efh,05ch,002h
            db    075h,001h,05ch,008h,075h,0ffh,0cfh,004h
            db    07fh,000h,0e8h,0ech,0e2h,016h,0d2h,0d2h
            db    0f9h,0d8h,0f9h,0d5h,0f7h,016h,0dch,06bh
            db    000h,09bh,081h,06dh,006h,06ch,000h,061h
            db    000h,069h,000h,03fh,003h,05ch,002h,075h
            db    001h,05ch,008h,075h,0ffh,0e8h,00fh,0e1h
            db    0e1h,0e2h,0e8h,018h,06fh,007h,017h,026h
            db    069h,001h,067h,00ah,077h,0ffh,097h,081h
            db    027h,095h,033h,0cbh,037h,01ch,055h,019h
            db    017h,03ch,055h,0ffh,017h,03ch,0a8h,0f0h
            db    0f3h,0a6h,053h,000h,017h,03ch,053h,01eh
            db    098h,0c1h,017h,001h,069h,000h,0e8h,040h
            db    0c0h,0a9h,0ffh,002h,0f2h,0c0h,069h,003h
            db    063h,0d3h,097h,034h,0e0h,0c0h,027h,046h
            db    0e4h,0e8h,053h,0c0h,03ch,024h,024h,03ch
            db    0d7h,097h,057h,017h,0b6h,076h,036h,095h
            db    055h,074h,03fh,03fh,03fh,03fh,03fh,03fh
            db    0eeh,084h,0e5h,024h,0e4h,077h,015h,075h
            db    045h,077h,0eeh,08ah,0eeh,028h,0e8h,067h
            db    024h,0a7h,021h,077h,07dh,055h,055h,045h
            db    045h,077h,044h,077h,011h,077h,0f6h,086h
            db    0e5h,084h,0f4h,05fh,049h,049h,0c9h,0dfh
            db    03ch,020h,038h,020h,020h,062h,060h,082h
            db    084h,093h,022h,0c0h,0a7h,058h,062h,058h
            db    082h,084h,0f2h,0b3h,0f3h,0a6h,062h,0d1h
            db    093h,024h,0c0h,06dh,002h,062h,060h,082h
            db    084h,063h,000h,093h,024h,071h,001h,06eh
            db    004h,03eh,0b9h,0c0h,0c3h,001h,043h,0cah
            db    027h,095h,043h,0cah,027h,09ch,0e8h,0c8h
            db    027h,0abh,0c0h,027h,09ch,0e8h,0cfh,0e8h
            db    0d3h,017h,024h,0e8h,0d5h,027h,0abh,057h
            db    005h,017h,0f3h,057h,002h,017h,0e5h,057h
            db    001h,017h,0e5h,017h,024h,04ch,0e3h,068h
            db    000h,060h,004h,027h,0bch,078h,001h,070h
            db    0ebh,017h,024h,04ch,0f1h,068h,006h,027h
            db    0bch,068h,004h,027h,0bch,017h,024h,0bbh

end:       ; That's all folks!

