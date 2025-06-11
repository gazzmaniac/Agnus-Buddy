# Agnus-Buddy
3 MB bank switching chip ram card for SMD 2000
# Agnus&Buddy
3 MB chip ram card for SMD 2000

## Introduction
This is a 3 MB Agnus Card for the SMD2000 "BUSHFIRE" project, a mini-DTX sized Amiga 2000.  Official project information can be found at Amiga Retro Brisbane projects page:
https://www.amigaretro.com/projects/

This card uses bank switching to address 3 MB of chip ram in the SMD2000.  It is intended solely for proof of concept for bank switching in the chip ram space of the ECS Amiga.  There is provision for future editions to potentially address up to 65 MB using the 2 MB Agnus and 32.5 MB using a 1 MB Agnus.   This should be considered highly experimental, and constructed by people who intend to either program for it or improve the physical design.

This card uses a 2 MB 8375 Agnus from an A500+ or A600.  Not all 8375s will work!!!! See notes on Agnus revisions below.
Do not build this card for general use with the SMD2000.  It is recommmended that regular users construct one of the following cards instead:

1 MB SMD Agnus card: https://github.com/gazzmaniac/SMD2000_Agnus_1MB 
2 MB Agnus card: https://github.com/gazzmaniac/SMD2000_Agnus2MB 
1 MB TTH Agnus card: https://github.com/gazzmaniac/SMD2000_Agnus_1MB_TTH 

## Special thanks
Special thanks to BirdHandler who suggested this idea, Retroswim who helped with testing and made the video (see project page at amigaretro.com) and Intangibles for hosting.

## Requirements
To use this card you need an SMD2000 motherboard and a CPU card.  They are documented separately.

Motherboard: https://github.com/gazzmaniac/SMD2000/ 

Basic CPU card: https://github.com/gazzmaniac/SMD2000_cpu-card

It is suggested that any user also use Amiga Monitor from Aminet:
https://aminet.net/package/dev/moni/AmigaMon_162

## How the card works
The card uses the memory space addressable by the 2 MB Agnus.  
Addresses 00 0000 through 0F FFFF is always connected (i.e. it behaves like ordinary chip ram).
Addresses 10 0000 through 1F FFFF contain the switchable banks.  
A detailed description of how the expansion works is provided in the Functional Description document.

The CPLD "Buddy" (because it's Agnus's buddy) contains a new register in the custom chip space called BNKCTR, at DFF1F0.  This register is one byte wide and consists of an instruction and a ram bank number:
| Instruction | Function |
| 0h=0000b | Disconnect all banks |
| 2h=0010b | Connect bank # |
| 6h=0110b | Connect and reset-proof bank # |

The bank number is just a number between 0 and F (there are actually two spare bits in the instruction nibble, this could eventually be up to 64 banks).
Writing the byte 21h to BNKCTR would connect bank #1.
Writing the byte 60h to BNKCTR would connect bank #0 and reset proof it (more about that below).
Writing the byte 00h to BNKCTR would disconnect all banks.
Attempting to write any other instruction to the register is an illegal instruction and will also disconnect all banks.

### Bank selection 
At power on there is no RAM connected at the chip ram expansion addresses 10 0000 through 1F FFFF.  This is so the OS doesn't try to use it and crash when it's changed.
The user/programmer can connect a bank by poking an instruction to the BNKCTR register at DFF1F0, as described above.
If instruction 2 is issued, a bank of RAM will be connected at addresses 10 000 through 1F FFFF.  This can then be used by software, however it will not be available to the OS.  If the Amiga is reset then the bank is disconnected.
Instruction 6 works the same as instruction 2, except the bank is not disconnected on reset.  This allows it to be available for the OS to use following a reset.

### Status and Config registers
The current status of the expansion can be obtained by reading a new register BNKSTA at DFF1F4 (it reads back the byte written to the BNKCON register DFF1F0).
The expansion's configuration may be determined by reading a new register BNKCON at DFF1F6.
These two registers are one byte wide and use the lower half of the address bus (i.e. they're really at DFF1F5 and DFF1F7).  They were intended to be one 16-bit wide register but I ran out of space on the CPLD and had to drop the output buffer for half of the data bus to make everything else fit.
Refer the Functional Description document for more detail about how these registers work.

### Copper
During development the registers were accessed only by the CPU.
The registers were deliberately placed in the address space for the Amiga registers so that the BNKCTR register might be operated by the Copper part way through a frame.  This functionality has not been tested because I am not a programmer and don't know how to do it.  If someone who knows how to write copper lists builds the card I'd really appreciate it if you could tests this function.


## Notes about Agnus revisions
This board is designed for the 2 MB 8375 Agnus from the A500+ and A600 only.  NOT ALL 8375s will work!!!!

1 MB and 512 kb Agnus from A500/A2000 (8370, 8371, 8372A) and 2 MB Agnus from A3000 (8372AB and 8372B) have a different pinout and WILL NOT WORK.  A bank switching board supporting these Agnuses may be a future project.

The 8375 Agnus ICs are not all the same.  Only Agnus with the following Commodore part numbers have the correct pinout:
390544-01, 318069-10 (PAL)
390544-02, 318069-11 (NTSC)

All the rest are the same pinout as the 1 MB Agnus.

## Change Log
Rev0 - initial release
Only minor layout changes from the working prototype, with the only change being the addition of RP302 & RP303, the pull  up resistors on the control lines for each of the switchable RAM banks.  This exact release has not been built; the near-identical working prototype omitted these resistors and were added by bodging in TTH resistors.

## References
Agnus Specification Rev C; 20/7/1988
Denise Specification; 1988 (Amigawiki.de version)
Motorola MC68000 microprocessor user manual 9ed; 1993.
A500+ Service Manual; October 1991.
Amiga Hardware Reference Manual 3ed; 1991.
US Patent 4,777,621 (Amiga patent); 11/7/1988.
Paula Dissection, http://forum.6502.org/viewtopic.php?f=4&t=7681 
Various component data sheets.  Refer component metadata in KiCad.
Symbols and footprints for most parts were downloaded from Mouser/Samacsys, and many were modified to make the schematics more readable.  Samacsys parts do not require further attribution, however I am doing so anyhow.  
Links to datasheets are in the symbol metadata. 
Footprints and symbols for generic parts e.g. jumpers/headers use Kicad libraries. 

Agnus Revision Information:
https://www.amigawiki.org/lib/exe/fetch.php?media=de:parts:agnus_reworks.pdf
https://bigbookofamigahardware.com/bboah/product.aspx?id=1478


## Licensing
Design is open source hardware.
1. Any and all derivative designs must also be open source.
2. No person, business, or other entity associated with this design shall be liable for any damages incurred by anyone as a result of using this design.  If you do not accept this condition do not build the project.
3. Free for private use by anyone.
5. Free for anyone to make for sale.
5. CERN Open Hardware Licence Version 2 - Strongly Reciprocal (CERN-OHL-S) license applies, subject to conditions 1-3 above.
6. Any portions of this design from other projects shall be licensed according to their respective licenses if their licenses are not compatible with CERN-OHL-S or the conditions above.
7. All Other Rights Reserved.


