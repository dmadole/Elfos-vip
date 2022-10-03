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

            db    10+80h                 ; month
            db    2                     ; day
            dw    2022                  ; year
            dw    1                     ; build

            db    'See github.com/dmadole/Elfos-vip for more info',0


           ; Main code starts here, check provided argument

main:       ldi   high file             ; place to append filename to path
            phi   rb
            ldi   low file
            plo   rb

skpspac:    lda   ra                    ; skip any leading spaces, copy rom
            lbz   copyrom               ;  if no filename chars found

            str   rb                    ; save to prefixed buffer

            sdi   ' '                   ; if whitespace then skip
            lbdf  skpspac

            ghi   ra                    ; save pointer to position
            phi   rf
            glo   ra
            plo   rf

            dec   rf                    ; adjust to first character

skpname:    lda   ra                    ; skip any non-space characters,

            inc   rb                    ; save to prefixed buffer
            str   rb

            lbz   endname               ; if end then go copy rom

            sdi   ' '                   ; skip until next whitespace
            lbnf  skpname

            dec   ra                    ; zero terminate over first space
            ldi   0                     ;  character
            str   ra


            ; We have a filename at this point so open the file to read
            ; the RAM image in.

endname:    plo   r7                    ; set flags to zero

            ldi   high fildes           ; get pointer to file descriptor
            phi   rd
            ldi   low fildes
            plo   rd

            sep   scall                 ; open file for read
            dw    o_open
            lbnf  opened

            ldi   high path             ; try again with prefixed name
            phi   rf
            ldi   low path
            plo   rf

            sep   scall                 ; open file for read
            dw    o_open
            lbnf  opened

            sep   scall                 ; fail if unable to open
            dw    o_inmsg
            db    'Unable to open input file',13,10,0

            sep   sret                  ; and return


            ; Read the RAM image into static memory following the DTA as a
            ; temporary buffer. We will later copy it to 0000, which will
            ; destroy Elf/OS, which is why we need to do this in two steps.

opened:     ldi   high ram              ; get ram buffer to load to
            phi   rf
            ldi   low ram
            plo   rf

            ldi   high 4000h            ; read up to 16k
            phi   rc
            ldi   low 4000h
            plo   rc

            sep   scall                 ; read from file
            dw    o_read


            ; The RF register will be left pointing just past the last byte
            ; loaded, subtract the start from it to get the length.

            glo   rf                    ; get length of image to copy
            smi   low ram
            plo   rf
            ghi   rf
            smbi  high ram
            phi   rf


            ; Copy the RAM image to doen to memory starting at 0000h.

copyram:    ldi   high bootpx           ; pointer to boot p,x
            phi   r9
            ldi   low bootpx
            plo   r9

            ldi   high ram              ; get pointer to start of image
            phi   r7
            ldi   low ram
            plo   r7

            ldi   0                     ; set boot p,x to 0,0
            str   r9

            phi   r8                    ; get pointer to start of memory
            plo   r8

ramloop:    lda   r7                    ; copy one byte of ram image
            str   r8
            inc   r8

            dec   rf                    ; loop until all bytes are copied
            glo   rf
            lbnz  ramloop
            ghi   rf
            lbnz  ramloop


            ; Copy the ROM image to memory at 8000h, but note that this
            ; requires an expander card. This could be patched into the
            ; start of the 32K of ROM with a little cleverness though.

copyrom:    ldi   high rom              ; get pointer to start of image
            phi   r7
            ldi   low rom
            plo   r7

            ldi   high 8000h            ; get pointer to start of memory
            phi   r8
            ldi   low 8000h
            plo   r8

            ldi   high 0200h            ; size of rom image
            phi   rf
            ldi   low 0200h
            plo   rf

romloop:    lda   r7                    ; copy one byte of rom image
            str   r8
            inc   r8

            dec   rf                    ; loop until all bytes are copied
            glo   rf
            lbnz  romloop
            ghi   rf
            lbnz  romloop


            ; Setup registers to the same as the initial ROM code does,
            ; then set P to either R0 or R2 to start from RAM or ROM,
            ; respectively, which is how the first monitor code works.

            plo   r0                    ; set r0 to 0000 to simulate reset
            phi   r0

            ldi   high 7fffh            ; set r1 to last byte of memory
            phi   r1
            ldi   low 7fffh
            plo   r1

            ldi   high 8028h            ; set r2 to start of monitor code
            phi   r2
            ldi   low 8028h
            plo   r2

            req                         ; turn off in case already on

            sex   r3                    ; inline arguments for next opcodes

            out   EXP_PORT              ; set port expander to group 1
            db    KEYS_GROUP

            ret                         ; set p and x to boot register
bootpx:     db    22h


            ; File descriptor for loading RAM image

fildes:     db    0,0,0,0               ; file descriptor with dta just past
            dw    dta                   ;  the rom image included below
            db    0,0
            db    0
            db    0,0,0,0
            dw    0,0
            db    0,0,0,0


            ; Copy of the built-in ROM from the VIP

rom:        db    0f8h,080h,0b2h,0f8h,008h,0a2h,0e2h,0d2h
            db    064h,000h,062h,00ch,0f8h,0ffh,0a1h,0f8h
            db    00fh,0b1h,0f8h,0aah,051h,001h,0fbh,0aah
            db    032h,022h,091h,0ffh,004h,03bh,022h,0b1h
            db    030h,012h,036h,028h,090h,0a0h,0e0h,0d0h
            db    0e1h,0f8h,000h,073h,081h,0fbh,0afh,03ah
            db    029h,0f8h,0d2h,073h,0f8h,09fh,051h,081h
            db    0a0h,091h,0b0h,0f8h,0cfh,0a1h,0d0h,073h
            db    020h,020h,040h,0ffh,001h,020h,050h,0fbh
            db    082h,03ah,03eh,092h,0b3h,0f8h,051h,0a3h
            db    0d3h,090h,0b2h,0bbh,0bdh,0f8h,081h,0b1h
            db    0b4h,0b5h,0b7h,0bah,0bch,0f8h,046h,0a1h
            db    0f8h,0afh,0a2h,0f8h,0ddh,0a4h,0f8h,0c6h
            db    0a5h,0f8h,0bah,0a7h,0f8h,0a1h,0ach,0e2h
            db    069h,0dch,0d7h,0d7h,0d7h,0b6h,0d7h,0d7h
            db    0d7h,0a6h,0d4h,0dch,0beh,032h,0f4h,0fbh
            db    00ah,032h,0efh,0dch,0aeh,022h,061h,09eh
            db    0fbh,00bh,032h,0c2h,09eh,0fbh,00fh,03ah
            db    08fh,0f8h,06fh,0ach,0f8h,040h,0b9h,093h
            db    0f6h,0dch,029h,099h,03ah,097h,0f8h,010h
            db    0a7h,0f8h,008h,0a9h,046h,0b7h,093h,0feh
            db    0dch,086h,03ah,0adh,02eh,097h,0f6h,0b7h
            db    0dch,029h,089h,03ah,0adh,017h,087h,0f6h
            db    0dch,08eh,03ah,09eh,0dch,069h,026h,0d4h
            db    030h,0c0h,0f8h,083h,0ach,0f8h,00ah,0b9h
            db    0dch,033h,0c5h,029h,099h,03ah,0c8h,0dch
            db    03bh,0cfh,0f8h,009h,0a9h,0a7h,097h,076h
            db    0b7h,029h,0dch,089h,03ah,0d6h,087h,0f6h
            db    033h,0e3h,07bh,097h,056h,016h,086h,03ah
            db    0cfh,02eh,08eh,03ah,0cfh,030h,0bdh,0dch
            db    016h,0d4h,030h,0efh,0d7h,0d7h,0d7h,056h
            db    0d4h,016h,030h,0f4h,000h,000h,000h,000h
            db    030h,039h,022h,02ah,03eh,020h,024h,034h
            db    026h,028h,02eh,018h,014h,01ch,010h,012h
            db    0f0h,080h,0f0h,080h,0f0h,080h,080h,080h
            db    0f0h,050h,070h,050h,0f0h,050h,050h,050h
            db    0f0h,080h,0f0h,010h,0f0h,080h,0f0h,090h
            db    0f0h,090h,0f0h,010h,0f0h,010h,0f0h,090h
            db    0f0h,090h,090h,090h,0f0h,010h,010h,010h
            db    010h,060h,020h,020h,020h,070h,0a0h,0a0h
            db    0f0h,020h,020h,07ah,042h,070h,022h,078h
            db    022h,052h,0c4h,019h,0f8h,000h,0a0h,09bh
            db    0b0h,0e2h,0e2h,080h,0e2h,0e2h,020h,0a0h
            db    0e2h,020h,0a0h,0e2h,020h,0a0h,03ch,053h
            db    098h,032h,067h,0abh,02bh,08bh,0b8h,088h
            db    032h,043h,07bh,028h,030h,044h,0d3h,0f8h
            db    00ah,03bh,076h,0f8h,020h,017h,07bh,0bfh
            db    0ffh,001h,03ah,078h,039h,06eh,07ah,09fh
            db    030h,078h,0d3h,0f8h,010h,03dh,085h,03dh
            db    08fh,0ffh,001h,03ah,087h,017h,09ch,0feh
            db    035h,090h,030h,082h,0d3h,0e2h,09ch,0afh
            db    02fh,022h,08fh,052h,062h,0e2h,0e2h,03eh
            db    098h,0f8h,004h,0a8h,088h,03ah,0a4h,0f8h
            db    004h,0a8h,036h,0a7h,088h,031h,0aah,08fh
            db    0fah,00fh,052h,030h,094h,000h,000h,000h
            db    000h,0d3h,0dch,0feh,0feh,0feh,0feh,0aeh
            db    0dch,08eh,0f1h,030h,0b9h,0d4h,0aah,00ah
            db    0aah,0f8h,005h,0afh,04ah,05dh,08dh,0fch
            db    008h,0adh,02fh,08fh,03ah,0cch,08dh,0fch
            db    0d9h,0adh,030h,0c5h,0d3h,022h,006h,073h
            db    086h,073h,096h,052h,0f8h,006h,0aeh,0f8h
            db    0d8h,0adh,002h,0f6h,0f6h,0f6h,0f6h,0d5h
            db    042h,0fah,00fh,0d5h,08eh,0f6h,0aeh,032h
            db    0dch,03bh,0eah,01dh,01dh,030h,0eah,001h

path:       db    '/vip/'

file:       ; filename will be appended here

end:        ; end of what is included in the executable size

dta:        ds    512

ram:        ; static memory address where vip code will be buffered

